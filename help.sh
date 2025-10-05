#!/usr/bin/env bash

# ========================================================================================
# Bash Help Template
#
#
# @author      : Marcel Gräfen
# @version     : 0.0.1
# @date        : 2025-10-04
#
# @requires    : Bash 4.3+
# @requires    : whiptail
#
# @see         : https://github.com/Marcel-Graefen/Bash-Help-Template
#
# @copyright   : Copyright (c) 2025 Marcel Gräfen
# @license     : MIT License
# ========================================================================================

# Automatisch beste Sprache wählen
source "./globals.sh"

  # === HELPER FUNKTIONS ===

  # =============================================================================
  # FUNKTION: convert_to_bytes
  #
  # KONVERTIERT human-readable Größenangaben in Bytes.
  #
  # UNTERSTÜTZTE FORMATE:
  #   "512"    → 512 Bytes
  #   "1K"     → 1024 Bytes      (1 Kilobyte)
  #   "1M"     → 1048576 Bytes   (1 Megabyte)
  #   "1G"     → 1073741824 Bytes (1 Gigabyte)
  #   "1T"     → 1099511627776 Bytes (1 Terabyte)
  #   "1P"     → 1125899906842624 Bytes (1 Petabyte)
  #
  # SYNTAX:
  #   convert_to_bytes "10M"    # Gibt 10485760 zurück
  #   convert_to_bytes "2.5G"   # Funktioniert NICHT (keine Dezimalzahlen)
  #   convert_to_bytes "invalid" # Gibt Default-Wert zurück
  #
  # GLOBALE BEISPIELE:
  #   MAX_MEMORY="2G"           → 2147483648 Bytes
  #   CACHE_SIZE="256M"         → 268435456 Bytes
  #   UPLOAD_LIMIT="50M"        → 52428800 Bytes
  #   LOG_FILE_SIZE="100K"      → 102400 Bytes
  #   BACKUP_SIZE="1T"          → 1099511627776 Bytes
  #
  # RETURN:
  #   Gibt Integer-Wert in Bytes zurück
  #   Bei ungültiger Eingabe: Default 10485760 (10MB)
  # =============================================================================
  # Human-readable zu Bytes konvertieren
  convert_to_bytes() {
    local size="$1"
    if [[ "$size" =~ ^([0-9]+)([KMGTP]?)$ ]]; then
      local number="${BASH_REMATCH[1]}"
      local unit="${BASH_REMATCH[2]}"
      case "$unit" in
        K) echo $(( number * 1024 )) ;;
        M) echo $(( number * 1024 * 1024 )) ;;
        G) echo $(( number * 1024 * 1024 * 1024 )) ;;
        T) echo $(( number * 1024 * 1024 * 1024 * 1024 )) ;;
        P) echo $(( number * 1024 * 1024 * 1024 * 1024 * 1024 )) ;;
        *) echo "$number" ;;  # Keine Unit = Bytes
      esac
    else
      echo "10485760"  # Default: 10MB
    fi
  }

  # FUNCTION CALCULATE DIMENSIONS

  calculate_dimensions() {

    local content="$1"
    local TERM_WIDTH=$(tput cols)
    local TERM_HEIGHT=$(tput lines)
    local width height

    if [[ -f "$content" ]]; then

      # File Handling
      local max_len=$(awk '{if(length>m)m=length}END{print m}' "$content" 2>/dev/null || echo 0)
      width=$((max_len + SYS_PADDING*2))
      height=$(wc -l < "$content" 2>/dev/null || echo 0)
      height=$(echo "$height" | tr -d '[:space:]')
      height=$((height + SYS_PADDING*2))
    else
      # Text-Input Handling
      local line_count=0
      local max_len=0

      # Use process substitution for the while loop
      while IFS= read -r line; do
        (( ${#line} > max_len )) && max_len=${#line}
        ((line_count++))
      done < <(echo "$content")

      width=$((max_len + SYS_PADDING*2))
      height=$((line_count + SYS_PADDING*2))
    fi

    # Size limitations
    (( width < SYS_MIN_WIDTH )) && width=$SYS_MIN_WIDTH
    (( width > _MAX_WIDTH )) && width=$SYS_MAX_WIDTH
    (( width > TERM_WIDTH - 10 )) && width=$((TERM_WIDTH - 10))
    (( height < SYS_MIN_HEIGHT )) && height=$SYS_MIN_HEIGHT
    (( height > SYS_MAX_HEIGHT )) && height=$SYS_MAX_HEIGHT
    (( height > TERM_HEIGHT - 5 )) && height=$((TERM_HEIGHT - 5))

    echo "$width $height"

  }

  # FUNCTION BUILD VREADCRUMB

  build_breadcrumb() {

    local bc=""

    # No history and no current menu -> use default backtitle
    if [[ ${#MENU_HISTORY[@]} -eq 0 && -z "$CURRENT_MENU" ]]; then
      bc="$TEXT_BACKTITLE"
    else
      # Start with BACKTITLE or default, then add history path
      bc="$TEXT_BACKTITLE"
      for h in "${MENU_HISTORY[@]}"; do
        bc="$bc › ${h//_/ }"  # Replace underscores with spaces for display
      done
      # Add current menu if exists
      [[ -n "$CURRENT_MENU" ]] && bc="$bc › ${CURRENT_MENU//_/ }"
    fi

    # Fallback to default if breadcrumb contains no letters (invalid state)
    if [[ ! "$bc" =~ [a-zA-Z] ]]; then
      bc="$TEXT_BACKTITLE"
    fi

    echo "$bc"

  }

  #!===


  #!===

  log_message() {
    [[ "$LOG" != "true" ]] && return 0
    local level="$1" message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $level: $message" >> "$SYS_LOG_FILE"
  }

  #!===

  # FUNCTION SHOW ERROR

  show_error() {

      local error_type="ERROR" error_code="" extra_info="" extra_line="" should_exit=false

      # Flags parsen
      while [[ $# -gt 0 ]]; do
          case "$1" in
              -t|--type)  error_type="$2"               ; shift 2   ;;
              -c|--code)  error_code="$2"               ; shift 2   ;;
              -i|--info)  extra_info="$2"               ; shift 2   ;;
              -l|--line)  extra_line="$2"               ; shift 2   ;;
              -x|--exit)  should_exit=true              ; shift     ;;
              *)          echo "Unknown option: $1" >&2 ; return 1  ;;
          esac
      done

      # Validation
      [[ -z "$error_code" ]] && { echo "Error: --code required" >&2; return 1; }

      # Get error message
      local var_name="ERR_${error_code}"
      local message="${!var_name:-"Unknown error: $error_code"}"

      # COMBINE BOTH TYPES OF INFORMATION
      [[ -n "$extra_info" ]] && message="$message: $extra_info"
      [[ -n "$extra_line" ]] && message="$message\n\n$extra_line"

      # Loggen
      log_message "ERROR" "$error_type ($error_code): $message"

      # Calculate dimensions
      read -r width height < <(calculate_dimensions "$message")

      # Show dialog
      if [[ "$should_exit" == true ]]; then
          whiptail --backtitle "$(build_breadcrumb)" \
                  --title "$error_type" \
                  --ok-button "$BTN_CLOSE" \
                  --msgbox "$message" 0 "$width"
          exit 1
      else
          whiptail --backtitle "$(build_breadcrumb)" \
                  --title "$error_type" \
                  --ok-button "$BTN_OK" \
                  --msgbox "$message" 0 "$width"
      fi

      return 0
  }

  #!===


get_ini_files() {
  # INPUT in Array umwandeln falls String
  local input_array=()
  if [[ "$(declare -p INPUT 2>/dev/null)" =~ "declare -a" ]]; then
    # INPUT ist Array
    input_array=("${INPUT[@]}")
  else
    # INPUT ist String
    input_array=("$INPUT")
  fi

  # Interne Variable für normalisierten Input
  local normalized_inputs=()

  _normalize_input_path() {
    local path="$1"
    local result="$path"

    # Wenn es ein Wildcard ist und ein führendes . hat, Realpath holen und . ersetzen
    if [[ "$path" == .* && "$path" == *"*"* ]]; then
      local current_dir=$(realpath ".")
      result="${path/./$current_dir}"
    # NUR für existierende Pfade ohne Wildcards Realpath anwenden
    elif [[ "$path" != *"*"* && -e "$path" ]]; then
      # Alles was mit . beginnt wird direkt in Realpath geändert
      if [[ "$path" == .* ]]; then
        result=$(realpath "$path" 2>/dev/null || echo "$path")
      # Alles was KEIN . oder / hat wird in Realpath geändert
      elif [[ "$path" != */* && "$path" != .* ]]; then
        result=$(realpath "$path" 2>/dev/null || echo "$path")
      fi
    fi

    # Alles was ein VERZEICHNIS ist und KEIN / am Ende hat wird / angehängt
    if [[ -d "$result" && "$result" != */ ]]; then
      result="$result/"
    fi

    echo "$result"
  }

  # Jeden Input normalisieren
  for input_item in "${input_array[@]}"; do
    local normalized=$(_normalize_input_path "$input_item")
    normalized_inputs+=("$normalized")
  done

  # Alle Unterfunktionen innerhalb der Hauptfunktion definieren
  _process_single_file() {
    local file="$1"

    # Deny-Check
    if _is_denied "$file"; then
      log_message "$TYPE_DEBUG" "$TYPE_FILE ${TEXT_SKIPPED_DENY}: $file"
      return
    fi

    # Größen-Check
    if ! _check_file_size "$file"; then
      ((size_errors++))
      return
    fi

    # Leserechte-Check
    if [[ ! -r "$file" ]]; then
      log_message "$TYPE_ERROR" "$TYPE_FILE ${TEXT_NO_READ_PERMISSION}: $file"
      ((permission_errors++))
      return
    fi

    ((files_found++))

    # Verify-Check
    if _verify_file "$file"; then
      verified_files+=("$file")
      ((files_verified++))
    else
      ((verify_errors++))
    fi
  }

  _process_directory() {
    local dir="$1"

    # Deny-Check für gesamten Ordner
    if _is_denied "$dir"; then
      log_message "$TYPE_DEBUG" "$TYPE_DIRECTORY ${TEXT_SKIPPED_DENY}: $dir"
      return
    fi

    found_dirs+=("$dir")
    ((dirs_found++))

    # Dateien im Verzeichnis finden
    while IFS= read -r file; do
      [[ -n "$file" ]] && _process_single_file "$file"
    done < <(find "$dir" -maxdepth 1 -name "*.ini" -type f 2>/dev/null)
  }

  _process_wildcard() {
    local pattern="$1"

    # Wildcard auflösen
    for file in $pattern; do
      if [[ -f "$file" && "$file" == *.ini ]]; then
        local resolved_file=$(realpath "$file" 2>/dev/null || echo "$file")
        _process_single_file "$resolved_file"
      elif [[ -d "$file" ]]; then
        local resolved_dir=$(realpath "$file" 2>/dev/null || echo "$file")
        _process_directory "$resolved_dir"
      fi
    done
  }

  _process_recursive() {
    local pattern="$1"
    local base_dir="." depth=""

    # Tiefe bestimmen
    if [[ "$pattern" == *"/**" ]]; then
      base_dir="${pattern%/**}"
      depth="-maxdepth $INT_MAX_RECURSION_DEPTH"
    else
      base_dir="${pattern%%/**/*}"
      depth=""
    fi

    [[ -z "$base_dir" ]] && base_dir="."

    # Rekursiv suchen
    while IFS= read -r file; do
      [[ -n "$file" ]] && _process_single_file "$file"
    done < <(find "$base_dir" $depth -name "*.ini" -type f 2>/dev/null)
  }

  _is_denied() {
    local path="$1"
    for denied in "${DENY[@]}"; do
      if [[ "$path" == $denied ]]; then
        return 0
      fi
    done
    return 1
  }

  _check_file_size() {
    local file="$1"
    local file_size=$(stat -c %s "$file" 2>/dev/null || echo 0)

    if [[ $file_size -gt $INT_MAX_FILE_SIZE ]]; then
      log_message "$TYPE_WARNING" "$TYPE_FILE ${TEXT_FILE_TOO_LARGE}: $file (${file_size} bytes)"
      return 1
    fi
    return 0
  }

  _verify_file() {
    local file="$1"

    # Globale Variablen zurücksetzen
    verify_error_msg=""
    verify_error_code=""

    if declare -f verify_file >/dev/null; then
      local message
      local code

      message=$(verify_file "$file" 2>&1)
      code=$?

      if [[ $code -eq 0 ]]; then
        return 0
      else
        # In globale Variablen schreiben
        verify_error_msg="${message:-${ERR_105}}"
        verify_error_code="$code"
        return 1
      fi
    else
      # ERROR mit globalem Error-Code
      verify_error_msg=""
      verify_error_code="700"
      return 1
    fi
  }

  # === HAUPTPROGRAMM ===
  local found_dirs=()
  local verified_files=()
  local verify_error_msg=""
  local verify_error_code=""

  local INT_MAX_FILE_SIZE=$(convert_to_bytes "${MAX_FILE_SIZE:-10M}")
  local INT_MAX_RECURSION_DEPTH="${MAX_RECURSION_DEPTH:-5}"

  # Counter für Fehlerbehandlung
  local dirs_found=0
  local files_found=0
  local files_verified=0
  local permission_errors=0
  local verify_errors=0
  local size_errors=0

  log_message "$TYPE_DEBUG" "${TEXT_SEARCH_START}: $INPUT"

  # Jeden normalisierten Input verarbeiten
  for normalized_input in "${normalized_inputs[@]}"; do
    # 1. Input-Typ erkennen und verarbeiten
    local resolved_path

    if [[ -f "$normalized_input" && "$normalized_input" == *.ini ]]; then
      log_message "$TYPE_DEBUG" "${TEXT_RECOGNIZED_SINGLE_FILE}"
      resolved_path=$(realpath "$normalized_input" 2>/dev/null || echo "$normalized_input")
      _process_single_file "$resolved_path"

    elif [[ -d "$normalized_input" ]]; then
      log_message "$TYPE_DEBUG" "${TEXT_RECOGNIZED_DIRECTORY}"
      resolved_path=$(realpath "$normalized_input" 2>/dev/null || echo "$normalized_input")
      _process_directory "$resolved_path"

    elif [[ "$normalized_input" == *"*"* ]]; then
      log_message "$TYPE_DEBUG" "${TEXT_RECOGNIZED_WILDCARD}"
      _process_wildcard "$normalized_input"

    elif [[ "$normalized_input" == *"**"* ]]; then
      log_message "$TYPE_DEBUG" "${TEXT_RECOGNIZED_RECURSIVE}"
      _process_recursive "$normalized_input"

    else
      log_message "$TYPE_ERROR" "${TEXT_INVALID_PATH}: $normalized_input"
      show_error -t "$TYPE_FILE" --code "201" --info "$normalized_input" --exit
      return 1
    fi
  done

  # Übersichtliche Fehlerbehandlung
  [[ $dirs_found -eq 0 ]] && { show_error -t "$TYPE_DIRECTORY" --code "203" --info "$INPUT" --exit; return 1; }
  [[ $files_found -eq 0 ]] && { show_error -t "$TYPE_FILE" --code "202" --info "$INPUT" --line "${TEXT_SEARCHED_DIRECTORY}:\n$(printf '%s\n' "${found_dirs[@]}")" --exit; return 1; }
  [[ $permission_errors -gt 0 && $files_verified -eq 0 ]] && { show_error -t "$TYPE_FILE" --code "204" --info "$INPUT" --exit; return 1; }
  [[ -n "$verify_error_code" || -n "$verify_error_msg" ]] && { show_error -t "$TYPE_VERIFY" --code "$verify_error_code" --line "$verify_error_msg" --exit; return 1; }

  # Erfolgreiche Ergebnisse in globale Arrays schreiben
  OUTPUT_DIRS=("${found_dirs[@]}")
  OUTPUT_FILES=("${verified_files[@]}")

  log_message "$TYPE_DEBUG" "${TEXT_SUCCESS}: ${#found_dirs[@]} ${TEXT_DIRECTORIES}, ${#verified_files[@]} ${TEXT_FILES}"
  return 0
}

INPUT="./**"
get_ini_files

# Nach Aufruf stehen Ergebnisse in:
echo "Gefundene Dateien: ${#OUTPUT_FILES[@]}"
echo "Gefundene Ordner: ${#OUTPUT_DIRS[@]}"

# Dateien durchlaufen
for file in "${OUTPUT_FILES[@]}"; do
  echo "Verarbeite: $file"
done

# Ordner durchlaufen
for dir in "${OUTPUT_DIRS[@]}"; do
  echo "Durchsucht: $dir"
done
