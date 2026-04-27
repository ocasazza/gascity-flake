{ config, lib, pkgs, ... }:

# Home Manager module for Gas City (`gc`) — installs the CLI and the
# runtime tools `gc` shells out to (tmux, jq, git, dolt, flock), with
# optional auto-enable of the companion `programs.beads` module.
#
# Note: `gc` does not currently expose a `completion` subcommand, so no
# `enableCompletions` option is provided.

let
  cfg = config.programs.gascity;
in
{
  options.programs.gascity = {
    enable = lib.mkEnableOption "gascity (Gas City CLI)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.gascity;
      defaultText = lib.literalExpression "pkgs.gascity";
      description = "The gascity package to install (provides the `gc` binary).";
    };

    runtimeDeps = {
      tmux = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install tmux on PATH for `gc` agent sessions.";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.tmux;
          defaultText = lib.literalExpression "pkgs.tmux";
          description = "The tmux package used by `gc`.";
        };
      };

      jq = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install jq on PATH (used by various `gc` subcommands).";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.jq;
          defaultText = lib.literalExpression "pkgs.jq";
          description = "The jq package used by `gc`.";
        };
      };

      git = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install git on PATH for `gc`. Disable if git is already managed via `programs.git`.";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.git;
          defaultText = lib.literalExpression "pkgs.git";
          description = "The git package used by `gc`.";
        };
      };

      dolt = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install dolt on PATH (used by the beads provider that `gc` drives).";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.dolt;
          defaultText = lib.literalExpression "pkgs.dolt";
          description = "The dolt package used by `gc`.";
        };
      };

      flock = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = pkgs.stdenv.hostPlatform.isDarwin;
          defaultText = lib.literalExpression "pkgs.stdenv.hostPlatform.isDarwin";
          description = "Install flock on PATH. Default true on Darwin (Linux ships flock via util-linux already).";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.flock;
          defaultText = lib.literalExpression "pkgs.flock";
          description = "The flock package used by `gc`.";
        };
      };
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages to install alongside `gc` (escape hatch for site-specific tooling).";
    };

    enableBeads = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Auto-enable `programs.beads` so `bd` is on PATH alongside `gc`.";
    };

    defaultProvider = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "claude" "codex" "gemini" ]);
      default = null;
      description = "If set, exports `GC_AGENT_PROVIDER` for the user's session.";
    };

    defaultModel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "If set, exports `GC_AGENT_MODEL` for the user's session.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !lib.hasAttrByPath ["home" "sessionVariables" "CLAUDE_CODE_USE_VERTEX"] config
                 && !lib.hasAttrByPath ["home" "sessionVariables" "ANTHROPIC_VERTEX_PROJECT_ID"] config
                 && !lib.hasAttrByPath ["home" "sessionVariables" "CLOUD_ML_REGION"] config
                 && !lib.hasAttrByPath ["home" "sessionVariablesExtra" "CLAUDE_CODE_USE_VERTEX"] config
                 && !lib.hasAttrByPath ["home" "sessionVariablesExtra" "ANTHROPIC_VERTEX_PROJECT_ID"] config
                 && !lib.hasAttrByPath ["home" "sessionVariablesExtra" "CLOUD_ML_REGION"] config;
        message = ''
          programs.gascity: GCP/Vertex proxy environment variables detected in session environment.

          gc does not support Vertex AI and should never be routed through GCP. These vars would
          leak from programs.claude-code or other sources into gc's shell environment.

          Fix: Ensure programs.claude-code uses litellm WITHOUT cloudPassthrough, or disable Vertex
          entirely. gc will shell out to claude/codex/gemini CLIs which handle their own auth
          independently and are isolated from Claude Code's configuration.
        '';
      }
    ];

    home.packages =
      [ cfg.package ]
      ++ lib.optional cfg.runtimeDeps.tmux.enable cfg.runtimeDeps.tmux.package
      ++ lib.optional cfg.runtimeDeps.jq.enable cfg.runtimeDeps.jq.package
      ++ lib.optional cfg.runtimeDeps.git.enable cfg.runtimeDeps.git.package
      ++ lib.optional cfg.runtimeDeps.dolt.enable cfg.runtimeDeps.dolt.package
      ++ lib.optional cfg.runtimeDeps.flock.enable cfg.runtimeDeps.flock.package
      ++ cfg.extraPackages;

    programs.beads.enable = lib.mkIf cfg.enableBeads (lib.mkDefault true);

    home.sessionVariables = lib.mkMerge [
      (lib.mkIf (cfg.defaultProvider != null) {
        GC_AGENT_PROVIDER = cfg.defaultProvider;
      })
      (lib.mkIf (cfg.defaultModel != null) {
        GC_AGENT_MODEL = cfg.defaultModel;
      })
    ];
  };
}
