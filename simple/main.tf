data "aws_availability_zones" "available" {
  state = "available"
}

# Main VPC that will run all the different orchestrators
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70"

  name = "vpc-cicd"
  cidr = "10.0.0.0/16"

  azs             = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_ipv6 = true

  enable_nat_gateway     = var.use_public_subnets ? false : true
  single_nat_gateway     = var.use_public_subnets ? false : true
  one_nat_gateway_per_az = false
}

data "aws_caller_identity" "current" {}

#############################################################################
# dev runner

# Role in the "dev" account that is going to be assumed by the dev worker
resource "aws_iam_role" "dev_assumed_role" {
  name     = "dev_assumed_role"
  provider = aws.dev

  # Allow this AWS account to assume the role on the external account
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  # Specific permissions that this role will have on the dev account
  inline_policy {
    name = "s3_read_access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = ["s3:ListAllMyBuckets"]
          Effect = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

module "dev_runner" {
  source = "../runner"

  name       = "dev"
  aws_region = var.aws_region

  vpc_id                   = module.vpc.vpc_id
  subnet_ids_gitlab_runner = var.use_public_subnets ? module.vpc.public_subnets : module.vpc.private_subnets
  subnet_ids_runners       = var.use_public_subnets ? module.vpc.public_subnets : module.vpc.private_subnets

  registration_token = var.registration_token
  tag_list = ["dev"]

  target_role_arn = aws_iam_role.dev_assumed_role.arn
}


#############################################################################

#############################################################################
# prod runner

# Role in the "prod" account that is going to be assumed by the dev worker
resource "aws_iam_role" "prod_assumed_role" {
  name     = "prod_assumed_role"
  provider = aws.prod

  # Allow this AWS account to assume the role on the external account
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  # Specific permissions that this role will have on the prod account
  inline_policy {
    name = "s3_read_access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = ["s3:ListAllMyBuckets"]
          Effect = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

module "prod_runner" {
  source = "../runner"

  name = "prod"
  aws_region = var.aws_region

  vpc_id                   = module.vpc.vpc_id
  subnet_ids_gitlab_runner = var.use_public_subnets ? module.vpc.public_subnets : module.vpc.private_subnets
  subnet_ids_runners       = var.use_public_subnets ? module.vpc.public_subnets : module.vpc.private_subnets

  registration_token = var.registration_token
  tag_list = ["prod"]

  target_role_arn = aws_iam_role.prod_assumed_role.arn
}

#############################################################################
