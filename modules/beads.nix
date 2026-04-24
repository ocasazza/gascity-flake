{ config, lib, pkgs, ... }:

# Home Manager module for Beads (`bd`) — installs the CLI and, when the
# matching shell module is enabled, wires up shell completions generated
# by `bd completion {bash,zsh,fish}`.

let
  cfg = config.programs.beads;
in
{
  options.programs.beads = {
    enable = lib.mkEnableOption "beads (bd CLI)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.beads;
      defaultText = lib.literalExpression "pkgs.beads";
      description = "The beads package to install (provides the `bd` binary).";
    };

    enableCompletions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Wire up bash/zsh/fish completions for `bd` when the matching shell module is enabled.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = lib.mkIf
      (cfg.enableCompletions && config.programs.bash.enable or false)
      ''
        if command -v bd >/dev/null 2>&1; then
          source <(bd completion bash)
        fi
      '';

    programs.zsh.initExtra = lib.mkIf
      (cfg.enableCompletions && config.programs.zsh.enable or false)
      ''
        if command -v bd >/dev/null 2>&1; then
          source <(bd completion zsh)
        fi
      '';

    programs.fish.interactiveShellInit = lib.mkIf
      (cfg.enableCompletions && config.programs.fish.enable or false)
      ''
        if command -v bd >/dev/null 2>&1
          bd completion fish | source
        end
      '';
  };
}
