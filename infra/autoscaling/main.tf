# Security groups
resource "aws_security_group" "asg_sg" {
  name        = "${var.project_name}-sg-${var.environment}"
  description = "asg repo private security group"
  vpc_id      = data.aws_vpc.vpc.id

  # Access from other security groups
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
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


resource "aws_security_group" "asg_alb_sg" {
  name        = "${var.project_name}-lb-sg-${var.environment}"
  description = "ALB security group"
  vpc_id      = data.aws_vpc.vpc.id

  # Access from other security groups
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
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

  load_balancer_type = "application"
  vpc_id             = data.aws_vpc.vpc.id
  security_groups    = [aws_security_group.asg_alb_sg.id]
  subnets            = [for s in data.aws_subnet.public_subnet_list : s.id]

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
      name             = "${var.project_name}-tg-${var.environment}"
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
  name                      = "${var.project_name}-asg-${var.environment}-dev"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  wait_for_capacity_timeout = 0
  health_check_grace_period = var.asg_grace
  vpc_zone_identifier       = [for s in data.aws_subnet.public_subnet_list : s.id]


  initial_lifecycle_hooks = [
    {
      name                  = "Startuphook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 60
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
      notification_metadata = jsonencode({ "hello" = "world" })
    },
    {
      name                  = "Terminationhook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 180
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
      notification_metadata = jsonencode({ "goodbye" = "world" })
    }
  ]
  target_group_arns = module.alb.target_group_arns
  security_groups   = [aws_security_group.asg_sg.id]

  # Launch template
  create_launch_template      = true
  launch_template_name        = "${var.project_name}-lt-${var.environment}"
  launch_template_description = "asg ec2 launch template for ${var.project_name}'s  instances in ${var.environment}."
  update_default_version      = true

  image_id          = var.asg_ami_id
  instance_type     = var.asg_instance_type
  key_name          = var.asg_ssh_key_name
  user_data_base64  = filebase64("${path.module}/userdata")
  ebs_optimized     = true
  enable_monitoring = true

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 20
        volume_type           = "gp2"
      }
      }, {
      device_name = "/dev/sda1"
      no_device   = 1
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 30
        volume_type           = "gp2"
      }
    }
  ]
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


}