# mocked provider, no oci account needed
mock_provider "oci" {
  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [
        { name = "xyz:US-ASHBURN-AD-1", id = "ad1", compartment_id = "ocid1.tenancy.oc1..test" },
        { name = "xyz:US-ASHBURN-AD-2", id = "ad2", compartment_id = "ocid1.tenancy.oc1..test" },
        { name = "xyz:US-ASHBURN-AD-3", id = "ad3", compartment_id = "ocid1.tenancy.oc1..test" },
      ]
    }
  }
  mock_data "oci_core_images" {
    defaults = {
      # mocks need every attribute
      images = [{
        id                       = "ocid1.image.oc1..ubuntu2404aarch64"
        agent_features           = null
        base_image_id            = null
        billable_size_in_gbs     = null
        compartment_id           = null
        create_image_allowed     = null
        defined_tags             = null
        display_name             = null
        freeform_tags            = null
        image_source_details     = null
        instance_id              = null
        launch_mode              = null
        launch_options           = null
        listing_type             = null
        operating_system         = null
        operating_system_version = null
        size_in_mbs              = null
        state                    = null
        time_created             = null
      }]
    }
  }
}

variables {
  region              = "us-ashburn-1"
  tenancy_ocid        = "ocid1.tenancy.oc1..test"
  ssh_public_key_path = "tests/test_key.pub"
}

run "a1_defaults" {
  command = plan

  assert {
    condition     = oci_core_instance.vpn.shape == "VM.Standard.A1.Flex"
    error_message = "default shape should be A1 Flex"
  }
  assert {
    condition     = oci_core_instance.vpn.shape_config[0].ocpus == 1 && oci_core_instance.vpn.shape_config[0].memory_in_gbs == 6
    error_message = "A1 should get 1 OCPU / 6 GB by default"
  }
  assert {
    condition     = oci_core_instance.vpn.availability_domain == "xyz:US-ASHBURN-AD-1"
    error_message = "AD index 0 should pick AD-1"
  }
  assert {
    condition     = oci_core_instance.vpn.source_details[0].source_id == "ocid1.image.oc1..ubuntu2404aarch64"
    error_message = "should boot the newest Ubuntu image"
  }
  assert {
    condition     = oci_core_instance.vpn.compartment_id == "ocid1.tenancy.oc1..test"
    error_message = "compartment should default to the tenancy"
  }
  assert {
    condition     = length([for r in oci_core_security_list.vpn.ingress_security_rules : r if r.protocol == "17"]) == 1
    error_message = "only the client WireGuard port should be open by default"
  }
  assert {
    condition     = one([for r in oci_core_security_list.vpn.ingress_security_rules : r if r.protocol == "17"]).udp_options[0].min == 51820
    error_message = "client WireGuard port should be 51820"
  }
  assert {
    condition     = length([for r in oci_core_security_list.vpn.ingress_security_rules : r if r.protocol == "1" && try(r.icmp_options[0].type, -1) == 3]) == 1
    error_message = "path-MTU ICMP must be allowed"
  }
  assert {
    condition     = toset([for r in oci_core_security_list.vpn.ingress_security_rules : r.tcp_options[0].min if r.protocol == "6"]) == toset([22, 9639])
    error_message = "SSH must be open on 22 (Ubuntu, install) and 9639 (NixOS)"
  }
  assert {
    condition     = startswith(oci_core_instance.vpn.metadata.ssh_authorized_keys, "ssh-ed25519 ")
    error_message = "SSH key should be read from the file"
  }
}

run "home_dials_in_opens_second_port" {
  command = plan
  variables {
    home_dials_in             = true
    availability_domain_index = 2
  }
  assert {
    condition     = contains([for r in oci_core_security_list.vpn.ingress_security_rules : r.udp_options[0].min if r.protocol == "17"], 51821)
    error_message = "home port 51821 should be open when home dials in"
  }
  assert {
    condition     = oci_core_instance.vpn.availability_domain == "xyz:US-ASHBURN-AD-3"
    error_message = "AD index 2 should pick AD-3"
  }
}

run "x86_shape_rejected" {
  command = plan
  variables {
    shape = "VM.Standard.E2.1.Micro"
  }
  expect_failures = [var.shape]
}
