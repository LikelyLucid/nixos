{ ... }:
{
  homeManager.modules.common =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        gnugrep
        python3Packages.jupytext # required by jupytext.nvim for .ipynb files
        marksman # markdown LSP (mason binary can't run on NixOS)
        zig
      ];

      home.sessionVariables.EDITOR = "nvim";
    };
}
