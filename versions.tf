terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.70"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.7"
    }
  }
}
