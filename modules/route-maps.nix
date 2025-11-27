{ lib, config, ... }:
let
  cfg = config.services.frr.settings.route-maps;
  inherit (lib) mkOption types;
  inherit (import ./utils.nix { inherit lib; }) mkComment mkEntry;

  attrsWith' =
    placeholder: elemType:
    types.attrsWith {
      inherit elemType placeholder;
    };

  rmOption = mkOption {
    type = attrsWith' "seq" (
      types.submodule ({
        options = {
          comments = mkOption {
            type = with types; either lines (listOf lines);
            default = "";
            example = "ensure own prefixes have own as in AS-PATH";
            description = ''
              String that are being added as comments before the route-map.
            '';
          };
          match = mkOption {
            type = with types; either lines (listOf lines);
            default = "";
            example = ''
              as-path OWN_AS
              ipv6 address prefix-list OWN_PREFIX
            '';
            description = ''
              A route-map entry may, optionally, specify one or more conditions
              must be matched if the entry is to be considered further, as governed
              by the Match Policy. If a route-map entry does not explicitly specify
              any matching conditions, then it always matches.
            '';
          };
          set = mkOption {
            type = with types; either lines (listOf lines);
            default = "";
            example = ''
              table 10
              ip next-hop 192.0.2.1
              local-preference 110
            '';
            description = ''
              A route-map entry may, optionally, specify one or more Set Actions to
              set or modify attributes of the route.
            '';
          };
          extraConfig = mkOption {
            type = with types; either lines (listOf lines);
            default = "";
            example = "continue 15";
            description = ''
              **Matching Policy**:

              This specifies the policy implied if the Matching Conditions are met or
              not met, and which actions of the route-map are to be taken, if any. The
              two possibilities are:

              * permit: If the entry matches, then carry out the Set Actions. Then
                finish processing the route-map, permitting the route, unless an Exit
                Policy action indicates otherwise.
              * deny: If the entry matches, then finish processing the route-map and
                deny the route (return deny).

              The Matching Policy is specified as part of the command which defines the
              ordered entry in the route-map. See below.

              **Call Action**:

              Call to another route-map, after any Set Actions have been carried out. If
              the route-map called returns deny then processing of the route-map finishes
              and the route is denied, regardless of the Matching Policy or the Exit Policy.
              If the called route-map returns permit, then Matching Policy and Exit Policy
              govern further behaviour, as normal.

              **Exit Policy**:

              An entry may, optionally, specify an alternative Exit Policy to take if the
              entry matched, rather than the normal policy of exiting the route-map and
              permitting the route. The two possibilities are:

              * next: Continue on with processing of the route-map entries.
              * goto N: Jump ahead to the first route-map entry whose order in the route-map
                is >= N. Jumping to a previous entry is not permitted.
            '';
          };
        };
      })
    );
    default = null;
  };
in
{
  options.services.frr.settings.route-maps = mkOption {
    type = attrsWith' "name" (
      with types;
      nullOr (submodule {
        options = {
          permit = rmOption;
          #optimization = rmOption;
          deny = rmOption;
        };
      })
    );
    default = null;
    description = ''
      Route maps provide a means to both filter and/or apply actions to route, hence allowing policy to be applied to routes.
      See [docs.frrouting.org/en/latest/routemap.html](https://docs.frrouting.org/en/latest/routemap.html).
    '';
  };

  config = {
    services.frr.config = lib.concatStringsSep "!\n" (
      lib.lists.concatMap (
        name:
        lib.lists.concatMap (
          action:
          lib.lists.map (
            seq:
            let
              comments = mkComment cfg.${name}.${action}.${seq}.comments;
              match = mkEntry cfg.${name}.${action}.${seq}.match "  match ";
              set = mkEntry cfg.${name}.${action}.${seq}.set "  set ";
              extraConfig = mkEntry cfg.${name}.${action}.${seq}.extraConfig "  ";
            in
            (
              "${comments}"
              + "route-map ${name} ${action} ${seq}\n"
              + "${match}"
              + "${set}"
              + "${extraConfig}"
              + "exit\n"
            )
          ) (builtins.attrNames cfg.${name}.${action})
        ) (builtins.attrNames (lib.filterAttrs (_: v: v != null) cfg.${name}))
      ) (builtins.attrNames cfg)
    );
  };
}
