#!/bin/bash

set -euo pipefail
ARCH=$(uname -m)

# --- Remove old configuration files ---
rm -f "$HOME/.vimrc" || true
rm -f "$HOME/.zshrc" || true
rm -rf "$HOME/.vim" "$HOME/.vim_runtime" "$HOME/.oh-my-zsh" || true

# --- Create XDG directories ---
mkdir -p "$HOME/.dev/cache" "$HOME/.dev/config" "$HOME/.dev/share" "$HOME/.cache"

# --- System update ---
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove --purge -y

# --- Install packages ---
APT_PACKAGES=(curl git vim zsh wget unzip ca-certificates build-essential autojump net-tools dnsutils ufw vivid python3-pygments command-not-found fastfetch)
sudo apt install -y "${APT_PACKAGES[@]}"

if command -v vivid >/dev/null 2>&1; then
  vivid generate one-dark > "$HOME/.ls_colors"
fi

# --- Add single-use file ---
SUF_DIR="$HOME/suf"
if [ -d "$SUF_DIR/.git" ]; then
  git -C "$SUF_DIR" pull --ff-only || true
else
  rm -rf "$SUF_DIR"
  git clone https://github.com/hug0-f/suf.git "$SUF_DIR"
fi

# --- Install Docker ---
DOCKER_DIR="$HOME/docker"

if command -v docker >/dev/null 2>&1; then
  echo "Docker already installed ($(docker --version))..."
else
  DOCKER_DIR="$HOME/docker"

  if [ -d "$DOCKER_DIR/.git" ]; then
    git -C "$DOCKER_DIR" pull --ff-only || true
  else
    rm -rf "$DOCKER_DIR"
    git clone https://github.com/hug0-f/docker-install.git "$DOCKER_DIR"
  fi

  if [ -f "$DOCKER_DIR/install-docker.sh" ]; then
    chmod +x "$DOCKER_DIR/install-docker.sh"
    "$DOCKER_DIR/install-docker.sh"
  else
    echo "install-docker.sh not found, skipping Docker installation..."
  fi

  rm -rf "$DOCKER_DIR"
fi

# --- Install lsdu ---
if [[ "$ARCH" == "x86_64" ]]; then
    sudo apt install -y "$SUF_DIR/lsdu_latest_amd64.deb"
elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "armv7l" ]]; then
    sudo apt install -y "$SUF_DIR/lsdu_latest_arm64.deb"
else
    echo "No version found for: $ARCH"
fi

# --- Install helper ---
if [[ "$ARCH" == "x86_64" ]]; then
    sudo apt install -y "$SUF_DIR/helper_latest_amd64.deb"
else
    echo "No version found for : $ARCH"
fi

# --- Install Vim ---
if [ -d "$HOME/.vim_runtime/.git" ]; then
  git -C "$HOME/.vim_runtime" pull --ff-only || true
else
  rm -rf "$HOME/.vim_runtime"
  git clone --depth=1 https://github.com/amix/vimrc.git "$HOME/.vim_runtime"
fi
sh "$HOME/.vim_runtime/install_awesome_vimrc.sh"

# --- Install Oh My Zsh ---
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh already installed, upgrade..."
    git -C "$OH_MY_ZSH_DIR" pull --ff-only || true
fi

# --- Install fonts and Powerlevel10k ---
FONTS_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR" || true

curl -fsSL -o "$FONTS_DIR/MesloLGS NF Regular.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
curl -fsSL -o "$FONTS_DIR/MesloLGS NF Bold.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
curl -fsSL -o "$FONTS_DIR/MesloLGS NF Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
curl -fsSL -o "$FONTS_DIR/MesloLGS NF Bold Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

if command -v fc-cache &>/dev/null; then
    fc-cache -f "$FONTS_DIR" || true
fi

# --- Install Powerlevel10k ---
POWERLEVEL10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -d "$POWERLEVEL10K_DIR" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$POWERLEVEL10K_DIR"
fi

# --- Install zsh-autosuggestions ---
ZSH_AUTOSUGGESTIONS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
if [ -d "$ZSH_AUTOSUGGESTIONS_DIR/.git" ]; then
    git -C "$ZSH_AUTOSUGGESTIONS_DIR" pull --ff-only || true
else
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"
fi

# --- Install zsh-syntax-highlighting ---
ZSH_SYNTAX_HIGHLIGHTING_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
if [ -d "$ZSH_SYNTAX_HIGHLIGHTING_DIR/.git" ]; then
    git -C "$ZSH_SYNTAX_HIGHLIGHTING_DIR" pull --ff-only || true
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_HIGHLIGHTING_DIR"
fi

# --- Check if a GUI is installed ---
is_gui_installed() {
    if command -v Xorg &>/dev/null || command -v Xwayland &>/dev/null || command -v gnome-session &>/dev/null || command -v startkde &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# --- Configure fastfetch ---
fastfetch --gen-config
cp "$SUF_DIR/fastfetch.config.jsonc" "$HOME/.dev/config/fastfetch/config.jsonc"

# --- Configure zsh ---
cp "$SUF_DIR/zshrc" "$HOME/.zshrc"

# --- Configure p10k ---
if is_gui_installed; then
    cp "$SUF_DIR/p10k.zsh" "$HOME/.p10k.zsh"
else
    cp "$SUF_DIR/p10k.zsh.noGUI" "$HOME/.p10k.zsh"
fi

# --- Remove suf repo ---
rm -rf "$SUF_DIR"

# --- Change the default shell ---
TARGET_SHELL="$(command -v zsh)"
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 || echo "")"
if [ -n "$TARGET_SHELL" ] && [ "$CURRENT_SHELL" != "$TARGET_SHELL" ]; then
    echo "Configuring the default shell using zsh..."
    chsh -s "$TARGET_SHELL" || echo "Failure, script continue..."
fi

# --- End ---
rm -rf mybash-deb.sh
echo ""
echo "Install complete, reboot asap..."
