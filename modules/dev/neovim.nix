{ ... }:
{
  homeManager.modules.common =
    { pkgs, lib, ... }:
    let
      parserDir = ".local/share/nvim/site/parser";
    in
    {
      home.packages = with pkgs; [
        fzf
        gcc # for compiling treesitter parsers if needed
        gnugrep
        marksman # markdown LSP (mason binary can't run on NixOS)
        neovim
        zig
      ];

      home.sessionVariables.EDITOR = "nvim";

      # symlink nvim-treesitter parsers to site/parser so nvim-treesitter
      # detects them as installed (avoids TSInstall loop on NixOS)
      home.activation.linkTreesitterParsers = lib.mkAfter ''
        if [ -d "$HOME/.local/share/nvim/lazy/nvim-treesitter/parser" ]; then
          mkdir -p "$HOME/${parserDir}"
          for f in "$HOME/.local/share/nvim/lazy/nvim-treesitter/parser"/*.so; do
            [ -f "$f" ] && ln -sf "$f" "$HOME/${parserDir}/"
          done
        fi
      '';
    };
}
