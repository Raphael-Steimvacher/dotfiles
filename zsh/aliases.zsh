# ==========================================================
# ALIASES PESSOAIS
# ==========================================================

# Arquivos e diretórios
alias ll='ls -lah'
alias la='ls -A'

# Git
alias gst='git status'
alias gadd='git add .'
alias gcm='git commit -m'
alias gps='git push'
alias gpl='git pull'
alias gft='git fetch'
alias gmr='git merge'

# Configuração do Zsh
alias zshconfig='vim ~/.zshrc'
alias zshfunctions='vim ~/.config/zsh/functions.zsh'
alias zshaliases='vim ~/.config/zsh/aliases.zsh'

# clippy Land
alias clippylandatualizar='
	cd ~/clippy-land
	git fetch origin
	git merge origin/main
	just build
	just prefix="$HOME/.local" install
	git push -u backup main'
