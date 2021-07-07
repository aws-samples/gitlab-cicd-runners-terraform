variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "use_public_subnets" {
  description = "Set to true to put everything in public subnets, avoiding the cost of a NAT gateway"
  type        = bool
  default     = false
}

variable "cicd_profile" {
  description = "AWS account that where the CI/CD jobs will run. Needs to be on the same AWS Organization as the main account"
  type        = string
}

variable "dev_profile" {
  description = "AWS account where the CD pipeline will deploy dev components"
  type        = string
}

variable "prod_profile" {
  description = "AWS account where the CD pipeline will deploy prod components"
  type        = string
}

variable "registration_token" {
  type      = string
  sensitive = true
}

variable "timezone" {
  description = "Name of the timezone that the runner will be used in."
  type        = string
  default     = "Europe/Copenhagen"
}
