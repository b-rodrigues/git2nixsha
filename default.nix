let
 pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/194846768975b7ad2c4988bdb82572c00222c0d7.tar.gz") {};

 system_packages = builtins.attrValues {
  inherit (pkgs) R glibcLocalesUtf8 nix;
 };

 r_packages = builtins.attrValues {
  inherit (pkgs.rPackages) sys plumber curl;
 };

 rix = [
    (pkgs.rPackages.buildRPackage {
      name = "rix";
      src = pkgs.fetchgit {
        url = "https://github.com/ropensci/rix/";
        rev = "0d28163f217fa36ccf910ac9af0456838ca0e4b8";
        sha256 = "sha256-IpZSIyNub+U9vh1mqHiC3WxcmqoUadkblxdjLeTLmp4=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          codetools
          curl
          jsonlite
          sys;
      };
    })
  ];
in
  pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then  "${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";

    buildInputs = [ system_packages r_packages rix ];

  }
