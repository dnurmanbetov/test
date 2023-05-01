
locals {
  # default build steps to init qemu/buildx
  docker_buildx_init = [
    {
      name = "gcr.io/cloud-builders/docker"
      id   = "Install QEMU"
      args = [
        "run",
        "--privileged",
        "tonistiigi/binfmt",
        "--install",
        "all",
      ]
    },
    {
      name = "gcr.io/cloud-builders/docker"
      id   = "Create builder"
      args = [
        "buildx",
        "create",
        "--name",
        "buildxbuilder",
        "--driver-opt",
        "env.BUILDKIT_STEP_LOG_MAX_SIZE=-1",
        "--driver-opt",
        "env.BUILDKIT_STEP_LOG_MAX_SPEED=-1",
      ]
    },
    {
      name = "gcr.io/cloud-builders/docker"
      id   = "Use builder"
      args = [
        "buildx",
        "use",
        "buildxbuilder",
      ]
    },
  ]
}
