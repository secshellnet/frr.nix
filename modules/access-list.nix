{ lib, config, ... }:
let
  cfg = config.services.frr.settings.access-list;
  inherit (lib) mkOption types;
  inherit (import ./utils.nix { inherit lib; }) mkComment;

  attrsWith' =
    placeholder: elemType:
    types.attrsWith {
      inherit elemType placeholder;
    };

  alOption =
    alFor:
    mkOption {
      type =
        with types;
        (nullOr (
          attrsWith' "name" (
            nullOr (
              attrsWith' "seq" (
                nullOr (submodule {
                  options = {
                    permit = innerOption;
                    deny = innerOption;
                  };
                })
              )
            )
          )
        ));
      default = null;
      description = "access lists for ${alFor}";
    };

  innerOption = mkOption {
    type = types.nullOr (
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
    );
    default = null;
  };
in
{
  options.services.frr.settings.access-list = mkOption {
    type = types.submodule ({
      options = {
        ip = alOption "ipv4";
        ipv6 = alOption "ipv6";
        bgp_as-path = alOption "bgp as-path";
      };
    });
    default = null;
    description = ''
      [docs.frrouting.org/en/latest/filter.html#ip-access-list](https://docs.frrouting.org/en/latest/filter.html#ip-access-list).
    '';
  };

  config = {
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
                # The type need to be adjusted a bit
                # - ipv4 access lists are not being prefixed
                # - bgp as-path had to be configured with bgp_as-path
                fixedType = builtins.getAttr type {
                  "ip" = "";
                  "ipv6" = "ipv6 ";
                  "bgp_as-path" = "bgp as-path ";
                };
                comments = mkComment cfg.${type}.${name}.${seq}.${action}.comments;
                value = cfg.${type}.${name}.${seq}.${action}.value;
              in
              "${comments}" + "${fixedType}access-list ${name} seq ${seq} ${action} ${value}\n"
            ) (builtins.attrNames (lib.filterAttrs (_: v: v != null) cfg.${type}.${name}.${seq}))
          ) (builtins.attrNames cfg.${type}.${name})
        ) (builtins.attrNames cfg.${type})
      ) (builtins.attrNames (lib.filterAttrs (_: v: v != null) cfg))
    );
  };
}
