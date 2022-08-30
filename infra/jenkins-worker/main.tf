resource "random_id" "random" {
  byte_length = 4
}

# Instance IAM profile, roles and policies
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.application_name}-instance-profile-${var.environment}-${random_id.random.hex}"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name = "${var.application_name}-instance-role-${var.environment}-${random_id.random.hex}"
  assume_role_policy = jsonencode(
    {
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
    }
  )
}

resource "aws_iam_policy" "instance_s3_policy" {
  name        = "${var.application_name}-s3-policy-${var.environment}-${random_id.random.hex}"
  description = "iam access policy for ${var.project_name} ${var.application_name} instance access to s3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:List*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.instance_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.instance_role.name
  policy_arn = data.aws_iam_policy.ssm_instance_policy.arn
}


resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
  description      = "A service linked role for ${var.project_name} ${var.application_name} autoscaling"
  custom_suffix    = "${var.application_name}-${var.environment}-${random_id.random.hex}"

  # Sometimes good sleep is required to have some IAM resources created before they can be used
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

# Security groups
resource "aws_security_group" "instance_sg" {
  name        = "${var.application_name}-sg-${var.environment}-${random_id.random.hex}"
  description = "asg repo private security group"
  vpc_id      = data.aws_vpc.selected.id

  # Access from other security groups
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.5.0"

  name = "${var.project_name}-${var.application_name}-instance-${var.environment}-${random_id.random.hex}"
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  subnet_id       = element(data.aws_subnets.private_subnets.ids, 0)
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  ami          = var.ami_id
  instance_type     = var.instance_type
  associate_public_ip_address = false
  key_name          = var.ssh_key_name
  user_data_base64  = base64encode(local.user_data)

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = var.instance_root_device_size
      },
    ]

  tags = local.tags
  // tags_as_map = local.tags

}

