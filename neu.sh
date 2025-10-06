#!/usr/bin/env bash

# ========================================================================================
# Bash Help Template
#
# Vollständiges Script mit allen Kommentaren und Fehlerkorrekturen
#
# Autor      : Marcel Gräfen
# Version    : 0.0.1
# Datum      : 2025-10-05
#
# Anforderungen:
#   - Bash 4.3+
#   - whiptail
#
# Repository :
#   https://github.com/Marcel-Graefen/Bash-Help-Template
#
# Lizenz     : MIT License
# ========================================================================================

# Automatisch beste Sprache wählen
source "./globals.sh"

# Output Arrays für get_ini_files
declare -a OUTPUT_DIRS=()
declare -a OUTPUT_FILES=()

declare -A LANGUAGES       # Lokale Namen: "de" → "Deutsch"
declare -A LANGUAGES_EN    # Internationale Namen: "de" → "German"
declare -A LANGUAGE_FILES  # INI-Pfade: "de" → "/pfad/de.ini"

declare -A config_cache      # "de"=1, "en"=1
declare -A config_timestamp  # timestamp pro lang_code
declare -A config_by_lang    # "<lang_code>.<key>" = value

declare -A menu_order content_value content_keys
declare -a content_order


CURRENT_MENU=""
CURRENT_LANG_CODE="$CURRENT_LANG"


NAME_KEY="help"

declare -a verify_error_msg verify_error_code

# ========================================================================================
# HELPER FUNKTIONEN
# ========================================================================================

# =============================================================================
# convert_to_bytes
#
# Konvertiert human-readable Größenangaben in Bytes.
#
# Formate:
#   "512"    → 512 Bytes
#   "1K"     → 1024 Bytes
#   "1M"     → 1048576 Bytes
#   "1G"     → 1073741824 Bytes
#   "1T"     → 1099511627776 Bytes
#   "1P"     → 1125899906842624 Bytes
#
# Rückgabe:
#   Integer-Wert in Bytes
#   Default 10MB bei ungültiger Eingabe
# =============================================================================
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
      *) echo "$number" ;; # Bytes
    esac
  else
    echo "10485760" # Default 10MB
  fi
}

# =============================================================================
# calculate_dimensions
#
# Berechnet passende Whiptail-Dimensionen für Text oder Dateien
#
# Parameter:
#   $1 Text oder Pfad zu Datei
#
# Rückgabe:
#   Breite Höhe
# =============================================================================
calculate_dimensions() {
  local content="$1"
  local TERM_WIDTH=$(tput cols)
  local TERM_HEIGHT=$(tput lines)
  local width height

  if [[ -f "$content" ]]; then
    # Datei
    local max_len=$(awk '{if(length>m)m=length}END{print m}' "$content" 2>/dev/null || echo 0)
    width=$((max_len + SYS_PADDING*2))
    height=$(wc -l < "$content" 2>/dev/null || echo 0)
    height=$((height + SYS_PADDING*2))
  else
    # Textinput
    local line_count=0
    local max_len=0
    while IFS= read -r line; do
      (( ${#line} > max_len )) && max_len=${#line}
      ((line_count++))
    done < <(echo "$content")
    width=$((max_len + SYS_PADDING*2))
    height=$((line_count + SYS_PADDING*2))
  fi

  # Begrenzungen
  (( width < SYS_MIN_WIDTH )) && width=$SYS_MIN_WIDTH
  (( width > SYS_MAX_WIDTH )) && width=$SYS_MAX_WIDTH
  (( width > TERM_WIDTH - 10 )) && width=$((TERM_WIDTH - 10))
  (( height < SYS_MIN_HEIGHT )) && height=$SYS_MIN_HEIGHT
  (( height > SYS_MAX_HEIGHT )) && height=$SYS_MAX_HEIGHT
  (( height > TERM_HEIGHT - 5 )) && height=$((TERM_HEIGHT - 5))

  echo "$width $height"
}

# =============================================================================
# build_breadcrumb
#
# Erstellt Breadcrumb für Whiptail Backtitle
# =============================================================================
build_breadcrumb() {
  local bc=""

  if [[ ${#MENU_HISTORY[@]} -eq 0 && -z "$CURRENT_MENU" ]]; then
    bc="$TEXT_BACKTITLE"
  else
    bc="$TEXT_BACKTITLE"
    for h in "${MENU_HISTORY[@]}"; do
      bc="$bc › ${h//_/ }"
    done
    [[ -n "$CURRENT_MENU" ]] && bc="$bc › ${CURRENT_MENU//_/ }"
  fi

  [[ ! "$bc" =~ [a-zA-Z] ]] && bc="$TEXT_BACKTITLE"
  echo "$bc"
}

# =============================================================================
# log_message
#
# Loggt Nachricht falls LOG=true
# =============================================================================
log_message() {
  [[ "$LOG" != "true" ]] && return 0
  local level="$1" message="$2"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $level: $message" >> "$SYS_LOG_FILE"
}

# =============================================================================
# show_error
#
# Zeigt Fehler mit Whiptail an
# =============================================================================
show_error() {
  local error_type="ERROR" error_code="" extra_info="" extra_line="" should_exit=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--type)  error_type="$2"; shift 2 ;;
      -c|--code)  error_code="$2"; shift 2 ;;
      -i|--info)  extra_info="$2"; shift 2 ;;
      -l|--line)  extra_line="$2"; shift 2 ;;
      -x|--exit)  should_exit=true; shift ;;
      *) echo "Unknown option: $1" >&2; return 1 ;;
    esac
  done

  [[ -z "$error_code" ]] && { echo "Error: --code required" >&2; return 1; }

  local var_name="ERR_${error_code}"
  local message="${!var_name:-"Unknown error: $error_code"}"
  [[ -n "$extra_info" ]] && message="$message: $extra_info"
  [[ -n "$extra_line" ]] && message="$message\n\n$extra_line"
  log_message "ERROR" "$error_type ($error_code): $message"

  read -r width height < <(calculate_dimensions "$message")
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
}



