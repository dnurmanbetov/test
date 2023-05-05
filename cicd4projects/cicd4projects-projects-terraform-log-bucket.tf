# terraform logs
resource "google_storage_bucket" "bucket_terraform_log" {
  for_each                    = local.buckets_per_project_map
  project                     = each.key
  name                        = each.value.tf_log
  location                    = var.default_projects_bucket_location
  storage_class               = "REGIONAL"
  uniform_bucket_level_access = true

  # move old backups to nearline
  lifecycle_rule {
    condition {
      age = "7"
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # use archive storage class
  lifecycle_rule {
    condition {
      age = "38"
      matches_storage_class = [
        "NEARLINE",
      ]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  # delete after 7 years
  lifecycle_rule {
    condition {
      age = 7 * 364
    }
    action {
      type = "Delete"
    }
  }
}
