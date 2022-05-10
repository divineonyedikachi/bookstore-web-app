
data "aws_region" "current" {}

data "aws_availability_zones" "available" {}


// data "aws_vpc" "selected" {
//   filter {
//     name   = "tag:Name"
//     values = ["${var.project_name}-vpc-${var.environment}"]
//   }
// }


# bring your own vpc. 
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}*"]
  }
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.selected.id
}

data "aws_subnet" "subnet_all_lists" {
  for_each = data.aws_subnet_ids.all.ids
  id       = each.value
}

// data "aws_subnet_ids" "subnets" {
//   vpc_id = data.aws_vpc.selected.id
//   filter {
//     name   = "tag:Name"
//     values = ["${var.project_name}-${var.subnet_filter_tag}-${var.environment}"]
//   }
// }

# bring your own subnets. 
// data "aws_subnet_ids" "subnets" {
//   vpc_id = data.aws_vpc.selected.id
//   filter {
//     name   = "tag:Name"
//     values = ["${var.project_name}-private*"]
//   }
// }

// data "aws_subnet" "subnet_lists" {
//   for_each = data.aws_subnet_ids.subnets.ids
//   id       = each.value
// }


data "aws_subnets" "private_subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-private*"]
  }
}

data "aws_subnet" "private_subnet_lists" {
  for_each = toset(data.aws_subnets.private_subnets.ids)
  id       = each.value
}


data "aws_subnets" "public_subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-public*"]
  }
}

data "aws_subnet" "public_subnet_lists" {
  for_each = toset(data.aws_subnets.public_subnets.ids)
  id       = each.value
}




data "aws_iam_policy" "asg_ssm_instance_policy" {
  name = "AmazonSSMManagedInstanceCore"
}


locals {
  s3_logging_bucket_name = "${var.project_name}-${var.application_name}-logging-${var.environment}-${random_id.asg_random.hex}"
  asg_tags = [
    {
      key                 = "Name"
      value               = "${var.project_name}-${var.application_name}-instance-${var.environment}-${random_id.asg_random.hex}"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
  ]

  tags = {
    Environment   = var.environment
    Project       = var.project_name
    Owner         = var.owner
    "Cost Center" = var.cost_center
  }

  asg_instance_tags = [
    {
      key                 = "Environment"
      value               = var.environment
      propagate_at_launch = true
    },
    {
      key                 = "Owner"
      value               = var.owner
      propagate_at_launch = true
    },
    {
      key                 = "Cost Center"
      value               = var.cost_center
      propagate_at_launch = true
    },
    {
      key                 = "Operating System"
      value               = var.operating_system
      propagate_at_launch = true
    },
  ]

  user_data = file("${path.module}/userdata")

}