get_meta_value() {
  local lang="$1"
  local key="$2"
  echo "${config_by_lang["$lang.$key"]:-}"
}


verify_file() {

  local -A _temp_global _temp_menu_order _temp_content_value _temp_content_key
  local -a _temp_section_order _temp_content_order
  local -A _key_counter


  local file="$1"
  local file_timestamp
  local meta_lang_code meta_lang_code meta_name


_parse_ini_to_arrays() {
  local file="$1"
  local current_section=""
  declare -A _key_counter=()  # für Duplikate

  while IFS= read -r line || [[ -n $line ]]; do
    # Whitespace trim
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue

    case "$line" in
      \#*|\;*) continue ;;  # Kommentare überspringen
      \[*\])                # Sektion
        current_section="${line:1:-1}"
        _temp_section_order+=("$current_section")
        ;;
      *=*)
        # Key-Value Paar verarbeiten
        local key="${line%%=*}"
        local value="${line#*=}"

        # Whitespace von Key und Value trimmen
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        if [[ -n "$current_section" ]]; then
          # Key-Counter für Duplikate
          _key_counter["$current_section.$key"]=$(( ${_key_counter["$current_section.$key"]:-0} + 1 ))
          local count="${_key_counter["$current_section.$key"]}"

          # Key mit Zähler suffix wenn nötig
          # local full_key="$key"
          # if [[ $count -gt 1 ]]; then
            full_key="${key}$((count))"
          # fi

          # In globale Variable schreiben
          _temp_global["$current_section.$key"]="$value"

          # Menu Order für nicht-type Keys
          if [[ "$key" != "type" ]]; then
            _temp_menu_order["$current_section"]="${_temp_menu_order["$current_section"]:-} $key"
          fi

          # Output Arrays für type=output Sections
          if [[ "$key" == "type" && "$value" == "output" ]]; then
            # Diese Section ist eine Output-Section
            _temp_content_order+=("$current_section")
            # Initialisiere die Content-Arrays für diese Section
          elif [[ -n "${_temp_global["$current_section.type"]}" && "${_temp_global["$current_section.type"]}" == "output" && "$key" != "type" ]]; then
            # Wenn current_section type=output hat, dann in content Arrays speichern
            _temp_content_value["$current_section.$full_key"]="$value"
            _temp_content_key["$current_section.$full_key"]="$full_key"
          fi
        else
          # Globale Keys (ohne Section)
          _key_counter[".$key"]=$(( ${_key_counter[".$key"]:-0} + 1 ))
          local count="${_key_counter[".$key"]}"

          local full_key="$key"
          if [[ $count -gt 1 ]]; then
            full_key="${key}$((count))"
          fi

          _temp_global["$key"]="$value"
        fi
        ;;
    esac
  done < "$file"
}

  # Validate full INI structure
  _validate_ini_structure() {

    local has_menu_sections=false
    local has_output_sections=false

    # Menü- und Output-Prüfung
    for section in "${_temp_section_order[@]}"; do
      local section_type="${_temp_global[$section.type]}"
      if [[ "$section_type" == "menu" ]]; then
        has_menu_sections=true
      elif [[ "$section_type" == "output" ]]; then
        has_output_sections=true
      fi
    done

    # Auto-Menü falls nur Output vorhanden
    if [[ "$has_menu_sections" != true && "$has_output_sections" == true ]]; then
      create_auto_menu_from_outputs
      has_menu_sections=true
    fi

    # Kein Menü → Fehler
    if [[ "$has_menu_sections" != true ]]; then
      verify_error_msg=""
      verify_error_code="104"
      return 1
    fi

    return 0
  }


  # Schritt 1: Meta nur parsen

  _parse_ini_to_arrays "$file" || { echo "${ERR_101}"; return 1; }
  meta_language="${_temp_global["meta.language"]:-}"
  meta_lang_code="${_temp_global["meta.lang_code"]:-}"
  meta_name="${_temp_global["meta.name"]:-}"
  file_timestamp=$(stat -c %Y "$file" 2>/dev/null || echo 0)

  # Meta validieren
  if [[ -z "$meta_language" || -z "$meta_lang_code" || -z "$meta_name" || "$meta_name" != "$NAME_KEY" ]]; then
    verify_error_msg=""
    verify_error_code="100"
    return 1
  fi

  # Schritt 2: Cache prüfen
  if [[ -n "${config_cache[$meta_lang_code]}" && $file_timestamp -le ${config_timestamp[$meta_lang_code]:-0} ]]; then
    # Bereits aktuelle Version im Cache → skip
    return 0
  fi

  # Schritt 3: Volle Struktur validieren
  _validate_ini_structure || { echo "${ERR_105}"; return 1; }

  # Schritt 4: Cache aktualisieren (bestehender Code)
  for key in "${!_temp_global[@]}"; do
    config_by_lang["$meta_lang_code.$key"]="${_temp_global[$key]}"
  done


    section_order=("${_temp_section_order[@]}")
    for section in "${!_temp_menu_order[@]}"; do
      menu_order["$section"]="${_temp_menu_order[$section]}"
    done

  for key in "${!_temp_content_value[@]}"; do
    content_value["$meta_lang_code.$key"]="${_temp_content_value[$key]}"
  done

  for key in "${!_temp_content_key[@]}"; do
    content_keys["$meta_lang_code.$key"]="${_temp_content_key[$key]}"
  done

  for section in "${_temp_content_order[@]}"; do
      content_order+=("$meta_lang_code.$section")
  done



  config_cache["$meta_lang_code"]=1
  config_timestamp["$meta_lang_code"]="$file_timestamp"

  # === NEU: globale Sprache registrieren ===
  LANGUAGES["$meta_lang_code"]="${_temp_global[meta.language]:-$meta_lang_code}"
  LANGUAGES_EN["$meta_lang_code"]="${_temp_global[meta.language_en]:-$meta_lang_code}"
  LANGUAGE_FILES["$meta_lang_code"]="$file"

  return 0

}


