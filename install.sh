#!/bin/bash

set -e

sudo -v

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE='dotfiles.log'

brew_apps=(
  'fd'
  'lazygit'
  'lazydocker'
  'mise'
  'neovim'
  'ripgrep'
  'tmux'
  'wget'
  'xclip'
)

dotbot_install() {
  local CONFIG="install.conf.yaml"
  local DOTBOT_DIR="dotbot"
  local DOTBOT_BIN="bin/dotbot"

  cd "${BASEDIR}"
  git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
  git submodule update --init --recursive "${BASEDIR}"

  "${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" -d "${BASEDIR}" -c "${CONFIG}" "${@}"
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

tmux_config() {
  local TPM_PATH=$HOME/.tmux/plugins/tpm

  if [ ! -d $TPM_PATH ];then
    git clone https://github.com/tmux-plugins/tpm $TPM_PATH\
      && $TPM_PATH/bin/install_plugins
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

main() {
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

  brew install $(printf " %s" "${brew_apps[@]}")

  sudo chsh -s /bin/zsh $USER

  dotbot_install
  neovim_config
  tmux_config
  git_config
}

main | tee -a $LOGFILE