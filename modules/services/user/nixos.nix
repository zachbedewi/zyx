{ lib, config, pkgs, ... }:

let
  userConfig = config.services.user;
  
  # Helper functions for user management
  
  # Backend-specific package selection
  profilePackages = {
    git = [ pkgs.git pkgs.git-crypt ];
    rsync = [ pkgs.rsync ];
    cloud = [ pkgs.rclone pkgs.syncthing ];
  };

  workspacePackages = {
    hyprland = [ pkgs.hyprland pkgs.hyprpaper pkgs.hyprpicker ];
    sway = [ pkgs.sway pkgs.swayidle pkgs.swaylock ];
    i3 = [ pkgs.i3 pkgs.i3status pkgs.i3lock ];
    kde = [ pkgs.kdePackages.kwin ];
    gnome = [ pkgs.gnome.gnome-shell ];
  };

  shellPackages = {
    bash = [ pkgs.bash pkgs.bash-completion ];
    zsh = [ pkgs.zsh pkgs.zsh-completions pkgs.oh-my-zsh ];
    fish = [ pkgs.fish pkgs.fishPlugins.done pkgs.fishPlugins.fzf-fish ];
  };

  editorPackages = {
    vim = [ pkgs.vim pkgs.vimPlugins.vim-plug ];
    nvim = [ pkgs.neovim pkgs.vimPlugins.nvim-treesitter ];
    emacs = [ pkgs.emacs pkgs.emacsPackages.use-package ];
    vscode = [ pkgs.vscode pkgs.vscode-extensions.ms-vscode.cpptools ];
    nano = [ pkgs.nano ];
  };

  # Generate dotfile synchronization script
  mkDotfileSyncScript = backend: patterns: excludes: 
    let
      includeArgs = lib.concatMapStringsSep " " (p: "--include='${p}'") patterns;
      excludeArgs = lib.concatMapStringsSep " " (p: "--exclude='${p}'") excludes;
    in
    if backend == "git" then
      pkgs.writeShellScript "sync-dotfiles-git" ''
        set -euo pipefail
        
        DOTFILES_DIR="${userConfig.profiles.dotfiles.location}"
        REMOTE_URL="${userConfig.profiles.synchronization.remote.url or ""}"
        
        if [[ ! -d "$DOTFILES_DIR/.git" ]] && [[ -n "$REMOTE_URL" ]]; then
          ${pkgs.git}/bin/git clone "$REMOTE_URL" "$DOTFILES_DIR"
        fi
        
        if [[ -d "$DOTFILES_DIR/.git" ]]; then
          cd "$DOTFILES_DIR"
          ${pkgs.git}/bin/git add ${includeArgs}
          ${pkgs.git}/bin/git commit -m "Auto-sync dotfiles $(date)" || true
          if [[ -n "$REMOTE_URL" ]]; then
            ${pkgs.git}/bin/git push origin main || true
          fi
        fi
      ''
    else if backend == "rsync" then
      pkgs.writeShellScript "sync-dotfiles-rsync" ''
        set -euo pipefail
        
        SOURCE_DIR="${userConfig.profiles.dotfiles.location}"
        DEST_URL="${userConfig.profiles.synchronization.remote.url or ""}"
        
        if [[ -n "$DEST_URL" ]]; then
          ${pkgs.rsync}/bin/rsync -avz ${includeArgs} ${excludeArgs} \
            "$SOURCE_DIR/" "$DEST_URL/"
        fi
      ''
    else
      pkgs.writeShellScript "sync-dotfiles-noop" ''
        echo "No synchronization backend configured"
      '';

  # Generate workspace management script
  mkWorkspaceScript = backend:
    if backend == "hyprland" then
      pkgs.writeShellScript "manage-workspace-hyprland" ''
        set -euo pipefail
        
        WORKSPACE_DIR="$HOME/.local/share/workspaces"
        mkdir -p "$WORKSPACE_DIR"
        
        case "''${1:-save}" in
          save)
            ${pkgs.hyprland}/bin/hyprctl clients -j > "$WORKSPACE_DIR/windows.json"
            ${pkgs.hyprland}/bin/hyprctl workspaces -j > "$WORKSPACE_DIR/workspaces.json"
            echo "Workspace saved to $WORKSPACE_DIR"
            ;;
          restore)
            if [[ -f "$WORKSPACE_DIR/windows.json" ]]; then
              echo "Restoring workspace from $WORKSPACE_DIR"
              # Implementation would use hyprctl to restore window positions
              # This is a simplified version - real implementation would be more complex
              echo "Workspace restoration not fully implemented yet"
            else
              echo "No saved workspace found"
            fi
            ;;
          *)
            echo "Usage: $0 {save|restore}"
            exit 1
            ;;
        esac
      ''
    else if backend == "sway" then
      pkgs.writeShellScript "manage-workspace-sway" ''
        set -euo pipefail
        
        WORKSPACE_DIR="$HOME/.local/share/workspaces"
        mkdir -p "$WORKSPACE_DIR"
        
        case "''${1:-save}" in
          save)
            ${pkgs.sway}/bin/swaymsg -t get_tree > "$WORKSPACE_DIR/tree.json"
            ${pkgs.sway}/bin/swaymsg -t get_workspaces > "$WORKSPACE_DIR/workspaces.json"
            echo "Workspace saved to $WORKSPACE_DIR"
            ;;
          restore)
            if [[ -f "$WORKSPACE_DIR/tree.json" ]]; then
              echo "Restoring workspace from $WORKSPACE_DIR"
              echo "Workspace restoration not fully implemented yet"
            else
              echo "No saved workspace found"
            fi
            ;;
          *)
            echo "Usage: $0 {save|restore}"
            exit 1
            ;;
        esac
      ''
    else
      pkgs.writeShellScript "manage-workspace-noop" ''
        echo "No workspace backend configured"
      '';

  # Generate SSH key management script
  mkSSHKeyScript = keyTypes:
    pkgs.writeShellScript "manage-ssh-keys" ''
      set -euo pipefail
      
      SSH_DIR="$HOME/.ssh"
      mkdir -p "$SSH_DIR"
      chmod 700 "$SSH_DIR"
      
      # Generate keys if they don't exist
      ${lib.concatMapStringsSep "\n" (keyType: 
        let
          keyFile = if keyType == "ed25519" then "id_ed25519"
                   else if keyType == "rsa" then "id_rsa"
                   else if keyType == "ecdsa" then "id_ecdsa"
                   else "id_${keyType}";
          keyArgs = if keyType == "ed25519" then "-t ed25519 -a 100"
                   else if keyType == "rsa" then "-t rsa -b 4096"
                   else if keyType == "ecdsa" then "-t ecdsa -b 521"
                   else "-t ${keyType}";
        in ''
          if [[ ! -f "$SSH_DIR/${keyFile}" ]]; then
            echo "Generating ${keyType} SSH key..."
            ${pkgs.openssh}/bin/ssh-keygen ${keyArgs} \
              -f "$SSH_DIR/${keyFile}" \
              -C "$(whoami)@$(hostname)-${keyType}-$(date +%Y%m%d)" \
              -N ""
            chmod 600 "$SSH_DIR/${keyFile}"
            chmod 644 "$SSH_DIR/${keyFile}.pub"
            echo "Generated ${keyType} SSH key at $SSH_DIR/${keyFile}"
          fi
        ''
      ) keyTypes}
      
      # Update SSH config if needed
      if [[ ! -f "$SSH_DIR/config" ]]; then
        cat > "$SSH_DIR/config" << 'EOF'
      # Auto-generated SSH configuration
      Host *
        AddKeysToAgent yes
        UseKeychain yes
        IdentitiesOnly yes
        
      ${lib.concatMapStringsSep "\n" (keyType:
        let
          keyFile = if keyType == "ed25519" then "id_ed25519"
                   else if keyType == "rsa" then "id_rsa"
                   else if keyType == "ecdsa" then "id_ecdsa"
                   else "id_${keyType}";
        in "  IdentityFile ~/.ssh/${keyFile}"
      ) keyTypes}
      EOF
        chmod 600 "$SSH_DIR/config"
        echo "Created SSH config at $SSH_DIR/config"
      fi
    '';

  # Generate backup script
  mkBackupScript = 
    pkgs.writeShellScript "backup-user-config" ''
      set -euo pipefail
      
      BACKUP_DIR="${userConfig.backup.destination.local}"
      REMOTE_DEST="${userConfig.backup.destination.remote or ""}"
      TIMESTAMP=$(date +%Y%m%d_%H%M%S)
      BACKUP_NAME="user-config-$TIMESTAMP.tar"
      
      mkdir -p "$(dirname "$BACKUP_DIR")"
      
      # Create backup archive
      echo "Creating backup..."
      tar -cf "$BACKUP_DIR/$BACKUP_NAME" \
        --exclude-caches \
        --exclude='*.log' \
        --exclude='*.tmp' \
        --exclude='cache/*' \
        -C "$HOME" \
        ${lib.concatStringsSep " " userConfig.profiles.dotfiles.patterns}
      
      ${lib.optionalString userConfig.backup.compression ''
        echo "Compressing backup..."
        ${pkgs.gzip}/bin/gzip "$BACKUP_DIR/$BACKUP_NAME"
        BACKUP_NAME="$BACKUP_NAME.gz"
      ''}
      
      ${lib.optionalString userConfig.backup.encryption ''
        echo "Encrypting backup..."
        ${pkgs.age}/bin/age -r $(cat ~/.local/share/secrets/backup.key.pub) \
          -o "$BACKUP_DIR/$BACKUP_NAME.age" \
          "$BACKUP_DIR/$BACKUP_NAME"
        rm "$BACKUP_DIR/$BACKUP_NAME"
        BACKUP_NAME="$BACKUP_NAME.age"
      ''}
      
      echo "Backup created: $BACKUP_DIR/$BACKUP_NAME"
      
      # Upload to remote if configured
      if [[ -n "$REMOTE_DEST" ]]; then
        echo "Uploading backup to remote..."
        ${pkgs.rclone}/bin/rclone copy "$BACKUP_DIR/$BACKUP_NAME" "$REMOTE_DEST/"
      fi
      
      # Clean up old backups based on retention
      echo "Cleaning up old backups..."
      find "$BACKUP_DIR" -name "user-config-*.tar*" -mtime +${
        if lib.hasSuffix "d" userConfig.backup.retention 
        then lib.removeSuffix "d" userConfig.backup.retention
        else "30"
      } -delete || true
    '';

