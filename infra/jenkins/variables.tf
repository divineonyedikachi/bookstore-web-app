
variable "vpc_id" {
  type    = string
  default = "vpc-xxxxxxx"
}

variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "application_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "owner" {
  type = string
}

variable "cost_center" {
  type = string
}

variable "operating_system" {
  type = string
}

// variable "subnet_filter_tag" {
//   description = "name used to filter subnets used by asg. Options are public, private, and database"
//   type        = string
// }

# bring your own subnets
variable "private_subnets_tag" {
  description = "subnet name tag filter for asg instances"
  type        = list(string)
}

# elb vars
variable "asg_elb_listeners" {
  type = list(map(string))
}

variable "elb_healthy_threshold" {
}

variable "elb_unhealthy_threshold" {
}

variable "elb_timeout" {
}

variable "elb_interval" {
}


# asg vars
variable "asg_ssh_key_name" {
  type = string
}

variable "asg_grace" {
  type = string
}

variable "min_size" {
}

variable "max_size" {
}

variable "desired_capacity" {
}

variable "health_check_type" {
  type = string
}

variable "asg_instance_type" {
  type = string
}

// variable "asg_ami_filter_value" {
//   type = list(string)
// }

variable "asg_ami_id" {
  type = string
}

variable "asg_initial_lifecycle_hooks" {
  type    = list(map(string))
  default = []
}

variable "asg_block_device_mappings" {
  type = list(any)
}

