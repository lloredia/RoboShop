# RoboShop Terraform Main Configuration

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment after creating S3 bucket and DynamoDB table
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "roboshop/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-locks"
  # }
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

  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr

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
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.roboshop.key_name
  subnet_id              = module.vpc.public_subnet_id
  vpc_security_group_ids = [module.security_groups.bastion_sg_id]

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

# TODO: Add application and database instances
# This will be done in the next phase using the ec2-app and ec2-database modules
