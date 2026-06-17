variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["frontend", "backend"]
}

variable "image_retention_count" {
  description = "Number of images to keep per repository. Older images are deleted automatically."
  type        = number
  default     = 10
}

variable "tags" {
  type    = map(string)
  default = {}
}
