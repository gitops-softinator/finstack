resource "aws_efs_file_system" "monitoring" {
  creation_token = "finstack-monitoring-efs"
  encrypted      = true

  tags = {
    Name = "finstack-monitoring-efs"
  }
}

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Allow NFS traffic for EFS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_mount_target" "monitoring" {
  file_system_id  = aws_efs_file_system.monitoring.id
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "monitoring_2" {
  file_system_id  = aws_efs_file_system.monitoring.id
  subnet_id       = aws_subnet.private_2.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_access_point" "prometheus" {
  file_system_id = aws_efs_file_system.monitoring.id
  posix_user {
    gid = 65534
    uid = 65534
  }
  root_directory {
    path = "/prometheus"
    creation_info {
      owner_gid   = 65534
      owner_uid   = 65534
      permissions = "777"
    }
  }
}

resource "aws_efs_access_point" "grafana" {
  file_system_id = aws_efs_file_system.monitoring.id
  posix_user {
    gid = 472
    uid = 472
  }
  root_directory {
    path = "/grafana"
    creation_info {
      owner_gid   = 472
      owner_uid   = 472
      permissions = "777"
    }
  }
}

resource "aws_efs_access_point" "alertmanager" {
  file_system_id = aws_efs_file_system.monitoring.id
  posix_user {
    gid = 65534
    uid = 65534
  }
  root_directory {
    path = "/alertmanager"
    creation_info {
      owner_gid   = 65534
      owner_uid   = 65534
      permissions = "777"
    }
  }
}
