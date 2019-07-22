{ lib, pkgs, config, ... }:
with lib;
let
  pkg-puff = import ./nix/default.nix {};
  cfg = config.services.puff;
  faucet-txt = pkgs.writeTextFile {
    name = "faucet.json";
    text = ''{"faucet_sk":"${cfg.faucet-sk}", "faucet_address":"${cfg.faucet-address}"}'';
  };
  jolt-deploy = pkgs.fetchFromGitHub {
    owner = "carbonideltd";
    repo = "jolt-deploy";
    rev = "495de70720cc1f0b5b0ea854042ffc97768774e3";
    sha256 = "00v119qysh3cin36hb4pr5kk9976wh37wvjjmbgwl0v4r85p4g05";
  };
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

      dataDir = mkOption {
        type = types.path;
        default = "/run/puff";
        description = ''
          path to files served
        '';
      };

      faucet-sk = mkOption {
        type = types.str;
        default = null;
        description = ''
          faucet's secret key, yes, this temporary is a dirty hack
        '';
      };

      faucet-address = mkOption {
        type = types.str;
        default = null;
        description = ''
          faucet's address
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.puff = {
      after = [ "network.target" ];
      description = "Puff";
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        mkdir -m 0755 -p ${cfg.dataDir}
        ln -sf ${jolt-deploy}/deploy ${cfg.dataDir}/jolt
        ln -sf ${cfg.package}/static/favicon.ico ${cfg.dataDir}/favicon.ico
        ln -sf ${faucet-txt} ${cfg.dataDir}/faucet.json
      '';
      postStop = ''
        rm -rf ${cfg.dataDir}
    '';
      serviceConfig = {
        Type = "simple";
        PermissionsStartOnly = true;
        RuntimeDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/puff ${cfg.host} ${cfg.dataDir}";
        DynamicUser = true;
      };
    };
  };
}
