# main account where all the components will be deployed
provider "aws" {
  region = var.aws_region
}

# "dev" account where the dev tagged jobs will deploy
provider "aws" {
  alias   = "dev"
  region  = var.aws_region
  profile = var.dev_profile
}

# "prod" account where the prod tagged jobs will deploy
provider "aws" {
  alias   = "prod"
  region  = var.aws_region
  profile = var.prod_profile
}
