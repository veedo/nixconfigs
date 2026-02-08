{
  disko.devices = {
    disk = {
      clouddisk1 = {
        type = "disk";
        device = "/dev/disk/by-id/usb-TerraMas_TDAS_WSC2Z2DA-0:0";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zclouddata";
              };
            };
          };
        };
      };
      clouddisk2 = {
        type = "disk";
        device = "/dev/disk/by-id/usb-TerraMas_TDAS_ZR161W01-0:0";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zclouddata";
              };
            };
          };
        };
      };
    };
    zpool = {
      zclouddata = {
        type = "zpool";
        mode = "mirror";
        # Workaround: cannot import 'zclouddata': I/O error in disko tests
        options.cachefile = "none";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/clouddata";
        mountOptions = [ "nofail" ];
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zclouddata@blank$' || zfs snapshot zclouddata@blank";

        datasets = {
          encrypted = {
            type = "zfs_fs";
            mountOptions = [ "nofail" ];
            options = {
              mountpoint = "none";
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file:///dev/disk/by-partlabel/KEYDATA1";
              "com.sun:auto-snapshot" = "true";
            };
            # use this to read the key during boot
            # postCreateHook = ''
            #   zfs set keylocation="prompt" "zclouddata/$name";
            # '';
          };
          "encrypted/serverdata" = {
            type = "zfs_fs";
            mountpoint = "/clouddata/serverdata";
            mountOptions = [ "nofail" ];
          };
        };
      };
    };
  };
}
