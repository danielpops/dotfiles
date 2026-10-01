#!/usr/bin/env bash
# claude-watch.sh - Monitor Claude Code panes for when they finish working
# Cross-platform: macOS (osascript notifications) and Linux (iTerm2 OSC 9 via SSH).
#
# Usage: claude-watch.sh [start|stop|status]
#
# Notification model:
#   A finish notification requires an OBSERVED working phase followed by an
#   OBSERVED idle tick — nothing else counts as evidence. Output hashes are
#   NOT evidence, so idle-time output churn (classifier misses, redraws)
#   cannot re-arm a notification: at most one finish per real work phase,
#   and no notify storms.
#   "Working" is detected from the last output lines: braille spinner, the
#   flower-glyph status line (✻ ✽ ✳ ✶ ✢ — it rotates, so the whole family
#   is matched), a token-traffic arrow, or "esc to interrupt". "Idle" is the
#   "· done" status line, a picker/permission prompt, or a bare prompt.
#   A pane must first be seen idle once since first sight/reseed before its
#   working phases latch, so fresh sessions and watcher restarts never
#   announce startup output.
#   A finish while the window is on screen in ANY attached client is
#   consumed silently (a finish you watched is not news); one on a hidden
#   window notifies.
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
#     - iTerm2 on the Mac with iTerm2's notification integration working
#       (verified working with "Notification Center Alerts" checked).
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
  #   settled      — the pane showed idle on the PREVIOUS tick.
  #   seen_settled — the pane has been observed idle at least once since
  #                  first sight/reseed. Until then, working ticks don't
  #                  latch: startup output and watcher restarts are never
  #                  news.
  #   saw_work     — the finish latch: set by an observed working tick once
  #                  seen_settled holds; cleared by the first idle tick after
  #                  it, which is the one finish notification. Idle hash
  #                  churn can never set it, so no notify storm is possible.
  #   w/h/grace    — pane geometry and redraw-grace ticks; see below.
  declare -A settled seen_settled saw_work out_hash w h grace

  # Ticks after a geometry change that can't count as work (capture-pane and
  # list-panes can straddle the resize, so the reflow may surface next tick).
  local REDRAW_GRACE=1
  # Lines at the bottom of the pane that belong to the input box + footer +
  # statusline. Captured but excluded from the output inspection.
  local INPUT_TAIL_LINES=3
  # How far back we look for agent output.
  local CAPTURE_LINES=20

  while true; do
    # visible = "win_index:session_name" pairs actually displayed by attached
    # clients, fresh this tick. A window on screen in ANY client counts as
    # visible. There is no #{client_window_index} format var, so ask each
    # attached client what it is currently showing via display-message -c.
    local -A visible=()
    local ctty vinfo
    while IFS= read -r ctty; do
      [ -n "$ctty" ] || continue
      vinfo=$(tmux display-message -p -c "$ctty" '#{window_index}|#{session_name}' 2>/dev/null)
      [ -n "$vinfo" ] && visible["$vinfo"]=1
    done < <(tmux list-clients -F '#{client_tty}' 2>/dev/null)

    while IFS='|' read -r pane_id win_idx pane_pid width height pane_title sess_name pane_mode; do
      # Only watch panes running claude or pi — cmux_pane_agent restricts to
      # processes owned by $USER so a shared/multi-tenant host doesn't
      # cross-notify on other users' shells.
      local agent
      if ! agent=$(cmux_pane_agent "$pane_pid"); then
        unset "settled[$pane_id]" "saw_work[$pane_id]" "seen_settled[$pane_id]"
        unset "out_hash[$pane_id]" "w[$pane_id]" "h[$pane_id]" "grace[$pane_id]"
        continue
      fi

      # Copy-mode (user scrolling scrollback) rewrites the visible region with
      # no agent action — the pane can't be classified meaningfully while
      # it's active. Re-seed and skip, so paging can't fabricate a finish.
      if [ "$pane_mode" = "1" ]; then
        settled[$pane_id]=""
        seen_settled[$pane_id]=""
        saw_work[$pane_id]=""
        out_hash[$pane_id]=""
        grace[$pane_id]=$REDRAW_GRACE
        w[$pane_id]="$width"
        h[$pane_id]="$height"
        continue
      fi

      # Capture the bottom of the pane. Lines 1..N are agent output; the last
      # INPUT_TAIL_LINES are the input box/footer/statusline the user types into.
      # (awk not `head -n -K`: BSD head on macOS doesn't take negative counts.)
      local all_lines out_lines
      all_lines=$(tmux capture-pane -t "$pane_id" -p -S -"$CAPTURE_LINES" 2>/dev/null | tail -"$CAPTURE_LINES")
      out_lines=$(echo "$all_lines" | awk -v n="$INPUT_TAIL_LINES" '{ln[NR]=$0} END{for(i=1;i<=NR-n;i++) print ln[i]}')
      # Output churn hash: used only to HOLD an already-latched working
      # phase through classifier misses (see below), never as evidence.
      local content_hash
      content_hash=$(printf '%s' "$out_lines" | grep -vE -- 'tokens:[0-9]|-- INSERT --|-- NORMAL --' | tr -d '[:space:]' | _hash)

      # Redraw detection: resize or pane switch reflows content with no agent
      # action, and the classification of the reflowed frame is unreliable.
      # Re-seed: the pane goes back to "first sight" semantics — what it was
      # doing around the resize is not news (no latch, next settle re-arms).
      local redraw=0
      if [ -n "${w[$pane_id]:-}" ] && { [ "${w[$pane_id]}" != "$width" ] || [ "${h[$pane_id]}" != "$height" ]; }; then
        redraw=1
        grace[$pane_id]=$REDRAW_GRACE
        settled[$pane_id]=""
        seen_settled[$pane_id]=""
        saw_work[$pane_id]=""
        out_hash[$pane_id]=""
      fi
      w[$pane_id]="$width"
      h[$pane_id]="$height"
      if [ "${grace[$pane_id]:-0}" -gt 0 ]; then
        redraw=1
        grace[$pane_id]=$(( ${grace[$pane_id]} - 1 ))
      fi

      # Working vs idle, judged from the OUTPUT region only, chrome-stripped:
      # pane borders, the ❯ prompt line, and the host/INSERT footer lines are
      # dropped, and only the tail of what remains is inspected — the status
      # line always sits at the bottom of the output region:
      #   WORKING — the bottom status line is a flower-glyph line WITHOUT
      #             "· done" (e.g. "✻ Sunrise-setting… (5m 24s · ↓ 41.0k
      #             tokens)"), a braille spinner, or a token-traffic arrow
      #             (· ↓ 41.0k tokens). Claude keeps these up through output
      #             pauses mid-turn, so a quiet tick mid-turn is NOT idle.
      #   IDLE    — the bottom status line says "· done", or the pane shows a
      #             picker/permission popup, or (no status line) the agent
      #             exited / is at a bare prompt.
      local working=0
      local chrome out_tail
      chrome='^[[:space:]]*─+[[:space:]]*$|─+[^─]*─[[:space:]]*$|❯|@|-- INSERT --|-- NORMAL --'
      out_tail=$(printf '%s\n' "$out_lines" | grep -vE -- "$chrome" | grep -v '^[[:space:]]*$' | tail -3)
      # The status line's leading glyph rotates through a flower family
      # (observed live: ✻ ✽ ✳ ✶ ✢ and a bare ·), plus braille frames. Match
      # the whole family, anchored at line start — a two-glyph check missed
      # frames and read them as idle mid-turn.
      if printf '%s' "$out_tail" | grep -qE -- '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|· *(↓|↑)'; then
        working=1
      elif printf '%s' "$out_tail" | grep -E -- '^[[:space:]]*[✻✽✳✶✢✦·]' | grep -vq -- '· *done'; then
        working=1
      elif printf '%s' "$out_tail" | grep -q -- 'esc to interrupt'; then
        working=1
      fi
      local idle=0
      [ "$working" -eq 0 ] && idle=1

      # Output churn HOLD, not evidence: a hash change can never arm the
      # finish latch (that re-arm loop was the notify storm), but churn
      # observed while a work phase is latched means the turn is still
      # moving — it resets the idle debounce so a classifier miss streak
      # (status line pushed out of the capture by a growing bottom UI)
      # can't fire the finish mid-turn. Between turns (idle, latch clear)
      # churn does nothing.
      local prev_hash="${out_hash[$pane_id]:-}"
      out_hash[$pane_id]="$content_hash"
      local churn=0
      if [ -n "$prev_hash" ] && [ "$content_hash" != "$prev_hash" ] && [ "$redraw" -eq 0 ]; then
        churn=1
      fi
      if [ "$churn" -eq 1 ] && [ -n "${saw_work[$pane_id]:-}" ]; then
        settled[$pane_id]=""
      fi

      # The finish latch (this replaced hash-diff "work evidence", which
      # re-armed on every idle tick with output churn and storm-notified).
      local was_settled=0
      [ -n "${settled[$pane_id]:-}" ] && was_settled=1
      if [ "$idle" -eq 1 ]; then
        seen_settled[$pane_id]="1"
        # Debounce: the finish fires only on the SECOND consecutive idle
        # tick (was_settled = idle was observed on the previous tick too).
        # A single idle-looking frame mid-work (transient status-line render
        # gap) must not spend the latch; a real finish persists across ticks.
        if [ "$was_settled" -eq 1 ] && [ -n "${saw_work[$pane_id]:-}" ]; then
          # Observed work → two observed idle ticks: this IS the finish. The
          # latch clears here, so a finish notifies at most once per phase.
          saw_work[$pane_id]=""
          if [ -n "${visible[${win_idx}|${sess_name}]:-}" ]; then
            : # finish watched on-screen: consumed, never deferred
          else
            local win_name
            win_name=$(tmux display-message -t ":${win_idx}" -p '#{window_name}' 2>/dev/null)
            _notify "$win_name" "$win_idx" "$agent"
          fi
        fi
        settled[$pane_id]=1
      else
        settled[$pane_id]=""
        # Working tick. Latches as a work phase only after the pane has been
        # seen idle once since first sight — startup output is not work.
        if [ -n "${seen_settled[$pane_id]:-}" ]; then
          saw_work[$pane_id]="1"
        fi
      fi
    done < <(tmux list-panes -a -F "#{pane_id}|#{window_index}|#{pane_pid}|#{pane_width}|#{pane_height}|#{pane_title}|#{session_name}|#{pane_in_mode}" 2>/dev/null)

    sleep "$POLL_INTERVAL"
  done
}

case "${1:-status}" in
  start)  start_watcher ;;
  stop)   stop_watcher ;;
  status) status_watcher ;;
  *)      echo "Usage: $0 [start|stop|status]"; exit 1 ;;
esac
