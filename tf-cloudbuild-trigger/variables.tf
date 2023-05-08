variable "logs_bucket_name" {
  description = "logs_bucket_name"
  type        = string
  default     = "tf-cloudbuild-base-images-logs-3"
}

variable "directory" {
  description = "path to module inside repo"
  type        = string
  default     = "nginx"
}
