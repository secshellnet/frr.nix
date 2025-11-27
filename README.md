# secshellnet/frr.nix

This NixOS module allows the declarative configuration of access-lists, prefix-lists and route-maps.

A custom option search for the module can be found on [secshellnet.github.io/frr.nix](https://secshellnet.github.io/frr.nix/).

## ToDo
- Add assertions:
  ```nix
  {
    assertions = [
      {
        assertion = true;
        message = "...";
      }
    ];
  }
  ```
  - ensure `access-list` `type` has valid value: `lib.types.enum [ "ip" "ipv6" ];`
  - ensure `prefix-list` `afi` has valid value: `lib.types.enum [ "ip" "ipv6" ];`
  - ensure `name` has valid value
  - ensure `action` has valid value:
    - for `route-maps`: `lib.types.enum [ "permit" "optimization" "deny" ];`
    - for `access-list`: `lib.types.enum [ "permit" "deny" ];`
    - for `prefix-list`: `lib.types.enum [ "permit" "deny" ];`
  - ensure `seq` is in range of valid value:
    - for `route-maps`: `lib.types.ints.u16` (1-65535)
    - for `access-list`: `lib.types.ints.u32` (1-4294967295)
    - for `prefix-list`: `lib.types.ints.u32` (1-4294967295)
