#!/usr/bin/env bash
# claude-watch.sh - Monitor Claude Code panes for when they finish working
# Cross-platform: macOS (osascript notifications) and Linux (iTerm2 OSC 9 via SSH).
#
# Usage: claude-watch.sh [start|stop|status]
#
# macOS notification style:
#   osascript notifications are delivered under "Script Editor" in Notification
#   Center. To make banners persist until dismissed instead of auto-hiding after
#   ~5s, open System Settings > Notifications > Script Editor, and change the
#   alert style from "Banners" to "Alerts".
#
# Remote-Linux notifications:
#   When running on Linux, the watcher writes an iTerm2 OSC 9 escape sequence
#   directly to each attached tmux client's tty. iTerm2 on the Mac end (over
#   SSH) turns it into a real macOS Notification Center banner. Requires:
#     - iTerm2 on the Mac (with default "Show Bells in Notification Center"
#       ON — Preferences > Profiles > Terminal > Notifications). OSC 9 uses
#       the same subsystem.
#     - No extra packages on the Linux box.
#   If no client is attached, it falls back to just the tmux status message.

PIDFILE="/tmp/tmux-cmux-watcher.pid"
POLL_INTERVAL=3
OS="$(uname -s)"
HOSTNAME_SHORT="$(hostname -s 2>/dev/null || hostname 2>/dev/null)"

CMUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=agent.sh
. "${CMUX_DIR}/agent.sh"

_hash() {
  if command -v md5 >/dev/null 2>&1; then
    md5
  else
    md5sum | cut -d' ' -f1
  fi
}

