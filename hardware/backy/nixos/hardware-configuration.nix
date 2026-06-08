{
  imports = [ ];

  boot.initrd = {
    availableKernelModules = [
      "ata_piix"
      "uhci_hcd" # "platform_pci"
      "sr_mod"
      "xen_blkfront"
    ];
    kernelModules = [ "dm-snapshot" ];
    systemd.enable = true;
  };
}
