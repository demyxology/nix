{ pkgs, ... }:

{

  fonts.packages = [
    (import ./berkeley-mono.nix { inherit pkgs; })
  ];

  programs = {
    zsh = {
      enable = true;
      enableCompletion = false; # enabled by home-manager
      enableBashCompletion = false;
      promptInit = ""; # overwritten by pure
    };

    tmux.enable = true;
  };

  nix = {
    package = pkgs.lixPackageSets.latest.lix;
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "auto-allocate-uids"
        "cgroups"
        "flakes"
        "nix-command"
      ];
    };

  };

  services.tailscale = {
    enable = true;
  };

  services.emacs.enable = true;

  nixpkgs.config = {
    allowUnfree = true;

    overlays = [
      (final: prev: {
        inherit (prev.lixPackageSets.stable)
          nixpkgs-review
          nix-eval-jobs
          nix-fast-build
          colmena
          ;
      })
    ];
  };

  environment = {
    shells = with pkgs; [ zsh ];
    etc."dict.conf".text = "server dict.org";
    pathsToLink = [ "/share/zsh" ];
  };

  documentation = {
    enable = true;
    doc.enable = true;
    info.enable = true;
    man.enable = true;
  };

}
