terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    shared_config_files      = ["/home/cris/.aws/config"]
    shared_credentials_files = ["/home/cris/.aws/credentials"]
    profile                  = "test"
    region = "us-east-1"
}