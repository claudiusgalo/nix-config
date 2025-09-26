{ config, pkgs, lib, ... }: {

  imports = [ ./hardware-configuration.nix ];

  # Nix settings
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "nvidia-x11" "nvidia-settings" "cuda_cudart" "libcublas" "cuda_cccl" "cuda_nvcc"
  ];

  nix.settings = {
    trusted-users = [ "root" "claudius" ];
    experimental-features = [ "nix-command" "flakes" ];
    download-buffer-size = 4294967296;
    substituters = [
      "https://cache.nixos.org"
      "https://cuda-maintainers.cachix.org"
      "https://nixpkgs-python.cachix.org"
      "https://ai.cachix.org"
    ];
    trusted-public-keys = [
      "nvidia.cachix.org-1:U6c+LqF+Zd0dtGZk0FQlSENWREiRccB9vUZBK4UQ4yQ="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "nixpkgs-python.cachix.org-1:g+Ld5vqSJ6LFpmu0i3g9hxZMxZVZz47xPBiwEOGTrgA="
      "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
    ];
  };

  # Boot / Kernel
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.evdi ];
  boot.kernelModules = [ "evdi" ];

  # Time and locale
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
  };

  # Hostname + Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 3389 8080 ];

  # Display stack
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" "nomodeset" ];
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = false;

  # NVIDIA settings
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  hardware.graphics.enable = true;
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  # Audio
  # hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # RDP
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "${pkgs.gnome.gnome-session}/bin/gnome-session";
  services.xrdp.openFirewall = true;

  # Remote Access
  services.openssh.enable = true;

  # Avahi / mDNS
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish.enable = true;
    publish.addresses = true;
  };

  # Power and logging
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = true;
  services.journald.extraConfig = "Storage=persistent";
  systemd.defaultUnit = "graphical.target";

  # Auto upgrade
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;

  # Swap
  swapDevices = [{
    device = "/swapfile";
    size = 32768;
  }];

  # CPU microcode
  hardware.cpu.amd.updateMicrocode = true;

  # Web UI + Ollama
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    loadModels = [ "llama3:8b" "mistral:7b-instruct" ];
    environmentVariables = {
      OLLAMA_KEEP_ALIVE = "-1";
      OLLAMA_MAX_LOADED_MODELS = "1";
    };
  };
  services.open-webui.enable = true;

  # Printing
  services.printing.enable = true;

  # User
  users.users.claudius = {
    isNormalUser = true;
    description = "Claudius";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Installed packages
  environment.systemPackages = with pkgs; [
    # Editors and dev tools
    (vim_configurable.customize {
      name = "vim-full-with-plugins";
      vimrcConfig = {
        packages.myVimPackage = with pkgs.vimPlugins; { start = [ nerdtree vim-airline ]; };
        customRC = ''
          set clipboard=unnamedplus
          set number
          syntax on
          filetype plugin indent on
          let g:airline#extensions#tabline#enabled = 1
        '';
      };
    })
    vim neovim vscode kitty git wget pciutils gcc docker

    # CUDA + ML
    cudaPackages.cudatoolkit
    python3 python3Packages.pip python3Packages.numpy python3Packages.scipy
    python3Packages.matplotlib python3Packages.pandas python3Packages.jupyter
    python3Packages.pillow python3Packages.torch python3Packages.torchvision
    python3Packages.torchaudio python3Packages.scikit-learn python3Packages.tqdm
    python3Packages.h5py
    python311 python311Packages.pip python311Packages.numpy python311Packages.scipy
    python311Packages.matplotlib python311Packages.pandas python311Packages.jupyter
    python311Packages.pillow python311Packages.torch python311Packages.torchvision
    python311Packages.torchaudio python311Packages.scikit-learn python311Packages.tqdm
    python311Packages.h5py

    # Web + media
    firefox discord-ptb mpv newsboat tauon musicpod zulu
    cloudflared ngrok

    # R stack
    R rstudio
    
    neo4j-desktop

    # Misc
    ollama

    monero-gui 
    xmrig
  ];
  
  # Set up service for mining
  systemd.services.xmrig = {
     description = "XMRig miner";
     wantedBy = [ "multi-user.target" ];
     after = [ "network.target" ];

    serviceConfig = {
       ExecStart = "${pkgs.xmrig}/bin/xmrig --config /etc/xmrig/config.json";
       Restart = "always";
       RestartSec = "10s";
    };
  };

  # System version pin
  system.stateVersion = "24.11";
}

