locals {
  # transform pull request triggers into set of objects
  pull_request_triggers_list = flatten([
    for config_name, config in var.cicd4projects : [
      for pull_request_trigger in config.pull_request_triggers : {
        "${config_name}-${pull_request_trigger.project}-${pull_request_trigger.branch}" = {
          disabled             = config.disabled || pull_request_trigger.disabled || var.disable_github_triggers || var.disable_github_pull_request_triggers
          config_name          = config_name
          github               = config.github
          pull_request_trigger = pull_request_trigger
          service_account_id = join("-", [
            "pr-${substr(replace("${config_name}-${pull_request_trigger.branch}-${config.github.name}", "/[^0-9A-Za-z-]/", ""), 0, 20)}",
            substr(md5("${config_name}-${pull_request_trigger.branch}-${config.github.name}"), 0, 6)
          ]) # 30 chars max
          service_account_description = "SA for ${config_name} triggered on pull request to ${config.github.name} repository and ${pull_request_trigger.branch} branch"
        }
      }
    ]
  ])
  pull_request_triggers_map = {
    for item in local.pull_request_triggers_list :
    keys(item)[0] => values(item)[0]
  }
  # transform push triggers into set of objects
  push_triggers_list = flatten([
    for config_name, config in var.cicd4projects : [
      for push_trigger in config.push_triggers : {
        "${config_name}-${push_trigger.project}-${push_trigger.branch}" = {
          disabled     = config.disabled || push_trigger.disabled || var.disable_github_triggers || var.disable_github_push_triggers
          config_name  = config_name
          github       = config.github
          push_trigger = push_trigger
          service_account_id = join("-", [
            "ps-${substr(replace("${config_name}-${push_trigger.branch}-${config.github.name}", "/[^0-9A-Za-z-]/", ""), 0, 20)}",
            substr(md5("${config_name}-${push_trigger.branch}-${config.github.name}"), 0, 6)
          ]) # 30 chars max
          service_account_description = "SA for ${config_name} triggered on push to ${config.github.name} repository and ${push_trigger.branch} branch"
        }
      }
    ]
  ])
  push_triggers_map = {
    for item in local.push_triggers_list :
    keys(item)[0] => values(item)[0]
  }

  build_restore_cache_args = [
    "-eEuo",
    "pipefail",
    "-c",
    join(" ", [
      "gsutil -q -m cp -R gs://$${_TERRAFORM_CACHE_BUCKET}/.terraform ./ &&",
      "chmod +x -R .terraform && ",
      "gsutil -q -m cp -R gs://$${_TERRAFORM_CACHE_BUCKET}/.bin ./ &&",
      "chmod +x -R .bin &&",
      "gsutil -q -m cp -R gs://${var.terraform_scripts_cache_bucket_name}/.trigger_scripts ./ &&",
      "mv .trigger_scripts/.env.terraform_version .env.terraform_version &&",
      "chmod +x -R .trigger_scripts &&",
      "true"
    ])
  ]
  build_save_cache_args = [
    "-eEuo",
    "pipefail",
    "-c",
    join(" ", [
      "gsutil -q -m cp -n -R .terraform gs://$${_TERRAFORM_CACHE_BUCKET}/ &&",
      "gsutil -q -m cp -n -R .bin gs://$${_TERRAFORM_CACHE_BUCKET}/ &&",
      "true"
    ])
  ]
  path_to_run_script = ".trigger_scripts/run.sh"
}

resource "google_cloudbuild_trigger" "pull_request_trigger" {
  provider    = google-beta
  for_each    = local.pull_request_triggers_map
  project     = each.value.pull_request_trigger.project
  name        = trimsuffix(substr(replace("pr--${each.value.config_name}--${each.value.github.name}--${each.value.pull_request_trigger.branch}", "/[^0-9A-Za-z-]/", ""), 0, 64), "-") # 64 chars, alpha-numberic-dashes
  description = "Job for ${each.value.config_name} triggered on pull request to ${each.value.github.name} repository and ${each.value.pull_request_trigger.branch} branch"
  tags = [
    "PR",
    each.value.config_name,
    each.value.github.name,
    replace(each.value.pull_request_trigger.branch, "/[^0-9A-Za-z-]/", ""),
    "pull-request",
    "config--${each.value.config_name}",
    "repository--${each.value.github.name}",
    "branch--${replace(each.value.pull_request_trigger.branch, "/[^0-9A-Za-z-]/", "")}",
  ]
  disabled = each.value.disabled

  included_files = each.value.github.path_filters
  github {
    owner = each.value.github.owner
    name  = each.value.github.name
    pull_request {
      branch          = each.value.pull_request_trigger.branch
      comment_control = each.value.pull_request_trigger.comment_control
    }
  }

  // send logs to github
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  build {
    step {
      name       = "us-docker.pkg.dev/pp-devops/custom-gcloud-builder-image/gcloud-builder:latest"
      id         = "Restore terraform cache"
      entrypoint = "bash"
      args       = local.build_restore_cache_args
    }

    step {
      name       = "us-docker.pkg.dev/pp-devops/custom-gcloud-builder-image/gcloud-builder:latest"
      id         = "Save terraform cache"
      entrypoint = "bash"
      args       = local.build_save_cache_args
    }

    timeout = "${6 * 60 * 60}s"

    logs_bucket = join("/", [
      "gs://${google_storage_bucket.bucket_terraform_log[each.value.pull_request_trigger.project].name}",
      "config--${each.value.config_name}",
      "pull-requests",
      "repository--${each.value.github.name}",
      "branch--${replace(each.value.pull_request_trigger.branch, "/[^0-9A-Za-z-]/", "")}",
      "2023-04-21",
    ])
    tags = [
      "PR",
      each.value.config_name,
      each.value.github.name,
      replace(each.value.pull_request_trigger.branch, "/[^0-9A-Za-z-]/", ""),
      "pull-request",
      "config--${each.value.config_name}",
      "repository--${each.value.github.name}",
      "branch--${replace(each.value.pull_request_trigger.branch, "/[^0-9A-Za-z-]/", "")}",
    ]

    options {
      machine_type = each.value.pull_request_trigger.machine_type == "UNSPECIFIED" ? null : each.value.pull_request_trigger.machine_type
      env = [
        "_TERRAFORM_CACHE_BUCKET=${google_storage_bucket.buckets_terraform_cache[each.value.pull_request_trigger.project].name}"
      ]
    }
  }

  substitutions = {
    // _GOOGLE_IMPERSONATE_SERVICE_ACCOUNT = google_service_account.sa_github_tf_runner.email
    // _TERRAFORM_CACHE_BUCKET = google_storage_bucket.buckets_terraform_cache[each.value.pull_request_trigger.project].name
  }

  depends_on = [
    google_project_service.project_services,
  ]
}
