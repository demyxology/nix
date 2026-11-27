# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  pkgs,
  config,
  ...
}:

let
  commonPkgs = import ./packages.nix { inherit pkgs; };
  # x11vnc mirroring the logged-in X display; clip = "" for the whole desktop,
  # or "xineramaN" for one monitor (N = X's monitor index, not desk position).
  mkVnc = port: clip: {
    description = "x11vnc - mirror ${
      if clip == "" then "all monitors" else clip
    } on port ${toString port}";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :0 ${
        if clip == "" then "" else "-clip ${clip} "
      }-forever -noxwarppointer -shared -rfbauth %h/.vnc/passwd -rfbport ${toString port}";
      Restart = "always";
      RestartSec = 3;
    };
  };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "ntsync" ];
    initrd.systemd.network.wait-online.enable = false; # faster boot w tailscale
    tmp = {
      cleanOnBoot = true;
      tmpfsHugeMemoryPages = "within_size";
      useTmpfs = true;
    };
  };

  fileSystems."/".options = [ "noatime" ];

  # squash force maps uids so i dont have to gaf, the two subnets are home & tailnet
  services.nfs.server = {
    enable = true;
    exports = ''
      /home/nikita    192.168.1.0/24(insecure,rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=100) 100.64.0.0/10(insecure,rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=100)
    '';
  };

  # TODO: get mountable 9p server working
  # services.diod = {
  #   enable = true;
  #   exports = [ "/home/nikita/" ];
  # };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";
        #"use sendfile" = "yes";
        #"max protocol" = "smb2";
        # LAN, tailnet (v4 + v6), loopback
        "hosts allow" = "192.168.1.0/24 100.64.0.0/10 fd7a:115c:a1e0::/48 127.0.0.1 ::1";
        "hosts deny" = "0.0.0.0/0 ::/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      # "public" = {
      #   "path" = "/mnt/Shares/Public";
      #   "browseable" = "yes";
      #   "read only" = "no";
      #   "guest ok" = "yes";
      #   "create mask" = "0644";
      #   "directory mask" = "0755";
      #   "force user" = "username";
      #   "force group" = "groupname";
      # };
      "private" = {
        "path" = "/home/nikita";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "nikita";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.udev.extraRules = ''
    KERNEL=="ntsync", MODE="0660", GROUP="ntsync"
  '';
  #SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", MODE="0666"
  #  '';

  # powerManagement.cpuFreqGovernor = "performance";

  # The main HDMI monitor drops hotplug when it goes into standby, which makes X
  # remove it, re-layout and wake the other screens. Pin it as connected.
  hardware.display = {
    edid.packages = [
      (pkgs.runCommand "main-hdmi-edid" { } ''
        mkdir -p $out/lib/firmware/edid
        cp ${./edid/main-hdmi.bin} $out/lib/firmware/edid/main-hdmi.bin
      '')
    ];
    outputs."HDMI-A-1" = {
      edid = "main-hdmi.bin";
      mode = "e";
    };
  };

  networking = {
    hostName = "nixos";
    nftables.enable = true;
    firewall = {
      enable = true;
      trustedInterfaces = [ config.services.tailscale.interfaceName ];
      allowedTCPPorts = [
        2049
        5900
        5901
        5902
        5903
      ];
      allowedUDPPorts = [
        config.services.tailscale.port
        8376
      ];
    };
  };

  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  systemd.network.wait-online.enable = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.cinnamon = {
      enable = true;
    };
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/cinnamon/desktop/input-sources" = {
          xkb-options = [ "ctrl:nocaps" ];
        };
      };
    }
  ];

  systemd.user.services.xcape = {
    description = "xcape - Caps Lock as Escape when tapped";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "forking";
      ExecStart = "${pkgs.xcape}/bin/xcape -e 'Control_L=Escape' -t 100";
      Restart = "always";
      RestartSec = 3;
    };
  };

  # VNC (password in ~/.vnc/passwd): 5900 = all monitors, 5901-5903 = left/middle/right.
  systemd.user.services.x11vnc = mkVnc 5900 "";
  systemd.user.services.x11vnc-left = mkVnc 5901 "xinerama1"; # DP-1
  systemd.user.services.x11vnc-middle = mkVnc 5902 "xinerama0"; # HDMI-1 (main)
  systemd.user.services.x11vnc-right = mkVnc 5903 "xinerama2"; # HDMI-1-2

  services.cinnamon.apps.enable = true;

  services.xrdp = {
    enable = true;
    # own session bus, so it doesn't clash with a local Cinnamon login
    defaultWindowManager = "${pkgs.dbus}/bin/dbus-run-session -- cinnamon-session";
    openFirewall = true;
  };

  # programs.hyprland = {
  #   enable = true;
  #   withUWSM = true; # recommended for most users
  #   xwayland.enable = true; # Xwayland can be disabled.
  # };

  # Enable the gnome-keyring secrets vault.
  # Will be exposed through DBus to programs willing to store secrets.
  services.gnome.gnome-keyring.enable = true;

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.amdgpu = {
    overdrive.enable = true;
    initrd.enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  services.blueman.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nikita = {
    isNormalUser = true;
    description = "Nikita";
    extraGroups = [
      "networkmanager"
      "wheel"
      "ntsync"
      "samba"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      #  thunderbird
    ];
  };
  users.groups.ntsync = { };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = commonPkgs.commonPackages ++ commonPkgs.nixosPackages;
    variables = {
      TERMINAL = "ghostty";
    };
    shellAliases = {
      update = "nix flake update --flake ~/nix/.; sudo nixos-rebuild switch --flake ~/nix/.";
      gridup = "rlwrap ~/9pro/9gc nikita";
    };
  };

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts-color-emoji
      open-sans
    ];
  };

  programs.steam.enable = true;
  programs.mosh.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libglvnd # libEGL, libGLESv2
      vulkan-loader
      wayland
      libxcb
      libxkbcommon
      pipewire
      libpulseaudio
      pam
      webkitgtk_4_1 # web page blocks
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.emacs = {
    package = commonPkgs.withGrammars pkgs.emacs-gtk;
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      AllowUsers = [ "nikita" ];
      PermitRootLogin = "no";
      X11Forwarding = true;
    };
  };

  documentation.man = {
    cache = {
      enable = true;
      generateAtRuntime = true;
    };

  };

  services.fail2ban.enable = true;

  services.flatpak.enable = true;

  # enabled just for kvm support
  virtualisation.virtualbox.host = {
    enable = false;
    enableKvm = true;
    addNetworkInterface = false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
