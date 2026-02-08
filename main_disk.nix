{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-path/pci-0000:00:17.0-ata-2";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              extraOpenArgs = [ ];
              settings = {
                keyFile = "/dev/disk/by-partlabel/KEYMAIN";
                keyFileSize = 4096;
                allowDiscards = true;
                fallbackToPassword = true;
              };
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          var = {
            size = "32G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/var";
              mountOptions = [
                "defaults"
                "noexec"
                "nodev"
                "nosuid"
              ];
            };
          };
          tmp = {
            size = "8G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/tmp";
              mountOptions = [
                "defaults"
                "noexec"
                "nodev"
                "nosuid"
              ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "defaults"
              ];
            };
          };
          swap = {
            size = "32G";
            content.type = "swap";
          };
          raw = {
            size = "10M";
          };
        };
      };
    };
  };
}
