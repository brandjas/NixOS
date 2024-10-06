{ config, pkgs, lib, ... }:

let
  machineOptions = import ./local-machine/options.nix;
  confidentialOptions = import ./local-machine/confidential-options.nix;
in

# Conditionally use GNOME or KDE Plasma. Raise an error if desktop is neither.
assert machineOptions.desktop == "gnome" || machineOptions.desktop == "kde";
let desktopManager = if machineOptions.desktop == "gnome" then "gnome" else "plasma6"; in
let displayManager = if machineOptions.desktop == "gnome" then "gdm" else "sddm"; in

{
  imports =
    [ # Include the results of the hardware scan.
      ./local-machine/hardware-configuration.nix
    ];

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = lib.mkIf machineOptions.nvidia ["nvidia"];

  hardware.nvidia = lib.mkIf machineOptions.nvidia {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
	  # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  networking.hostName = machineOptions.hostname;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_TIME = "nl_NL.UTF-8";
  };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Install window manager and desktop environment.
  services.xserver.displayManager.${displayManager}.enable = true;
  services.xserver.desktopManager.${desktopManager}.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.zsh.enable = true;
  virtualisation.docker = {
    enable = true;
    enableNvidia = machineOptions.nvidia;
  };

  hardware.nvidia-container-toolkit.enable = machineOptions.nvidia;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jasper = {
    isNormalUser = true;
    description = "Jasper Brandsma";
    extraGroups = [ "networkmanager" "wheel" "docker" "adbusers" "plugdev" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      anki
      bat
      btop
      dust
      firefox
      fzf
      htop
      mangohud
      nextcloud-client
      kitty
      rmtrash
      thefuck
      tldr
      tmux
      trash-cli
      usbutils
    ] ++ lib.optionals (machineOptions.desktop == "gnome") [
      gnome.gnome-software
    ] ++ lib.optionals machineOptions.nvidia [
      nvtop
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.steam.enable = true;
  programs.gamemode.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
  };

  services.flatpak.enable = true;

  services.syncthing = confidentialOptions.syncthingSettings;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    vim
    vscode.fhs
  ] ++ lib.optionals (machineOptions.desktop == "gnome") [
    gnomeExtensions.appindicator
  ];

  services.udev.packages = with pkgs; [
  ] ++ lib.optionals (machineOptions.desktop == "gnome") [
    gnome.gnome-settings-daemon
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
