output "aws_ecr_repository_frontend_arn" {
    value = aws_ecr_repository.frontend.arn
}

output "aws_ecr_repository_backend_arn" {
    value = aws_ecr_repository.backend.arn
}