# ========================================================================================
# get_ini_files
# ========================================================================================

# FUNCTION GET INI FILES


get_ini_files() {

  local found_dirs=()
  local verified_files=()

  local INT_MAX_FILE_SIZE=$(convert_to_bytes "${MAX_FILE_SIZE:-10M}")
  local INT_MAX_RECURSION_DEPTH="${MAX_RECURSION_DEPTH:-5}"

  # Counter für Fehlerbehandlung
  local dirs_found=0
  local files_found=0
  local files_verified=0
  local permission_errors=0
  local verify_errors=0
  local size_errors=0


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

      verify_file "$file"

    else
      # ERROR mit globalem Error-Code
      verify_error_msg=""
      verify_error_code="700"
      return 1
    fi
  }

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



# FUNCTION SHOW LANGUAGE MENU
show_language_menu() {
  local menu_items=()
  local default_item=""

  # Menüeinträge vorbereiten
  for code in "${!LANGUAGES[@]}"; do
    # KEY: Englischname, VALUE: lokaler Name
    local eng_name="${LANGUAGES_EN[$code]}"
    local local_name="${LANGUAGES[$code]}"
    menu_items+=("$eng_name" "$local_name")
    [[ "$code" == "$CURRENT_LANG_CODE" ]] && default_item="$eng_name"
  done

  # Whiptail Menü anzeigen
  local choice
  choice=$(whiptail --backtitle "$(build_breadcrumb)" \
                    --title "$LANGUAGE_NAME" \
                    --ok-button "$BTN_OK" \
                    --cancel-button "$BTN_BACK" \
                    --default-item "$default_item" \
                    --menu "$BTN_LANGUAGE:" 0 $SYS_MIN_WIDTH 0 \
                    "${menu_items[@]}" 3>&1 1>&2 2>&3)
  local status=$?

  [[ $status -ne 0 ]] && return 0  # Abbrechen

  # Gewählten Sprachcode ermitteln
  local selected_code=""
  for code in "${!LANGUAGES_EN[@]}"; do
    if [[ "${LANGUAGES_EN[$code]}" == "$choice" ]]; then
      selected_code="$code"
      break
    fi
  done

  if [[ -z "$selected_code" ]]; then
    show_error -t "Language Error" -c 601 -i "$choice"
    return 1
  fi

  CURRENT_LANG_CODE="$selected_code"
  CURRENT_LANG_FILE="${LANGUAGE_FILES[$CURRENT_LANG_CODE]}"
  CURRENT_LANG_NAME="${LANGUAGES[$CURRENT_LANG_CODE]}"
  CURRENT_LANG_NAME_EN="${LANGUAGES_EN[$CURRENT_LANG_CODE]}"

  # Optional: globals.sh nur sourcen, wenn nötig
  source "./globals.sh" "$CURRENT_LANG_CODE"

  return 0

}


  validate_file_path() {
    local file="$1"

    # Security check for path traversal
    [[ "$file" =~ \.\. ]] && show_error -t "Security Error" -c 400 -i "$file" -x

    # Check if file exists and is readable
    [[ -f "$file" && -r "$file" ]] || return 1

    return 0
  }


  show_text_with_buttons() {

    local title="$1"
    local text="$2"
    local yes_button="${3:-$BTN_OK}"
    local no_button="$4"
    read -r width height < <(calculate_dimensions "$text")

    if [[ -z "$no_button" ]]; then
      # Only one button - use msgbox
      whiptail --backtitle "$(build_breadcrumb)" \
               --title "$title" \
               --ok-button "$yes_button" \
               --msgbox "$text" "$height" "$width"
    else
      # Two buttons - use yesno
      whiptail --backtitle "$(build_breadcrumb)" \
               --title "$title" \
               --yes-button "$yes_button" \
               --no-button "$no_button" \
               --yesno "$text" "$height" "$width"
    fi

  }

  #!===

  show_file_with_buttons() {

    local title="$1"
    local file="$2"
    local yes_button="${3:-$BTN_OK}"
    local no_button="$4"
    validate_file_path "$file" || {
      show_error -t "File Error" -c 200 -i "$file"
      return 1
    }
    local file_content=$(cat "$file")
    read -r width height < <(calculate_dimensions "$file_content")

    if [[ -z "$no_button" ]]; then
      # Only one button - use msgbox
      whiptail --backtitle "$(build_breadcrumb)" \
               --title "$title" \
               --ok-button "$yes_button" \
               --msgbox "$file_content" "$height" "$width"
    else
      # Two buttons - use yesno
      whiptail --backtitle "$(build_breadcrumb)" \
               --title "$title" \
               --yes-button "$yes_button" \
               --no-button "$no_button" \
               --yesno "$file_content" "$height" "$width"
    fi

  }



