variable "logs_bucket_name" {
  description = "logs_bucket_name"
  type        = string
  default     = "tf-cloudbuild-base-images-logs"
}

variable "directory" {
  description = "path to module inside repo"
  type        = string
  default     = "nginx"
}
