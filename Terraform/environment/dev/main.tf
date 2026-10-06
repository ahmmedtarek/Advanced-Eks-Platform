module "vpc" {
  source = "../../modules/vpc"
}

module "backend" {
  source = "../../modules/backend"
}

module "IAM" {
  source = "../../modules/IAM"
  aws_ecr_repository_frontend_arn = module.ecr.aws_ecr_repository_frontend_arn
  aws_ecr_repository_backend_arn = module.ecr.aws_ecr_repository_backend_arn
}

module "eks" {
  source = "../../modules/eks"
  private_subnet_ids = module.vpc.private_subnet_ids
  aws_eks_cluster_role_arn = module.IAM.aws_eks_cluster_role_arn
  aws_iam_role_worker_role_arn = module.IAM.aws_iam_role_worker_role_arn
  principal_arn = "arn:aws:iam::305018987435:user/ahmmedtarek"
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}

module "ecr" {
  source = "../../modules/ecr"
}