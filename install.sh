#!/bin/sh
# Zoldshell - instalador para Void Linux + Sway
# Uso: ./install.sh [--no-deps] [--optional]

set -eu

REPO="$(cd "$(dirname "$0")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"

WITH_DEPS=1
WITH_OPTIONAL=0
for arg in "$@"; do
  case "$arg" in
    --no-deps)  WITH_DEPS=0 ;;
    --optional) WITH_OPTIONAL=1 ;;
    -h|--help)
      echo "Uso: $0 [--no-deps] [--optional]"
      exit 0
      ;;
    *) echo "Opção desconhecida: $arg"; exit 1 ;;
  esac
done

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

install_list() {
  file="$1"
  [ -f "$file" ] || return 0
  while IFS= read -r pkg; do
    case "$pkg" in ''|'#'*) continue ;; esac
    if xbps-query "$pkg" >/dev/null 2>&1; then
      echo "   ok      $pkg"
    elif sudo xbps-install -y "$pkg" >/dev/null 2>&1; then
      echo "   instalado $pkg"
    else
      warn "não consegui instalar '$pkg' (procure o nome com: xbps-query -Rs $pkg)"
    fi
  done < "$file"
}

link_dir() {
  src="$1"; dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    warn "$dst já existe; movendo para $dst.bak-$STAMP"
    mv "$dst" "$dst.bak-$STAMP"
  fi
  ln -sfn "$src" "$dst"
  echo "   link    $dst -> $src"
}

# 1. Dependências
if [ "$WITH_DEPS" -eq 1 ]; then
  command -v xbps-install >/dev/null 2>&1 || { warn "xbps-install não encontrado (este script é para Void Linux)"; exit 1; }
  info "Sincronizando repositórios"
  sudo xbps-install -S >/dev/null
  info "Instalando dependências obrigatórias"
  install_list "$REPO/deps/void.txt"
  if [ "$WITH_OPTIONAL" -eq 1 ]; then
    info "Instalando dependências opcionais"
    install_list "$REPO/deps/optional.txt"
  fi
fi

# 2. Links das configs
info "Ligando as configurações em $CFG"
link_dir "$REPO/quickshell/minimal"        "$CFG/quickshell/minimal"
link_dir "$REPO/quickshell/theme-switcher" "$CFG/quickshell/theme-switcher"

# 3. Arquivos gerados pelo seletor de tema (precisam existir antes do primeiro uso)
info "Criando arquivos de estado"
mkdir -p "$CFG/sway" "$CFG/kitty"
[ -f "$CFG/sway/theme.conf" ]         || : > "$CFG/sway/theme.conf"
[ -f "$CFG/kitty/theme-colors.conf" ] || : > "$CFG/kitty/theme-colors.conf"
[ -f "$CFG/quickshell/theme.conf" ]   || printf '0' > "$CFG/quickshell/theme.conf"

# 4. Sensor de temperatura (coretemp) no boot
if [ ! -f /etc/modules-load.d/coretemp.conf ]; then
  info "Configurando o módulo coretemp para carregar no boot"
  echo coretemp | sudo tee /etc/modules-load.d/coretemp.conf >/dev/null
  sudo modprobe coretemp 2>/dev/null || warn "não consegui carregar o coretemp agora"
fi

# 5. Verificações
info "Verificando configs que dependem de você"
grep -qs 'theme.conf' "$CFG/sway/config" 2>/dev/null \
  || warn "Adicione ao ~/.config/sway/config:  include ~/.config/sway/theme.conf"
grep -qs 'allow_remote_control' "$CFG/kitty/kitty.conf" 2>/dev/null \
  || warn "Adicione ao kitty.conf:  allow_remote_control yes  e  listen_on unix:/tmp/kitty"
grep -qs 'theme-colors.conf' "$CFG/kitty/kitty.conf" 2>/dev/null \
  || warn "Adicione ao kitty.conf:  include theme-colors.conf"

cat <<'EOF'

Pronto. Falta ativar os serviços do runit, se ainda não estiverem:

  sudo ln -s /etc/sv/dbus           /var/service/
  sudo ln -s /etc/sv/NetworkManager /var/service/
  sudo ln -s /etc/sv/bluetoothd     /var/service/

E iniciar o daemon de wallpaper e o shell (no config do Sway):

  exec awww-daemon
  exec qs -c minimal
EOF
