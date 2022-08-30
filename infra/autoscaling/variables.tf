variable "project_name" {
  type        = string
  description = "name of the entire project"

}


variable "environment" {
  type        = string
  description = "defines the enviroment"

}

variable "asg_ami_id" {
  type        = string
  description = "this defines the image id for launch template"

}

variable "asg_instance_type" {
  type        = string
  description = "this defines the instance type for the launch template"

}

variable "asg_ssh_key_name" {
  type        = string
  description = "this defines the key pair for ssh into ec2's"

}

variable "min_size" {
  type        = string
  description = "defines minimum number of instances on standby for auto scaling group"

}

variable "max_size" {
  type        = string
  description = "defines maximum number of instances to be created for auto scaling group"

}

variable "desired_capacity" {
  type        = string
  description = "defines number of default instances"

}

variable "asg_grace" {
  type        = string
  description = "grace period for instance health check"

}

