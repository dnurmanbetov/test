locals {
  # transform pull request triggers into set of objects
  pull_request_projects_list = flatten([
    for config_name, config in var.cicd4projects : [
      for pull_request_trigger in config.pull_request_triggers : {
        "${pull_request_trigger.project}" = pull_request_trigger.project
      }
    ]
  ])

  push_triggers_projects_list = flatten([
    for config_name, config in var.cicd4projects : [
      for push_trigger in config.push_triggers : {
        "${push_trigger.project}" = push_trigger.project
      }
    ]
  ])

  projects_map = {
    for item in distinct(concat(local.pull_request_projects_list, local.push_triggers_projects_list)) :
    keys(item)[0] => values(item)[0]
  }

  # buckets for each project
  buckets_per_project_map = {
    for key, item in local.projects_map :
    key => {
      tf_log   = "tf1-logs-${key}"
      tf_cache = "tf1-caches-${key}"
      tf_state = "tf1-states-${key}"
    }
  }
}
