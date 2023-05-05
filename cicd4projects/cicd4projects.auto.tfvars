cicd4projects = {
  # keep names short as possible to allow generation of readable names of resources
  "bs-docker" = {
    disabled = false # If true, triggers will be disabled
    github = {
      name = "test"
      path_filters = [
        "php/tf-cloudbuild-trigger/**",
        "nginx/tf-cloudbuild-trigger/**",
      ]
      managed_directories = [
        "php/tf-cloudbuild-trigger",
        "nginx/tf-cloudbuild-trigger",
      ]
    }
    push_triggers = [
      {
        project = "test-project-doni"
        branch  = "^main$"
        sa_roles_per_project = [
          "roles/artifactregistry.repoAdmin",
          "roles/cloudbuild.builds.editor",
        ]
        disabled = false # If true, trigger will be disabled
      },
    ],
    pull_request_triggers = [
      {
        project = "test-project-doni"
        branch  = "^main$"
        sa_roles_per_project = [
          "roles/iam.securityReviewer",
          "roles/artifactregistry.repoAdmin",
        ]
        disabled = false # If true, trigger will be disabled
      },
    ],
  },
}
