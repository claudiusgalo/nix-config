#Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  
  nix.settings.trusted-users = [ "root" "claudius" ];
  
  #------- Start of Ollama Configuration ---------
  # One systemd unit, always running
  services.ollama = {
    enable       = true;
    acceleration = "cuda";                                # use your RTX-3060 :contentReference[oaicite:1]{index=1}
    loadModels   = [ "llama3:8b" "mistral:7b-instruct" ]; # pre-pull once :contentReference[oaicite:2]{index=2}

    # Example resource limits (tweak to taste)
    environmentVariables = {
      OLLAMA_KEEP_ALIVE        = "-1";   # never evict from VRAM
      OLLAMA_MAX_LOADED_MODELS = "1";    # only one model resident
    };
  };

  # Optional Web UI on :8080
  services.open-webui.enable = true;
  #------ End of Ollama Configuration ---------



 
  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };
  
  # Tweaks to download buffer and ram swap size for very large downloads such as cuda.
  swapDevices = [
    {
     device = "/swapfile";
     size = 32768; # Size in MB (this is 32 GB)
    }
  ];
  nix.settings.download-buffer-size = 4294967296; #4GB 
 
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia.modesetting.enable = true;
  hardware.graphics.enable = true;
 
  # Modesetting is required.
  # modesetting.enable = true;

  # ML Package Caches
    nix.settings = {
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

  #hardware.opengl.enable = true;
  hardware.cpu.amd.updateMicrocode = true;
  powerManagement.enable = true; 
  #services.tlp.enable = true;
  boot.blacklistedKernelModules = ["nouveau"];
  #Enable persistent logging to debug crashes or freeze issues
  services.journald.extraConfig = "Storage=persistent";
  #Periodically clean the system to reduce clutter
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false; # Avoid unexpected reboots
  hardware.nvidia = {

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = true;

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
    open = true;

    # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

 # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

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
   services.xserver.enable = true;
  # Remote Desktop
  # services.xrdp.enable = true;
  # services.xrdp.defaultWindowsManager = "gnome-session";

  # GNOME Desktop
   services.xserver.desktopManager.gnome.enable = true;
   services.xserver.displayManager.gdm.enable = true;
   services.gnome.gnome-remote-desktop.enable = true;

  # Enable RDP access
  # services.xrdp = {
  #  enable = true;
  #  defaultWindowManager = "gnome-session";
  #};
  

  # GNOME XRDP
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "${pkgs.gnome.gnome-session}/bin/gnome-session";
  services.xrdp.openFirewall = true;

  # Disable the GNOME3/GDM auto-suspend feature that cannot be disabled in GUI!
  # If no user is logged in, the machine will power down after 20 minutes.
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Open the RDP port in firewall
  networking.firewall.allowedTCPPorts = [ 3389 8080 ];

  # Optional: advertise hostname on LAN
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish.enable = true;
    publish.addresses = true;
  };
  
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
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
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.claudius = {
    isNormalUser = true;
    description = "Claudius";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  
  # Unfree package installation.
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
	# Required for nvidia driver
	"nvidia-x11"
	"nvidia-settings"
	# Required for machine learning projects
	"cuda_cudart"
	"libcublas"
	"cuda_cccl"
	"cuda_nvcc"
  ];
  
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
   (vim_configurable.customize {
      name = "vim-full-with-plugins";
      vimrcConfig = {
        packages.myVimPackage = with pkgs.vimPlugins; {
          start = [ nerdtree vim-airline ];
       };
       customRC = ''
        set clipboard=unnamedplus
        set number
        syntax on
        filetype plugin indent on
        let g:airline#extensions#tabline#enabled = 1
      '';
     };
    })
    #Python and ML stack 
    python3
    python3Packages.pip
    python3Packages.numpy
    python3Packages.scipy
    python3Packages.matplotlib
    python3Packages.pandas
    python3Packages.jupyter
    python3Packages.pillow
    python3Packages.torch
    python3Packages.torchvision
    python3Packages.torchaudio
    python3Packages.scikit-learn
    python3Packages.tqdm
    python3Packages.h5py
    #Python and ML stack 3.11
    python311
    python311Packages.pip
    python311Packages.numpy
    python311Packages.scipy
    python311Packages.matplotlib
    python311Packages.pandas
    python311Packages.jupyter
    python311Packages.pillow
    python311Packages.torch       
    python311Packages.torchvision  
    python311Packages.torchaudio    
    python311Packages.scikit-learn
    python311Packages.tqdm
    python311Packages.h5py
    cudaPackages.cudatoolkit         
    # CUDA toolkit for GPU support
    cudaPackages.cudatoolkit
    # (Optional: C compilers and other tools)
    gcc
    # Other system packages
    zulu 	    # For ToS client.
    ollama
    tauon           # All-in-one music + podcasts
    newsboat        # For text-based news and podcast feeds
    mpv             # Audio player for feeds
    pciutils
    kitty
    musicpod
    vim
    neovim
    cloudflared
    ngrok
    wget
    discord-ptb
    vscode
    git
    R
    rstudio
    docker
    
  ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # services.openssh.settings.PasswordAuthentication = true;
  # services.openssh.settings.PermitRootLogin = "no";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ 8080 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
  } 
