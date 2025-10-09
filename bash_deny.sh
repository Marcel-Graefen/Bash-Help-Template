#!/usr/bin/env bash

# ========================================================================================
# Bash Deny
#
#
# Autor      : Marcel Gräfen
# Version    : 0.0.1
# Datum      : 2025-10-09
#
# Anforderungen:
#   - Bash 4.3+
#   - whiptail
#
# Repository :
#   https://github.com/Marcel-Graefen/
#
# Lizenz     : MIT License
# ========================================================================================

# caller_script=$(basename "${BASH_SOURCE[1]}")

# echo "$caller_script"

show_bash_source_table() {
  printf "%-3s | %-25s | %-15s | %-8s | %s\n" "Idx" "Script" "Function" "Line" "Exists"
  printf "%s\n" "----------------------------------------------------------------"

  for (( i=0; i<${#BASH_SOURCE[@]}; i++ )); do
    local script="${BASH_SOURCE[$i]}"
    local function="${FUNCNAME[$i]:-main}"
    local line=""

    if [[ $i -gt 0 ]]; then
      line="${BASH_LINENO[$((i-1))]}"
    else
      line="current"
    fi

    local exists="❌"
    [[ -f "$script" ]] && exists="✅"

    printf "%-3d | %-25s | %-15s | %-8s | %s\n" "$i" "$(basename "$script")" "$function" "$line" "$exists"
  done
}

# show_bash_source_table

declare -g SYS_MIN_WIDTH=50
declare -g SYS_MAX_WIDTH=100
declare -g SYS_MIN_HEIGHT=10
declare -g SYS_MAX_HEIGHT=40
declare -g SYS_PADDING=10



calculate_dimensions() {
  local content="$1"
  local TERM_WIDTH=$(tput cols)
  local TERM_HEIGHT=$(tput lines)
  local width height

  if [[ -f "$content" ]]; then
    # Datei
    local max_len=$(awk '{if(length>m)m=length}END{print m}' "$content" 2>/dev/null || echo 0)
    width=$((max_len + SYS_PADDING))
    height=$(wc -l < "$content" 2>/dev/null || echo 0)
    height=$((height + 4))  # Reduziertes Höhen-Padding
  else
    # Textinput
    local line_count=0
    local max_len=0

    while IFS= read -r line; do
      ((line_count++))
      if [[ -n "$line" ]]; then
        (( ${#line} > max_len )) && max_len=${#line}
      fi
    done < <(echo "$content")

    width=$((max_len + SYS_PADDING))
    height=$((line_count + 4))  # Reduziertes Höhen-Padding
  fi

  # Begrenzungen mit den globalen Variablen
  (( width < SYS_MIN_WIDTH )) && width=$SYS_MIN_WIDTH
  (( width > SYS_MAX_WIDTH )) && width=$SYS_MAX_WIDTH
  (( width > TERM_WIDTH - 5 )) && width=$((TERM_WIDTH - 5))
  (( height < SYS_MIN_HEIGHT )) && height=$SYS_MIN_HEIGHT
  (( height > SYS_MAX_HEIGHT )) && height=$SYS_MAX_HEIGHT
  (( height > TERM_HEIGHT - 3 )) && height=$((TERM_HEIGHT - 3))

  echo "$width $height"
}


file_content=$(cat "./meins.txt")

read -r width height < <(calculate_dimensions "$file_content")

Background="Hallo du doof"

Caller="$(realpath ${BASH_SOURCE[-1]})"

if whiptail --backtitle "$Background" \
               --title "TITLE" \
               --yes-button "Zu Help" \
               --no-button "Schließen" \
               --yesno "${file_content}${Caller}" "$height" "$width"; then

  echo "yes $?"

fi