in {
  config = lib.mkIf (
    userConfig.enable && 
    config.platform.capabilities.supportsNixOS
  ) {
    
    # System packages for user management
    environment.systemPackages = lib.flatten [
      # Profile management packages
      (lib.optionals userConfig.profiles.enable (
        profilePackages.${userConfig.profiles.synchronization.backend} or []
      ))
      
      # Workspace management packages
      (lib.optionals userConfig.applications.workspace.enable (
        workspacePackages.${userConfig.applications.workspace.backend} or []
      ))
      
      # Shell packages
      (lib.optionals userConfig.experience.shell.enable (
        shellPackages.${userConfig.experience.shell.defaultShell} or []
      ))
      
      # Editor packages
      (lib.optionals userConfig.experience.editor.enable (
        editorPackages.${userConfig.experience.editor.defaultEditor} or []
      ))
      
      # Backup tools
      (lib.optionals userConfig.backup.enable [
        pkgs.tar pkgs.gzip pkgs.age pkgs.rclone
      ])
      
      # User management utilities
      [
        (pkgs.writeShellScriptBin "zyx-sync-dotfiles" ''
          exec ${mkDotfileSyncScript 
            userConfig.profiles.synchronization.backend 
            userConfig.profiles.dotfiles.patterns
            userConfig.profiles.dotfiles.excludePatterns}
        '')
        
        (pkgs.writeShellScriptBin "zyx-manage-workspace" ''
          exec ${mkWorkspaceScript userConfig.applications.workspace.backend} "$@"
        '')
        
        (lib.mkIf userConfig.security.sshKeys.enable
          (pkgs.writeShellScriptBin "zyx-setup-ssh-keys" ''
            exec ${mkSSHKeyScript userConfig.security.sshKeys.keyTypes}
          ''))
        
        (lib.mkIf userConfig.backup.enable
          (pkgs.writeShellScriptBin "zyx-backup-user-config" ''
            exec ${mkBackupScript}
          ''))
      ]
    ];

    # System services for user management
    systemd.user.services = lib.mkMerge [
      # Dotfile synchronization service
      (lib.mkIf userConfig.profiles.synchronization.enable {
        zyx-dotfile-sync = {
          description = "Sync user dotfiles";
          after = [ "network.target" ];
          wantedBy = [ "default.target" ];
          
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${mkDotfileSyncScript 
              userConfig.profiles.synchronization.backend 
              userConfig.profiles.dotfiles.patterns
              userConfig.profiles.dotfiles.excludePatterns}";
          };
        };
      })
      
      # Workspace management service
      (lib.mkIf userConfig.applications.workspace.enable {
        zyx-workspace-manager = {
          description = "Manage user workspace";
          after = [ "graphical-session.target" ];
          wantedBy = [ "default.target" ];
          
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = lib.mkIf userConfig.applications.workspace.restoreOnLogin
              "${mkWorkspaceScript userConfig.applications.workspace.backend} restore";
            ExecStop = lib.mkIf userConfig.applications.workspace.autoSave
              "${mkWorkspaceScript userConfig.applications.workspace.backend} save";
          };
        };
      })
      
      # SSH key management service
      (lib.mkIf userConfig.security.sshKeys.enable {
        zyx-ssh-key-setup = {
          description = "Setup SSH keys for user";
          wantedBy = [ "default.target" ];
          
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${mkSSHKeyScript userConfig.security.sshKeys.keyTypes}";
          };
        };
      })

      # Backup service
      (lib.mkIf userConfig.backup.automatic {
        zyx-user-backup = {
          description = "Backup user configuration";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${mkBackupScript}";
          };
        };
      })
    ];

    # Systemd timers for periodic tasks
    systemd.user.timers = lib.mkMerge [
      # Backup timer
      (lib.mkIf userConfig.backup.automatic {
        zyx-user-backup = {
          description = "Backup user configuration";
          wantedBy = [ "timers.target" ];
          
          timerConfig = {
            OnCalendar = userConfig.backup.interval;
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };
      })
      
      # SSH key rotation timer
      (lib.mkIf userConfig.security.sshKeys.rotation.enable {
        zyx-ssh-key-rotation = {
          description = "Rotate SSH keys";
          wantedBy = [ "timers.target" ];
          
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
            RandomizedDelaySec = "6h";
          };
        };
      })
    ];


    # Personal secrets integration
    services.secrets = lib.mkIf userConfig.security.personalSecrets.enable {
      userSecrets = {
        enable = true;
        location = userConfig.security.personalSecrets.location;
        categories = userConfig.security.personalSecrets.categories;
        backend = config.services.secrets.backend;
      };
    };

    # SSH configuration integration  
    services.openssh = lib.mkIf userConfig.security.sshKeys.enable {
      userKeyManagement = {
        enable = true;
        keyTypes = userConfig.security.sshKeys.keyTypes;
        autoGenerate = userConfig.security.sshKeys.autoGenerate;
        rotation = userConfig.security.sshKeys.rotation;
      };
    };

    # User groups and access control
    users.groups = lib.mkMerge [
      (lib.genAttrs userConfig.security.accessControl.groups (group: {}))
    ];

    # Theme integration with display service
    services.display = lib.mkIf userConfig.experience.theme.enable {
      theme = {
        style = userConfig.experience.theme.style;
        colorScheme = userConfig.experience.theme.colorScheme;
        fontFamily = userConfig.experience.theme.fontFamily;
      };
    };

    # Store implementation metadata for introspection
    services.user._implementation = {
      platform = "nixos";
      profileBackend = userConfig.profiles.synchronization.backend;
      workspaceBackend = userConfig.applications.workspace.backend;
      shellBackend = userConfig.experience.shell.defaultShell;
      editorBackend = userConfig.experience.editor.defaultEditor;
      backupEnabled = userConfig.backup.enable;
      securityIntegration = userConfig.security.enable;
      
      # Service status
      dotfileSyncEnabled = userConfig.profiles.synchronization.enable;
      workspaceManagementEnabled = userConfig.applications.workspace.enable;
      sshKeyManagementEnabled = userConfig.security.sshKeys.enable;
      personalSecretsEnabled = userConfig.security.personalSecrets.enable;
    };
  };
}