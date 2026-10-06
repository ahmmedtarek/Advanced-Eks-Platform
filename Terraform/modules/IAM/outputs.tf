output "aws_eks_cluster_role_arn" {
    value = aws_iam_role.cluster_role.arn
}

output "aws_iam_role_worker_role_arn" {
    value = aws_iam_role.worker_role.arn
}