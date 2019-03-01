{ config, pkgs, ... }:

with builtins;

let
  epson-escpr2 = pkgs.callPackage /home/sean/devel/epson-escpr2 {};

in {
  system.stateVersion = "18.03";

  imports = [
    /etc/nixos/hardware-configuration.nix
    /home/sean/devel/homepage
    /home/sean/devel/hymnal
  ];

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    pulseaudio = {
      enable = true;
      support32Bit = true;
      package = pkgs.pulseaudioFull;
      tcp.enable = true;
    };
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    plymouth.enable = true;
    kernelParams = [ "quiet" "iommu=soft" "splash" ];
    kernelModules = [ "coretemp" "thermal" "it87" ];
    blacklistedKernelModules = [ "k10temp" "fam15h_power" ];
  };

  environment = {
    variables = { "NIX_AUTO_RUN" = "y"; };
    systemPackages = with pkgs; [ sc-controller ];
  };

  networking = {
    hostName = "akita";

    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp5s0";
    };

    firewall.enable = false;
  };

  services = {
    geoclue2.enable = true;
    upower.enable = true;
    xrdp.enable = true;

    printing = {
      enable = true;
      drivers = with pkgs; [ epson-escpr2 ];
    };

    xserver = {
      enable = true;
      windowManager.awesome.enable = true;
      displayManager.slim.enable = true;
      videoDrivers = [ "nvidia" ];
      xkbOptions = "ctrl:nocaps";
    };

    avahi = {
      enable = true;
      nssmdns = true;
      reflector = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };

    openssh = {
      enable = true;
      forwardX11 = true;
    };
  };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    zsh.enable = true;
  };

  containers = {
    blizzard = {
      config = import (fetchGit {
        url = "https://github.com/furrycatherder/blizzard";
        ref = "master";
      });

      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.8.1";
      localAddress = "192.168.8.2";
    };
  };

  fonts = let
    greentea = pkgs.callPackage (fetchGit {
      url = "https://github.com/furrycatherder/greentea";
      ref = "master";
    }) {};
  in {
    fontconfig.enable = true;
    enableDefaultFonts = true;
    fonts = with pkgs; [
      siji
      hack-font
      noto-fonts noto-fonts-cjk noto-fonts-emoji
      powerline-fonts
      ubuntu_font_family
      unifont unifont_upper
      wqy_microhei wqy_zenhei
      greentea
    ];
  };

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleUseXkbConfig = true;
    glibcLocales = pkgs.glibcLocales;
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [ mozc ];
    };
  };

  nix = {
    gc.automatic = true;
    optimise.automatic = true;

    useSandbox = true;
    trustedUsers = [ "root" "sean" ];
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      chromium.enableWideVine = true;
    };

    overlays =
      let 
        bento = import (fetchGit {
          url = "https://github.com/furrycatherder/bento";
          ref = "master";
        }) {};

      in bento.overlays;
  };

  users = {
    users.sean = with pkgs; {
      uid = 1000;
      shell = zsh;
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" ];
      packages = map optimizePackage [ steam dolphinEmu ];
    };
  };

  time.timeZone = "US/Central";
  sound.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  security.sudo.wheelNeedsPassword = false;
}
