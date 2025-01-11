#!/bin/bash

set -e


BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE='dotfiles.log'

flatpak_apps=(
  'com.bitwarden.desktop'
  'com.discordapp.Discord'
  'com.mattjakeman.ExtensionManager'
  'io.github.zen_browser.zen'
  'md.obsidian.Obsidian'
  'org.libreoffice.LibreOffice'
  'org.qbittorrent.qBittorrent'
  'org.videolan.VLC'
)

pacman_apps=(
  'bat'
  'btop'
  'curl'
  'docker'
  'docker-compose'
  'eza'
  'fd'
  'fzf'
  'git'
  'github-cli'
  'lazygit'
  'man-db'
  'neovim'
  'nodejs'
  'noto-fonts'
  'noto-fonts-cjk'
  'noto-fonts-emoji'
  'npm'
  'openssh'
  'pacman-contrib'
  'python'
  'python-pip'
  'python-poetry'
  'python-pynvim'
  'plocate'
  'ripgrep'
  'tailscale'
  'tmux'
  'ttf-jetbrains-mono-nerd'
  'unzip'
  'uv'
  'xclip'
  'wget'
  'yazi'
  'zip'
  'zoxide'
  'zsh'
)

pacman_gui_apps=(
  'steam'
  'spotify-launcher'
  'ghostty'
  'vagrant'
  'virtualbox'
  'virtualbox-host-modules-arch'
  'zed'
)

yay_apps=(
  'lazydocker'
)

show_help() {
  echo 'install.sh'
  echo
  echo 'Usage ./install.sh [OPTS]'
  echo
  echo 'This script install the dotfiles in Arch linux'
  echo
  echo 'Options:'
  echo '  -h, --help  show Help me'
  echo '  -g, --gui   install GUI packages'
  echo
}

yay_install() {
  local YAYDIR=$BASEDIR/yay
  if ! command -v yay 1>/dev/null 2>&1; then
    git clone https://aur.archlinux.org/yay.git $YAYDIR\
      && cd $YAYDIR \
      && makepkg -si --noconfirm \
      && cd $BASEDIR \
      && rm -rf $YAYDIR
  fi
}

dotbot_install() {
  local CONFIG="install.conf.yaml"
  local DOTBOT_DIR="dotbot"
  local DOTBOT_BIN="bin/dotbot"

  cd "${BASEDIR}"
  git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
  git submodule update --init --recursive "${BASEDIR}"

  "${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" -d "${BASEDIR}" -c "${CONFIG}" "${@}"
}

config_pacman() {
  local PACMANCONF=/etc/pacman.conf

  sudo sed -i "s/^#Color$/Color/g" \
    $PACMANCONF
}

tmux_config() {
  local TPM_PATH=$HOME/.tmux/plugins/tpm

  if [ ! -d $TPM_PATH ];then
    git clone https://github.com/tmux-plugins/tpm $TPM_PATH\
      && $TPM_PATH/bin/install_plugins
  fi
}

neovim_config() {
  local NEOVIM_CONFIG_PATH=$HOME/.config/nvim

  if [ ! -d $NEOVIM_CONFIG_PATH ];then
    git clone https://github.com/pedrohenrick777/configs.nvim.git $NEOVIM_CONFIG_PATH
  fi

  if ! npm ls -g | grep -q neovim;then
    sudo npm install -g neovim
  fi
}

git_config() {
  if [ ! -f $HOME/.gitconfig ];then
    read -p "Nome do Usuário do GIT: " GIT_NOME
    read -p "E-mail do Usuário do GIT: " GIT_EMAIL

    git config --global user.name "${GIT_NOME}"
    git config --global user.email $GIT_EMAIL
    git config --global core.editor nvim
    git config --global init.defaultBranch main
    git config --global credential.helper store
  fi
}

profile_config() {
  local PROFILEPATH=/etc/profile.d

  sudo cp dotfiles/rootfs/custom-envs.sh $PROFILEPATH
}

mise_install() {
  echo "Mise já instalado -- pulando"
  if [ ! -f $HOME/.local/bin/mise ];then
    curl https://mise.run | sh
  fi
}

main() {
  yay_install

  sudo pacman -Sy
  sudo pacman -S --needed --noconfirm $(printf " %s" "${pacman_apps[@]}")
  yay -S --needed --noconfirm $(printf " %s" "${yay_apps[@]}")

  if [ -n "$INSTALL_GUI_PACKAGES" ];then
    echo "Installing GUI packages"
    sudo pacman -S --needed --noconfirm $(printf " %s" "${pacman_gui_apps[@]}")
    flatpak install -y $(printf " %s" "${flatpak_apps[@]}")
  fi

  sudo systemctl enable --now docker
  sudo usermod -aG docker $USER

  if ! lsmod | grep -q vboxdrv;then
      sudo modprobe vboxdrv
  fi

  sudo chsh -s /bin/zsh $USER
  sudo systemctl enable bluetooth.service
  sudo updatedb

  mise_install
  dotbot_install
  tmux_config
  neovim_config
  git_config
  profile_config
}

while [ -n "$1" ]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -g|--gui-packages)
      INSTALL_GUI_PACKAGES=true
      shift
      ;;
    *)
      echo "ERROR: invalid argument $1"
      show_help
      exit 1
  esac
done

sudo -v

main | tee -a $LOGFILE