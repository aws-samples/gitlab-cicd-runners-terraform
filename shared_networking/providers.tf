terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.46.0"
    }
  }
}

# Main account where the networking components will be deployed
provider "aws" {
  region = var.aws_region
}

# CI/CD account where the Gitlab runners will run
provider "aws" {
  alias   = "cicd"
  region  = var.aws_region
  profile = var.cicd_profile
}

# Target account where the CD part will deploy dev components to
provider "aws" {
  alias   = "dev"
  region  = var.aws_region
  profile = var.dev_profile
}

# Target account where the CD part will deploy prod components to
provider "aws" {
  alias   = "prod"
  region  = var.aws_region
  profile = var.prod_profile
}
