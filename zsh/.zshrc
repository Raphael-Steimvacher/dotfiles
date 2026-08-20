# ==========================================================
# POWERLEVEL10K INSTANT PROMPT
# Deve permanecer próximo do início do arquivo
# ==========================================================

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==========================================================
# CONFIGURAÇÕES GERAIS
# ==========================================================

export ZSH="$HOME/.oh-my-zsh"

export EDITOR="vim"
export VISUAL="vim"

ZSH_THEME="powerlevel10k/powerlevel10k"

# ==========================================================
# PLUGINS
# ==========================================================

plugins=(
  git
  npm
  sudo
  command-not-found
  zsh-autosuggestions
  zsh-syntax-highlighting
  web-search
  copypath
  copyfile
  copybuffer
)

source "$ZSH/oh-my-zsh.sh"

# ==========================================================
# NODE.JS E NVM
# ==========================================================

export NVM_DIR="$HOME/.nvm"

[[ -s "$NVM_DIR/nvm.sh" ]] &&
  source "$NVM_DIR/nvm.sh"

[[ -s "$NVM_DIR/bash_completion" ]] &&
  source "$NVM_DIR/bash_completion"

# ==========================================================
# CONFIGURAÇÕES PESSOAIS
# ==========================================================

export ZSH_CONFIG_DIR="$HOME/.config/zsh"

[[ -r "$ZSH_CONFIG_DIR/functions.zsh" ]] &&
  source "$ZSH_CONFIG_DIR/functions.zsh"

[[ -r "$ZSH_CONFIG_DIR/aliases.zsh" ]] &&
  source "$ZSH_CONFIG_DIR/aliases.zsh"

# ==========================================================
# POWERLEVEL10K
# ==========================================================

[[ -r "$HOME/.p10k.zsh" ]] &&
  source "$HOME/.p10k.zsh"
