# secshellnet/frr.nix

This NixOS module allows the declarative configuration of access-lists, prefix-lists and route-maps.

A custom option search for the module can be found on [secshellnet.github.io/frr.nix](https://secshellnet.github.io/frr.nix/).

## Examples
```nix
{ lib, frr, ... }:
{
  imports = [
    frr.nixosModules.common
  ];
  services.frr = {
    settings = {
      access-list.bgp_as-path.own-asns."10".permit.value = "4200000000";
      prefix-list = {
        ip.own."10".permit.prefix = "198.51.100.0/24";
        ipv6.own-6."10".permit.prefix = "3fff::/48";

        # These prefix lists contain the IXP peering LANs we’re connected to, to prevent smaller announcements from non-IXP peers.
        # - 10: XXXX-IX: https://www.peeringdb.com/ix/XXXX
        ip.ixp-peering-lans = {
          "10".permit = {
            prefix = "192.0.2.0/24";
            le = 32;
          };
        };
        ipv6.ixp-peering-lans-6 = {
          "10".permit = {
            prefix = "2001:db8::/64";
            le = 128;
          };
        };

      };
      route-maps = (
        lib.recursiveUpdate (builtins.listToAttrs (
          builtins.concatMap
            (
              v:
              let
                plPrefix = if (v.afi or "ipv6") == "ipv6" then "ipv6" else "ip";
                suffix = if (v.afi or "ipv6") == "ipv6" then "-6" else "-4";
              in
              [
                # export: only advertise own prefixes
                {
                  name = "self-${v.name}${suffix}";
                  value.permit."10".match = "${plPrefix} address prefix-list own${suffix}";
                }
                # import
                {
                  name = "${v.name}-self${suffix}";
                  value = {
                    deny = builtins.removeAttrs {
                      # bogon asns (private, documentation) should no appear in default free zone (aka. full table).
                      "10".match = "as-path bogon-asns";
                      # reject route if bgp path contains own asn
                      "11".match = "as-path own-asns";
                      "20".match = "${plPrefix} address prefix-list special-purpose${suffix}";
                      "21".match = "${plPrefix} address prefix-list own${suffix}";
                      "22".match = "${plPrefix} address prefix-list ixp-peering-lans${suffix}";
                      "23".match = "${plPrefix} address prefix-list default-route${suffix}";
                      "24".match = "${plPrefix} address prefix-list too-small${suffix}";
                      "30".match = "rpki invalid";
                    } (v.skip or [ ]);

                    permit = builtins.removeAttrs {
                      "31" = {
                        match = "rpki notfound";
                        set = "local-preference 50";
                      };
                      "32" = {
                        match = "rpki valid";
                        set = "local-preference 150";
                      };
                      "100" = { };
                    } (v.skip or [ ]);
                  };
                }
              ]
            )
            [
              {
                name = "transit";
              }
              {
                name = "ixp";
                skip = [
                  "23" # ixp peering lans
                ];
              }
            ]
        )) { /* custom overrides to merge custom rules */ }
      );
    };
    config = ''
      ip route 198.51.100.0/24 reject
      ipv6 route 3fff::/48 reject

      router bgp 4200000000
        bgp router-id 198.51.100.1
        bgp log-neighbor-changes
        no bgp default ipv4-unicast

        neighbor 192.0.2.5 remote-as 64999
        neighbor 2001:db8::5 remote-as 64999

        neighbor 192.0.2.100 remote-as 65000
        neighbor 2001:db8::100 remote-as 65000

        address-family ipv4 unicast
          network 198.51.100.0/24

          neighbor 192.0.2.5 activate
          neighbor 192.0.2.5 remove-private-AS
          neighbor 192.0.2.5 soft-reconfiguration inbound
          neighbor 192.0.2.5 route-map self-ixp out
          neighbor 192.0.2.5 route-map ixp-self in

          neighbor 192.0.2.100 activate
          neighbor 192.0.2.100 remove-private-AS
          neighbor 192.0.2.100 soft-reconfiguration inbound
          neighbor 192.0.2.100 route-map self-transit out
          neighbor 192.0.2.100 route-map transit-self in
        exit-address-family

        address-family ipv6 unicast
          network 3fff::/48

          neighbor 2001:db8::5 activate
          neighbor 2001:db8::5 remove-private-AS
          neighbor 2001:db8::5 soft-reconfiguration inbound
          neighbor 2001:db8::5 route-map self-ixp out
          neighbor 2001:db8::5 route-map ixp-self in

          neighbor 2001:db8::100 activate
          neighbor 2001:db8::100 remove-private-AS
          neighbor 2001:db8::100 soft-reconfiguration inbound
          neighbor 2001:db8::100 route-map self-transit out
          neighbor 2001:db8::100 route-map transit-self in
        exit-address-family
      exit
    '';
  };
}
```
