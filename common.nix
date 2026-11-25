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
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "auto-allocate-uids"
        "ca-derivations"
        "cgroups"
        "flakes"
        "git-hashing"
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
