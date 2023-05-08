variable "cicd4projects" {
  description = "collection of cicd for different projects, https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudbuild_trigger"
  type = map(object({
    disabled = optional(bool, false) # If true, triggers will be disabled
    github = object({
      name                = string                         # Name of the repository
      owner               = optional(string, "dnurmanbetov") # Owner of the repository.
      path_filters        = list(string)                   # file glob matches using https://golang.org/pkg/path/filepath/#Match extended with support for **, if any of the files altered in the commit pass the filter, then we should trigger the build
      managed_directories = list(string)                   # directories inside repository with terraform root modules
    })
    pull_request_triggers = list(object({                    # run on PR
      project              = string                          # Project where trigger will be created
      branch               = string                          # Regex of branches to match.
      comment_control      = optional(string)                # Whether to block builds on a "/gcbrun" comment from a repository owner or collaborator. Possible values are: COMMENTS_DISABLED, COMMENTS_ENABLED, COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY
      invert_regex         = optional(bool)                  # If true, branches that do NOT match the git_ref will trigger a build.
      sa_roles_per_project = list(string)                    # roles used by sa that run trigger
      disabled             = optional(bool, false)           # If true, trigger will be disabled
      machine_type         = optional(string, "UNSPECIFIED") # Compute Engine machine type on which to run the build. Possible values are: UNSPECIFIED, N1_HIGHCPU_8, N1_HIGHCPU_32, E2_HIGHCPU_8, E2_HIGHCPU_32.
    }))
    push_triggers = list(object({                            # run on push
      project              = string                          # Project where trigger will be created
      branch               = optional(string)                # Regex of branches to match. Specify only one of branch or tag.
      tag                  = optional(string)                # Regex of tags to match. Specify only one of branch or tag.
      invert_regex         = optional(bool)                  # When true, only trigger a build if the revision regex does NOT match the git_ref regex.
      sa_roles_per_project = list(string)                    # roles used by sa that run trigger
      disabled             = optional(bool, false)           # If true, trigger will be disabled
      machine_type         = optional(string, "UNSPECIFIED") # Compute Engine machine type on which to run the build. Possible values are: UNSPECIFIED, N1_HIGHCPU_8, N1_HIGHCPU_32, E2_HIGHCPU_8, E2_HIGHCPU_32.
    }))
  }))
}

variable "disable_github_triggers" {
  description = "disable triggers"
  type        = bool
  default     = false
}

variable "disable_github_push_triggers" {
  description = "disable push triggers (merging don't start terraform apply)"
  type        = bool
  default     = false
}

variable "disable_github_pull_request_triggers" {
  description = "disable pull_request triggers"
  type        = bool
  default     = false
}

variable "terraform_scripts_cache_bucket_name" {
  description = "terraform_scripts_cache_bucket_name"
  type        = string
  default     = "tf-cicd4projects-scripts-cache-2"
}

variable "terraform_scripts_cache_project" {
  description = "terraform_scripts_cache_project"
  type        = string
  default     = "test-project-doni"
}

variable "default_projects_bucket_location" {
  description = "Zone for bucket to store logs"
  type        = string
  default     = "us-east4"
}
