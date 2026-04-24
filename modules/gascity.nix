{ config, lib, pkgs, ... }:

# Stub Home Manager module for Gas City (`gc`). Real options/config will
# be ported from ~/.config/nixos-config/modules/home/gascity in a
# follow-up task.
{
  options.programs.gascity.enable = lib.mkEnableOption "gascity";

  config = { };
}
