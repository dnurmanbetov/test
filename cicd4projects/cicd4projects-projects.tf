data "google_projects" "projects" {
  provider = google-beta
  filter   = "name:*"
}

locals {
  projects_data_map = {
    for item in data.google_projects.projects.projects :
    item.project_id => item
    if item.project_id != "pp-devops"
  }
}

