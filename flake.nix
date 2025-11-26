{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    search = {
      url = "github:NuschtOS/search";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      search,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      defaultSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      eachDefaultSystem = lib.genAttrs defaultSystems;
    in
    {
      nixosModules = rec {
        frr = ./modules;
        default = frr;
      };

      packages = eachDefaultSystem (system: {
        default = search.packages.${system}.mkSearch {
          modules = [
            self.nixosModules.default
          ];
          title = "Module Search of secshellnet/frr.nix";
          baseHref = "/frr.nix/";
          urlPrefix = "https://github.com/secshellnet/frr.nix/blob/main/";
        };
      });

      checks = eachDefaultSystem (
        system:
        let
          pkgs = (import nixpkgs) { inherit system; };
        in
        import ./checks { inherit self lib pkgs; }
      );
    };
}
