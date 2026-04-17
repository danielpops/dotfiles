#!/usr/bin/env bash
# fzf-source.sh — dynamic source for cmux workspace prompt
# Called by fzf via --bind 'change:reload(...)' to switch between
# workspace listing and filesystem directory completion.
#
# Usage: fzf-source.sh <query>

query="$1"
CLAUDE_DIR="$HOME/claude"

# If query looks like a path, do directory completion
if [[ "$query" == /* || "$query" == ~* || "$query" == ./* || "$query" == ../* ]]; then
  # Expand ~ to $HOME
  expanded="${query/#\~/$HOME}"

  # Find the directory portion to list from
  if [ -d "$expanded" ]; then
    base="$expanded"
  else
    base="$(dirname "$expanded" 2>/dev/null)"
  fi

  [ ! -d "$base" ] && exit 0

  # List subdirectories, showing full paths with ~ abbreviation
  find "$base" -maxdepth 1 -type d ! -name '.*' 2>/dev/null | sort | while read -r d; do
    echo "${d/#$HOME/\~}"
  done
  exit 0
fi

# Default: list existing workspaces from ~/claude/
if [ -d "$CLAUDE_DIR" ]; then
  # Show most recent first
  ls -1dt "$CLAUDE_DIR"/*/ 2>/dev/null | while read -r d; do
    basename "$d"
  done
fi
