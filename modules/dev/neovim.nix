{ ... }:
{
  homeManager.modules.common =
    { pkgs, lib, ... }:
    let
      parserDir = ".local/share/nvim/site/parser";
      queriesDir = ".local/share/nvim/site/queries";
    in
    {
      home.packages = with pkgs; [
        gcc # for compiling treesitter parsers if needed
        gnugrep
        python3Packages.jupytext # required by jupytext.nvim for .ipynb files
        marksman # markdown LSP (mason binary can't run on NixOS)
        neovim
        zig
      ];

      home.sessionVariables.EDITOR = "nvim";

      # symlink nvim-treesitter parsers to site/parser so nvim-treesitter
      # detects them as installed (avoids TSInstall loop on NixOS), and link
      # the bundled queries to site/queries so the highlighter has capture
      # patterns (parsers without queries produce no colors at all)
      home.activation.linkTreesitterParsers = lib.mkAfter ''
        if [ -d "$HOME/.local/share/nvim/lazy/nvim-treesitter/parser" ]; then
          mkdir -p "$HOME/${parserDir}"
          for f in "$HOME/.local/share/nvim/lazy/nvim-treesitter/parser"/*.so; do
            [ -f "$f" ] && ln -sf "$f" "$HOME/${parserDir}/"
          done

          # same as nvim-treesitter's own installer: link runtime/queries/<lang>
          # for every installed parser, otherwise highlighting finds no queries
          queriesSrc="$HOME/.local/share/nvim/lazy/nvim-treesitter/runtime/queries"
          if [ -d "$queriesSrc" ]; then
            mkdir -p "$HOME/${queriesDir}"
            for f in "$HOME/${parserDir}"/*.so; do
              [ -e "$f" ] || continue
              lang=$(basename "$f" .so)
              [ -d "$queriesSrc/$lang" ] && ln -sfn "$queriesSrc/$lang" "$HOME/${queriesDir}/$lang"
            done
          fi
        fi
      '';
    };
}
