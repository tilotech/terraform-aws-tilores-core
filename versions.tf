terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.35"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.7"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2" # local_sensitive_file
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.8"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.3"
    }
  }
}
