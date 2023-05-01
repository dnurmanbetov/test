
locals {
  # parse .env
  envs                                = { for tuple in regexall("(.*)=(.*)", file("${path.module}/.env")) : tuple[0] => tuple[1] }
  docker_project                      = local.envs["GCLOUD_PROJECT"]
  docker_artifact_registry_repository = local.envs["ARTIFACT_REPOSITORY"]
  docker_image_name                   = local.envs["IMAGE_NAME"]
  build_env = [
    "SHORT_SHA=$SHORT_SHA"
  ]
}

resource "google_cloudbuild_trigger" "build_inventcorp_nginx_base_image" {
  provider    = google-beta
  project     = local.docker_project
  name        = "build-and-deploy"
  description = "Build inventcorp nginx base image."
  tags        = ["build", "infra", local.docker_artifact_registry_repository, local.docker_image_name]
  disabled    = false

  included_files = [
    "${var.directory}/**",
    "shared/terraform/**",
  ]

  github {
    owner = "dnurmanbetov"
    name  = "test"
    push {
      branch = "^main$"
    }
  }

  // send logs to github
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  build {
    dynamic "step" {
      for_each = local.docker_buildx_init
      content {
        name = step.value.name
        id   = step.value.id
        args = step.value.args
      }
    }

    step {
      name       = "gcr.io/cloud-builders/docker"
      id         = "Build nginx image"
      dir        = var.directory
      entrypoint = "bash"
      args       = ["build-inventcorp-nginx-base-image.sh"]
      env = [
        "PLAN_STR="
      ]
    }

    step {
      name       = "gcr.io/cloud-builders/docker"
      id         = "Build circleci image"
      dir        = var.directory
      entrypoint = "bash"
      args       = ["build-inventcorp-circleci-front-end-image.sh"]
      env = [
        "PLAN_STR="
      ]
    }

    options {
      env = local.build_env
    }

    timeout = "${6 * 60 * 60}s"

    logs_bucket = "gs://${var.logs_bucket_name}/${local.docker_artifact_registry_repository}/${local.docker_image_name}/build/2023-03-04"
    tags        = ["build", "infra", local.docker_artifact_registry_repository, local.docker_image_name]
  }
}