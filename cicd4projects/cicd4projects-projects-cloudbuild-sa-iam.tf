locals {
  # cloudbuild sa for each project
  cloudbuild_sa_per_project_map = {
    for project, item in local.projects_data_map :
    project => "serviceAccount:${item.number}@cloudbuild.gserviceaccount.com"
  }

  cloudbuild_sa_devops_roles = [
    # Allow CICD to view all resources within the devops project so it can run terraform plans against them.
    # It won't be able to actually apply any changes unless granted the permission in this list.
    "roles/viewer",

    # Enable Cloud Build SA to list and enable APIs in the devops project.
    "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.objectAdmin"
  ]

  cloudbuild_sa_devops_roles_per_project_map = {
    for pair in setproduct(keys(local.projects_map), local.cloudbuild_sa_devops_roles) :
    "${pair[0]}-${pair[1]}" => {
      project = pair[0]
      role    = pair[1]
    }
  }
}

# allow Cloud Build SA to access terraform scripts bucket.
resource "google_storage_bucket_iam_member" "bucket_terraform_scripts_cache_cloudbuild_sa_reader_iam" {
  for_each = local.projects_map
  bucket   = google_storage_bucket.bucket_terraform_scripts_cache.name
  role     = "roles/storage.objectViewer"
  member   = local.cloudbuild_sa_per_project_map[each.key]
  depends_on = [
    google_project_service.project_services,
  ]
}

# Grant Cloud Build Service Account access to the devops project.
resource "google_project_iam_member" "per_project_roles_cloudbuild_sa_project_iam" {
  for_each = local.cloudbuild_sa_devops_roles_per_project_map
  project  = each.value.project
  role     = each.value.role
  member   = local.cloudbuild_sa_per_project_map[each.value.project]
  depends_on = [
    google_project_service.project_services,
  ]
}

# allow Cloud Build SA to read/write terraform cache bucket.
resource "google_storage_bucket_iam_member" "bucket_terraform_cache_cloudbuild_sa_admin_iam" {
  for_each = local.buckets_per_project_map
  bucket   = google_storage_bucket.buckets_terraform_cache[each.key].name
  role     = "roles/storage.objectAdmin"
  member   = local.cloudbuild_sa_per_project_map[each.key]
  depends_on = [
    google_project_service.project_services,
  ]
}

# allow Cloud Build SA to read/write terraform logs bucket.
resource "google_storage_bucket_iam_member" "bucket_terraform_log_cloudbuild_sa_admin_iam" {
  for_each = local.buckets_per_project_map
  bucket   = google_storage_bucket.bucket_terraform_log[each.key].name
  role     = "roles/storage.objectAdmin"
  member   = local.cloudbuild_sa_per_project_map[each.key]
  depends_on = [
    google_project_service.project_services,
  ]
}

# allow Cloud Build SA to read/write terraform state bucket.
resource "google_storage_bucket_iam_member" "bucket_terraform_state_cloudbuild_sa_admin_iam" {
  for_each = local.buckets_per_project_map
  bucket   = google_storage_bucket.bucket_terraform_state[each.key].name
  role     = "roles/storage.objectAdmin"
  member   = local.cloudbuild_sa_per_project_map[each.key]
  depends_on = [
    google_project_service.project_services,
  ]
}
