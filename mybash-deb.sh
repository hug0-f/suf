#!/bin/bash

set -euo pipefail

# ============================================================
# Global variables
# ============================================================
ARCH="$(uname -m)"

export DEV_HOME="$HOME/.dev"
export XDG_CACHE_HOME="$DEV_HOME/cache"
export XDG_CONFIG_HOME="$DEV_HOME/config"
export XDG_DATA_HOME="$DEV_HOME/share"

# Keep sudo alive
sudo -v

# ============================================================
# Create base XDG directory layout
# ============================================================
mkdir -p \
  "$XDG_CACHE_HOME" \
  "$XDG_CONFIG_HOME" \
  "$XDG_DATA_HOME"

mkdir -p \
  "$XDG_CACHE_HOME"/{zsh,npm,pip,python,docker} \
  "$XDG_CONFIG_HOME"/{zsh,npm,docker,fastfetch} \
  "$XDG_DATA_HOME"/{zsh,cargo,rustup,go,fonts,gnupg}

# ============================================================
# System update
# ============================================================
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove --purge -y

# ============================================================
# Install base packages
# ============================================================
APT_PACKAGES=(
  curl git vim zsh wget unzip ca-certificates
  build-essential autojump net-tools dnsutils ufw
  vivid python3-pygments command-not-found fastfetch
)

sudo apt install -y "${APT_PACKAGES[@]}"

# ============================================================
# LS_COLORS generation (XDG compliant)
# ============================================================
if command -v vivid >/dev/null 2>&1; then
  vivid generate one-dark > "$XDG_CONFIG_HOME/ls_colors"
fi

# ============================================================
# Clone single-use files repository
# ============================================================
SUF_DIR="$HOME/suf"

rm -rf "$SUF_DIR"

if [ -d "$SUF_DIR/.git" ]; then
  git -C "$SUF_DIR" fetch --all
  git -C "$SUF_DIR" reset --hard origin/master
else
  rm -rf "$SUF_DIR"
  git clone https://github.com/hug0-f/suf.git "$SUF_DIR"
fi

# ============================================================
# Docker installation (if missing)
# ============================================================
if ! command -v docker >/dev/null 2>&1; then
  DOCKER_TMP="$HOME/docker-install"
  rm -rf "$DOCKER_TMP"
  git clone https://github.com/hug0-f/docker-install.git "$DOCKER_TMP"

  if [ -f "$DOCKER_TMP/install-docker.sh" ]; then
    chmod +x "$DOCKER_TMP/install-docker.sh"
    "$DOCKER_TMP/install-docker.sh"
  fi

  rm -rf "$DOCKER_TMP"
fi

# ============================================================
# Install lsdu
# ============================================================
if [[ "$ARCH" == "x86_64" ]]; then
  sudo apt install -y "$SUF_DIR/lsdu_latest_amd64.deb"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "armv7l" ]]; then
  sudo apt install -y "$SUF_DIR/lsdu_latest_arm64.deb"
fi

# ============================================================
# Install helper
# ============================================================
if [[ "$ARCH" == "x86_64" ]]; then
  sudo apt install -y "$SUF_DIR/helper_latest_amd64.deb"
fi

# ============================================================
# Vim configuration 
# ============================================================
VIM_RUNTIME="$HOME/.vim_runtime"

if [ -d "$VIM_RUNTIME/.git" ]; then
  git -C "$VIM_RUNTIME" fetch --all
  git -C "$VIM_RUNTIME" reset --hard origin/main
else
  rm -rf "$VIM_RUNTIME"
  git clone --depth=1 https://github.com/amix/vimrc.git "$VIM_RUNTIME"
fi

VIMRC_TARGET="$HOME/.vimrc"
if [ -f "$VIMRC_TARGET" ] || [ -L "$VIMRC_TARGET" ]; then
    rm -f "$VIMRC_TARGET"
fi

ln -s "$VIM_RUNTIME/vimrc" "$VIMRC_TARGET"
sh "$VIM_RUNTIME/install_awesome_vimrc.sh"

# ============================================================
# Oh My Zsh installation
# ============================================================
OH_MY_ZSH_DIR="$DEV_HOME/oh-my-zsh"

if [ ! -d "$OH_MY_ZSH_DIR" ]; then
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  if [ -d "$HOME/.oh-my-zsh" ]; then
    rsync -a "$HOME/.oh-my-zsh/" "$OH_MY_ZSH_DIR/"
    rm -rf "$HOME/.oh-my-zsh"
  fi
else
  if command -v omz >/dev/null 2>&1; then
    omz update || true
  fi
fi

ZSH_CUSTOM="$OH_MY_ZSH_DIR/custom"

# ============================================================
# Powerlevel10k theme
# ============================================================
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [ -d "$P10K_DIR/.git" ]; then
  git -C "$P10K_DIR" fetch --all
  git -C "$P10K_DIR" reset --hard origin/master
else
  rm -rf "$P10K_DIR"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# ============================================================
# Zsh plugins
# ============================================================
for repo in \
  zsh-users/zsh-autosuggestions \
  zsh-users/zsh-syntax-highlighting
do
  name="${repo##*/}"
  target="$ZSH_CUSTOM/plugins/$name"

  if [ -d "$target/.git" ]; then
    git -C "$target" fetch --all
    git -C "$target" reset --hard origin/master
  else
    rm -rf "$target"
    git clone "https://github.com/$repo.git" "$target"
  fi
done

# ============================================================
# Fonts (Powerlevel10k)
# ============================================================
FONT_DIR="$XDG_DATA_HOME/fonts"
mkdir -p "$FONT_DIR"

for font in Regular Bold Italic "Bold Italic"; do
  curl -fsSL -o "$FONT_DIR/MesloLGS NF $font.ttf" \
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20${font// /%20}.ttf"
done

command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$FONT_DIR" || true

# ============================================================
# fastfetch configuration
# ============================================================
if [ ! -f "$XDG_CONFIG_HOME/fastfetch/config.jsonc" ]; then
  fastfetch --gen-config
fi

cp "$SUF_DIR/fastfetch.config.jsonc" \
   "$XDG_CONFIG_HOME/fastfetch/config.jsonc"

rm -rf "$HOME/fastfetch"

# ============================================================
# Zsh configuration (FORCED, source of truth = SUF)
# ============================================================
cp "$SUF_DIR/zshrc" "$HOME/.zshrc"

# ============================================================
# Powerlevel10k configuration
# ============================================================
if command -v Xorg >/dev/null 2>&1 || command -v Xwayland >/dev/null 2>&1; then
  cp "$SUF_DIR/p10k.zsh" "$HOME/.p10k.zsh"
else
  cp "$SUF_DIR/p10k.zsh.noGUI" "$HOME/.p10k.zsh"
fi

# ============================================================
# Cleanup legacy files and directories
# ============================================================
rm -rf \
  "$HOME/.oh-my-zsh" \
  "$HOME/.vim_runtime" \
  "$HOME/.vim" \
  "$HOME/.cache/zsh" \
  "$HOME/.zcompdump"* \
  "$HOME/.npmrc" \
  "$HOME/.docker"

# ============================================================
# Remove SUF repository
# ============================================================
rm -rf "$SUF_DIR"

# ============================================================
# Set default shell
# ============================================================
TARGET_SHELL="$(command -v zsh)"
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 || true)"

if [ -n "$TARGET_SHELL" ] && [ "$CURRENT_SHELL" != "$TARGET_SHELL" ]; then
  chsh -s "$TARGET_SHELL" || true
fi

# ============================================================
# End
# ============================================================
echo ""
echo "Install complete. Reboot recommended."
