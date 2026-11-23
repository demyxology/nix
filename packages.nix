{ pkgs, ... }:

{
  commonPackages = with pkgs; [
    alacritty
    antigravity-acp
    antigravity-cli
    antigravity-hub
    bat
    btop
    claude-code
    dict
    discord
    dust
    drawterm
    emacs
    fd
    file
    findutils
    fish
    gcc
    git
    gnumake
    helix
    irssi
    kakoune
    kitty
    llvmPackages.libcxxClang
    llvmPackages.clang-tools
    neovide
    nixfmt
    nix-output-monitor
    nmap
    nodejs
    nushell
    omp
    pi-coding-agent
    plan9port
    pv
    qbittorrent
    qemu
    ripgrep
    rlwrap
    sshfs
    signal-desktop
    spotify
    tldr
    tlsclient
    tmux
    tree
    vim-full
    vscode
    wezterm
    wget
    xonsh
    zed-editor
  ];

  darwinPackages = with pkgs; [
    antigravity-ide
    appcleaner
    coreutils-prefixed
    ghostty-bin
    iterm2
    mosh
    tailscale
    utm
    vlc-bin
  ];

  nixosPackages = with pkgs; [
    # fails due to deprecated dependency on fuse2
    # _9pfs
    antigravity-ide-fhs
    ardour
    dolphin-emu
    emote
    firefox
    fuzzel
    ghostty
    gnome-system-monitor
    gnome-weather
    libreoffice
    mangohud
    pulseaudio
    pciutils
    protonup-qt
    obs-studio
    unzip
    vulkan-tools
    xcape
    xclip
    xsel
  ];
}
