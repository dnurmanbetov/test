// terraform state buckets
resource "google_storage_bucket" "bucket_terraform_state" {
  for_each                    = local.buckets_per_project_map
  project                     = each.key
  name                        = each.value.tf_state
  location                    = var.default_projects_bucket_location
  storage_class               = "REGIONAL"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

