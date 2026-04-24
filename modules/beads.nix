{ config, lib, pkgs, ... }:

# Stub Home Manager module for Beads (`bd`). Real options/config will be
# ported in a follow-up task.
{
  options.programs.beads.enable = lib.mkEnableOption "beads";

  config = { };
}
