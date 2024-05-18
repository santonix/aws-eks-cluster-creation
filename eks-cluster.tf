/*
 Terraform will use the terraform-aws-modules/eks/aws module
to configure and provision the AWS EKS cluster. It will create
 a t3.small instance type for the eks_managed_node_groups.
 */
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.4"

  cluster_name    = local.cluster_name
  cluster_version = "1.24"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

resource "aws_iam_policy" "create_log_group_and_tag_resource" {
  name        = "CreateLogGroupAndTagResourcePolicy"
  description = "Policy to allow creating log group and tagging KMS resources"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:PutRetentionPolicy"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Effect" : "Allow",
        "Action" : "kms:TagResource",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "francis_create_log_group_and_tag_resource" {
  user       = "francis"
  policy_arn = aws_iam_policy.create_log_group_and_tag_resource.arn
}

# Create IAM Policy for EKS-related actions
resource "aws_iam_policy" "eks_policy" {
  name        = "EKSFullAccessPolicy"
  description = "Policy to allow full access to EKS resources"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "eks:*",
          "ec2:*",
          "cloudwatch:*",
          "iam:GetPolicy",
          "iam:ListPolicyVersions",
          "iam:GetPolicyVersion",
          "iam:PassRole"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# Attach EKS Policy to Francis User
resource "aws_iam_user_policy_attachment" "francis_eks_policy" {
  user       = "francis"
  policy_arn = aws_iam_policy.eks_policy.arn
}

resource "aws_iam_policy" "assume_role_policy" {
  name        = "AssumeRolePolicy"
  description = "Policy to allow assuming necessary roles"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Resource" : "*"
      }
    ]
  })
}


