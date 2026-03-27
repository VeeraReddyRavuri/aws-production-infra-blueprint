resource "aws_iam_role" "ec2_role" {
    name = "${var.env}-ec2-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        ]
    })  
}

resource "aws_iam_policy" "ec2_policy" {
    name = "${var.env}-ec2-policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:GetObject"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow"
                Action = [
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
                Resource = "*"
            }
        ]
    })  
}

resource "aws_iam_role_policy_attachment" "attach" {
    role = aws_iam_role.ec2_role.name
    policy_arn = aws_iam_policy.ec2_policy.arn  
}

resource "aws_iam_instance_profile" "ec2_profile" {
    name = "${var.env}-ec2-profile"
    role = aws_iam_role.ec2_role.name  
}