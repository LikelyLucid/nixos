{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      mk_craft =
        {
          pname,
          version,
          hash,
          description,
        }:
        pkgs.stdenvNoCC.mkDerivation {
          inherit pname version;

          src = pkgs.fetchurl {
            url = "https://github.com/storytold/${pname}/releases/download/v${version}/${pname}-${version}-linux-x86_64.tar.gz";
            inherit hash;
          };

          nativeBuildInputs = [
            pkgs.autoPatchelfHook
            pkgs.makeWrapper
          ];
          buildInputs = [ pkgs.stdenv.cc.cc.lib ];
          dontStrip = true;

          installPhase = ''
            runHook preInstall

            mkdir -p "$out"
            cp -r bin share "$out/"
            substituteInPlace "$out/share/applications/ai.storyteller.${pname}.desktop" \
              --replace-fail 'Exec=${pname} ' "Exec=$out/bin/${pname} " \
              --replace-fail 'TryExec=${pname}' "TryExec=$out/bin/${pname}"
            wrapProgram "$out/bin/${pname}" \
              --prefix LD_LIBRARY_PATH : "${
                pkgs.lib.makeLibraryPath [
                  pkgs.libglvnd
                  pkgs.vulkan-loader
                  pkgs.wayland
                  pkgs.libxkbcommon
                  pkgs.fontconfig
                  pkgs.libx11
                  pkgs.libxcursor
                  pkgs.libxi
                  pkgs.libxrandr
                ]
              }"

            runHook postInstall
          '';

          meta = {
            inherit description;
            homepage = "https://getartcraft.com/apps/${pname}";
            license = with pkgs.lib.licenses; [
              mit
              asl20
            ];
            mainProgram = pname;
            platforms = [ "x86_64-linux" ];
          };
        };
      wordcraft = mk_craft {
        pname = "wordcraft";
        version = "0.7.0";
        hash = "sha256-YwCfiOPbrqcKwTePq8hVWuFHddMoKRdcXaJVGr4Dky8=";
        description = "Native word processor with DOCX support";
      };
      gridcraft = mk_craft {
        pname = "gridcraft";
        version = "0.7.0";
        hash = "sha256-wBvC3EKVVW9TgQ3+1KhaP1g4hVLBV6ED4QYmwGmznhw=";
        description = "Native spreadsheet editor with XLSX support";
      };
      deckcraft = mk_craft {
        pname = "deckcraft";
        version = "0.7.0";
        hash = "sha256-Mwovsu+IkNre2RCE5b/SnfpBHjOisnwBrDueUg/5jZ8=";
        description = "Native presentation editor with PPTX support";
      };
      pdfcraft = mk_craft {
        pname = "pdfcraft";
        version = "0.8.0";
        hash = "sha256-P0/V3dmYAqPTSUdMYc89q9H7cZjqDfANJMwxBRa9HCo=";
        description = "Native PDF reader and editor";
      };
    in
    {
      home.packages = [
        wordcraft
        gridcraft
        deckcraft
        pdfcraft
      ];
      xdg.mimeApps.defaultApplications = {
        "application/msword" = "ai.storyteller.wordcraft.desktop";
        "application/vnd.ms-excel" = "ai.storyteller.gridcraft.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
          "ai.storyteller.wordcraft.desktop";
        "application/vnd.oasis.opendocument.text" = "ai.storyteller.wordcraft.desktop";
        "application/rtf" = "ai.storyteller.wordcraft.desktop";
        "text/rtf" = "ai.storyteller.wordcraft.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" =
          "ai.storyteller.gridcraft.desktop";
        "application/vnd.oasis.opendocument.spreadsheet" = "ai.storyteller.gridcraft.desktop";
        "text/csv" = "ai.storyteller.gridcraft.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
          "ai.storyteller.deckcraft.desktop";
        "application/pdf" = "ai.storyteller.pdfcraft.desktop";
      };
    };
}
