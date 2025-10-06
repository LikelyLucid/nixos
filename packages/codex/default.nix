{ lib, stdenvNoCC, fetchurl }:
let
  version = "0.45.0";
  release_tag = "rust-v${version}";
  asset_name = "codex-x86_64-unknown-linux-musl.tar.gz";
  src_url = "https://github.com/openai/codex/releases/download/${release_tag}/${asset_name}";
  hash = "1f3jvqdi02a6814ms8w60c9ph51k3a4ik7s8zxx5slh0am8ldd23";
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = src_url;
    sha256 = hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src
    install -Dm755 codex-x86_64-unknown-linux-musl $out/bin/codex
    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenAI Codex CLI built from the latest GitHub release";
    homepage = "https://github.com/openai/codex";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex";
  };
}
