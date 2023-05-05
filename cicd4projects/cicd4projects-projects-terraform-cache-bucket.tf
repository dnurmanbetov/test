# temporary caching terraform files
resource "google_storage_bucket" "buckets_terraform_cache" {
  for_each                    = local.buckets_per_project_map
  project                     = each.key
  name                        = each.value.tf_cache
  location                    = var.default_projects_bucket_location
  storage_class               = "REGIONAL"
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age                   = 3
      matches_storage_class = ["REGIONAL"]
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

# ensure that directories exists
resource "google_storage_bucket_object" "buckets_terraform_cache_bin_directory" {
  for_each      = local.buckets_per_project_map
  name          = ".bin/README.txt"
  content       = "Cache directory"
  storage_class = "NEARLINE"
  bucket        = google_storage_bucket.buckets_terraform_cache[each.key].name
}

resource "google_storage_bucket_object" "bucket_terraform_cache_terraform_directory" {
  for_each      = local.buckets_per_project_map
  name          = ".terraform/README.txt"
  content       = "Cache directory"
  storage_class = "NEARLINE"
  bucket        = google_storage_bucket.buckets_terraform_cache[each.key].name
}
