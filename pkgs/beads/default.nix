{ runCommand, ... }:

# Stub package — real definition will be ported from
# ~/.config/nixos-config/packages/beads in a follow-up task.
runCommand "beads-stub" { } ''
  mkdir -p $out/bin
  : > $out/bin/bd
  chmod +x $out/bin/bd
''
