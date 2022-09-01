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


# asg vars
variable "ssh_key_name" {
  type = string
}


variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "instance_root_device_size" {
  type = number
}















