resource "random_id" "asg_random" {
  byte_length = 4
}

# Instance IAM profile, roles and policies
resource "aws_iam_instance_profile" "asg_instance_profile" {
  name = "${var.application_name}-instance-profile-${var.environment}-${random_id.asg_random.hex}"
  role = aws_iam_role.asg_instance_role.name
}

resource "aws_iam_role" "asg_instance_role" {
  name = "${var.application_name}-instance-role-${var.environment}-${random_id.asg_random.hex}"
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

resource "aws_iam_policy" "asg_instance_s3_policy" {
  name        = "${var.application_name}-s3-policy-${var.environment}-${random_id.asg_random.hex}"
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

resource "aws_iam_role_policy_attachment" "asg_s3_policy_attach" {
  role       = aws_iam_role.asg_instance_role.name
  policy_arn = aws_iam_policy.asg_instance_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "asg_ssm_policy_attach" {
  role       = aws_iam_role.asg_instance_role.name
  policy_arn = data.aws_iam_policy.asg_ssm_instance_policy.arn
}


resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
  description      = "A service linked role for ${var.project_name} ${var.application_name} autoscaling"
  custom_suffix    = "${var.application_name}-${var.environment}-${random_id.asg_random.hex}"

  # Sometimes good sleep is required to have some IAM resources created before they can be used
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

# Security groups
resource "aws_security_group" "asg_sg" {
  name        = "${var.application_name}-sg-${var.environment}-${random_id.asg_random.hex}"
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
    cidr_blocks = ["12.139.124.198/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "asg_alb_sg" {
  name        = "${var.application_name}-lb-sg-${var.environment}-${random_id.asg_random.hex}"
  description = "ALB security group"
  vpc_id      = data.aws_vpc.selected.id

  # Access from other security groups
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["12.139.124.198/32"]
  }
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


module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "7.0.0"

  load_balancer_type = "application"
  vpc_id             = data.aws_vpc.selected.id
  security_groups    = [aws_security_group.asg_alb_sg.id]
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
      name             = "${var.application_name}-${var.environment}-${random_id.asg_random.hex}"
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "instance"
    },
  ]
}


module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "5.1.1"

  # Autoscaling group
  name                      = "${var.application_name}-asg-${var.environment}-${random_id.asg_random.hex}"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  wait_for_capacity_timeout = 0
  health_check_grace_period = var.asg_grace
  vpc_zone_identifier       = [for s in data.aws_subnet.public_subnet_lists : s.id]

  initial_lifecycle_hooks = var.asg_initial_lifecycle_hooks
  target_group_arns       = module.alb.target_group_arns
  security_groups         = [aws_security_group.asg_sg.id]

  # Launch template
  create_launch_template      = true
  launch_template_name        = "${var.application_name}-lt-${var.environment}-${random_id.asg_random.hex}"
  launch_template_description = "asg ec2 launch template for ${var.project_name}'s ${var.application_name} instances in ${var.environment}."
  update_default_version      = true

  image_id          = var.asg_ami_id
  instance_type     = var.asg_instance_type
  key_name          = var.asg_ssh_key_name
  user_data_base64  = base64encode(local.user_data)
  ebs_optimized     = true
  enable_monitoring = true

  block_device_mappings = var.asg_block_device_mappings
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 32
  }

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = { resourceType = "Instance" }
    },
    {
      resource_type = "volume"
      tags          = { resourceType = "Volume" }
    }
  ]

  tags = local.tags
}

