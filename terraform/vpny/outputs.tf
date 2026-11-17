output "public_ip" {
  value = oci_core_instance.vpn.public_ip
}

output "ssh" {
  description = "Before the NixOS install (Ubuntu, port 22)."
  value       = "ssh ubuntu@${oci_core_instance.vpn.public_ip}"
}

output "ssh_nixos" {
  description = "After the install (NixOS, port 9639). Add to ~/.ssh/config as Host vpny for deploy-rs."
  value       = "ssh -p 9639 root@${oci_core_instance.vpn.public_ip}"
}

output "nixos_anywhere" {
  description = "Run from the repo root; see hardware/vpny/README.md for preparing ./vpny-extra-files."
  value       = "nix run github:nix-community/nixos-anywhere -- --flake .#vpny --target-host ubuntu@${oci_core_instance.vpn.public_ip} --build-on remote --extra-files ./vpny-extra-files"
}

output "client_endpoint" {
  value = "${oci_core_instance.vpn.public_ip}:${var.wireguard_port}"
}
