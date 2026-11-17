variable "oci_profile" {
  description = "Profile in ~/.oci/config to authenticate with."
  type        = string
  default     = "DEFAULT"
}

variable "region" {
  description = "OCI region, e.g. us-ashburn-1. Always Free resources only exist in your home region."
  type        = string
}

variable "tenancy_ocid" {
  description = "Tenancy OCID (ocid1.tenancy...). Also used as the compartment unless compartment_ocid is set."
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment to create everything in. Defaults to the tenancy (root compartment)."
  type        = string
  default     = null
}

variable "ssh_public_key_path" {
  description = "Public key installed for the 'ubuntu' user; nixos-anywhere logs in with it."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_ports" {
  description = "TCP ports for SSH: 22 for Ubuntu during the nixos-anywhere install, 9639 for NixOS (my.services.ssh) after."
  type        = list(number)
  default     = [22, 9639]
}

variable "ssh_allowed_cidr" {
  description = "Who may reach SSH (every port in ssh_ports). Narrow this to your home IP/32 if it is static."
  type        = string
  default     = "0.0.0.0/0"
}

variable "availability_domain_index" {
  description = "Which availability domain (0, 1, 2) to use. Change it if A1 says 'Out of host capacity'."
  type        = number
  default     = 0
}

variable "shape" {
  description = "OCI shape. vpny is an aarch64-linux NixOS host, so it must be an Arm (A1) shape; Always Free allows up to 2 OCPU/12 GB."
  type        = string
  default     = "VM.Standard.A1.Flex"
  validation {
    # vpny is aarch64
    condition     = var.shape == "VM.Standard.A1.Flex"
    error_message = "vpny is aarch64-linux: use VM.Standard.A1.Flex."
  }
}

variable "ocpus" {
  description = "Always Free allows 2 OCPU in total across all A1 VMs."
  type        = number
  default     = 1
}

variable "memory_gb" {
  description = "Always Free allows 12 GB in total across all A1 VMs."
  type        = number
  default     = 6
}

variable "boot_volume_gb" {
  description = "Boot volume size. Always Free includes 200 GB of block storage in total."
  type        = number
  default     = 50
}

variable "wireguard_port" {
  description = "UDP port clients connect to (hardware/vpny/settings.nix clients.port)."
  type        = number
  default     = 51820
}

variable "home_dials_in" {
  description = "Open home_port too, for when the router connects to vpny (hardware/vpny/settings.nix home.endpoint = null)."
  type        = bool
  default     = false
}

variable "home_port" {
  description = "UDP port wg-home listens on (hardware/vpny/settings.nix home.port)."
  type        = number
  default     = 51821
}
