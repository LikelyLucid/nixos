{ codex_binary, codex_release_meta }:
final: prev:
{
  ############################################
  # CODEX WRAPPER
  ############################################
  codex = prev.callPackage ../packages/codex {
    inherit codex_binary codex_release_meta;
  };
}
