variable "private_subnet_ids" {
  description = "IDs of the private subnets used by EKS"
  type        = list(string)
}

variable "aws_eks_cluster_role_arn" {
    type = string
}

variable "aws_iam_role_worker_role_arn" {
    type = string
}

variable "principal_arn" {
    type = string
}

variable "policy_arn" {
    type = string
}