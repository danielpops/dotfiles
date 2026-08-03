#!/usr/bin/env bash
# Claude Code statusLine command
# Shows: user@host:cwd (git branch) [time] tokens:N (X%)

# Read all input once, extract everything in a single jq call
input=$(cat)
eval "$(echo "$input" | jq -r '
  "sl_cwd=" + (.cwd // "" | @sh),
  "sl_effort=" + (.effort.level // "" | @sh),
  "sl_total_in=" + ((.context_window.total_input_tokens // 0) | tostring | @sh),
  "sl_total_out=" + ((.context_window.total_output_tokens // 0) | tostring | @sh),
  "sl_used_pct=" + ((.context_window.used_percentage // 0) | tostring | @sh),
  "sl_cost_usd=" + ((.cost.total_cost_usd // 0) | tostring | @sh)
' 2>/dev/null)" 2>/dev/null

# Fallback for cwd
if [ -z "$sl_cwd" ]; then
    sl_cwd="$(pwd)"
fi

# Display path with $HOME abbreviated to ~ (keep sl_cwd intact for git)
sl_cwd_display="$sl_cwd"
if [ -n "$HOME" ]; then
    case "$sl_cwd" in
        "$HOME") sl_cwd_display="~" ;;
        "$HOME"/*) sl_cwd_display="~${sl_cwd#"$HOME"}" ;;
    esac
fi

# ANSI color codes (bold)
BBlue='\033[1;34m'
BGreen='\033[1;32m'
BYellow='\033[1;33m'
BCyan='\033[1;36m'
BPurple='\033[1;35m'
BRed='\033[1;31m'
Color_Off='\033[0m'

# Git branch (skip optional locks to avoid hanging)
git_part=""
if git_branch=$(git -C "$sl_cwd" --no-optional-locks branch --show-current 2>/dev/null) && [ -n "$git_branch" ]; then
    git_part=" ($git_branch)"
fi

# Thinking effort level (.effort.level: low|medium|high|xhigh|max)
effort_part=""
if [ -n "$sl_effort" ]; then
    effort_part=" [${sl_effort}]"
fi

# Time
time_part=$(date +%H:%M:%S)

# Session cost (formatted to cents). LC_ALL=C forces '.' as the decimal
# separator -- in comma-decimal locales printf rejects "1.23456" as invalid.
# (LC_ALL, not LC_NUMERIC: LC_ALL in the caller's env would override the latter.)
sl_cost_usd="${sl_cost_usd:-0}"
cost_part=$(LC_ALL=C printf '$%.2f' "$sl_cost_usd" 2>/dev/null) || cost_part='$0.00'

# Token count and context usage percentage
tokens_part=""
sl_total_in="${sl_total_in:-0}"
sl_total_out="${sl_total_out:-0}"
sl_used_pct="${sl_used_pct:-0}"
total_tokens=$(( sl_total_in + sl_total_out ))
if [ "$total_tokens" -gt 0 ] 2>/dev/null; then
    tokens_part=" tokens:${total_tokens}"
    used_pct_rounded=$(LC_ALL=C printf "%.0f" "$sl_used_pct" 2>/dev/null) || used_pct_rounded=0
    tokens_part="${tokens_part} (${used_pct_rounded}%)"
fi

printf '%b' "${BBlue}$(whoami)@${BGreen}$(hostname -s):${BYellow}${sl_cwd_display}${BCyan}${git_part}${BGreen}${effort_part}${BPurple} [${time_part}]${BCyan}${tokens_part} ${BRed}(${cost_part})${Color_Off}"
