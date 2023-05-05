
locals {
  project_services_list = [
    "admin.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
  ]

  services_per_project_map = {
    for pair in setproduct(keys(local.projects_map), local.project_services_list) :
    "${pair[0]}-${pair[1]}" => {
      project = pair[0]
      service = pair[1]
    }
  }
}

# ensure all needed services enabled on project
resource "google_project_service" "project_services" {
  for_each           = local.services_per_project_map
  project            = each.value.project
  service            = each.value.service
  disable_on_destroy = false
}
