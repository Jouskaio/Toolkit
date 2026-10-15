#!/bin/bash

# Puts `toolkit` on your PATH with a symlink, and its tab completion where your shell looks for it.
#   bash install.sh [folder]     default folder: ~/.local/bin
#   bash install.sh --uninstall [folder]

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
action="install"
[ "$1" == "--uninstall" ] && { action="uninstall"; shift; }
BIN="${1:-$HOME/.local/bin}"
BASH_COMPLETION_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
ZSH_COMPLETION_DIR="${TOOLKIT_ZSH_COMPLETIONS:-$HOME/.zsh/completions}"

if [ "$action" == "uninstall" ]; then
  rm -f "$BIN/toolkit" "$BASH_COMPLETION_DIR/toolkit" "$ZSH_COMPLETION_DIR/_toolkit"
  echo "Removed toolkit from $BIN and its completions."
  exit 0
fi

mkdir -p "$BIN" "$BASH_COMPLETION_DIR" "$ZSH_COMPLETION_DIR" || exit 1
ln -sf "$ROOT/toolkit" "$BIN/toolkit"
cp "$ROOT/completions/toolkit.bash" "$BASH_COMPLETION_DIR/toolkit"
cp "$ROOT/completions/_toolkit" "$ZSH_COMPLETION_DIR/_toolkit"
echo "Installed: $BIN/toolkit -> $ROOT/toolkit"

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "Add $BIN to your PATH:  export PATH=\"$BIN:\$PATH\"" ;;
esac
echo "Tab completion: bash loads it from $BASH_COMPLETION_DIR (needs bash-completion); for zsh add"
echo "  fpath=($ZSH_COMPLETION_DIR \$fpath); autoload -Uz compinit && compinit"
echo "to ~/.zshrc, then open a new terminal."
