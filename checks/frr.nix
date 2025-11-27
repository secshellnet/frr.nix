{
  self,
  lib,
  pkgs,
  ...
}:

pkgs.testers.nixosTest {
  name = "frr";

  nodes.machine = {
    imports = [
      self.nixosModules.default
    ];
    services.frr = {
      bgpd.enable = true;
      settings = {
        access-list = {
          ip.upstreams."10".permit.value = "192.0.2.1";
          ipv6.upstreams-6."10".permit.value = "2001:db8::1";
          bgp_as-path.bogon-asns = {
            "10".permit = {
              comments = [
                "a list of ASNs that should not appear in the default free zone"
                "e. g. transition, documentation and private asn"
              ];
              value = "23456";
            };
            "11".permit.value = "64496-131071";
            "12".permit.value = "4200000000-4294967295";
          };
        };
        prefix-list.ipv6 = {
          own-6 = {
            "10".permit = {
              prefix = "2001:db8::/48";
              le = 128;
            };
            "11".permit = {
              prefix = "3fff::/40";
              ge = 44;
              le = 48;
            };
          };
          default-route-6."10".permit.prefix = "::/0";
          too-small-6."10".permit = {
            comments = "/48 is minimum for ipv6 on dfz";
            prefix = "::/0";
            ge = 49;
          };
        };
        route-maps = {
          export = {
            permit."10".match = "ipv6 address prefix-list own-6";
            deny."100".comments = ''
              do not advertise other prefixes
              the peer should not accept them anyway
            '';
          };
          import = {
            deny = {
              "5".match = [
                "as-path own-asns"
                "ipv6 address prefix-list own-6"
              ];
              "10".match = "as-path bogon-asns";
              "11".match = "as-path own-asns";
              "20".match = "ipv6 address prefix-list own-6";
              "21".match = "ipv6 address prefix-list default-route-6";
              "22".match = "ipv6 address prefix-list too-small-6";
              "30" = {
                match = "as-path bogon-asns";
                set = "rpki invalid";
              };
            };
            permit = {
              "31" = {
                match = "rpki notfound";
                set = "local-preference 50";
              };
              "32" = {
                match = "rpki valid";
                set = "local-preference 150";
              };
              "100" = { };
            };
          };
        };
      };
      config = ''
        ! additional static configuration
      '';
    };
  };

  testScript = /* python */ ''
    start_all()

    machine.wait_for_unit("frr.service")
    print(machine.succeed("vtysh -c 'show run'"))
    # TODO validate
    machine.succeed("vtysh -c 'show ipv6 prefix-list own-6 json' | ${lib.getExe pkgs.jq}")
    machine.succeed("vtysh -c 'show route-map import json' | ${lib.getExe pkgs.jq}")
    machine.succeed("vtysh -c 'show route-map export json' | ${lib.getExe pkgs.jq}")
  '';
}
