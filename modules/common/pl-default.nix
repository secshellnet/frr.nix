{
  # This file defines prefix-lists for FRR that match default routes
  services.frr.settings.prefix-list = {
    ip.default-route-4."10".permit.prefix = "0.0.0.0/0";
    ipv6.default-route-6."10".permit.prefix = "::/0";
  };
}
