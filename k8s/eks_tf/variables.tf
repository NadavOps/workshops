variable "aws_provider_default_region" {
  description = "Even if this variable is not used in this configuration, it is used with the generated providers in terragrunt"
  type        = string
  default     = "us-west-1"
}

variable "aws_provider_profile" {
  description = "Even if this variable is not used in this configuration, it is used with the generated providers in terragrunt"
  type        = string
}
