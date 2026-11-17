terraform {
  required_version = ">= 1.8" # mock_provider
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.0"
    }
  }
}

# auth from ~/.oci/config
provider "oci" {
  config_file_profile = var.oci_profile
  region              = var.region
}
