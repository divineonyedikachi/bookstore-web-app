variable "project_name" {
  type        = string
  description = "this defines the project name"

}

variable "tags" {
  type = map(string)
  default = {

    Environment   = "dev"
    Project       = "bookstore-app"
    Owner         = "Divine"
    "Cost Center" = "trident"

  }

}