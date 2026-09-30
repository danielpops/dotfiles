#!/usr/bin/env bash
# agent.sh - Shared agent (claude / pi) detection and launch logic for cmux.
# Sourced by workspace.sh, claude-watch.sh, pane-info.sh.

CMUX_DEFAULT_AGENT="claude"

# Marker file written into each workspace dir recording which agent launched it,
# so resuming picks the right one. Absent marker = claude (all pre-pi workspaces).
CMUX_AGENT_MARKER=".cmux-agent"

# cmux_agent_cmd <agent> — the binary to invoke
cmux_agent_cmd() {
  case "$1" in
    pi) echo "pi" ;;
    *)  echo "claude" ;;
  esac
}

# cmux_agent_label <agent> — short display label for pickers/status
cmux_agent_label() {
  case "$1" in
    pi) echo "pi" ;;
    *)  echo "cl" ;;
  esac
}

# cmux_agent_valid <agent> — 0 if we know this agent
cmux_agent_valid() {
  case "$1" in
    claude|pi) return 0 ;;
    *)         return 1 ;;
  esac
}

# cmux_write_marker <dir> <agent>
cmux_write_marker() {
  local dir="$1" agent="$2"
  [ -d "$dir" ] || return 0
  printf '%s\n' "$agent" > "${dir}/${CMUX_AGENT_MARKER}" 2>/dev/null
}

# cmux_read_marker <dir> — echoes recorded agent, or the default
cmux_read_marker() {
  local dir="$1" agent=""
  [ -f "${dir}/${CMUX_AGENT_MARKER}" ] && agent=$(tr -d '[:space:]' < "${dir}/${CMUX_AGENT_MARKER}" 2>/dev/null)
  cmux_agent_valid "$agent" && echo "$agent" || echo "$CMUX_DEFAULT_AGENT"
}

# cmux_pane_agent <pane_pid> — echoes "claude" or "pi" if a child of the pane's
# shell is running that agent, else nothing (return 1).
#
# Matches on args, not comm: /opt/homebrew/bin/claude is a bash wrapper script,
# so its comm is "/bin/bash" and a comm-based match never fires. Restricted to
# $USER's processes so a shared host doesn't cross-detect other users' shells.
cmux_pane_agent() {
  local pane_pid="$1"
  [ -z "$pane_pid" ] && return 1

  local args found=""
  while IFS= read -r args; do
    if [[ "$args" =~ (^|/)claude([[:space:]]|$) ]]; then
      found="claude"; break
    elif [[ "$args" =~ (^|/)pi([[:space:]]|$) ]]; then
      found="pi"; break
    fi
  done < <(ps -u "$USER" -o ppid=,args= 2>/dev/null \
             | awk -v p="$pane_pid" '$1 == p { $1 = ""; sub(/^[[:space:]]+/, ""); print }')

  [ -n "$found" ] || return 1
  echo "$found"
}

# cmux_pane_has_agent <pane_pid> — quiet predicate form
cmux_pane_has_agent() {
  cmux_pane_agent "$1" >/dev/null 2>&1
}

# cmux_pane_status <pane_id> — "working" | "waiting" | "active"
#
# Both claude and pi show a vim-mode marker (-- INSERT --/INSERT) when idle at
# the prompt. Spinner glyphs and progress verbs mean actively working.
cmux_pane_status() {
  local pane_id="$1" last_line
  last_line=$(tmux capture-pane -t "$pane_id" -p -S -3 2>/dev/null | grep -v '^$' | tail -1)
  if echo "$last_line" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|Thinking|Reading|Writing|Running|esc to interrupt'; then
    echo "working"
  elif echo "$last_line" | grep -qE '^\$|^\>|y/n|Y/n|approve|deny|Do you want to'; then
    echo "waiting"
  else
    echo "active"
  fi
}

# cmux_launch_cmd <agent> <mode> <name> — the shell command line to send to a pane.
# mode: "" (fresh session) or "resume".
#
# claude resumes by display name (claude --resume '<name>'). pi has no
# --resume <name>; its --resume is an interactive picker, so a per-workspace
# resume maps to --continue (most recent session in that directory).
cmux_launch_cmd() {
  local agent="$1" mode="$2" name="$3"
  local cmd
  cmd=$(cmux_agent_cmd "$agent")

  if [ "$mode" = "resume" ]; then
    case "$agent" in
      # --name is passed alongside --continue so the resumed session keeps its
      # display name; without it the tmux-title extension falls back to "pi".
      pi) if [ -n "$name" ]; then echo "$cmd --continue --name '$name'"; else echo "$cmd --continue"; fi ;;
      *)  if [ -n "$name" ]; then echo "$cmd --resume '$name'"; else echo "$cmd --resume"; fi ;;
    esac
  else
    if [ -n "$name" ]; then echo "$cmd --name '$name'"; else echo "$cmd"; fi
  fi
}
