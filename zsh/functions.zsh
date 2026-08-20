# ==========================================================
# FUNÇÃO PARA ATUALIZAR O POP!_OS E OS APLICATIVOS FLATPAK
# ==========================================================

function atualizar() {
  echo "🔄 Atualizando a lista de pacotes..."

  sudo apt update || {
    echo "❌ Erro ao atualizar a lista de pacotes."
    return 1
  }

  echo "📦 Instalando atualizações disponíveis..."

  sudo apt full-upgrade -y || {
    echo "❌ Erro durante a atualização dos pacotes."
    return 1
  }

  echo "🧹 Removendo pacotes desnecessários..."

  sudo apt autoremove --purge -y

  echo "📦 Atualizando aplicativos Flatpak..."

  flatpak update -y
  flatpak uninstall --unused -y

  echo "✅ Atualização finalizada."
}


# ═══════════════════════════════════════════════════════════════
# RCLONE — MONTAGEM DAS NUVENS
# ═══════════════════════════════════════════════════════════════

export NUVENS_DIR="$HOME/Nuvens"
export RCLONE_CACHE_DIR="$HOME/.cache/rclone"
export RCLONE_LOG_DIR="$HOME/.local/state/rclone"


# Nome do remote -> nome da pasta
typeset -A NUVENS_REMOTES=(
  onedrive OneDrive
  pcloud   pCloud
  gdrive   GoogleDrive
  icloud   icloud
)


# ═══════════════════════════════════════════════════════════════
# ICLOUD — VALIDAÇÃO E REAUTENTICAÇÃO
# ═══════════════════════════════════════════════════════════════

_icloud_validar_sessao() {
  local remote="icloud:"
  local ponto="$NUVENS_DIR/icloud"
  local output
  local status

  echo "🔎 Verificando sessão do iCloud..."

  output=$(rclone lsd "$remote" 2>&1)
  status=$?

  # Sessão funcionando normalmente
  if (( status == 0 )); then
    echo "✅ Sessão do iCloud válida."
    return 0
  fi


  # ----------------------------------------------------------
  # Sessão do iCloud expirada/inválida
  # ----------------------------------------------------------

  if echo "$output" | grep -qi "Invalid global session"; then

    echo ""
    echo "🔐 Sessão do iCloud expirada ou inválida."
    echo ""


    # --------------------------------------------------------
    # Se existir um mount antigo, desmontamos antes.
    #
    # Isso é importante porque um processo rclone antigo
    # continuará usando a sessão antiga mesmo depois do
    # reconnect.
    # --------------------------------------------------------

    if mountpoint -q "$ponto"; then

      echo "⏏️  Desmontando sessão antiga do iCloud..."

      if command -v fusermount3 >/dev/null 2>&1; then
        fusermount3 -u "$ponto"

      elif command -v fusermount >/dev/null 2>&1; then
        fusermount -u "$ponto"

      else
        umount "$ponto"
      fi


      # Confere se realmente desmontou
      if mountpoint -q "$ponto"; then
        echo "❌ Não foi possível desmontar o iCloud."
        echo "   Feche arquivos ou pastas que estejam usando:"
        echo "   $ponto"
        return 1
      fi

      echo "✅ Mount antigo do iCloud desmontado."
    fi


    # --------------------------------------------------------
    # Reautenticação
    # --------------------------------------------------------

    echo ""
    echo "🔄 Iniciando reautenticação do iCloud..."
    echo ""
    echo "👉 Faça a autenticação solicitada pelo rclone."
    echo "👉 Se solicitado, informe também o código 2FA."
    echo ""

    rclone config reconnect "$remote"

    if (( $? != 0 )); then
      echo ""
      echo "❌ Não foi possível reautenticar o iCloud."
      return 1
    fi


    # --------------------------------------------------------
    # Testa novamente depois da autenticação
    # --------------------------------------------------------

    echo ""
    echo "🔎 Testando nova sessão do iCloud..."

    output=$(rclone lsd "$remote" 2>&1)
    status=$?

    if (( status != 0 )); then

      echo ""
      echo "❌ A nova autenticação do iCloud não funcionou."
      echo ""
      echo "Detalhes:"
      echo "$output"

      return 1
    fi


    echo "✅ iCloud autenticado novamente com sucesso."

    return 0
  fi


  # ----------------------------------------------------------
  # Outro erro que NÃO seja sessão expirada
  # ----------------------------------------------------------

  echo ""
  echo "❌ Ocorreu um erro ao acessar o iCloud."
  echo ""
  echo "$output"

  return 1
}


