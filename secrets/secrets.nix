let
  cloud_secrets = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7c1YXp0NaHB/dElMIZ+zi4xOojEYu6TM6KEXnMui0a";
in
{
  "cloud/nc_admin.age".publicKeys = [ cloud_secrets ];
}
