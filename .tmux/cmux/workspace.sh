#!/usr/bin/env bash
# workspace.sh - Manage Claude Code workspaces in tmux
# Cross-platform: macOS and Linux

CLAUDE_CMD="claude"
OS="$(uname -s)"


# _launch_workspace: creates the tmux window, tags it, launches claude
# Args: name (for --name flag, can be empty), dir (working directory)
_launch_workspace() {
  local name="$1" dir="$2"

  mkdir -p "$dir"
  tmux new-window -n "${name:-claude}" -c "$dir"

  local win_id
  win_id=$(tmux display-message -p '#{window_id}')

  tmux set-option -w -t "$win_id" @cmux 1
  tmux set-option -w -t "$win_id" automatic-rename off
  tmux set-option -w -t "$win_id" allow-rename off
  tmux set-option -w -t "$win_id" window-status-style 'fg=colour156,bg=colour236'
  tmux set-option -w -t "$win_id" window-status-current-style 'fg=colour156,bg=cyan,bold'

  if [ -n "$name" ]; then
    tmux send-keys -t "$win_id" "$CLAUDE_CMD --name '$name'" Enter
  else
    tmux send-keys -t "$win_id" "$CLAUDE_CMD" Enter
  fi
}

cmd_new() {
  local input="$1"

  if [ -z "$input" ]; then
    _launch_workspace "" "$HOME"
    return
  fi

  # If input looks like a path (contains /), use it as the directory
  if [[ "$input" == */* ]]; then
    # Expand ~ if present
    local dir="${input/#\~/$HOME}"
    dir=$(cd "$dir" 2>/dev/null && pwd || echo "$dir")
    local name
    name=$(basename "$dir")
    mkdir -p "$dir"
    _launch_workspace "$name" "$dir"
    return
  fi

  # Plain name — use dated subfolder under ~/claude/
  local date_prefix
  date_prefix=$(date +%Y%m%d)
  local dir="$HOME/claude/${date_prefix}_${input}"
  if [ -d "$dir" ]; then
    local seq=2
    while [ -d "${dir}_${seq}" ]; do
      seq=$((seq + 1))
    done
    dir="${dir}_${seq}"
  fi
  mkdir -p "$dir"
  _launch_workspace "$input" "$dir"
}

cmd_list() {
  echo "Claude Workspaces:"
  echo "─────────────────────────────────────────────────────"
  printf "%-4s %-20s %-30s %-10s\n" "Win" "Name" "Directory" "Status"
  echo "─────────────────────────────────────────────────────"

  while IFS= read -r line; do
    local win_idx win_name pane_pid pane_cwd
    win_idx=$(echo "$line" | cut -d'|' -f1)
    win_name=$(echo "$line" | cut -d'|' -f2)
    pane_pid=$(echo "$line" | cut -d'|' -f3)
    pane_cwd=$(echo "$line" | cut -d'|' -f4)

    local has_claude=false
    local status="idle"
    while IFS= read -r pane_line; do
      local ppid
      ppid=$(echo "$pane_line" | cut -d'|' -f1)
      if ps -eo ppid,comm 2>/dev/null | grep -q "^ *${ppid} .*claude"; then
        has_claude=true
        local pane_id_check
        pane_id_check=$(echo "$pane_line" | cut -d'|' -f2)
        local last_line
        last_line=$(tmux capture-pane -t "$pane_id_check" -p -S -3 2>/dev/null | grep -v '^$' | tail -1)
        if echo "$last_line" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|Thinking|Reading|Writing|Running'; then
          status="working"
        elif echo "$last_line" | grep -qE '^\$|^\>|y/n|Y/n|approve|deny'; then
          status="waiting"
        else
          status="active"
        fi
        break
      fi
    done < <(tmux list-panes -t ":${win_idx}" -F '#{pane_pid}|#{pane_id}' 2>/dev/null)

    if [ "$has_claude" = true ]; then
      local short_cwd="${pane_cwd/#$HOME/~}"
      local status_color=""
      case "$status" in
        working) status_color="\033[33m" ;;
        waiting) status_color="\033[31m" ;;
        active)  status_color="\033[32m" ;;
        *)       status_color="\033[37m" ;;
      esac
      printf "%-4s %-20s %-30s ${status_color}%-10s\033[0m\n" "$win_idx" "$win_name" "$short_cwd" "$status"
    fi
  done < <(tmux list-windows -F '#{window_index}|#{window_name}|#{pane_pid}|#{pane_current_path}' 2>/dev/null)
}

cmd_send() {
  local window="$1"; shift
  local text="$*"
  [ -z "$window" ] || [ -z "$text" ] && { echo "Usage: workspace.sh send <window> <text>"; return 1; }
  tmux send-keys -t ":${window}.0" "$text" Enter
}

cmd_send_key() {
  local window="$1" key="$2"
  [ -z "$window" ] || [ -z "$key" ] && { echo "Usage: workspace.sh send-key <window> <key>"; return 1; }
  tmux send-keys -t ":${window}.0" "$key"
}

cmd_read() {
  local window="$1" lines="${2:-50}"
  [ -z "$window" ] && { echo "Usage: workspace.sh read <window> [lines]"; return 1; }
  tmux capture-pane -t ":${window}.0" -p -S "-${lines}"
}

cmd_kill() {
  local window="$1"
  [ -z "$window" ] && { echo "Usage: workspace.sh kill <window>"; return 1; }
  tmux send-keys -t ":${window}" C-c
  sleep 1
  tmux kill-window -t ":${window}"
  echo "Killed workspace $window"
}

cmd_focus() {
  local window="$1"
  [ -z "$window" ] && { echo "Usage: workspace.sh focus <window>"; return 1; }
  tmux select-window -t ":${window}"
}

cmd_split() {
  local window="$1" direction="${2:-right}"
  [ -z "$window" ] && { echo "Usage: workspace.sh split <window> [left|right|up|down]"; return 1; }
  local cwd
  cwd=$(tmux display-message -t ":${window}" -p '#{pane_current_path}')
  case "$direction" in
    left)  tmux split-window -t ":${window}" -hb -c "$cwd" ;;
    right) tmux split-window -t ":${window}" -h -c "$cwd" ;;
    up)    tmux split-window -t ":${window}" -vb -c "$cwd" ;;
    down)  tmux split-window -t ":${window}" -v -c "$cwd" ;;
    *)     echo "Invalid direction: $direction"; return 1 ;;
  esac
}

cmd_notify() {
  local window="$1"; shift
  local msg="$*"
  [ -z "$window" ] || [ -z "$msg" ] && { echo "Usage: workspace.sh notify <window> <message>"; return 1; }
  local win_name
  win_name=$(tmux display-message -t ":${window}" -p '#{window_name}' 2>/dev/null)
  tmux display-message "Notification [${win_name}]: ${msg}"
  if [ "$(uname -s)" = "Darwin" ]; then
    osascript <<EOF 2>/dev/null
display notification "${msg}" with title "cmux" subtitle "Window: ${win_name} (#${window})"
EOF
  fi
}

cmd_menu() {
  local current_pane="${1:-}"

  local -a actions=("New workspace" "Switch to pane" "Send to pane" "Read pane output" "Kill workspace" "Split workspace")
  local -a action_keys=("new" "pick" "send" "read" "kill" "split")
  local action_count=${#actions[@]}
  local selected=0

  # --- helpers ---
  _read_key() {
    IFS= read -rsn1 key
    if [ "$key" = $'\x1b' ]; then
      read -rsn2 -t 0.1 seq
      case "$seq" in
        '[A') echo "up" ;;
        '[B') echo "down" ;;
        '')   echo "escape" ;;
        *)    echo "" ;;
      esac
    else
      echo "$key"
    fi
  }

  # Collect claude panes into arrays (reused by multiple actions)
  _collect_panes() {
    pane_ids=()
    pane_labels=()
    pane_cwds=()
    pane_statuses=()

    while IFS= read -r line; do
      local pid wix wn pix ppid pcwd
      pid=$(echo "$line" | cut -d'|' -f1)
      wix=$(echo "$line" | cut -d'|' -f2)
      wn=$(echo "$line" | cut -d'|' -f3)
      pix=$(echo "$line" | cut -d'|' -f4)
      ppid=$(echo "$line" | cut -d'|' -f5)
      pcwd=$(echo "$line" | cut -d'|' -f6)

      [ "$wn" = "[tmux]" ] && wn=$(basename "$pcwd")

      ps -eo ppid,comm 2>/dev/null | grep -q "^ *${ppid} .*claude" || continue

      local status="active"
      local ll
      ll=$(tmux capture-pane -t "$pid" -p -S -3 2>/dev/null | grep -v '^$' | tail -1)
      if echo "$ll" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|Thinking|Reading|Writing|Running'; then
        status="working"
      elif echo "$ll" | grep -qE '^\$|^\>|y/n|Y/n|approve|deny'; then
        status="waiting"
      fi

      pane_ids+=("$pid")
      pane_labels+=("${wix}:${pix} ${wn}")
      pane_cwds+=("${pcwd/#$HOME/~}")
      pane_statuses+=("$status")
    done < <(tmux list-panes -a -F '#{pane_id}|#{window_index}|#{window_name}|#{pane_index}|#{pane_pid}|#{pane_current_path}' 2>/dev/null)
  }

  # Draw a pane list with selection highlight, returns via pane_selected
  _pick_pane() {
    local title="$1"
    local -a pane_ids pane_labels pane_cwds pane_statuses
    _collect_panes

    local pcount=${#pane_ids[@]}
    if [ "$pcount" -eq 0 ]; then
      clear
      echo "  No Claude panes found."
      read -rsn1 -p "  Press any key..."
      pane_selected=""
      return
    fi

    local psel=0
    # Pre-select current pane
    if [ -n "$current_pane" ]; then
      for i in $(seq 0 $((pcount - 1))); do
        [ "${pane_ids[$i]}" = "$current_pane" ] && psel=$i && break
      done
    fi

    while true; do
      clear
      echo "  ${title}"
      echo "  ──────────────────────────────────────────────────────────────────────────"
      echo ""
      printf "    %-12s %-22s %-38s %-10s\n" "Win:Pane" "Name" "Directory" "Status"
      echo "    ────────────────────────────────────────────────────────────────────────"
      for i in $(seq 0 $((pcount - 1))); do
        local prefix="    " sc="" reset="\033[0m"
        case "${pane_statuses[$i]}" in
          working) sc="\033[33m" ;; waiting) sc="\033[31m" ;; active) sc="\033[32m" ;; *) sc="\033[37m" ;;
        esac
        if [ "$i" -eq "$psel" ]; then
          prefix="  \033[7m>"
          printf "${prefix} %-12s %-22s %-38s ${sc}%-10s${reset}\033[0m\n" \
            "${pane_labels[$i]%% *}" "${pane_labels[$i]#* }" "${pane_cwds[$i]}" "${pane_statuses[$i]}"
        else
          printf "${prefix} %-12s %-22s %-38s ${sc}%-10s${reset}\n" \
            "${pane_labels[$i]%% *}" "${pane_labels[$i]#* }" "${pane_cwds[$i]}" "${pane_statuses[$i]}"
        fi
      done
      echo ""
      echo "  (j/k or arrows to move, Enter to select, Esc to go back)"

      local k
      k=$(_read_key)
      case "$k" in
        k|up)   [ "$psel" -gt 0 ] && psel=$((psel - 1)) ;;
        j|down) [ "$psel" -lt $((pcount - 1)) ] && psel=$((psel + 1)) ;;
        ''|' ') pane_selected="${pane_ids[$psel]}"; pane_selected_label="${pane_labels[$psel]}"; return ;;
        q|escape) pane_selected=""; return ;;
      esac
    done
  }

  # --- main action menu ---
  tput civis 2>/dev/null

  while true; do
    clear
    echo "  Claude Code Workspace Manager"
    echo "  ──────────────────────────────────────────────────────────────────────────"
    echo ""
    for i in $(seq 0 $((action_count - 1))); do
      if [ "$i" -eq "$selected" ]; then
        printf "  \033[7m> %-30s\033[0m\n" "${actions[$i]}"
      else
        printf "    %-30s\n" "${actions[$i]}"
      fi
    done
    echo ""
    echo "  (j/k or arrows to move, Enter to select, q/Esc to close)"

    local key
    key=$(_read_key)
    case "$key" in
      k|up)   [ "$selected" -gt 0 ] && selected=$((selected - 1)) ;;
      j|down) [ "$selected" -lt $((action_count - 1)) ] && selected=$((selected + 1)) ;;
      q|escape)
        tput cnorm 2>/dev/null
        return
        ;;
      ''|' ')
        local action="${action_keys[$selected]}"

        case "$action" in
          new)
            tput cnorm 2>/dev/null
            clear
            echo "  New Claude Workspace"
            echo "  ────────────────────"
            echo ""
            read -p "  Name: " name
            if [ -n "$name" ]; then
              ~/.tmux/cmux/workspace.sh new "$name"
            fi
            return
            ;;
          pick)
            local pane_selected="" pane_selected_label=""
            _pick_pane "Switch to Claude pane"
            if [ -n "$pane_selected" ]; then
              tput cnorm 2>/dev/null
              tmux select-window -t "$pane_selected"
              tmux select-pane -t "$pane_selected"
              return
            fi
            ;;
          send)
            local pane_selected="" pane_selected_label=""
            _pick_pane "Send text to Claude pane"
            if [ -n "$pane_selected" ]; then
              tput cnorm 2>/dev/null
              clear
              echo "  Send to: ${pane_selected_label}"
              echo "  ────────────────────"
              echo ""
              read -p "  Text: " txt
              if [ -n "$txt" ]; then
                tmux send-keys -t "$pane_selected" "$txt" Enter
              fi
              return
            fi
            ;;
          read)
            local pane_selected="" pane_selected_label=""
            _pick_pane "Read output from Claude pane"
            if [ -n "$pane_selected" ]; then
              tput cnorm 2>/dev/null
              tmux capture-pane -t "$pane_selected" -p -S -100 | less
              return
            fi
            ;;
          kill)
            local pane_selected="" pane_selected_label=""
            _pick_pane "Kill Claude pane (select pane)"
            if [ -n "$pane_selected" ]; then
              tput cnorm 2>/dev/null
              clear
              echo "  Kill pane: ${pane_selected_label}?"
              echo ""
              read -p "  Confirm (y/N): " confirm
              if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                tmux send-keys -t "$pane_selected" C-c
                sleep 1
                tmux kill-pane -t "$pane_selected"
              fi
              return
            fi
            ;;
          split)
            local pane_selected="" pane_selected_label=""
            _pick_pane "Split Claude workspace (select pane)"
            if [ -n "$pane_selected" ]; then
              tput cnorm 2>/dev/null
              local target_win
              target_win=$(tmux display-message -t "$pane_selected" -p '#{window_index}' 2>/dev/null)
              clear
              echo "  Split workspace: ${pane_selected_label}"
              echo ""
              echo "  Direction:"
              echo "    l) left    r) right"
              echo "    u) up      d) down"
              echo ""
              read -p "  Choice: " dir_choice
              local direction=""
              case "$dir_choice" in
                l) direction="left" ;; r) direction="right" ;; u) direction="up" ;; d) direction="down" ;;
              esac
              if [ -n "$direction" ]; then
                local cwd
                cwd=$(tmux display-message -t ":${target_win}" -p '#{pane_current_path}')
                case "$direction" in
                  left)  tmux split-window -t ":${target_win}" -hb -c "$cwd" ;;
                  right) tmux split-window -t ":${target_win}" -h -c "$cwd" ;;
                  up)    tmux split-window -t ":${target_win}" -vb -c "$cwd" ;;
                  down)  tmux split-window -t ":${target_win}" -v -c "$cwd" ;;
                esac
              fi
              return
            fi
            ;;
        esac
        ;;
    esac
  done
}

# Interactive picker with arrow keys and j/k vim bindings
# Operates at the pane level so every Claude pane is individually selectable.
cmd_pick() {
  local current_pane="${1:-}"

  local -a pane_ids=()
  local -a pane_labels=()
  local -a pane_cwds=()
  local -a pane_statuses=()

  while IFS= read -r line; do
    local pane_id win_idx win_name pane_idx pane_pid pane_cwd
    pane_id=$(echo "$line" | cut -d'|' -f1)
    win_idx=$(echo "$line" | cut -d'|' -f2)
    win_name=$(echo "$line" | cut -d'|' -f3)
    pane_idx=$(echo "$line" | cut -d'|' -f4)
    pane_pid=$(echo "$line" | cut -d'|' -f5)
    pane_cwd=$(echo "$line" | cut -d'|' -f6)

    # Fix [tmux] name that appears when a pane is in copy/scroll mode
    if [ "$win_name" = "[tmux]" ]; then
      win_name=$(basename "$pane_cwd")
    fi

    # Check if this pane is running claude
    if ! ps -eo ppid,comm 2>/dev/null | grep -q "^ *${pane_pid} .*claude"; then
      continue
    fi

    local status="active"
    local last_line
    last_line=$(tmux capture-pane -t "$pane_id" -p -S -3 2>/dev/null | grep -v '^$' | tail -1)
    if echo "$last_line" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|Thinking|Reading|Writing|Running'; then
      status="working"
    elif echo "$last_line" | grep -qE '^\$|^\>|y/n|Y/n|approve|deny'; then
      status="waiting"
    fi

    pane_ids+=("$pane_id")
    pane_labels+=("${win_idx}:${pane_idx} ${win_name}")
    pane_cwds+=("${pane_cwd/#$HOME/~}")
    pane_statuses+=("$status")
  done < <(tmux list-panes -a -F '#{pane_id}|#{window_index}|#{window_name}|#{pane_index}|#{pane_pid}|#{pane_current_path}' 2>/dev/null)

  local count=${#pane_ids[@]}
  if [ "$count" -eq 0 ]; then
    echo "No Claude panes found."
    read -rsn1 -p "Press any key to close..."
    return
  fi

  local selected=0
  if [ -n "$current_pane" ]; then
    for i in $(seq 0 $((count - 1))); do
      if [ "${pane_ids[$i]}" = "$current_pane" ]; then
        selected=$i
        break
      fi
    done
  fi

  tput civis 2>/dev/null

  _draw() {
    clear
    echo "  Claude Panes (j/k or arrows to move, Enter to select, q/Esc to cancel)"
    echo "  ──────────────────────────────────────────────────────────────────────────"
    echo ""
    printf "    %-12s %-22s %-38s %-10s\n" "Win:Pane" "Name" "Directory" "Status"
    echo "    ────────────────────────────────────────────────────────────────────────"
    for i in $(seq 0 $((count - 1))); do
      local prefix="    "
      local status_color=""
      local reset="\033[0m"
      case "${pane_statuses[$i]}" in
        working) status_color="\033[33m" ;;
        waiting) status_color="\033[31m" ;;
        active)  status_color="\033[32m" ;;
        *)       status_color="\033[37m" ;;
      esac

      if [ "$i" -eq "$selected" ]; then
        prefix="  \033[7m>"
        printf "${prefix} %-12s %-22s %-38s ${status_color}%-10s${reset}\033[0m\n" \
          "${pane_labels[$i]%% *}" "${pane_labels[$i]#* }" "${pane_cwds[$i]}" "${pane_statuses[$i]}"
      else
        printf "${prefix} %-12s %-22s %-38s ${status_color}%-10s${reset}\n" \
          "${pane_labels[$i]%% *}" "${pane_labels[$i]#* }" "${pane_cwds[$i]}" "${pane_statuses[$i]}"
      fi
    done
  }

  _draw

  while true; do
    IFS= read -rsn1 key

    if [ "$key" = $'\x1b' ]; then
      read -rsn2 -t 0.1 seq
      case "$seq" in
        '[A') key="up" ;;
        '[B') key="down" ;;
        '')   key="escape" ;;
        *)    continue ;;
      esac
    fi

    case "$key" in
      k|up)
        [ "$selected" -gt 0 ] && selected=$((selected - 1))
        ;;
      j|down)
        [ "$selected" -lt $((count - 1)) ] && selected=$((selected + 1))
        ;;
      ''|' ')
        tput cnorm 2>/dev/null
        local target="${pane_ids[$selected]}"
        tmux select-window -t "$target"
        tmux select-pane -t "$target"
        return
        ;;
      q|escape)
        tput cnorm 2>/dev/null
        return
        ;;
    esac

    _draw
  done
}

cmd_prompt_new() {
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local FZF_SOURCE="${SCRIPT_DIR}/fzf-source.sh"
  local CLAUDE_DIR="$HOME/claude"

  # Build initial candidate list (existing workspaces, most recent first)
  local initial_list=""
  if [ -d "$CLAUDE_DIR" ]; then
    initial_list=$(ls -1dt "$CLAUDE_DIR"/*/ 2>/dev/null | while read -r d; do basename "$d"; done)
  fi

  # Run fzf with dynamic reload for path completion
  local result
  result=$(echo "$initial_list" | fzf \
    --print-query \
    --header='Type name (fuzzy match) or path (/ ~ ./ for dirs) | Esc to cancel' \
    --prompt='Workspace: ' \
    --height=100% \
    --layout=reverse \
    --info=inline \
    --bind "change:reload:$FZF_SOURCE {q}" \
    --preview="
      item={};
      query={q};
      if [ -n \"\$item\" ]; then
        # Selected an item from the list
        if [ -d \"$CLAUDE_DIR/\$item\" ]; then
          echo \"Existing workspace: $CLAUDE_DIR/\$item\";
          echo '';
          ls -lt \"$CLAUDE_DIR/\$item\" 2>/dev/null | head -10;
        elif [ -d \"\${item/#\\~/$HOME}\" ]; then
          expanded=\"\${item/#\\~/$HOME}\";
          echo \"Directory: \$expanded\";
          echo '';
          ls -lt \"\$expanded\" 2>/dev/null | head -10;
        else
          echo \"New workspace: $CLAUDE_DIR/\$(date +%Y%m%d)_\$item\";
        fi;
      elif [ -n \"\$query\" ]; then
        if [[ \"\$query\" == /* || \"\$query\" == ~* || \"\$query\" == ./* ]]; then
          expanded=\"\${query/#\\~/$HOME}\";
          echo \"Path: \$expanded\";
        else
          echo \"New workspace: $CLAUDE_DIR/\$(date +%Y%m%d)_\$query\";
        fi;
      fi
    " \
    --preview-window=right:40%:wrap \
  ) || true

  # fzf --print-query outputs: line 1 = query, line 2 = selected item (if any)
  local query selected
  query=$(echo "$result" | sed -n '1p')
  selected=$(echo "$result" | sed -n '2p')

  # Nothing entered and nothing selected — cancelled or empty
  if [ -z "$query" ] && [ -z "$selected" ]; then
    return
  fi

  # Determine what to launch
  local input="${selected:-$query}"

  # If selected item is an existing workspace dir name
  if [ -n "$selected" ] && [ -d "$CLAUDE_DIR/$selected" ]; then
    local name
    name=$(echo "$selected" | sed 's/^[0-9]*_//')
    _launch_workspace "$name" "$CLAUDE_DIR/$selected"
    return
  fi

  # If it's a path (selected from dir listing or typed)
  if [[ "$input" == /* || "$input" == ~* || "$input" == ./* || "$input" == ../* ]]; then
    local dir="${input/#\~/$HOME}"
    dir=$(cd "$dir" 2>/dev/null && pwd || echo "$dir")
    local name
    name=$(basename "$dir")
    mkdir -p "$dir"
    _launch_workspace "$name" "$dir"
    return
  fi

  # Plain name — delegate to cmd_new which handles dated subfolder creation
  cmd_new "$input"
}

case "${1:-}" in
  new)        shift; cmd_new "$@" ;;
  prompt-new) cmd_prompt_new ;;
  list|ls)   cmd_list ;;
  pick)      shift; cmd_pick "$@" ;;
  send)      shift; cmd_send "$@" ;;
  send-key)  shift; cmd_send_key "$@" ;;
  read)      shift; cmd_read "$@" ;;
  kill)      shift; cmd_kill "$@" ;;
  focus)     shift; cmd_focus "$@" ;;
  split)     shift; cmd_split "$@" ;;
  notify)    shift; cmd_notify "$@" ;;
  menu)      shift; cmd_menu "$@" ;;
  *)
    echo "Usage: workspace.sh <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  new [name] [dir]       Create a new Claude Code workspace"
    echo "  list                   List all Claude Code workspaces"
    echo "  pick                   Interactive workspace picker"
    echo "  send <win> <text>      Send text to Claude in window"
    echo "  send-key <win> <key>   Send a key to Claude in window"
    echo "  read <win> [lines]     Read Claude's output"
    echo "  kill <win>             Kill a Claude workspace"
    echo "  focus <win>            Switch to workspace (clears notifications)"
    echo "  split <win> [dir]      Add split pane (left/right/up/down)"
    echo "  notify <win> <msg>     Send notification for workspace"
    echo "  menu                   Interactive popup menu"
    ;;
esac
