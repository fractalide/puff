{ lib, pkgs, config, ... }:
with lib;
let
  pkg-puff = import ./nix/default.nix {};
  cfg = config.services.puff;
in {
  options = {
    services.puff = {
      enable = mkEnableOption "puff service";

      package = mkOption {
        type = types.package;
        default = pkg-puff;
        description = ''
          The package that contains puff's sources. Can be overriden.
        '';
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1:8080";
        description = ''
          The host and port to run on
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.puff = {
      after = [ "network.target" ];
      description = "Puff";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        PermissionsStartOnly = true;
        ExecStart = "${cfg.package}/bin/puff ${cfg.host} ${cfg.package}/static";
        DynamicUser = true;
      };
    };

  };
}
