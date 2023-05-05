locals {
  # transform triggers map into set of permissions
  pull_request_triggers_sa_roles_list = flatten([
    for key, config in local.pull_request_triggers_map : [
      for role in config.pull_request_trigger.sa_roles_per_project : {
        "${key}-${config.service_account_id}-${role}" = {
          key     = key
          role    = role
          project = config.pull_request_trigger.project
        }
      }
    ]
  ])
  pull_request_triggers_sa_roles_map = {
    for item in local.pull_request_triggers_sa_roles_list :
    keys(item)[0] => values(item)[0]
  }

  push_triggers_sa_roles_list = flatten([
    for key, config in local.push_triggers_map : [
      for role in config.push_trigger.sa_roles_per_project : {
        "${key}-${config.service_account_id}-${role}" = {
          key     = key
          role    = role
          project = config.push_trigger.project
        }
      }
    ]
  ])
  push_triggers_sa_roles_map = {
    for item in local.push_triggers_sa_roles_list :
    keys(item)[0] => values(item)[0]
  }
}

# pull requests
resource "google_service_account" "pull_request_service_account" {
  for_each     = local.pull_request_triggers_map
  project      = each.value.pull_request_trigger.project
  account_id   = each.value.service_account_id
  display_name = substr(each.value.service_account_description, 0, 100)
  description  = each.value.service_account_description
}

resource "google_project_iam_member" "pull_request_service_account_project_roles_iam" {
  for_each = local.pull_request_triggers_sa_roles_map
  project  = each.value.project
  role     = each.value.role
  member   = google_service_account.pull_request_service_account[each.value.key].member
}

# push
resource "google_service_account" "push_service_account" {
  for_each     = local.push_triggers_map
  project      = each.value.push_trigger.project
  account_id   = each.value.service_account_id
  display_name = substr(each.value.service_account_description, 0, 100)
  description  = each.value.service_account_description
}

resource "google_project_iam_member" "push_service_account_project_roles_iam" {
  for_each = local.push_triggers_sa_roles_map
  project  = each.value.project
  role     = each.value.role
  member   = google_service_account.push_service_account[each.value.key].member
}
