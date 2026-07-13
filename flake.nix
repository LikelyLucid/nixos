{
  description = "My XPS 15 9530 NixOS Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree = {
      url = "github:vic/import-tree";
      flake = false;
    };

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    zenBrowser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    lazyvim-config = {
      url = "github:LikelyLucid/lazyvim-dotfiles";
      flake = false;
    };

    dotfiles = {
      url = "github:LikelyLucid/dotfiles";
      flake = false;
    };

    pi-config = {
      url = "github:LikelyLucid/pi-config";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    pi.url = "github:lukasl-dev/pi.nix";

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium-browser.url = "github:schembriaiden/helium-browser-nix-flake";

    beeper = {
      url = "github:hashcube-dev/beeperDesktopFlake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-canvas = {
      url = "github:zyrophix/hyprland-canvas";
      flake = false;
    };
  };

  outputs =
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } ((import inputs.import-tree) ./modules);
}
