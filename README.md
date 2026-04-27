# gascity-flake

A Nix flake that packages the [Gas City](https://github.com/gastownhall/gascity)
CLI (`gc`) and the [Beads](https://github.com/gastownhall/beads) issue
tracker (`bd`), and exposes Home Manager modules to install them and the
runtime tools they shell out to. Both upstream tools are distributed as
prebuilt binaries; this flake wraps them and the surrounding PATH wiring,
nothing more.

## Quick start

Add the input:

```nix
{
  inputs.gascity-flake.url = "github:ocasazza/gascity-flake";
}
```

Pull both Home Manager modules in (this also auto-enables `programs.beads`):

```nix
{ inputs, ... }: {
  imports = [ inputs.gascity-flake.homeManagerModules.default ];

  programs.gascity.enable = true;
}
```

Or, if you only want one of them, import `homeManagerModules.gascity` /
`homeManagerModules.beads` directly. Each module pulls its package from
`pkgs.gascity` / `pkgs.beads`, so register the overlay (or override the
`package` option) so those attributes resolve:

```nix
nixpkgs.overlays = [ inputs.gascity-flake.overlays.default ];
```

To grab a binary outside Home Manager:

```sh
nix run github:ocasazza/gascity-flake#gascity -- --help
nix run github:ocasazza/gascity-flake#beads   -- --help
```

## Provider configuration

`gc` does not embed any LLM client. It shells out to whichever provider CLI
you point it at (`claude`, `codex`, or `gemini`), and authentication lives
in those tools — not in this module.

**⚠️ IMPORTANT: GCP/Vertex proxy is NOT supported.** gc will not work with
Vertex AI or GCP proxies. If you have `programs.claude-code` configured with
`vertex.enable = true` or `litellm.cloudPassthrough = true`, those settings
will NOT be inherited by gc. Instead:
- For **Claude Code**, configure `programs.claude-code` without Vertex, or use
  `litellm.enable = true` with `litellm.cloudPassthrough = false` to route
  through LiteLLM's `/v1` endpoints (not `/vertex/v1`).
- gc will only recognize `claude`, `codex`, or `gemini` CLIs and will shell
  out to their native implementations. Provider CLI auth is independent.

Usage guidance:
- For the Claude Code provider, your host should configure `programs.claude-code.*`
  separately. This flake intentionally does not bundle `claude-code`.
- The two env-var knobs we expose, `defaultProvider` and `defaultModel`,
  only set `GC_AGENT_PROVIDER` and `GC_AGENT_MODEL` as session defaults (both
  default to `null`).
- The actual per-workspace provider is chosen at `gc init --provider X`
  time and persisted to `.gc/city.toml` in that workspace.
- If `gc init` warns about provider configuration, that is a provider-CLI
  auth issue. For Claude Code, fix it under `programs.claude-code` and/or
  verify with `claude auth status --json`.

## Option reference

### `programs.gascity`

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Master enable switch. |
| `package` | package | `pkgs.gascity` | Provides the `gc` binary. |
| `extraPackages` | list of package | `[ ]` | Escape hatch for site-specific tools. |
| `enableBeads` | bool | `true` | Auto-enables `programs.beads` (via `mkDefault`). |
| `defaultProvider` | null or one of `claude` / `codex` / `gemini` | `null` | Exports `GC_AGENT_PROVIDER` when set. |
| `defaultModel` | null or string | `null` | Exports `GC_AGENT_MODEL` when set. |
| `runtimeDeps.tmux.enable` | bool | `true` | Install tmux for `gc` agent sessions. |
| `runtimeDeps.tmux.package` | package | `pkgs.tmux` | |
| `runtimeDeps.jq.enable` | bool | `true` | jq is used by various `gc` subcommands. |
| `runtimeDeps.jq.package` | package | `pkgs.jq` | |
| `runtimeDeps.git.enable` | bool | `true` | Disable if git is already managed via `programs.git`. |
| `runtimeDeps.git.package` | package | `pkgs.git` | |
| `runtimeDeps.dolt.enable` | bool | `true` | Used by the beads provider that `gc` drives. |
| `runtimeDeps.dolt.package` | package | `pkgs.dolt` | |
| `runtimeDeps.flock.enable` | bool | `pkgs.stdenv.hostPlatform.isDarwin` | Defaults true on Darwin only. |
| `runtimeDeps.flock.package` | package | `pkgs.flock` | |

### `programs.beads`

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Master enable switch. |
| `package` | package | `pkgs.beads` | Provides the `bd` binary. |
| `enableCompletions` | bool | `true` | Wires `bd completion {bash,zsh,fish}` into the matching shell module when enabled. |

## Runtime dependencies

`gc` discovers the following tools from PATH at runtime; the module installs
them by default and lets you opt out when something else owns them.

| Tool | Why it is needed | How to disable |
| --- | --- | --- |
| `tmux` | `gc` runs each agent session inside a managed tmux pane. | `runtimeDeps.tmux.enable = false;` |
| `jq` | Used by several `gc` subcommands for JSON parsing. | `runtimeDeps.jq.enable = false;` |
| `git` | Workspace inspection, branch operations. | `runtimeDeps.git.enable = false;` (recommended when `programs.git` already installs git). |
| `dolt` | Backing store for the beads provider that `gc` drives. | `runtimeDeps.dolt.enable = false;` |
| `flock` | Cross-process locking around the shared workspace state. Linux ships flock in `util-linux`, so the default is `true` only on Darwin. | `runtimeDeps.flock.enable = false;` |

## Security and telemetry posture

- Both `gc` and `bd` are installed from upstream prebuilt release tarballs
  (`sourceProvenance = [ binaryNativeCode ]`). This flake does not build
  them from source.
- `gc` shells out to provider CLIs (`claude`, `codex`, `gemini`); any
  network traffic happens inside those tools, governed by their config.
- This module does not write to `~/.config` at activation, does not run
  `gc` during a build, and does not phone home.
- Adopters concerned about supply chain should pin a specific commit or
  tag of this flake input (`url = "github:ocasazza/gascity-flake/<rev>"`)
  rather than tracking `main`.
- `LICENSE` covers the flake glue itself; upstream `gc` and `bd` carry
  their own licenses (both MIT at the time of writing).

## Supported platforms

| System | Status |
| --- | --- |
| `aarch64-darwin` | Built and used in production on the maintainer's fleet. |
| `x86_64-darwin` | Tarball wired and hash-pinned; not actively exercised. |
| `aarch64-linux` | Tested via evaluation; end-to-end build verification pending. |
| `x86_64-linux` | Tested via evaluation; end-to-end build verification pending. |

## Migration from inline copies

If you previously vendored these packages and the Home Manager module
inside your own nixos-config (e.g. `packages/gascity`, `packages/beads`,
`modules/home/gascity`):

1. Delete the inline `packages/gascity`, `packages/beads`, and
   `modules/home/gascity` trees from your config.
2. Drop any overlay entries you had registering `pkgs.gascity` /
   `pkgs.beads` from those local paths.
3. Add `gascity-flake` as a flake input and register
   `inputs.gascity-flake.overlays.default` on your `nixpkgs.overlays`.
4. Import `inputs.gascity-flake.homeManagerModules.default` from your
   Home Manager configuration.
5. Set `programs.gascity.enable = true;` (and override
   `defaultProvider` / `defaultModel` if you previously set those env
   vars by hand).
6. `nh home switch` (or `nh os switch` on NixOS) and confirm `gc --help`
   and `bd --help` still resolve.

## License

MIT — see [LICENSE](./LICENSE).

## Status

`v0.0.1` — initial release. The option surface may change before `1.0`;
pin a specific revision if you need stability across upgrades.