# ═══════════════════════════════════════════════════════════════
# FUNÇÃO INTERNA PARA MONTAR QUALQUER NUVEM
# ═══════════════════════════════════════════════════════════════

_nuvem_montar() {
  local remote="$1"
  local pasta="$2"
  local ponto="$NUVENS_DIR/$pasta"
  local cache="$RCLONE_CACHE_DIR/$pasta"
  local log="$RCLONE_LOG_DIR/${remote}.log"
  local tentativa=1


  # ----------------------------------------------------------
  # Verifica se rclone existe
  # ----------------------------------------------------------

  if ! command -v rclone >/dev/null 2>&1; then
    echo "❌ O rclone não está instalado."
    return 1
  fi


  # ----------------------------------------------------------
  # Verifica se remote existe
  # ----------------------------------------------------------

  if ! rclone listremotes | grep -Fxq "${remote}:"; then
    echo "❌ Remote não encontrado: ${remote}:"
    return 1
  fi


  # ----------------------------------------------------------
  # ICLOUD
  #
  # Antes de montar, verifica se a sessão continua válida.
  # Se tiver expirado, abre automaticamente o reconnect.
  # ----------------------------------------------------------

  if [[ "$remote" == "icloud" ]]; then

    if ! _icloud_validar_sessao; then
      echo "❌ Não foi possível preparar o iCloud."
      return 1
    fi

  fi


  # ----------------------------------------------------------
  # Cria diretórios necessários
  # ----------------------------------------------------------

  mkdir -p "$ponto" "$cache" "$RCLONE_LOG_DIR"


  # ----------------------------------------------------------
  # Evita montar a mesma nuvem duas vezes
  # ----------------------------------------------------------

  if mountpoint -q "$ponto"; then
    echo "☁️  $pasta já está montado."
    return 0
  fi


  # ----------------------------------------------------------
  # Montagem
  # ----------------------------------------------------------

  echo "☁️  Montando $pasta..."


  rclone mount "${remote}:" "$ponto" \
    --daemon \
    --vfs-cache-mode writes \
    --cache-dir "$cache" \
    --log-file "$log" \
    --log-level INFO


  if (( $? != 0 )); then

    echo "❌ Erro ao iniciar o mount de $pasta."
    echo "📄 Verifique o log:"
    echo "   $log"

    return 1
  fi


  # ----------------------------------------------------------
  # Espera até 5 segundos pelo mount
  #
  # Antes você esperava somente 1 segundo.
  # Algumas nuvens podem demorar um pouco mais.
  # ----------------------------------------------------------

  tentativa=1

  while (( tentativa <= 5 )); do

    if mountpoint -q "$ponto"; then

      echo "✅ $pasta montado em $ponto"

      return 0
    fi

    sleep 1

    ((tentativa++))
  done


  # ----------------------------------------------------------
  # Mount não apareceu
  # ----------------------------------------------------------

  echo "❌ Não foi possível montar $pasta."
  echo "📄 Verifique o log:"
  echo "   $log"

  return 1
}


# ── Montagens individuais ─────────────────────────────────────

montar_onedrive() {
  _nuvem_montar onedrive OneDrive
}


montar_pcloud() {
  _nuvem_montar pcloud pCloud
}


