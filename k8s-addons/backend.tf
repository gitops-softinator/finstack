terraform {
  backend "s3" {
    bucket         = "finstack-tf-state-256461400092"
    key            = "finstack/k8s-addons.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "finstack-tf-locks"
    encrypt        = true
  }
}
