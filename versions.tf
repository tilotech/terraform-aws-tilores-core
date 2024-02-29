terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.38"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.7"
    }
  }
}
