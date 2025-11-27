{ lib, config, ... }:
let
  cfg = config.services.frr.settings.access-list;
  inherit (lib) mkOption types;
  attrsWith' =
    placeholder: elemType:
    types.attrsWith {
      inherit elemType placeholder;
    };

  inherit (import ./utils.nix { inherit lib; }) mkComment;
in
{
  options.services.frr.settings.access-list = mkOption {
    type = attrsWith' "type" (
      attrsWith' "name" (
        attrsWith' "seq" (
          attrsWith' "action" (
            types.submodule ({
              options = {
                comments = mkOption {
                  type = with types; either lines (listOf lines);
                  default = "";
                  example = "define own prefixes";
                  description = ''
                    String that are being added as comments before the route-map.
                  '';
                };
                value = mkOption {
                  type = types.str;
                  description = ''
                    The value for the access list entry.
                  '';
                };
              };
            })
          )
        )
      )
    );
    default = null;
    description = ''
      [docs.frrouting.org/en/latest/filter.html#ip-access-list](https://docs.frrouting.org/en/latest/filter.html#ip-access-list).
    '';
  };

  config = {
    # TODO ensure action matches types.enum [ "permit" "deny" ];
    # TODO ensure seq matches types.ints.u32 validates 1-4294967295

    #assertions = [
    #  {
    #    assertion = false;
    #    message = "TODO";
    #  }
    #];

    services.frr.config = lib.concatStringsSep "" (
      lib.lists.concatMap (
        type:
        lib.lists.concatMap (
          name:
          lib.lists.concatMap (
            seq:
            lib.lists.map (
              action:
              let
                comments = mkComment cfg.${type}.${name}.${seq}.${action}.comments;
                value = cfg.${type}.${name}.${seq}.${action}.value;
              in
              "${comments}" + "${type} access-list ${name} seq ${seq} ${action} ${value}\n"
            ) (builtins.attrNames cfg.${type}.${name}.${seq})
          ) (builtins.attrNames cfg.${type}.${name})
        ) (builtins.attrNames cfg.${type})
      ) (builtins.attrNames cfg)
    );
  };
}
