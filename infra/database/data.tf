data "aws_region" "current" {}

data "aws_availability_zones" "available" {
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}*"]
  }
}

data "aws_subnet_ids" "private_subnets" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-private*"]
  }
}

data "aws_subnet" "private_subnet_list" {
  for_each = data.aws_subnet_ids.private_subnets.ids
  id       = each.value
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-public*"]
  }
}

data "aws_subnet" "public_subnet_list" {
  for_each = data.aws_subnet_ids.public_subnets.ids
  id       = each.value
}