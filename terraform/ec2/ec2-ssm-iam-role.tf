resource "aws_iam_role" "session_manager_role" {
  name = "session-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  description = "IAM role for AWS Systems Manager Session Manager"
}

resource "aws_iam_role_policy_attachment" "session_manager_policy_attachment" {
  role       = aws_iam_role.session_manager_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "session_manager_instance_profile" {
  name = "session-manager-instance-profile"
  role = aws_iam_role.session_manager_role.name
}
