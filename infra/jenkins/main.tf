resource "random_id" "random" {
  byte_length = 2
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
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["98.218.211.45/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.application_name}-lb-sg-${var.environment}-${random_id.random.hex}"
  description = "ALB security group"
  vpc_id      = data.aws_vpc.selected.id

  # Access from other security groups
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["98.218.211.45/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "7.0.0"

  name               = "${var.project_name}-alb-${random_id.random.hex}"
  load_balancer_type = "application"
  vpc_id             = data.aws_vpc.selected.id
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in data.aws_subnet.public_subnet_lists : s.id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      # action_type        = "forward"
    },
  ]

  target_groups = [
    {
      name             = "${var.project_name}-tg-${var.environment}-${random_id.random.hex}"
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "instance"
      targets = [
        {
          target_id = module.instance.id
          port      = 8080
        },
      ]
      health_check = {
        enabled             = true
        interval            = 10
        path                = "/login"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
      }
      protocol_version = "HTTP1"
    },
  ]
}


module "instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.5.0"

  name                 = "${var.project_name}-${var.application_name}-instance-${var.environment}-${random_id.random.hex}"
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  subnet_id              = element(data.aws_subnets.public_subnets.ids, 0)
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  ami                         = var.ami_id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name                    = var.ssh_key_name
  user_data_base64            = base64encode(local.user_data)

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









