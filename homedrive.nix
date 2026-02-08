{
      disko.devices = {
        disk.home = {
            type = "disk";
            device = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
            content = {
              type = "gpt";
              partitions = {
                luks = {
                  size = "100%";
                  content = {
                    type = "luks";
                    name = "cryptedMain";
                    extraOpenArgs = [ ];
                    settings = {
                      keyFile = "/dev/disk/by-partlabel/KEYMAIN";
                      keyFileSize = 4096;
                      allowDiscards = true;
                      fallbackToPassword = true;
                    };
                    content = {
                      type = "filesystem";
                      format = "ext4";
                      mountpoint = "/home";
                      mountOptions = [
                        "defaults"
                        "noexec"
                        "nodev"
                        "nosuid"
                      ];
                    };
                  };
                };
              };
            };
        };
      };

    }
