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
alias gb='git branch'
alias gc='git checkout'
alias gcb='git checkout -b'

# Gita
alias gtll='gita ll'
alias gtft='gita fetch'
alias gtpl='gita super pull origin'
alias gtc='gita super checkout'
alias gtbc='gita super checkout -b'
alias gtb='gita super branch'

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
