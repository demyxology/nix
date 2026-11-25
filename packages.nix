{ pkgs, ... }:

let
  # Emacs with tree-sitter grammars for the built-in treesit.el.
  withGrammars =
    emacs:
    emacs.pkgs.withPackages (epkgs: [
      (epkgs.treesit-grammars.with-grammars (g: [
        g.tree-sitter-nix
        g.tree-sitter-c
        g.tree-sitter-cpp
      ]))
    ]);

  emacs = withGrammars pkgs.emacs;

  # macOS: CLI binaries only, so no standalone Emacs.app lands in /Applications/Nix Apps.
  emacsNoApp = pkgs.symlinkJoin {
    name = "emacs-no-app";
    paths = [ emacs ];
    postBuild = "rm -rf $out/Applications";
  };

  # Launcher: raise an existing GUI frame, or create one with -c.
  emacsLauncher = pkgs.writeShellScript "emacs-launcher" ''
    ec=${emacs}/bin/emacsclient
    # Lisp expression for the first GUI (ns) frame, if any.
    find='(seq-find (lambda (f) (eq (framep f) (quote ns))) (frame-list))'
    # No files given and a GUI frame exists: raise it instead of making a new one.
    if [ $# -eq 0 ] && [ "$($ec -e "(and $find t)")" = t ]; then
      exec $ec -n -e "(select-frame-set-input-focus $find)"
    fi
    exec $ec -c -n "$@"
  '';

  # Spotlight/Dock entry point: a stub app that opens a frame on the launchd daemon.
  emacsClientApp = pkgs.runCommand "emacs-client-app" { } ''
    app=$out/Applications/Emacs.app/Contents
    mkdir -p $app/MacOS $app/Resources
    cp ${pkgs.emacs}/Applications/Emacs.app/Contents/Resources/Emacs.icns $app/Resources/
    cp ${emacsLauncher} $app/MacOS/Emacs
    printf '<plist><dict><key>CFBundleExecutable</key><string>Emacs</string><key>CFBundleIdentifier</key><string>org.gnu.EmacsClient</string><key>CFBundleIconFile</key><string>Emacs</string></dict></plist>' > $app/Info.plist
  '';
in
{
  inherit withGrammars emacs;

  commonPackages = with pkgs; [
    alacritty
    antigravity-acp
    antigravity-cli
    antigravity-hub
    bat
    btop
    claude-code
    curl
    dict
    discord
    dust
    drawterm
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
    nh
    nix-output-monitor
    nixd
    nixfmt
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
    emacsNoApp
    emacsClientApp
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
    emacs
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
