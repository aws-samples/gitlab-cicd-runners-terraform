variable "aws_region" {
  description = "AWS Region"
  type = string
}

variable "name" {
  description = "Name of this worker"
  type = string
}

variable "vpc_id" {
  description = "VPC ID"
  type = string
}

variable "subnet_ids_gitlab_runner" {
  description = "Subnets for the gitlab-runner"
  type = list(string)
}

variable "subnet_ids_runners" {
  description = "Subnet for the workers"
  type = list(string)
}

variable "registration_token" {
  description = "Gitlab registration token"
  type = string
}

variable "runners_concurrent" {
  description = "Number of simulatenous jobs that can be running on the same worker"
  type = number
  default = 10
}

variable "runners_idle_time" {
  description = "How long (in seconds) is a worker kept alive when no jobs are available"
  type = number
  default = 600
}

variable "runners_image" {
  description = "The default docker image that is used to run the workers, when none is specified"
  type = string
  default = "docker:20.10.7"
}

variable "runners_use_private_address" {
  description = "Use a private address for the runner"
  type = bool
  default = true
}

variable "tag_list" {
  description = "List of tags for the runner"
  type = list(string)
}

variable "pre_build_script" {
  description = "Commands to run before each job"
  type = string
  default = ""
}

variable "target_role_arn" {
  description = "The arn of the role to assume during each build"
  type = string
}

variable "docker_machine_instance_type" {
  description = "Instance type used for the instances hosting docker-machine"
  type        = string
  default     = "m5.large"
}

variable "docker_machine_spot_price_bid" {
  description = "Spot price bid"
  type        = string
  default     = "1.00"
}
