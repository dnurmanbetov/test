output "projects" {
  value = {
    for project in local.projects_map :
    project => {
      "helper_buckets" = local.buckets_per_project_map[project]
      "pull_request_service_accounts" = {
        for key, value in local.pull_request_triggers_map :
        google_service_account.pull_request_service_account[key].email => value.service_account_description
        if value.pull_request_trigger.project == project
      }
      "push_service_accounts" = {
        for key, value in local.push_triggers_map :
        google_service_account.push_service_account[key].email => value.service_account_description
        if value.push_trigger.project == project
      }
    }
  }
}

/*
output "pull_request_triggers_map" {
  value = local.pull_request_triggers_map
}

output "projects_data" {
  value = local.projects_data_map
}
*/
