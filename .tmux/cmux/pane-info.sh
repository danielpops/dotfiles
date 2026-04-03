#!/usr/bin/env bash
# pane-info.sh - Gather git branch, cwd, and listening ports for a tmux pane
# Cross-platform: macOS and Linux
#
# Usage: pane-info.sh <pane_id>

PANE_ID="${1:-}"

if [ -n "$PANE_ID" ]; then
  PANE_PID=$(tmux display-message -t "$PANE_ID" -p '#{pane_pid}')
  PANE_CWD=$(tmux display-message -t "$PANE_ID" -p '#{pane_current_path}')
else
  PANE_PID=$(tmux display-message -p '#{pane_pid}')
  PANE_CWD=$(tmux display-message -p '#{pane_current_path}')
fi

# Git branch
GIT_BRANCH=""
if [ -d "$PANE_CWD/.git" ] || git -C "$PANE_CWD" rev-parse --git-dir >/dev/null 2>&1; then
  GIT_BRANCH=$(git -C "$PANE_CWD" symbolic-ref --short HEAD 2>/dev/null || git -C "$PANE_CWD" rev-parse --short HEAD 2>/dev/null)
fi

# Shorten cwd
SHORT_CWD="${PANE_CWD/#$HOME/~}"
if [ "$(echo "$SHORT_CWD" | tr '/' '\n' | wc -l)" -gt 3 ]; then
  SHORT_CWD="…/$(echo "$SHORT_CWD" | rev | cut -d'/' -f1-2 | rev)"
fi

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
    done | sort -un | tr '\n' ',' | sed 's/,$//')
  elif command -v lsof >/dev/null 2>&1; then
    local pid_csv
    pid_csv=$(echo "$ALL_PIDS" | tr '\n' ',' | sed 's/,$//')
    PORTS=$(lsof -nP -iTCP -sTCP:LISTEN -a -p "$pid_csv" 2>/dev/null | awk 'NR>1 {split($9,a,":"); print a[length(a)]}' | sort -un | tr '\n' ',' | sed 's/,$//')
  fi
fi

# Build output
OUTPUT=""
if [ -n "$GIT_BRANCH" ]; then
  OUTPUT="#[fg=colour114]${GIT_BRANCH}#[default]"
fi
OUTPUT="${OUTPUT} #[fg=colour246]${SHORT_CWD}#[default]"
if [ -n "$PORTS" ]; then
  OUTPUT="${OUTPUT} #[fg=colour209]:${PORTS}#[default]"
fi

echo "$OUTPUT"
