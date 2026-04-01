data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "finstack-tf-state-256461400092"
    key    = "finstack/terraform.tfstate"
    region = "eu-north-1"
  }
}

data "aws_eks_cluster_auth" "eks" {
  name = data.terraform_remote_state.infra.outputs.eks_cluster_name
}
