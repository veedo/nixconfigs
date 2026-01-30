{ inputs, self, ... }:
{
  flake.nixosModules.git =
    { ... }:
    {
      programs.git = {
        enable = true;
        lfs.enable = true;
        config = {
          user.name = "Zander Erasmus";
          user.email = "zerasmus@corvusenergy.com";
          push = {
            autoSetupRemote = true;
          };
          alias = {
            lg1 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all";
            lg2 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all";
            lg = "lg1";
            Push = "push";
          };
          credential.helper = "store";
        };
      };
    };
}
