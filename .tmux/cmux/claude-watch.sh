#!/usr/bin/env bash
# claude-watch.sh - Monitor Claude Code panes for when they finish working
# Cross-platform: macOS (osascript notifications) and Linux (tmux-only)
#
# Usage: claude-watch.sh [start|stop|status]
#
# macOS notification style:
#   osascript notifications are delivered under "Script Editor" in Notification
#   Center. To make banners persist until dismissed instead of auto-hiding after
#   ~5s, open System Settings > Notifications > Script Editor, and change the
#   alert style from "Banners" to "Alerts".

PIDFILE="/tmp/tmux-cmux-watcher.pid"
POLL_INTERVAL=3
OS="$(uname -s)"

_hash() {
  if command -v md5 >/dev/null 2>&1; then
    md5
  else
    md5sum | cut -d' ' -f1
  fi
}

_notify() {
  local win_name="$1" win_idx="$2"
  # tmux message (always)
  tmux display-message "Claude finished in [${win_name}] (window #${win_idx})" 2>/dev/null
  # macOS notification
  if [ "$OS" = "Darwin" ]; then
    osascript <<EOF 2>/dev/null
display notification "Claude finished in ${win_name}" with title "cmux" subtitle "Window #${win_idx}"
EOF
  fi
}

start_watcher() {
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "Watcher already running (PID $(cat "$PIDFILE"))"
    return 0
  fi
  echo "Starting Claude Code watcher..."
  _run_watcher &
  echo $! > "$PIDFILE"
  disown 2>/dev/null
  echo "Watcher started (PID $!)"
}

stop_watcher() {
  if [ -f "$PIDFILE" ]; then
    local pid
    pid=$(cat "$PIDFILE")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null
      echo "Watcher stopped (PID $pid)"
    else
      echo "Watcher was not running"
    fi
    rm -f "$PIDFILE"
  else
    echo "No watcher PID file found"
  fi
}

status_watcher() {
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "Watcher running (PID $(cat "$PIDFILE"))"
  else
    echo "Watcher not running"
  fi
}

_run_watcher() {
  # Track per-pane:
  #   pane_hash    — last content hash we saw
  #   pane_changed — set to 1 the first time we see the hash actually change
  #                  (guarantees we've observed at least one real working→idle transition)
  #   notified     — set to 1 after we fire; cleared on next content change
  declare -A pane_hash
  declare -A pane_changed
  declare -A notified

  while true; do
    local active_win
    active_win=$(tmux display-message -p '#{window_index}' 2>/dev/null)

    while IFS= read -r line; do
      local pane_id win_idx pane_pid
      pane_id=$(echo "$line" | cut -d'|' -f1)
      win_idx=$(echo "$line" | cut -d'|' -f2)
      pane_pid=$(echo "$line" | cut -d'|' -f3)

      # Only watch panes running claude
      if ! ps -eo ppid,comm 2>/dev/null | grep -q "^ *${pane_pid} .*claude"; then
        unset "pane_hash[$pane_id]" "pane_changed[$pane_id]" "notified[$pane_id]"
        continue
      fi

      # Get pane content, strip the volatile status bar lines before hashing
      local last_lines content_hash
      last_lines=$(tmux capture-pane -t "$pane_id" -p -S -10 2>/dev/null | tail -10)
      content_hash=$(echo "$last_lines" | grep -vE -- 'tokens:[0-9]|-- INSERT --|-- NORMAL --' | _hash)

      local prev_hash="${pane_hash[$pane_id]:-}"
      pane_hash[$pane_id]="$content_hash"

      # First time seeing this pane: seed baseline and mark as already-notified so
      # panes that are ALREADY idle at watcher startup don't trigger a false alert.
      # We only care about future busy→idle transitions.
      if [ -z "$prev_hash" ]; then
        notified[$pane_id]="1"
        continue
      fi

      if [ "$content_hash" != "$prev_hash" ]; then
        # Content actively changing → Claude is working. Clear notified so the next
        # idle transition can fire, and mark that we've seen a real change.
        pane_changed[$pane_id]="1"
        notified[$pane_id]=""
      elif [ -n "${pane_changed[$pane_id]}" ] && [ -z "${notified[$pane_id]}" ]; then
        # Content stable this poll AND we saw it change earlier AND we haven't
        # notified for this idle transition yet. Check for any idle-input marker:
        #   -- INSERT -- / -- NORMAL --   free-text prompt (default state)
        #   Enter to select               interactive picker / question popup
        #   Do you want to                permission/confirmation prompt
        if echo "$last_lines" | grep -qE -- '-- INSERT --|-- NORMAL --|Enter to select|Do you want to'; then
          # Only notify if user is on a different window
          if [ "$active_win" != "$win_idx" ]; then
            notified[$pane_id]="1"
            local win_name
            win_name=$(tmux display-message -t ":${win_idx}" -p '#{window_name}' 2>/dev/null)
            _notify "$win_name" "$win_idx"
          fi
        fi
      fi
    done < <(tmux list-panes -a -F '#{pane_id}|#{window_index}|#{pane_pid}' 2>/dev/null)

    sleep "$POLL_INTERVAL"
  done
}

case "${1:-status}" in
  start)  start_watcher ;;
  stop)   stop_watcher ;;
  status) status_watcher ;;
  *)      echo "Usage: $0 [start|stop|status]"; exit 1 ;;
esac
