resource "aws_iam_role" "cluster_role" {
    name = "eks-cluster-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
    })
    
    tags = {
        Name = "eks-cluster-role"
    }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role" {
    role = aws_iam_role.cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "worker_role" {
    name = "eks-worker-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Sid    = ""
            Principal = {
            Service = "ec2.amazonaws.com"
            }
        },
        ]
    })
    tags = {
        Name = "worker-role"
    }
}

resource "aws_iam_role_policy_attachment" "worker_policy" {
    role = aws_iam_role.worker_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "CNI_policy" {
    role = aws_iam_role.worker_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "pull_image_policy" {
    role = aws_iam_role.worker_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name = "github-actions-oidc"
  }
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
            StringEquals = {
                "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
                "token.actions.githubusercontent.com:sub" = "repo:ahmmedtarek@182046826/Advanced-Eks-Platform@1377328342:ref:refs/heads/main"
            }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions_ecr" {
  name        = "github-actions-ecr-policy"
  description = "Allow GitHub Actions to push images to frontend and backend ECR repositories"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]

        Resource = [
          var.aws_ecr_repository_frontend_arn,
          var.aws_ecr_repository_backend_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ecr.arn
}

data "aws_eks_cluster" "ebs_csi" {
  name = var.cluster_name
}



locals {
  ebs_csi_oidc_host = replace(data.aws_eks_cluster.ebs_csi.identity[0].oidc[0].issuer, "https://", "")
}

data "tls_certificate" "ebs_csi" {
  url = data.aws_eks_cluster.ebs_csi.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "ebs_csi" {
  url             = data.aws_eks_cluster.ebs_csi.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.ebs_csi.certificates[0].sha1_fingerprint]
}
resource "aws_iam_role" "ebs_csi" {
  name = "ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.ebs_csi.arn }
      Condition = {
        StringEquals = {
          "${local.ebs_csi_oidc_host}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${local.ebs_csi_oidc_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [aws_iam_role_policy_attachment.ebs_csi]
}

resource "aws_iam_policy" "lbc" {
  name = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/lbc_policy.json")
}

resource "aws_iam_role" "lbc" {
  name = "aws-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.ebs_csi.arn }
      Condition = {
        StringEquals = {
          "${local.ebs_csi_oidc_host}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${local.ebs_csi_oidc_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}

resource "aws_iam_role" "vpc_cni" {
  name = "vpc-cni"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.ebs_csi.arn }
      Condition = {
        StringEquals = {
          "${local.ebs_csi_oidc_host}:sub" = "system:serviceaccount:kube-system:aws-node"
          "${local.ebs_csi_oidc_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = var.cluster_name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.vpc_cni.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    enableNetworkPolicy = "true"
  })

  depends_on = [aws_iam_role_policy_attachment.vpc_cni]
}