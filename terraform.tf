terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">6.35"
    }
  }
 
  backend "gcs" {
    bucket = "bucket_devops_72"
    prefix = "terraform/state"
  }
}