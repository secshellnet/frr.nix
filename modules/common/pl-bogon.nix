{ lib, ... }:
{
  # This file defines prefix-lists for FRR that match special purpose and multicast networks
  services.frr.settings.prefix-list = {
    ip.special-purpose-4 = builtins.listToAttrs (
      lib.imap0
        (i: prefix: {
          name = "${toString (10 + i)}";
          value.permit = {
            inherit prefix;
            le = 128;
          };
        })
        [
          # https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml
          "0.0.0.0/8"
          "10.0.0.0/8"
          "100.64.0.0/10"
          "127.0.0.0/8"
          "169.254.0.0/16"
          "172.16.0.0/12"
          "192.0.0.0/24"
          "192.0.2.0/24"
          "192.88.99.2/32"
          "192.168.0.0/16"
          "198.18.0.0/15"
          "198.51.100.0/24"
          "203.0.113.0/24"
          "224.0.0.0/3"
        ]
    );

    ipv6.special-purpose-6 = builtins.listToAttrs (
      lib.imap0
        (i: prefix: {
          name = "${toString (10 + i)}";
          value.permit = {
            inherit prefix;
            le = 128;
          };
        })
        [
          # https://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xhtml
          "::/64"
          "64:ff9b:1::/48"
          "100:0:0:1::/64"
          "100::/64"
          "2001::/23"
          "2001:2::/48"
          "2001:db8::/32"
          "2002::/16"
          "3fff::/20"
          "5f00::/16"
          "fc00::/7"
          "fe80::/10"
          "ff00::/8"
        ]
    );
  };
}
