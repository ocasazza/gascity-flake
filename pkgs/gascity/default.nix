{ runCommand, ... }:

# Stub package — real definition will be ported from
# ~/.config/nixos-config/packages/gascity in a follow-up task.
runCommand "gascity-stub" { } ''
  mkdir -p $out/bin
  : > $out/bin/gc
  chmod +x $out/bin/gc
''
