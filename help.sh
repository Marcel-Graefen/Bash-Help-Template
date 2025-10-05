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
    (( width > SYS_MAX_WIDTH )) && width=$SYS_MAX_WIDTH
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

  # Alle Unterfunktionen innerhalb der Hauptfunktion definieren
  _process_single_file() {
    local file="$1"

    # Deny-Check
    if _is_denied "$file"; then
      log_message "DEBUG" "Übersprungen (Deny): $file"
      return
    fi

    # Größen-Check
    if ! _check_file_size "$file"; then
      ((size_errors++))
      return
    fi

    # Leserechte-Check
    if [[ ! -r "$file" ]]; then
      log_message "ERROR" "Keine Leserechte: $file"
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
      log_message "DEBUG" "Übersprungen (Deny): $dir"
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
      log_message "WARNING" "Datei zu groß: $file (${file_size} bytes)"
      return 1
    fi
    return 0
  }

  _verify_file() {
    local file="$1"

    if declare -f verify_file >/dev/null; then
      if verify_file "$file"; then
        return 0
      else
        temp_verify_message="Verify fehlgeschlagen für: $file"
        return 1
      fi
    fi
    # Falls keine verify_file existiert, automatisch erfolgreich
    return 0
  }

  # === HAUPTPROGRAMM ===
  local found_dirs=()
  local found_files=()
  local verified_files=()
  local temp_verify_message=""

  local INT_MAX_FILE_SIZE="${MAX_FILE_SIZE:-10485760}"
  local INT_MAX_FILE_SIZE=$(convert_to_bytes "${MAX_FILE_SIZE:-10M}")


  # Counter für Fehlerbehandlung
  local dirs_found=0
  local files_found=0
  local files_verified=0
  local permission_errors=0
  local verify_errors=0
  local size_errors=0

  log_message "DEBUG" "Starte Suche in: $INPUT"

  # 1. Input-Typ erkennen und RealPath konvertieren
  local resolved_path
  if [[ -f "$INPUT" && "$INPUT" == *.ini ]]; then
    log_message "DEBUG" "Erkannt: Einzelne INI-Datei"
    resolved_path=$(realpath "$INPUT" 2>/dev/null || echo "$INPUT")
    _process_single_file "$resolved_path"

  elif [[ -d "$INPUT" ]]; then
    log_message "DEBUG" "Erkannt: Verzeichnis"
    resolved_path=$(realpath "$INPUT" 2>/dev/null || echo "$INPUT")
    _process_directory "$resolved_path"

  elif [[ "$INPUT" == *"*"* ]]; then
    log_message "DEBUG" "Erkannt: Wildcard Pattern"
    _process_wildcard "$INPUT"

  elif [[ "$INPUT" == *"**"* ]]; then
    log_message "DEBUG" "Erkannt: Rekursives Pattern"
    _process_recursive "$INPUT"

  else
    log_message "ERROR" "Ungültiger Pfad: $INPUT"
    show_error --code "201" --info "$INPUT" --exit
    return 1
  fi

  # 2. Gezielte Fehlerbehandlung basierend auf Counters
  if [[ $dirs_found -eq 0 ]]; then
    # Keine Ordner gefunden
    show_error --code "203" --info "$INPUT" --exit
    return 1
  elif [[ $files_found -eq 0 ]]; then
    # Ordner da, aber keine Dateien
    local dir_list=$(printf '%s\n' "${found_dirs[@]}")
    show_error --code "202" --info "$INPUT" --line "Durchsuchte Ordner:\n$dir_list" --exit
    return 1
  elif [[ $files_found -gt 0 && $files_verified -eq 0 ]]; then
    # Dateien da, aber alle Verify failed
    show_error --code "105" --info "$INPUT" --line "$temp_verify_message" --exit
    return 1
  elif [[ $permission_errors -gt 0 && $files_verified -eq 0 ]]; then
    # Nur Permission Errors, keine erfolgreichen Dateien
    show_error --code "204" --info "$INPUT" --exit
    return 1
  fi

  # 3. Erfolgreiche Ergebnisse in globale Arrays schreiben
  OUTPUT_DIRS=("${found_dirs[@]}")
  OUTPUT_FILES=("${verified_files[@]}")

  log_message "DEBUG" "Erfolg: ${#found_dirs[@]} Ordner, ${#verified_files[@]} Dateien"
  return 0

}

INPUT="./**/**"
DENY=("**/help.en.ini" "**/help.de.ini")
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
