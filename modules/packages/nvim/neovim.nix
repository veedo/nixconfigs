{inputs, lib, ...}: {
  flake-file.inputs.neovim-nightly-overlay = {
    url = "github:nix-community/neovim-nightly-overlay";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Tracks the same commit as the `modules/packages/nvim/kickstart-modular.nvim`
  # git submodule (kept in sync manually, e.g. via `nix flake lock --update-input
  # kickstart-modular-nvim`). Fetched as a separate flake input, rather than read
  # straight out of the submodule checkout, because Nix's local flake source
  # filtering only sees the submodule's gitlink, not its tracked files.
  flake-file.inputs.kickstart-modular-nvim = {
    url = "github:veedo/kickstart-modular.nvim/zander";
    flake = false;
  };

  flake.nixosModules.neovim = {pkgs, ...}: let
    nvimSrc = inputs.kickstart-modular-nvim;

    # Plugins that lua/plugins.lua and its required kickstart.plugins modules
    # load by default. Provided as Nix-managed native packages instead of
    # being installed at runtime by vim.pack.
    #
    # NOTE: nvim-treesitter (main branch) still downloads its own precompiled
    # grammar binaries over the network the first time a filetype is opened
    # (see lua/kickstart/plugins/treesitter.lua) - nixpkgs' `withPlugins` is a
    # no-op for this package, so that part can't be made fully offline/Nix-only.
    # `tree-sitter` is added to systemPackages below since it's needed to build
    # grammars nvim-treesitter can't find a prebuilt binary for.
    pluginNames = [
      "guess-indent-nvim"
      "gitsigns-nvim"
      "which-key-nvim"
      "tokyonight-nvim"
      "todo-comments-nvim"
      "mini-nvim"
      "plenary-nvim"
      "telescope-nvim"
      "telescope-ui-select-nvim"
      "telescope-fzf-native-nvim"
      "fidget-nvim"
      "nvim-lspconfig"
      "lazy-lsp-nvim"
      "conform-nvim"
      "luasnip"
      "blink-cmp"
      "nvim-treesitter"
    ];

    # A native `packpath` package directory: every plugin below shows up on
    # Neovim's runtimepath at startup with no plugin manager involved.
    nvimPack = pkgs.linkFarm "nvim-pack-nix-start" (map (name: {
        inherit name;
        path = pkgs.vimPlugins.${name};
      })
      pluginNames);
  in {
    environment.systemPackages = [
      inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.tree-sitter
    ];

    hjem.users.zander.files = {
      ".config/nvim/init.lua".source = "${nvimSrc}/init.lua";
      ".config/nvim/lua".source = "${nvimSrc}/lua";
      ".config/nvim/doc".source = "${nvimSrc}/doc";
      ".config/nvim/pack/nix/start".source = nvimPack;
    };
  };
}
