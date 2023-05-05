terraform {
  backend "gcs" {
    bucket = "test-project-312"
    prefix = "cicd4projects"
  }
}
