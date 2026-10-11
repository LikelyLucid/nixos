{
  description = "My XPS 15 9530 NixOS Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    handy.url = "github:cjpais/handy/fbd4e15fa14a721c66c57006ae110428b9e255b3";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    pi = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cua-driver = {
      url = "github:trycua/cua/cua-driver-rs-v0.25.0";
      flake = false;
    };

    herdr = {
      url = "github:herdrdev/herdr/d277d2f83b749a38c90eb96ef7cd329cc2171cd7";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr-workspace-manager = {
      url = "github:razajamil/herdr-plugin-workspace-manager/v0.6.0";
      flake = false;
    };

    herdr-worktree-setup = {
      url = "github:tdi/herdr-worktree-setup/v0.2.0";
      flake = false;
    };

    herdr-command-palette = {
      url = "github:JanTvrdik/herdr-command-palette";
      flake = false;
    };

    herdr-pluck = {
      url = "github:rmarganti/herdr-pluck/v0.3.0";
      flake = false;
    };

    herdr-sidebar = {
      url = "github:alexarthurs/herdr-sidebar/4faeea73503bcfb7e5ba72ef0c683649f64f74e5";
      flake = false;
    };

    herdr-nvim = {
      url = "github:ChmaraX/herdr-nvim/5e20a4048a461457df995cf121c1a6c39990e95b";
      flake = false;
    };

    herdr-automatic-rename = {
      url = "github:qu8n/herdr-automatic-rename/v0.7.0";
      flake = false;
    };

    herdr-board = {
      url = "github:nelsonPires5/herdr-board/v0.15.0";
      flake = false;
    };

    herdr-navigator = {
      url = "github:thanhdat77/herdr-navigator/9bdf30f03f53730e6232377a3fca3bdc6ed9f3ca";
      flake = false;
    };

    memex = {
      url = "github:nicosuave/memex/969ab58c88661557d9e5a3445d7dfc583e89e1cb";
      flake = false;
    };

    herdr-hunk-diff = {
      url = "github:jhochenbaum/herdr-hunk-diff";
      flake = false;
    };

    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium-browser = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blip = {
      url = "github:blip-net/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    beeper = {
      url = "github:hashcube-dev/beeperDesktopFlake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-canvas = {
      url = "github:zyrophix/hyprland-canvas";
      flake = false;
    };

    omi = {
      url = "github:BasedHardware/Omi";
      flake = false;
    };
  };

  outputs =
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } ((import inputs.import-tree) ./modules);
}
