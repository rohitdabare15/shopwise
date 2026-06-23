variable "project_name" { type = string }
variable "environment"  { type = string }

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  description = "Public subnet to place Jenkins in — needs internet access"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "jenkins_instance_profile" {
  description = "IAM instance profile for Jenkins — from IAM module"
  type        = string
}

variable "allowed_cidr" {
  description = "Your IP address to allow SSH and Jenkins UI access"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = "shopwise-dev-key"
}
