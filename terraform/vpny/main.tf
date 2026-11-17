locals {
  compartment = coalesce(var.compartment_ocid, var.tenancy_ocid)
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# only boots once, nixos-anywhere replaces it
data "oci_core_images" "ubuntu" {
  compartment_id           = local.compartment
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_vcn" "vpn" {
  compartment_id = local.compartment
  display_name   = "vpny"
  cidr_blocks    = ["10.42.0.0/16"]
  dns_label      = "vpny"
}

resource "oci_core_internet_gateway" "vpn" {
  compartment_id = local.compartment
  vcn_id         = oci_core_vcn.vpn.id
  display_name   = "vpn-igw"
  enabled        = true
}

resource "oci_core_route_table" "vpn" {
  compartment_id = local.compartment
  vcn_id         = oci_core_vcn.vpn.id
  display_name   = "vpn-rt"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.vpn.id
  }
}

resource "oci_core_security_list" "vpn" {
  compartment_id = local.compartment
  vcn_id         = oci_core_vcn.vpn.id
  display_name   = "vpn-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  dynamic "ingress_security_rules" {
    for_each = var.ssh_ports
    content {
      description = "SSH ${ingress_security_rules.value}"
      source      = var.ssh_allowed_cidr
      protocol    = "6" # TCP
      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  ingress_security_rules {
    description = "WireGuard clients"
    source      = "0.0.0.0/0"
    protocol    = "17" # UDP
    udp_options {
      min = var.wireguard_port
      max = var.wireguard_port
    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.home_dials_in ? [1] : []
    content {
      description = "WireGuard from home"
      source      = "0.0.0.0/0"
      protocol    = "17"
      udp_options {
        min = var.home_port
        max = var.home_port
      }
    }
  }

  # path mtu discovery
  ingress_security_rules {
    description = "Path MTU discovery"
    source      = "0.0.0.0/0"
    protocol    = "1" # ICMP
    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    description = "ping"
    source      = "0.0.0.0/0"
    protocol    = "1"
    icmp_options {
      type = 8
    }
  }
}

resource "oci_core_subnet" "vpn" {
  compartment_id             = local.compartment
  vcn_id                     = oci_core_vcn.vpn.id
  display_name               = "vpn-public"
  cidr_block                 = "10.42.0.0/24"
  dns_label                  = "pub"
  route_table_id             = oci_core_route_table.vpn.id
  security_list_ids          = [oci_core_security_list.vpn.id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_instance" "vpn" {
  compartment_id      = local.compartment
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain_index].name
  display_name        = "vpny"
  shape               = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.vpn.id
    assign_public_ip = true
    hostname_label   = "vpny"
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
  }

  preserve_boot_volume = false

  lifecycle {
    # a newer ubuntu image would recreate (wipe) the vm
    ignore_changes = [source_details[0].source_id, metadata]
  }
}
