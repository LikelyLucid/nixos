{ lib, stdenvNoCC, codex_binary, codex_release_meta }:
let
  release_meta = lib.importJSON codex_release_meta;
  raw_tag = lib.attrByPath [ "tag_name" ] "unknown" release_meta;
  version =
    if lib.hasPrefix "rust-v" raw_tag then
      lib.removePrefix "rust-v" raw_tag
    else
      raw_tag;
  binary_name = "codex-x86_64-unknown-linux-musl";
  binary_path = "${codex_binary}/${binary_name}";
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  src = codex_binary;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    if [ ! -e "${binary_path}" ]; then
      echo "Expected Codex binary ${binary_name} not found in source" >&2
      exit 1
    fi
    install -Dm755 "${binary_path}" "$out/bin/codex"
    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenAI Codex CLI built from the latest GitHub release";
    homepage = "https://github.com/openai/codex";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    changelog = lib.attrByPath [ "html_url" ] null release_meta;
    mainProgram = "codex";
  };
}
