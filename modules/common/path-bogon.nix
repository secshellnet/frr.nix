{
  # This file defines access-lists for FRR to match bogon (private, documentation) asns
  # since they should not appear in the default free zone (i.e., the full routing table).
  services.frr.settings.access-list.bgp_as-path.bogon-asns = {
    "10".permit.value = "23456";
    "11".permit.value = "64496-131071";
    "12".permit.value = "4200000000-4294967295";
  };
}
