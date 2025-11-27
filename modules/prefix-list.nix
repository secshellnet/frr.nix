{ lib, config, ... }:
let
  cfg = config.services.frr.settings.prefix-list;
  inherit (lib) mkOption types;
  inherit (import ./utils.nix { inherit lib; }) mkComment getAttrsKeyWithoutNullValues;

  attrsWith' =
    placeholder: elemType:
    types.attrsWith {
      inherit elemType placeholder;
    };

  plOption = mkOption {
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
  };

  innerOption = mkOption {
    type =
      with types;
      nullOr (submodule {
        options = {
          comments = mkOption {
            type = with types; either lines (listOf lines);
            default = "";
            example = "define own prefixes";
            description = ''
              String that are being added as comments before the route-map.
            '';
          };
          prefix = mkOption {
            type = types.str;
            description = ''
              The prefix.
            '';
          };
          le = mkOption {
            type = with types; nullOr ints.u8;
            default = null;
            example = 24;
            description = ''
              Specifies prefix length. The prefix list will be applied if
              the prefix length is less than or equal to the le prefix length.
            '';
          };
          ge = mkOption {
            type = with types; nullOr ints.u8;
            default = null;
            example = 16;
            description = ''
              Specifies prefix length. The prefix list will be applied if
              the prefix length is greater than or equal to the ge prefix length.
            '';
          };
        };
      });
    default = null;
  };
in
{
  options.services.frr.settings.prefix-list = mkOption {
    type = types.submodule ({
      options = {
        ip = plOption;
        ipv6 = plOption;
      };
    });
    default = null;
    description = ''
      ip prefix-list provides the most powerful prefix based filtering mechanism. In addition to access-list
      functionality, ip prefix-list has prefix length range specification and sequential number specification.
      You can add or delete prefix based filters to arbitrary points of prefix-list using sequential number
      specification. See
      [docs.frrouting.org/en/latest/filter.html#ip-prefix-list](https://docs.frrouting.org/en/latest/filter.html#ip-prefix-list).
    '';
  };

  config = {
    assertions =
      let
        names = (getAttrsKeyWithoutNullValues cfg.ip) ++ (getAttrsKeyWithoutNullValues cfg.ipv6);
      in
      (map (name: {
        assertion = builtins.match "^[a-zA-Z0-9][a-zA-Z0-9._-]{0,62}$" name != null;
        message = "Invalid name for prefix-list ${name}";
      }) names)
    #++ map (
    #  name:
    #  (lib.lists.concatMap
    #    (seq: {
    #      assertion = builtins.isInt seq && seq >= 1 && seq <= 4294967295;
    #      message = "Invalid seq number for prefix-list ${name} (${seq})";
    #    })
    #    (
    #      (getAttrsKeyWithoutNullValues cfg.${name}.deny) ++ (getAttrsKeyWithoutNullValues cfg.${name}.permit)  # TODO add ip / ipv6
    #    )
    #  )
    #) names
    ;

    services.frr.config = lib.concatStringsSep "" (
      lib.lists.concatMap (
        afi:
        lib.lists.concatMap (
          name:
          lib.lists.concatMap (
            seq:
            lib.lists.map (
              action:
              let
                comments = mkComment cfg.${afi}.${name}.${seq}.${action}.comments;
                prefix = cfg.${afi}.${name}.${seq}.${action}.prefix;
                le = toString cfg.${afi}.${name}.${seq}.${action}.le;
                ge = toString cfg.${afi}.${name}.${seq}.${action}.ge;
                opt =
                  (lib.optionalString (le != "") " le ${le}") + (lib.optionalString (ge != "") " ge ${ge}") + "\n";
              in
              "${comments}" + "${afi} prefix-list ${name} seq ${seq} ${action} ${prefix}${opt}"
            ) (builtins.attrNames (lib.filterAttrs (_: v: v != null) cfg.${afi}.${name}.${seq}))
          ) (builtins.attrNames cfg.${afi}.${name})
        ) (builtins.attrNames cfg.${afi})
      ) (builtins.attrNames (lib.filterAttrs (_: v: v != null) cfg))
    );
  };
}
