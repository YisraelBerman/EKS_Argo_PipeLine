# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "clustername" {
  description = "cluster name"
  type        = string
  default     = "Commit"
}

variable "argo_repo_url" {
  description = "Repository URL"
  type        = string
  default     = ""
}

variable "argo_repo_username" {
  description = "Repository Username"
  type        = string
  default     = ""
}

variable "argo_repo_password" {
  description = "Repository Password"
  type        = string
  default     = ""
}

variable "host_address" {
  description = "The host address for the Argo CD ingress."
  type        = string
  
}

