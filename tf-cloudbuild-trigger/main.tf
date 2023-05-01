terraform {
  backend "gcs" {
    bucket = "test-project-312"
    prefix = "nginx/inventcorp-nginx-base-image-v2"
  }
}
