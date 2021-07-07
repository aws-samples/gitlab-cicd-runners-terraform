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

variable "dev_profile" {
  description = "AWS account profile for development deployments"
  type        = string
}

variable "prod_profile" {
  description = "AWS account profile for production deployments"
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
