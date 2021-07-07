terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}


resource "aws_security_group" "orchestrator" {
  name_prefix = "orchestrator"
  description = "Blocks all incoming connections to the orchestrator"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

module "runner" {
  source = "github.com/npalm/terraform-aws-gitlab-runner"

  aws_region  = var.aws_region
  environment = var.name

  vpc_id                   = var.vpc_id
  subnet_ids_gitlab_runner = var.subnet_ids_gitlab_runner
  subnet_id_runners        = element(var.subnet_ids_runners, 0)
  metrics_autoscaling      = ["GroupDesiredCapacity", "GroupInServiceCapacity"]

  runners_name             = var.name
  runners_gitlab_url       = "https://gitlab.com"
  enable_runner_ssm_access = true
  enable_docker_machine_ssm_access = true

  gitlab_runner_security_group_ids = [aws_security_group.orchestrator.id]

  docker_machine_download_url   = "https://gitlab-docker-machine-downloads.s3.amazonaws.com/v0.16.2-gitlab.12/docker-machine-Linux-x86_64"
  docker_machine_instance_type  = var.docker_machine_instance_type
  docker_machine_spot_price_bid = var.docker_machine_spot_price_bid

  cache_bucket_prefix = var.name

  gitlab_runner_registration_config = {
    registration_token = var.registration_token
    tag_list           = join(",", var.tag_list)
    description        = var.name
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  tags = {
    "instancelifecycle" = "spot:yes"
  }

  runners_image               = var.runners_image
  runners_privileged          = "true"
  runners_additional_volumes  = ["/certs/client"]
  runners_concurrent          = var.runners_concurrent
  runners_idle_time           = var.runners_idle_time
  runners_use_private_address = var.runners_use_private_address

  # Example of having a directory in RAM when the jobs run
  runners_volumes_tmpfs = [
    {
      volume  = "/var/opt/cache",
      options = "rw,noexec"
    }
  ]

  # Example if you're using MySQL on your jobs to mount MySQL on RAM
  runners_services_volumes_tmpfs = [
    {
      volume  = "/var/lib/mysql",
      options = "rw,noexec"
    }
  ]
  
  runners_pre_build_script = <<EOT
  '''
  curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
  unzip awscli-bundle.zip
  ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
  aws configure set profile.default.role_arn ${var.target_role_arn}
  aws configure set profile.default.region ${var.aws_region}
  aws configure set profile.default.credential_source Ec2InstanceMetadata
  ${var.pre_build_script}
  '''
  EOT
}

# Example of how to give the CI/CD worker permission to assume a role on a different account
resource "aws_iam_role_policy" "target_assume_role" {
  name_prefix = "target-assume-role"
  role        = module.runner.runner_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = [ "sts:AssumeRole*" ],
        Resource = var.target_role_arn
      },
    ]
  })
}


resource "null_resource" "cancel_spot_requests" {
  # Cancel active and open spot requests, terminate instances
  triggers = {
    environment       = var.name
    autoscaling_group = module.runner.runner_as_group_name
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/cancel-spot-instances.sh ${self.triggers.environment}"
  }
}
