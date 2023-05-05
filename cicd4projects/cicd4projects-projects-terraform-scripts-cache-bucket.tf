# caching terraform scripts files
# used to guarantee that there no injections
resource "google_storage_bucket" "bucket_terraform_scripts_cache" {
  project                     = var.terraform_scripts_cache_project
  name                        = var.terraform_scripts_cache_bucket_name
  location                    = var.default_projects_bucket_location
  storage_class               = "REGIONAL"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

# ensure that directories exists
resource "google_storage_bucket_object" "bucket_terraform_script_cache_readme" {
  name    = "README.txt"
  content = "Caching terraform scripts files.\nUsed to guarantee that there no injections.\nSee devops repository for details"
  bucket  = google_storage_bucket.bucket_terraform_scripts_cache.name
}

# keep scripts in cloud storage to disable ability to replace them via git
resource "google_storage_bucket_object" "bucket_terraform_scripts_cache_github_run_script" {
  name    = ".trigger_scripts/github_run.sh"
  content = file("../pp-devops/cicd/configs/github_run.sh")
  bucket  = google_storage_bucket.bucket_terraform_scripts_cache.name
}

# keep scripts in cloud storage to disable ability to replace them via git
resource "google_storage_bucket_object" "bucket_terraform_scripts_cache_run_script" {
  name    = ".trigger_scripts/run.sh"
  content = file("../pp-devops/cicd/configs/run.sh")
  bucket  = google_storage_bucket.bucket_terraform_scripts_cache.name
}

resource "google_storage_bucket_object" "bucket_terraform_scripts_cache_deletion_check_script" {
  name    = ".trigger_scripts/tf-deletion-check.sh"
  content = file("../pp-devops/cicd/configs/tf-deletion-check.sh")
  bucket  = google_storage_bucket.bucket_terraform_scripts_cache.name
}

resource "google_storage_bucket_object" "bucket_terraform_scripts_cache_terraform_version" {
  name    = ".trigger_scripts/.env.terraform_version"
  content = file(".env.terraform_version")
  bucket  = google_storage_bucket.bucket_terraform_scripts_cache.name
}
