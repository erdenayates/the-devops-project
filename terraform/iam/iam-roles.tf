# IAM Role for AWS Systems Manager Session Manager
resource "aws_iam_role" "session_manager_role" {
  name = "session-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  description = "IAM role for AWS Systems Manager Session Manager"
}

resource "aws_iam_policy" "custom_session_manager_permissions" {
  name        = "CustomSessionManagerPermissions"
  description = "Allow additional SSM permissions for Session Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ssm:ListInstanceAssociations",
          "ssm:UpdateInstanceInformation"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "session_manager_policy_attachment" {
  role       = aws_iam_role.session_manager_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "custom_session_manager_permissions_attachment" {
  role       = aws_iam_role.session_manager_role.name
  policy_arn = aws_iam_policy.custom_session_manager_permissions.arn
}


resource "aws_iam_instance_profile" "session_manager_instance_profile" {
  name = "session-manager-instance-profile"
  role = aws_iam_role.session_manager_role.name
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-jenkins-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          AWS = [
            aws_iam_role.session_manager_role.arn,
            "arn:aws:iam::792334107397:user/jenkins-job-user"
          ]
        }
      }
    ]
  })

  tags = {
    Name = "codebuild-jenkins-service-role"
  }
}


resource "aws_iam_policy" "codebuild_ecr_public_permissions" {
  name        = "CodeBuildECRPublicPermissions"
  description = "Allow CodeBuild to interact with ECR Public Repositories"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ecr-public:BatchGetImage",
          "ecr-public:BatchCheckLayerAvailability",
          "ecr-public:CompleteLayerUpload",
          "ecr-public:DescribeImages",
          "ecr-public:DescribeRepositories",
          "ecr-public:GetDownloadUrlForLayer",
          "ecr-public:InitiateLayerUpload",
          "ecr-public:ListImages",
          "ecr-public:PutImage",
          "ecr-public:UploadLayerPart"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr_public_permissions_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_ecr_public_permissions.arn
}


# Policy for session-manager-role to assume codebuild-jenkins-service-role
resource "aws_iam_role_policy" "allow_assume_codebuild_role" {
  name   = "AllowAssumeCodeBuildRole"
  role   = aws_iam_role.session_manager_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Resource = aws_iam_role.codebuild_role.arn
      }
    ]
  })
}

resource "aws_iam_policy" "codebuild_cloudwatch_logs" {
  name        = "CodeBuildCloudWatchLogsPermissions"
  description = "Allow CodeBuild to put log events to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_cloudwatch_logs_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_cloudwatch_logs.arn
}

# New Policy to allow ec2:DescribeNetworkInterfaces
resource "aws_iam_policy" "codebuild_ec2_permissions" {
  name        = "CodeBuildEC2Permissions"
  description = "Allow CodeBuild to describe EC2 network interfaces"

  policy = jsonencode({
    Version = "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateTags",
				"ec2:DescribeDhcpOptions",
				"ec2:DescribeNetworkInterfaces",
				"ec2:DescribeSecurityGroups",
				"ec2:DescribeSubnets",
				"ec2:DescribeVpcs"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateNetworkInterface",
				"ec2:CreateNetworkInterfacePermission",
				"ec2:DeleteNetworkInterface"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:CreateNetworkInterface",
			"Resource": "arn:aws:ec2:us-east-2:792334107397:subnet/*"
		},
		{
			"Effect": "Allow",
			"Action": "logs:CreateLogStream",
			"Resource": "arn:aws:logs:us-east-2:792334107397:log-group:*"
		}
	]
  })
}

resource "aws_iam_policy" "allow_jenkins_user_assume_codebuild_role" {
  name        = "AllowJenkinsUserAssumeCodeBuildRole"
  description = "Allow Jenkins user to assume the CodeBuild role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "sts:AssumeRole",
        Effect   = "Allow",
        Resource = aws_iam_role.codebuild_role.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "jenkins_user_assume_codebuild_role_attachment" {
  user       = "jenkins-job-user"
  policy_arn = aws_iam_policy.allow_jenkins_user_assume_codebuild_role.arn
}

resource "aws_iam_policy" "codebuild_terraform_backend_permissions" {
  name        = "CodeBuildTerraformBackendPermissions"
  description = "Allow CodeBuild to access the Terraform S3 backend and DynamoDB lock table"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:s3:::the-lazy-devops-project-tfstate-bucket",
          "arn:aws:s3:::the-lazy-devops-project-tfstate-bucket/*"
        ]
      },
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:dynamodb:us-east-2:792334107397:table/the-lazy-devops-project-tfstate-lock"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_terraform_backend_permissions_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_terraform_backend_permissions.arn
}

resource "aws_iam_policy" "codebuild_enhanced_permissions" {
  name        = "CodeBuildEnhancedPermissions"
  description = "Custom policy for enhanced CodeBuild operations"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:CreateTags",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetGroups",
          "sts:GetCallerIdentity",
          "ec2:CreateNetworkInterface",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeVpcAttribute",
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "logs:CreateLogStream"
        ],
        Effect   = "Allow",
        Resource = [
          "*"
        ]
      },
      {
        Action = [
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:PassRole"
        ],
        Effect = "Allow",
        Resource =  [
          "arn:aws:iam::792334107397:role/ecs-service-role",
          "arn:aws:iam::792334107397:role/ecs-execution-role"
        ]
      },
      {
        Action = [
          "ec2:DescribeVpcs"
        ],
        Effect   = "Allow",
        Resource = ["*"]
      },
      {
        Action = [
          "iam:ListRolePolicies"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:iam::792334107397:role/ecs-service-role",
          "arn:aws:iam::792334107397:role/ecs-execution-role"
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "codebuild_enhanced_permissions_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_enhanced_permissions.arn
}


terraform {
  backend "s3" {
    bucket         = "the-lazy-devops-project-tfstate-bucket"
    key            = "terraform/iam/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "the-lazy-devops-project-tfstate-lock"
  }
}
