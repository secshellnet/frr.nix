{
  # This file defines prefix-lists for FRR that match routes too small to be included in the default free zone
  services.frr.settings.prefix-list = {
    ip.too-small-4."10".permit = {
      prefix = "0.0.0.0/0";
      ge = 25;
    };
    ipv6.too-small-6."10".permit = {
      prefix = "::/0";
      ge = 49;
    };
  };
}
