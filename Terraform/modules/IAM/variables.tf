variable "aws_ecr_repository_frontend_arn" {
    type = string
}

variable "aws_ecr_repository_backend_arn" {
    type = string
}

variable "cluster_name" {
  type    = string
  default = "devops-eks-cluster"
}