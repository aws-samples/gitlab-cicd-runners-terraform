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

  enable_nat_gateway     = var.use_public_subnets ? false : true
  single_nat_gateway     = var.use_public_subnets ? false : true
  one_nat_gateway_per_az = false
}

# Share the subnets from the main account with the cicd account

data "aws_caller_identity" "cicd" {
  provider = aws.cicd
}

resource "aws_iam_service_linked_role" "ram" {
  aws_service_name = "ram.amazonaws.com"
}

resource "aws_ram_resource_share" "subnet" {
  name       = "cicd_subnet"
  depends_on = [aws_iam_service_linked_role.ram]
}

resource "aws_ram_principal_association" "subnet" {
  principal          = data.aws_caller_identity.cicd.account_id
  resource_share_arn = aws_ram_resource_share.subnet.arn
}

resource "aws_ram_resource_association" "subnet" {
  count = var.use_public_subnets ? length(module.vpc.public_subnet_arns) : length(module.vpc.private_subnet_arns)

  resource_arn       = var.use_public_subnets ? module.vpc.public_subnet_arns[count.index % length(module.vpc.public_subnet_arns)] : module.vpc.private_subnet_arns[count.index % length(module.vpc.private_subnet_arns)]
  resource_share_arn = aws_ram_resource_share.subnet.arn
}

# dev runner

# Role in the "dev" account that is going to be assumed by the cicd worker

resource "aws_iam_role" "dev_assumed_role" {
  name     = "dev_assumed_role"
  provider = aws.dev

  # Allow this AWS account to assume the role on the dev account
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.cicd.account_id}:root"
        }
      }
    ]
  })

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
  providers = {
    aws = aws.cicd
  }

  name       = "dev"
  aws_region = var.aws_region

  vpc_id                   = module.vpc.vpc_id
  subnet_ids_gitlab_runner = var.use_public_subnets ? module.vpc.public_subnets : module.vpc.private_subnets
  subnet_ids_runners       = var.use_public_subnets ? module.vpc.public_subnets : module.vpc.private_subnets

  registration_token          = var.registration_token
  runners_use_private_address = !var.use_public_subnets
  tag_list                    = ["dev"]

  target_role_arn = aws_iam_role.dev_assumed_role.arn

  depends_on = [aws_ram_resource_association.subnet]
}

# prod runner

# Role in the "prod" account that is going to be assumed by the cicd worker

resource "aws_iam_role" "prod_assumed_role" {
  name     = "prod_assumed_role"
  provider = aws.prod

  # Allow this AWS account to assume the role on the prod account
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.cicd.account_id}:root"
        }
      }
    ]
  })

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
  providers = {
    aws = aws.cicd
  }

  name       = "prod"
  aws_region = var.aws_region

  vpc_id                   = module.vpc.vpc_id
  subnet_ids_gitlab_runner = var.use_public_subnets ? module.vpc.public_subnets : module.vpc.private_subnets
  subnet_ids_runners       = var.use_public_subnets ? module.vpc.public_subnets : module.vpc.private_subnets

  registration_token          = var.registration_token
  runners_use_private_address = !var.use_public_subnets
  tag_list                    = ["prod"]

  target_role_arn = aws_iam_role.prod_assumed_role.arn

  depends_on = [aws_ram_resource_association.subnet]
}
