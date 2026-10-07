# RoboShop Terraform Main Configuration

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }

  # Remote state is opt-in so a fresh clone still plans against local state.
  # Copy backend.hcl.example to backend.hcl, uncomment it, then:
  #   terraform init -backend-config=backend.hcl
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# Data sources
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC Module
module "vpc" {
  source = "../modules/vpc"

  project_name            = var.project_name
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidr      = var.public_subnet_cidr
  private_app_subnet_cidr = var.private_app_subnet_cidr
  private_db_subnet_cidr  = var.private_db_subnet_cidr
  availability_zone       = var.availability_zone
  enable_flow_logs        = var.enable_flow_logs

  tags = var.tags
}

# Security Groups Module
module "security_groups" {
  source = "../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  admin_cidr   = var.admin_cidr

  tags = var.tags

  depends_on = [module.vpc]
}

# SSH Key Pair
resource "aws_key_pair" "roboshop" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = var.ssh_public_key

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-key"
    }
  )
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.roboshop.key_name
  subnet_id                   = module.vpc.public_subnet_id
  vpc_security_group_ids      = [module.security_groups.bastion_sg_id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true
  ebs_optimized               = true
  monitoring                  = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y telnet nc wget curl
  EOF

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-bastion"
      Role = "Bastion"
    }
  )
}

# Elastic IP for Bastion
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-bastion-eip"
    }
  )
}