_notify() {
  local win_name="$1" win_idx="$2" agent="${3:-claude}"
  # tmux status message (always)
  tmux display-message "${agent} finished in [${win_name}] (window #${win_idx})" 2>/dev/null
  if [ "$OS" = "Darwin" ]; then
    # Local Mac — use Notification Center via osascript
    osascript <<EOF 2>/dev/null
display notification "${agent} finished in ${win_name}" with title "cmux" subtitle "Window #${win_idx}"
EOF
  else
    # Remote host — send iTerm2 OSC 9 to each attached client's tty. iTerm2
    # converts it into a macOS Notification Center banner on the Mac end.
    # Format: ESC ] 9 ; <message> BEL
    #
    # Each write runs in a fire-and-forget subshell: a flow-stopped terminal
    # (Ctrl-S, a dead mosh/ssh client whose queue filled) accepts the open but
    # never drains, and a synchronous write would block the whole poll loop
    # forever on that one tty.
    local msg="cmux@${HOSTNAME_SHORT}: ${agent} finished in ${win_name} (window #${win_idx})"
    local tty
    while IFS= read -r tty; do
      if [ -n "$tty" ] && [ -w "$tty" ]; then
        ( printf '\033]9;%s\007' "$msg" > "$tty" 2>/dev/null ) &
      fi
    done < <(tmux list-clients -F '#{client_tty}' 2>/dev/null)
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
  # Per-pane memory:
  #   out_hash     — hash of the OUTPUT region only (pane content above the
  #                  input box). Input-box-only changes (the user typing in a
  #                  background pane) never touch this, so they can't
  #                  fabricate a busy→idle transition.
  #   out_changed  — set to 1 when out_hash actually changed (real agent work
  #                  observed).
  #   notified     — set to 1 after we fire; cleared on the next output change.
  #   w/h          — pane geometry last tick. A resize or pane-switch reflows
  #                  the visible text without the agent doing anything; changes
  #                  observed on such a tick are ignored for REDRAW_GRACE ticks.
  #   grace        — remaining redraw-grace ticks.
  #   title        — OSC title last tick (claude shows a live spinner there
  #                  while working; see title_spin below).
  declare -A out_hash out_changed notified w h grace title

  # How many ticks after a resize/pane-switch a body change still counts as a
  # redraw rather than the agent's own output.
  local REDRAW_GRACE=1
  # Lines at the bottom of the pane that belong to the input box + footer +
  # statusline. Captured but excluded from the output hash.
  local INPUT_TAIL_LINES=3
  # How far back we look for agent output.
  local CAPTURE_LINES=20

  while true; do
    local active_win
    active_win=$(tmux display-message -p '#{window_index}' 2>/dev/null)

    while IFS='|' read -r pane_id win_idx pane_pid width height pane_title; do
      # Only watch panes running claude or pi — cmux_pane_agent restricts to
      # processes owned by $USER so a shared/multi-tenant host doesn't
      # cross-notify on other users' shells.
      local agent
      if ! agent=$(cmux_pane_agent "$pane_pid"); then
        unset "out_hash[$pane_id]" "out_changed[$pane_id]" "notified[$pane_id]"
        unset "w[$pane_id]" "h[$pane_id]" "grace[$pane_id]" "title[$pane_id]"
        continue
      fi

      # Capture the bottom of the pane. Lines 1..N are agent output; the last
      # INPUT_TAIL_LINES are the input box/footer/statusline the user types into.
      # (awk not `head -n -K`: BSD head on macOS doesn't take negative counts.)
      local all_lines out_lines content_hash
      all_lines=$(tmux capture-pane -t "$pane_id" -p -S -"$CAPTURE_LINES" 2>/dev/null | tail -"$CAPTURE_LINES")
      out_lines=$(echo "$all_lines" | awk -v n="$INPUT_TAIL_LINES" '{ln[NR]=$0} END{for(i=1;i<=NR-n;i++) print ln[i]}')
      content_hash=$(printf '%s' "$out_lines" | grep -vE -- 'tokens:[0-9]|-- INSERT --|-- NORMAL --' | tr -d '[:space:]' | _hash)

      # Redraw detection: resize or pane switch reflows content with no agent action.
      # On a geometry change, the previous hash was computed under a different
      # layout and isn't comparable — re-seed it so this tick can't count as work,
      # and keep grace for the following tick (capture-pane and list-panes can
      # straddle the resize, so the reflow may only become visible next tick).
      local redraw=0
      if [ -n "${w[$pane_id]:-}" ] && { [ "${w[$pane_id]}" != "$width" ] || [ "${h[$pane_id]}" != "$height" ]; }; then
        redraw=1
        grace[$pane_id]=$REDRAW_GRACE
        out_hash[$pane_id]=""
        out_changed[$pane_id]=""
      fi
      w[$pane_id]="$width"
      h[$pane_id]="$height"
      if [ "${grace[$pane_id]:-0}" -gt 0 ]; then
        redraw=1
        grace[$pane_id]=$(( ${grace[$pane_id]} - 1 ))
      fi

      # OSC title: claude (and pi) put a live spinner frame in the terminal
      # title while working. A title change is strong evidence of work even if
      # the output hash somehow missed it.
      local title_changed=0
      if [ -n "${title[$pane_id]:-}" ] && [ "${title[$pane_id]}" != "$pane_title" ]; then
        title_changed=1
      fi
      title[$pane_id]="$pane_title"

      local prev_hash="${out_hash[$pane_id]:-}"
      out_hash[$pane_id]="$content_hash"

      # First time seeing this pane: seed baselines and mark as already-notified
      # so panes that are ALREADY idle at watcher startup don't trigger a false
      # alert. We only care about future busy→idle transitions.
      if [ -z "$prev_hash" ]; then
        notified[$pane_id]="1"
        continue
      fi

      if [ "$content_hash" != "$prev_hash" ]; then
        # Agent output changed — but attribute it as work only if it isn't a
        # redraw artifact.
        if [ "$redraw" -eq 0 ]; then
          out_changed[$pane_id]="1"
          notified[$pane_id]=""
        fi
      elif [ -n "${out_changed[$pane_id]}" ] && [ -z "${notified[$pane_id]}" ]; then
        # Output stable this poll AND we saw real work earlier AND we haven't
        # notified for this transition yet. Check for any idle-input marker:
        #   -- INSERT -- / -- NORMAL --   claude free-text prompt (default state)
        #   INSERT / NORMAL               pi's vim-mode marker (no dashes)
        #   Enter to select               interactive picker / question popup
        #   Do you want to                permission/confirmation prompt
        if echo "$all_lines" | grep -qE -- '(--[[:space:]]*)?(INSERT|NORMAL)([[:space:]]*--)?|Enter to select|Do you want to'; then
          # Only notify if user is on a different window
          if [ "$active_win" != "$win_idx" ]; then
            notified[$pane_id]="1"
            local win_name
            win_name=$(tmux display-message -t ":${win_idx}" -p '#{window_name}' 2>/dev/null)
            _notify "$win_name" "$win_idx" "$agent"
          fi
        fi
      fi
    done < <(tmux list-panes -a -F "#{pane_id}|#{window_index}|#{pane_pid}|#{pane_width}|#{pane_height}|#{pane_title}" 2>/dev/null)

    sleep "$POLL_INTERVAL"
  done
}

case "${1:-status}" in
  start)  start_watcher ;;
  stop)   stop_watcher ;;
  status) status_watcher ;;
  *)      echo "Usage: $0 [start|stop|status]"; exit 1 ;;
esac
