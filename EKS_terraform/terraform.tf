# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "1.3.2"  
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0" 
    }
  }

  required_version = "~> 1.3"
}




