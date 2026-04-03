#!/usr/bin/env bash
# install.sh - Install cmux-like tmux scripts (cross-platform)
#
# Copy this directory to the remote host and run:
#   scp -r ~/.tmux/cmux/ myhost:~/.tmux/cmux/
#   ssh myhost 'bash ~/.tmux/cmux/install.sh'
#
# Or from a fresh copy:
#   scp -r ~/.tmux/cmux/ myhost:/tmp/cmux-install/
#   ssh myhost 'bash /tmp/cmux-install/install.sh'

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.tmux/cmux"

echo "Installing cmux-like tmux scripts to ${TARGET_DIR}..."

mkdir -p "$TARGET_DIR"

for script in pane-info.sh window-info.sh claude-watch.sh workspace.sh cmux.tmux.conf; do
  if [ -f "${SCRIPT_DIR}/${script}" ]; then
    cp "${SCRIPT_DIR}/${script}" "${TARGET_DIR}/${script}"
  else
    echo "Warning: ${script} not found in ${SCRIPT_DIR}, skipping"
  fi
done

chmod +x "${TARGET_DIR}"/*.sh

TMUX_CONF="$HOME/.tmux.conf"
if [ -f "$TMUX_CONF" ] && grep -q 'cmux.tmux.conf\|cmux-like features' "$TMUX_CONF"; then
  echo "cmux config already referenced in ${TMUX_CONF}, skipping."
else
  if [ ! -f "$TMUX_CONF" ]; then
    echo "source-file ~/.tmux/cmux/cmux.tmux.conf" > "$TMUX_CONF"
    echo "Created ${TMUX_CONF} with cmux source line."
  elif grep -q "run.*tpm/tpm" "$TMUX_CONF"; then
    sed -i.bak '/run.*tpm\/tpm/i\
\
# Source cmux config\
source-file ~/.tmux/cmux/cmux.tmux.conf\
' "$TMUX_CONF"
    rm -f "${TMUX_CONF}.bak"
    echo "Added source-file line before TPM init in ${TMUX_CONF}"
  else
    printf '\n# Source cmux config\nsource-file ~/.tmux/cmux/cmux.tmux.conf\n' >> "$TMUX_CONF"
    echo "Appended source-file line to ${TMUX_CONF}"
  fi
fi

echo ""
echo "Done! Reload tmux config with: tmux source-file ~/.tmux.conf"
echo ""
echo "Keybindings (using your prefix):"
echo "  prefix + C   New Claude Code workspace"
echo "  prefix + W   List Claude workspaces (interactive picker)"
echo "  prefix + M   Workspace manager menu"
echo "  prefix + N   Notification watcher control"
