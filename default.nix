let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/3fdde11f18b73cc579c841e21cea8f6a8513c65f.tar.gz") {};
 system_packages = builtins.attrValues {
  inherit (pkgs) R glibcLocalesUtf8 nix;
};
 r_packages = builtins.attrValues {
  inherit (pkgs.rPackages) sys plumber curl;
};
  in
  pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then  "${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";

    buildInputs = [ system_packages r_packages ];

  }