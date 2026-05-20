{ config, lib, pi-config, isWsl ? false, ... }:
let
  mk_link = config.lib.file.mkOutOfStoreSymlink;
in {
  # Symlink pi-config files to ~/.pi/agent/
  # Pi auto-discovers extensions under ~/.pi/agent/extensions/
  home.file = {
    ".pi/agent/AGENTS.md".source = mk_link "${pi-config}/AGENTS.md";
    ".pi/agent/settings.json".text = builtins.toJSON {
      defaultProvider = "ollama-cloud";
      defaultModel = "deepseek-v4-flash";
      defaultThinkingLevel = "high";
      theme = "dark";
      hideThinkingBlock = false;
      enabledModels = [
        "ollama-cloud/deepseek-v4-flash"
        "ollama-cloud/deepseek-v4-pro"
        "ollama-cloud/qwen3.5:397b"
        "ollama-cloud/gemma4:31b"
      ];
    };
    ".pi/agent/README.md".source = mk_link "${pi-config}/README.md";
    ".pi/agent/extensions/pi-ollama-cloud".source = mk_link "${pi-config}/extensions/pi-ollama-cloud";
  };
}
