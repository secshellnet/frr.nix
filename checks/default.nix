{
  self,
  lib,
  pkgs,
}:

{
  frr = import ./frr.nix { inherit self lib pkgs; };
}
