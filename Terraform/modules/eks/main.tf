resource "aws_eks_cluster" "main" {
  name = "devops-eks-cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = var.aws_eks_cluster_role_arn
  version  = "1.35"

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "devops-eks-node-group"

  node_role_arn = var.aws_iam_role_worker_role_arn

  subnet_ids = var.private_subnet_ids

  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 2
  }


  tags = {
    Name = "eks-worker-node"
  }
}

resource "aws_eks_access_entry" "admin_user" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.principal_arn
}

resource "aws_eks_access_policy_association" "admin_user" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_eks_access_entry.admin_user.principal_arn

  policy_arn = var.policy_arn

  access_scope {
    type = "cluster"
  }
}