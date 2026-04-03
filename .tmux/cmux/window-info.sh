#!/usr/bin/env bash
# window-info.sh - Show per-window summary for the status bar
# Cross-platform: macOS and Linux

WINDOW_ID="${1:-}"

if [ -n "$WINDOW_ID" ]; then
  PANE_CWD=$(tmux display-message -t "$WINDOW_ID" -p '#{pane_current_path}' 2>/dev/null)
  PANE_PID=$(tmux display-message -t "$WINDOW_ID" -p '#{pane_pid}' 2>/dev/null)
  WIN_NAME=$(tmux display-message -t "$WINDOW_ID" -p '#{window_name}' 2>/dev/null)
else
  PANE_CWD=$(tmux display-message -p '#{pane_current_path}')
  PANE_PID=$(tmux display-message -p '#{pane_pid}')
  WIN_NAME=$(tmux display-message -p '#{window_name}')
fi

[ -z "$PANE_CWD" ] && exit 0

# Git branch
GIT_BRANCH=""
if git -C "$PANE_CWD" rev-parse --git-dir >/dev/null 2>&1; then
  GIT_BRANCH=$(git -C "$PANE_CWD" symbolic-ref --short HEAD 2>/dev/null || git -C "$PANE_CWD" rev-parse --short HEAD 2>/dev/null)
fi

# Use the window name (respects rename-window)
DIR_NAME="$WIN_NAME"

# Listening ports
PORTS=""
if [ -n "$PANE_PID" ]; then
  get_descendants() {
    local parent=$1
    echo "$parent"
    for child in $(pgrep -P "$parent" 2>/dev/null); do
      get_descendants "$child"
    done
  }
  ALL_PIDS=$(get_descendants "$PANE_PID")

  if command -v ss >/dev/null 2>&1; then
    PORTS=$(for pid in $ALL_PIDS; do
      ss -tlnp 2>/dev/null | grep "pid=${pid}," | awk '{print $4}' | grep -oE '[0-9]+$'
    done | sort -un | head -3 | tr '\n' ',' | sed 's/,$//')
  elif command -v lsof >/dev/null 2>&1; then
    local pid_csv
    pid_csv=$(echo "$ALL_PIDS" | tr '\n' ',' | sed 's/,$//')
    PORTS=$(lsof -nP -iTCP -sTCP:LISTEN -a -p "$pid_csv" 2>/dev/null | awk 'NR>1 {split($9,a,":"); print a[length(a)]}' | sort -un | head -3 | tr '\n' ',' | sed 's/,$//')
  fi
fi

# Notification count
NOTIF_COUNT=0
NOTIF_FILE="/tmp/tmux-cmux-notifications"
if [ -f "$NOTIF_FILE" ] && [ -n "$WINDOW_ID" ]; then
  WIN_INDEX=$(tmux display-message -t "$WINDOW_ID" -p '#{window_index}' 2>/dev/null)
  NOTIF_COUNT=$(grep -c "^${WIN_INDEX}:" "$NOTIF_FILE" 2>/dev/null || echo 0)
fi

# Build output
OUTPUT=""
[ -n "$GIT_BRANCH" ] && OUTPUT="${GIT_BRANCH} "
OUTPUT="${OUTPUT}${DIR_NAME}"
[ -n "$PORTS" ] && OUTPUT="${OUTPUT} :${PORTS}"
[ "$NOTIF_COUNT" -gt 0 ] && OUTPUT="${OUTPUT} !${NOTIF_COUNT}"

echo "$OUTPUT"