montar_gdrive() {
  _nuvem_montar gdrive GoogleDrive
}


montar_icloud() {
  _nuvem_montar icloud icloud
}


# ── Montar todas ──────────────────────────────────────────────

montar_nuvens() {
  echo "════════════════════════════════════"
  echo "☁️  Montando todas as nuvens..."
  echo "════════════════════════════════════"

  local falhas=0

  montar_onedrive || ((falhas++))

  echo "────────────────────────────────────"

  montar_pcloud || ((falhas++))

  echo "────────────────────────────────────"

  montar_gdrive || ((falhas++))

  echo "────────────────────────────────────"

  montar_icloud || ((falhas++))

  echo "════════════════════════════════════"

  if (( falhas == 0 )); then
    echo "✅ Todas as nuvens foram montadas."
  else
    echo "⚠️  Montagem concluída com $falhas falha(s)."
  fi

  status_nuvens
}


# ── Desmontar sempre todas ────────────────────────────────────

desmontar_nuvens() {
  local pasta
  local ponto
  local falhas=0

  echo "════════════════════════════════════"
  echo "⏏️  Desmontando todas as nuvens..."
  echo "════════════════════════════════════"

  for pasta in OneDrive pCloud GoogleDrive icloud; do
    ponto="$NUVENS_DIR/$pasta"

    if ! mountpoint -q "$ponto"; then
      echo "○ $pasta já está desmontado."
      continue
    fi

    echo "⏏️  Desmontando $pasta..."

    if command -v fusermount3 >/dev/null 2>&1; then
      fusermount3 -u "$ponto"

    elif command -v fusermount >/dev/null 2>&1; then
      fusermount -u "$ponto"

    else
      umount "$ponto"
    fi

    if mountpoint -q "$ponto"; then

      echo "❌ Não foi possível desmontar $pasta."
      echo "   Feche arquivos, terminais e pastas que estejam usando a nuvem."

      ((falhas++))

    else

      echo "✅ $pasta desmontado."

    fi
  done

  echo "════════════════════════════════════"

  if (( falhas == 0 )); then
    echo "✅ Todas as nuvens estão desmontadas."
  else
    echo "⚠️  $falhas nuvem(ns) não puderam ser desmontadas."
  fi
}


# ── Mostrar status ────────────────────────────────────────────

status_nuvens() {
  local pasta
  local ponto

  echo ""
  echo "──────── Status das nuvens ────────"

  for pasta in OneDrive pCloud GoogleDrive icloud; do
    ponto="$NUVENS_DIR/$pasta"

    if mountpoint -q "$ponto"; then
      echo "✅ $pasta: montado"
    else
      echo "○  $pasta: desmontado"
    fi
  done

  echo "────────────────────────────────────"
}


# ── Mostrar processos do rclone ───────────────────────────────
#
# Útil caso o computador fique lento novamente.
#
# Uso:
#
#   processos_rclone
#

processos_rclone() {
  echo ""
  echo "──────── Processos do rclone ────────"

  if pgrep -x rclone >/dev/null 2>&1; then

    ps -C rclone \
      -o pid,ppid,%cpu,%mem,etime,args

  else

    echo "○ Nenhum processo rclone rodando."

  fi

  echo "──────────────────────────────────────"
}


# ═══════════════════════════════════════════════════════════════
# COLD STORAGE — BACKUP DO HOME
# ═══════════════════════════════════════════════════════════════

function backup_cold() {
  "$HOME/.local/bin/cold-backup"
}


function backup_cold_teste() {
  "$HOME/.local/bin/cold-backup" --dry-run
}


function backup_cold_logs() {
  local log_dir="$HOME/.local/state/cold-backup"

  if [[ ! -d "$log_dir" ]]; then
    echo "Nenhum diretório de logs encontrado."
    return 1
  fi

  ls -lht "$log_dir" | head -n 10
}
