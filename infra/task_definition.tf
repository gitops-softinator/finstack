resource "aws_ecs_task_definition" "frontend" {
	family = "frontend"
	network_mode = "awsvpc"
	requires_compatibilities = ["FARGATE"]

	cpu = "256"
	memory = "512"

	container_definitions = jsonencode([
		{
			name = "frontend"
			image = "gitopssoftinator/finstack-frontend:latest"

			portMappings = [
				{
					containerPort = 80
					hostPort = 80
				}	
			]
		}
	])
} 