# FUNCTION SHOW CONTENT

show_output_content() {
  local section="$1"
  local title="${section//_/ }"

  local -a contents
  local -a types

  local full_section_key="$CURRENT_LANG_CODE.$section"

  # 1. Prüfen ob Section in content_order existiert (für Section-Reihenfolge)
  local section_exists=0
  for ordered_section in "${content_order[@]}"; do
    if [[ "$ordered_section" == "$full_section_key" ]]; then
      section_exists=1
      break
    fi
  done

  if [[ $section_exists -eq 0 ]]; then
    show_error -t "Content Error" -c 600 -i "$section"
    return 1
  fi

  local -a all_keys
  for key in "${!content_value[@]}"; do
    if [[ "$key" == "$full_section_key."* ]]; then
      local base_key="${key#$full_section_key.}"
      all_keys+=("$base_key")
    fi
  done

  # Keys sortieren für die REIHEFOLGE innerhalb der Section
  local -a sorted_keys
  mapfile -t sorted_keys < <(printf '%s\n' "${all_keys[@]}" | sort -V)


  if [[ ${#sorted_keys[@]} -eq 0 ]]; then
    show_error -t "Content Error" -c 600 -i "$section"
    return 1
  fi

  # 3. Werte in der RICHTIGEN REIHENFOLGE sammeln
  for key in "${sorted_keys[@]}"; do
    local full_value_key="$full_section_key.$key"
    local value="${content_value[$full_value_key]}"
    if [[ -n "$value" ]]; then
      contents+=("$value")
      types+=("$key")
    fi
  done

  local total_contents=${#contents[@]}

  # Rest der Funktion gleich...
  local current_index=0
  while [[ $current_index -lt $total_contents ]]; do
    local page_number=$((current_index + 1))
    local page_title="$title"
    (( total_contents > 1 )) && page_title="$title (Page $page_number/$total_contents)"

    local content="${contents[$current_index]}"
    local content_type="${types[$current_index]}"

    # Immer als Text anzeigen
    if [[ $total_contents -eq 1 ]]; then
      show_text_with_buttons "$page_title" "$content" "$BTN_CLOSE" ""
    elif [[ $page_number -eq 1 ]]; then
      show_text_with_buttons "$page_title" "$content" "$BTN_CLOSE" "$BTN_NEXT"
    elif [[ $page_number -eq $total_contents ]]; then
      show_text_with_buttons "$page_title" "$content" "$BTN_BACK" "$BTN_CLOSE"
    else
      show_text_with_buttons "$page_title" "$content" "$BTN_BACK" "$BTN_NEXT"
    fi

    local exit_status=$?
    if [[ $exit_status -eq 0 ]]; then
      (( page_number == 1 )) && break || ((current_index--))
    elif [[ $exit_status -eq 1 ]]; then
      (( page_number == total_contents )) && break || ((current_index++))
    else
      break
    fi
  done

  return 0
}
# FUNCTION SHOW HELP MENU

show_help_menu() {

  # Hilfsfunktion: Setzt CURRENT_MENU auf die erste Menüsektion der aktuellen Sprache
  _set_current_menu() {
    for key in "${!config_by_lang[@]}"; do
      IFS='.' read -r lang section type_key <<< "$key"
      if [[ "$lang" == "$CURRENT_LANG_CODE" && "$type_key" == "type" && "${config_by_lang[$key]}" == "menu" ]]; then
        CURRENT_MENU="$section"
        break
      fi
    done
  }

  # Setze CURRENT_MENU, falls leer
  [[ -z "$CURRENT_MENU" ]] && _set_current_menu
  [[ -z "$CURRENT_MENU" ]] && show_error -t "Menu Error" -c 301 -i "No menu sections found" --exit

  while true; do
    local menu_items=()
    local -a ordered_keys=()

      # Determine menu item order
      # FIX: Prüfe ob menu_order für CURRENT_MENU existiert
      if [[ -n "${menu_order[$CURRENT_MENU]+exists}" ]]; then
        read -ra ordered_keys <<< "${menu_order[$CURRENT_MENU]}"
      else
        # Fallback: collect all keys for current menu
        for key in "${!config_by_lang[${CURRENT_LANG_CODE}.@]}"; do
          if [[ "$key" == "$CURRENT_MENU."* && "$key" != "$CURRENT_MENU.type" ]]; then
            ordered_keys+=("${key#$CURRENT_MENU.}")
          fi
        done
      fi

      # Add menu items in determined order
      for key in "${ordered_keys[@]}"; do
        local full_key="${CURRENT_LANG_CODE}.${CURRENT_MENU}.${key}"
        [[ -n "${config_by_lang[$full_key]}" ]] && menu_items+=("$key" "${config_by_lang[$full_key]}")
      done



    # Keine Einträge → Fehler
    if [[ ${#menu_items[@]} -eq 0 ]]; then
      show_error -t "Menu Error" -c 301 -i "$CURRENT_MENU"
      exit 1
    fi

    # Sprache-Menü nur im Hauptmenü
    if [[ ${#MENU_HISTORY[@]} -eq 0 ]] && [[ ${#config_cache[@]} -gt 1 ]]; then
      local lang_upper=$(echo "$CURRENT_LANG_CODE" | tr '[:lower:]' '[:upper:]')
      menu_items+=("$lang_upper" "$BTN_LANGUAGE")
    fi

    # Cancel-Button
    local cancel_button
    [[ ${#MENU_HISTORY[@]} -eq 0 ]] && cancel_button="$BTN_EXIT" || cancel_button="$BTN_BACK"

    # Menügröße berechnen
    local max_len=0
    for i in "${menu_items[@]}"; do (( ${#i} > max_len )) && max_len=${#i}; done
    local TERM_WIDTH=$(tput cols)
    local width=$((max_len + SYS_PADDING*2))
    (( width < SYS_MIN_WIDTH )) && width=$SYS_MIN_WIDTH
    (( width > SYS_MAX_WIDTH )) && width=$SYS_MAX_WIDTH
    (( width > TERM_WIDTH - 10 )) && width=$((TERM_WIDTH - 10))
    local height=$(( ${#menu_items[@]} / 2 ))
    (( height < SYS_MIN_HEIGHT )) && height=$SYS_MIN_HEIGHT
    (( height > SYS_MAX_HEIGHT )) && height=$SYS_MAX_HEIGHT
    local menu_height=$height

    # Menü anzeigen
    local choice
    choice=$(whiptail --backtitle "$(build_breadcrumb)" \
              --title "${CURRENT_MENU//_/ }" \
              --ok-button "$BTN_OK" \
              --cancel-button "$cancel_button" \
              --menu "$TEXT_MENU_PROMPT" \
              "$menu_height" "$width" 0 \
              "${menu_items[@]}" 3>&1 1>&2 2>&3)
    local status=$?

    # Auswahl verarbeiten
    if [[ $status -eq 0 ]] && [[ -n "$choice" ]]; then
      # Sprache-Menü
      if [[ ${#MENU_HISTORY[@]} -eq 0 ]] && [[ "$choice" == "$(echo "$CURRENT_LANG_CODE" | tr '[:lower:]' '[:upper:]')" ]]; then
        show_language_menu
        _set_current_menu   # Reset CURRENT_MENU nach Sprachwechsel
        continue
      fi

      # Sub-Menü oder Output ermitteln
      local selected_value="${config_by_lang[${CURRENT_LANG_CODE}.${CURRENT_MENU}.${choice}]}"
      local selected_type="${config_by_lang[${CURRENT_LANG_CODE}.${selected_value}.type]:-}"

      if [[ "$selected_type" == "menu" ]]; then
          MENU_HISTORY+=("$CURRENT_MENU")
          CURRENT_MENU="$selected_value"
      elif [[ "$selected_type" == "output" ]]; then
          show_output_content "$selected_value"
      else
          show_error -t "Menu Error" -c 300
      fi


    elif [[ $status -eq 1 ]]; then
      # Back oder Exit
      if [[ ${#MENU_HISTORY[@]} -eq 0 ]]; then
        exit 0
      fi
      CURRENT_MENU="${MENU_HISTORY[-1]}"
      MENU_HISTORY=("${MENU_HISTORY[@]:0:$((${#MENU_HISTORY[@]}-1))}")
    elif [[ $status -eq 255 ]]; then
      exit 0
    fi
  done

}





INPUT="/home/marcel/Git_Public/Bash-Help-Template/neu/**/"
get_ini_files
show_help_menu
