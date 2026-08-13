# NixOS Configuration Agent Guide

This document provides essential information for agents working with this NixOS configuration repository.

## Project Overview

This is a NixOS system configuration repository that manages multiple NixOS hosts using flake-based deployment. The project uses:
- Nix flakes for configuration management
- Nixpkgs unstable and stable channels
- Flakes-parts for structured flake organization
- Disko for disk partitioning
- Agenix for secrets management
- Walker for application launching

## Directory Structure

```
/home/zandere/nixconfigs/
├── flake.nix              # Main flake configuration
├── modules/               # NixOS module definitions
│   ├── configuration.nix  # Common configuration for all hosts
│   ├── desktop.nix        # Desktop environment settings (Hyprland, Waybar)
│   ├── hosts/             # Host-specific configurations
│   │   ├── cloudNixos.nix  # Cloud server configuration
│   │   └── zanderNixos.nix # Personal laptop/desktop configuration
│   ├── git.nix            # Git configuration
│   ├── llama.nix          # Llama.cpp model serving
│   ├── mailserver.nix     # Mail server configuration
│   ├── nginx.nix          # Nginx reverse proxy
│   ├── tmux.nix           # Tmux configuration
│   └── zsh.nix            # Zsh configuration
├── secrets/               # Encrypted secrets directory
├── installer.nix          # Installation image configuration
└── *.nix                  # Disk partitioning configurations
```

## Key Components

### Host Configurations
- `cloudNixos`: Cloud server running NixOS with ZFS storage
- `zanderNixos`: Personal laptop/desktop with NVIDIA graphics

### NixOS Modules
- `commonNixosConfig`: Shared configuration for all hosts
- `desktop`: Desktop environment setup (Hyprland, Waybar, etc.)
- `configuration.nix`: Core system configuration
- `llama.nix`: Llama.cpp model serving
- `nginx.nix`: Reverse proxy configuration

## Essential Commands

### Building and Deploying
```bash
# Build the cloud configuration
nix build .#nixosConfigurations.cloudNixos.config.system.build.toplevel

# Deploy to cloud server
nixos-rebuild switch --flake .#cloudNixos

# Build the zanderNixos configuration
nix build .#nixosConfigurations.zanderNixos.config.system.build.toplevel

# Deploy to zander laptop
nixos-rebuild switch --flake .#zanderNixos
```

### Development Workflow
```bash
# Enter development shell with all necessary tools
nix develop

# Format Nix files
nix fmt

# Check for Nix syntax errors
nix check

# Build a specific host configuration
nix build .#nixosConfigurations.cloudNixos.config.system.build.toplevel
```

## Architecture and Design Patterns

### Flakes-based Organization
- Uses `flake-parts` for structured flake organization
- Modular approach with separate files for each component
- Host-specific configurations extend common base configurations

### Secrets Management
- Uses Agenix for encrypted secrets management
- Secrets are stored in `secrets/` directory as `.age` files
- Access to secrets requires proper SSH keys and age setup

### Disk Configuration
- Uses Disko for declarative disk partitioning
- ZFS filesystems on cloud server with automatic snapshots and scrubbing
- Multiple disk configurations (main_disk.nix, homedrive.nix, cloud_disk.nix)

## Key Conventions

### Naming
- Host configurations: `hostnameNixos` pattern (e.g., `cloudNixos`, `zanderNixos`)
- Module names: `nixosModules` prefix for NixOS modules
- Flakes output references: `flake.nixosConfigurations.*`

### File Structure
- All Nix files use standard Nix syntax with proper indentation
- Configuration modules follow the pattern of returning a function that takes inputs and returns configuration
- Host configurations are defined in their own files under `modules/hosts/`

## Gotchas and Non-obvious Patterns

1. **ZFS Setup**: The cloud server uses ZFS with automatic snapshots and scrubbing, but ZFS is not enabled by default (requires explicit enablement)

2. **Secrets Management**: Agenix requires proper age keys to decrypt secrets - without them, builds may fail

3. **NVIDIA Drivers**: The desktop configuration enables NVIDIA drivers with specific settings for power management

4. **Host-Specific Customizations**: Each host has its own unique packages and services (e.g., Steam on desktop, but not on cloud server)

5. **ZFS Pool Configuration**: ZFS pools are defined in `cloudDisks` module, requiring proper ZFS pool setup

6. **Build Dependencies**: Building requires Nix with flakes enabled and appropriate channels configured

7. **Disko Integration**: Uses Disko for declarative disk management - configuration files are imported into the system modules

## Testing and Validation

### Verify Configuration
```bash
# Check syntax of all Nix files
nix check

# Validate flake structure
nix flake check

# Build configuration to test for errors
nix build .#nixosConfigurations.cloudNixos.config.system.build.toplevel
```

## Important Notes

1. This repository is designed for specific hardware configurations (cloud server vs. personal laptop)
2. Secrets are encrypted and require proper key management
3. The system uses both stable and unstable Nixpkgs channels
4. ZFS is used on the cloud server with automatic maintenance features enabled
5. Both hosts use different desktop environments and software stacks due to hardware differences
6. The local machine where this repository is being developed is configured as `zanderNixos` (personal laptop/desktop)