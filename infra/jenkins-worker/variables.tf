
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


# asg vars
variable "ssh_key_name" {
  type = string
}


// variable "ami_filter_value" {
//   type = list(string)
// }

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "instance_root_device_size" {
  type = number
}

