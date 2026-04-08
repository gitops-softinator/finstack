variable "aws_region" {
	default = "eu-north-1"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  default     = 4
}
