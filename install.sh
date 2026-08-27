#!/usr/bin/env bash
# Symlink every tracked dotfile in this repo into place.
# Existing real files are moved into a timestamped backup directory first.
#
#   ./install.sh            link everything
#   ./install.sh --dry-run  show what would happen
#   ./install.sh hypr waybar  link only those top-level directories

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0
SELECT=()

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) SELECT+=("$arg") ;;
  esac
done

# Not config — never linked.
SKIP="README.md install.sh .gitignore .git secrets.example"

target_for() {
  case "$1" in
    home/*) echo "$HOME/${1#home/}" ;;
    bin/*)  echo "$HOME/.local/${1}" ;;
    *)      echo "$HOME/.config/$1" ;;
  esac
}

link() {
  local rel="$1" src="$REPO/$1" dst
  dst="$(target_for "$rel")"

  if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    return
  fi

  if [[ -e "$dst" || -L "$dst" ]]; then
    echo "backup  $dst"
    if (( ! DRY_RUN )); then
      mkdir -p "$BACKUP/$(dirname "$rel")"
      mv "$dst" "$BACKUP/$rel"
    fi
  fi

  echo "link    $dst"
  if (( ! DRY_RUN )); then
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
  fi
}

cd "$REPO"
while IFS= read -r rel; do
  top="${rel%%/*}"
  for s in $SKIP; do [[ "$top" == "$s" ]] && continue 2; done
  if (( ${#SELECT[@]} )); then
    printf '%s\n' "${SELECT[@]}" | grep -qxF "$top" || continue
  fi
  link "$rel"
done < <(git ls-files)

if (( DRY_RUN )); then
  echo "(dry run — nothing changed)"
else
  mkdir -p "$HOME/.config/.secrets" && chmod 700 "$HOME/.config/.secrets"
  [[ -e "$HOME/.config/zsh/secrets.zsh" ]] || {
    mkdir -p "$HOME/.config/zsh"
    cp "$REPO/zsh/secrets.zsh.example" "$HOME/.config/zsh/secrets.zsh"
    echo "created $HOME/.config/zsh/secrets.zsh — fill it in"
  }
  if [[ -d "$BACKUP" ]]; then
    echo "backups in $BACKUP"
  fi
fi
