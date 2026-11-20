{ pkgs, ... }:

{
  fonts.packages = [
    (import ./berkeley-mono.nix { inherit pkgs; })
  ];

  programs = {
    zsh = {
      enable = true;
      enableBashCompletion = false;
    };

    tmux.enable = true;
    mosh.enable = true;
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

  };

  services.tailscale = {
    enable = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  environment = {
    variables = {
      EDITOR = "nvim";
    };
    shells = with pkgs; [ zsh ];
    etc."dict.conf".text = "server dict.org";
  };

  documentation = {
    enable = true;
    doc.enable = true;
    info.enable = true;
    man.enable = true;
  };

}
