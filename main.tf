provider "google" {
  project = "test-project-doni"
  region  = "us-central1"
}

resource "google_compute_instance" "my-vm" {
  name         = "my-vm"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = "default"

    access_config {
    }
  }
}

resource "google_cloudbuild_trigger" "my_trigger" {
  name          = "my-trigger"
  description   = "My Cloud Build trigger"
  trigger_template {
    branch_name = "master"
    repo_name   = "my-repo"
  }
}
