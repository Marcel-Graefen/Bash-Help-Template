#!/usr/bin/env bash

# ========================================================================================
# Bash Lnguage
#
#
# Autor      : Marcel Gräfen
# Version    : 0.0.1
# Datum      : 2025-10-08
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

# UNIVERSAL DEFAULT LANGUAGE - COMPLETE 4-DIGIT SYSTEM

## BASIC INFO
declare -g LANG_CODE="en"
declare -g LANGUAGE_NAME="English"
declare -g LANGUAGE_NAME_EN="English"

# =============================================================================
# TEXT CODES (1000-1999) - UI ELEMENTS
# =============================================================================
declare -g TXT_1000="Continue"
declare -g TXT_1001="OK"
declare -g TXT_1002="Cancel"
declare -g TXT_1003="Exit"
declare -g TXT_1101="Yes"
declare -g TXT_1102="No"
declare -g TXT_1103="Back"
declare -g TXT_1104="Next"

# =============================================================================
# MESSAGE CODES (2000-2999) - USER MESSAGES
# =============================================================================
declare -g MSG_2000="Operation completed"
declare -g MSG_2100="Success"
declare -g MSG_2101="Operation completed successfully"
declare -g MSG_2200="Processing..."
declare -g MSG_2300="Warning"

# =============================================================================
# TYPE CODES (3000-3999) - CATEGORIES
# =============================================================================
declare -g TYPE_3000="General"
declare -g TYPE_3100="Configuration"
declare -g TYPE_3200="Directory"
declare -g TYPE_3300="File"
declare -g TYPE_3400="Network"
declare -g TYPE_3500="System"

# =============================================================================
# ERROR CODES (4000-4999) - ERROR MESSAGES
# =============================================================================
declare -g ERR_4000="An error occurred"
declare -g ERR_4100="Configuration error"
declare -g ERR_4200="Directory error"
declare -g ERR_4300="File error"
declare -g ERR_4400="Network error"
declare -g ERR_4500="System error"

# =============================================================================
# LOGGING CODES (5000-5999) - LOG FILES
# =============================================================================
declare -g LOG_5000="Event logged"
declare -g LOG_5100="Application started"
declare -g LOG_5101="Application shutdown"
declare -g LOG_5200="Configuration loaded"
declare -g LOG_5201="Configuration saved"
declare -g LOG_5300="File processed"
declare -g LOG_5301="File created"
declare -g LOG_5302="File deleted"

# =============================================================================
# CONFIGURATION CODES (6000-6999) - CONFIG UI
# =============================================================================
declare -g CFG_6000="Configuration"
declare -g CFG_6100="Settings"
declare -g CFG_6101="General settings"
declare -g CFG_6102="Network settings"
declare -g CFG_6103="Security settings"
declare -g CFG_6200="Setup wizard"
declare -g CFG_6201="Welcome to setup"
declare -g CFG_6202="Setup completed"

# =============================================================================
# HELP CODES (7000-7999) --help OUTPUT
# =============================================================================
declare -g HELP_7000="Help"
declare -g HELP_7100="Usage"
declare -g HELP_7101="Syntax"
declare -g HELP_7102="Parameters"
declare -g HELP_7103="Options"
declare -g HELP_7200="Examples"
declare -g HELP_7300="Description"

# =============================================================================
# PROGRESS CODES (8000-8999) - PROGRESS STATUS
# =============================================================================
declare -g PROG_8000="Progress"
declare -g PROG_8100="Installing..."
declare -g PROG_8101="Downloading..."
declare -g PROG_8102="Processing..."
declare -g PROG_8103="Initializing..."
declare -g PROG_8200="Complete"
declare -g PROG_8201="Installation complete"
declare -g PROG_8202="Download complete"

# =============================================================================
# INPUT CODES (9000-9999) - USER INPUT PROMPTS
# =============================================================================
declare -g INPUT_9000="Input required"
declare -g INPUT_9100="Enter value"
declare -g INPUT_9101="Enter path"
declare -g INPUT_9102="Enter name"
declare -g INPUT_9200="Confirmation"
declare -g INPUT_9201="Are you sure?"
declare -g INPUT_9202="Confirm deletion"

# =============================================================================
# MENU CODES (A000-A999) - MENU SYSTEM (hex für 10. Gruppe)
# =============================================================================
declare -g MENU_A000="Menu"
declare -g MENU_A100="Main menu"
declare -g MENU_A101="Settings menu"
declare -g MENU_A102="Tools menu"
declare -g MENU_A200="Select option"
declare -g MENU_A201="Navigation"



declare -A LANGUAGE_MAP=(
  # Europäische Sprachen
  ["de"]="Deutsch:German"
  ["en"]="English:English"
  ["fr"]="Français:French"
  ["es"]="Español:Spanish"
  ["it"]="Italiano:Italian"
  ["pt"]="Português:Portuguese"
  ["nl"]="Nederlands:Dutch"

  # Skandinavische Sprachen
  ["sv"]="Svenska:Swedish"
  ["no"]="Norsk:Norwegian"
  ["da"]="Dansk:Danish"
  ["fi"]="Suomi:Finnish"

  # Osteuropäische Sprachen
  ["pl"]="Polski:Polish"
  ["ru"]="Русский:Russian"
  ["cs"]="Čeština:Czech"
  ["sk"]="Slovenčina:Slovak"
  ["hu"]="Magyar:Hungarian"
  ["ro"]="Română:Romanian"

  # Asiatische Sprachen
  ["zh"]="中文:Chinese"
  ["ja"]="日本語:Japanese"
  ["ko"]="한국어:Korean"
  ["ar"]="العربية:Arabic"
  ["th"]="ไทย:Thai"
  ["vi"]="Tiếng Việt:Vietnamese"

  # Weitere Sprachen
  ["tr"]="Türkçe:Turkish"
  ["el"]="Ελληνικά:Greek"
  ["he"]="עברית:Hebrew"
  ["hi"]="हिन्दी:Hindi"
)


get_system_language_code() {

  local lang=""

  for env_var in LANG LC_MESSAGES LC_ALL LANGUAGE; do
    if [[ -n "${!env_var}" ]]; then
      lang="${!env_var%%_*}"
      lang="${lang%%.*}"
      lang=$(echo "$lang" | tr '[:upper:]' '[:lower:]')
      [[ -n "$lang" ]] && break
    fi
  done

  if [[ -z "$lang" ]] && command -v locale &>/dev/null; then
    lang=$(locale 2>/dev/null | grep -E "LANG=|LC_MESSAGES=" | head -1 | cut -d= -f2 | cut -d_ -f1 | tr '[:upper:]' '[:lower:]')
  fi

  LANG_CODE="${lang:-$LANG_CODE}"

  return 0

}


get_language() {
  local lang="${1:-en}"
  lang="${lang,,}"

  if [[ -n "${LANGUAGE_MAP[$lang]}" ]]; then
    IFS=':' read -r LANGUAGE_NAME LANGUAGE_NAME_EN <<< "${LANGUAGE_MAP[$lang]}"
    LANG_CODE="$lang"
  fi

  return 0

}


set_language() {

  local warning=false
  local missing_folders=()

  local default_lang="en"

  local lang="${1:-$default_lang}"
  local types="${2:-}"  # Additional folders (optional)
  local base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/lang" && pwd -P)

  # Always search default + additional folders
  local search_dirs="default"
  if [[ -n "$types" ]]; then
    search_dirs="default,${types}"
  fi

  # Convert folder types to array
  IFS=',' read -ra type_dirs <<< "$search_dirs"

  # Check if all specified folders exist (case-insensitive)
  local valid_dirs=()
  for type_dir in "${type_dirs[@]}"; do
    local found_dir=""
    # Case-insensitive folder search
    for actual_dir in "$base_dir/"*/; do
      actual_dir=$(basename "$actual_dir")
      if [[ "${actual_dir,,}" == "${type_dir,,}" ]]; then
        found_dir="$actual_dir"
        break
      fi
    done

    if [[ -n "$found_dir" ]]; then
      valid_dirs+=("$found_dir")
    else
      warning=true
      missing_folders+=("$type_dir")
    fi
  done

  # If no valid folders found
  if [[ ${#valid_dirs[@]} -eq 0 ]]; then
    echo "Error: No valid language folders in $base_dir/ found" >&2
    return 1
  elif [[ "$warning" == true ]]; then
    echo "Warning: Folder(s) '${missing_folders[*]}' do not exist in $base_dir/" >&2
  fi

  local lang_found=0

  # FIRST PASS: Search for desired language (with wildcard)
  for type_dir in "${valid_dirs[@]}"; do
    local lang_dir="$base_dir/$type_dir"
    # Search for language files with wildcard
    for lang_file in "$lang_dir/"*"${lang}.sh"; do
      if [[ -f "$lang_file" ]]; then
        source "$lang_file"
        lang_found=1
      fi
    done
  done

  # SECOND PASS: If language not found, set ALL to English
  if [[ $lang_found -eq 0 ]]; then
    echo "Warning: Language '$lang' not found, falling back to '$default_lang'" >&2
    for type_dir in "${valid_dirs[@]}"; do
      local lang_dir="$base_dir/$type_dir"
      # Search for English files with wildcard
      for lang_file in "$lang_dir/"*"$default_lang.sh"; do
        if [[ -f "$lang_file" ]]; then
          source "$lang_file"
        fi
      done
    done
  fi

  return 0

}


get_translation() {
  local code="$1"
  local prefix=""

  # Automatische Präfix-Erkennung
  if [[ "$code" =~ ^[0-9A-Fa-f]{4}$ ]]; then
    local first_char="${code:0:1}"
    case "$first_char" in
      "1") prefix="TXT_" ;;
      "2") prefix="MSG_" ;;
      "3") prefix="TYPE_" ;;
      "4") prefix="ERR_" ;;
      "5") prefix="LOG_" ;;
      "6") prefix="CFG_" ;;
      "7") prefix="HELP_" ;;
      "8") prefix="PROG_" ;;
      "9") prefix="INPUT_" ;;
      "A"|"a") prefix="MENU_" ;;
      *) prefix="UNKNOWN_" ;;
    esac
    code="${prefix}${code}"
  fi

  # Case-insensitive Suche
  local upper_code=$(echo "$code" | tr '[:lower:]' '[:upper:]')

  # Direkter Treffer
  if [[ -n "${!upper_code}" ]]; then
    echo "${!upper_code}"
    return 0
  fi

  # KORRIGIERT: Präfix und Digits korrekt extrahieren
  local prefix=""
  local digits=""

  # Extrahiere Präfix (alles bis zum letzten Unterstrich)
  if [[ "$upper_code" =~ ^([A-Z]+)_([0-9A-F]+)$ ]]; then
    prefix="${BASH_REMATCH[1]}"  # TXT, MSG, TYPE, etc.
    digits="${BASH_REMATCH[2]}"  # 1001, 2000, 3000, etc.
  else
    # Fallback für ungültiges Format
    echo "Unknown code"
    return 1
  fi

  # Hierarchischen Fallback finden
  if [[ ${#digits} -eq 4 ]]; then
    local fallback_codes=()

    # Level 3: Letzte Ziffer auf 0 (4301 -> 4300)
    fallback_codes+=("${prefix}_${digits:0:3}0")

    # Level 3: Letzte zwei Ziffern auf 0 (4300 -> 4300)
    fallback_codes+=("${prefix}_${digits:0:2}00")

    # Level 2: Letzte drei Ziffern auf 0 (4300 -> 4000)
    fallback_codes+=("${prefix}_${digits:0:1}000")

    # Durch alle Fallback-Codes probieren
    for fallback_code in "${fallback_codes[@]}"; do
      if [[ -n "${!fallback_code}" ]]; then
        echo "${!fallback_code}"
        return 0
      fi
    done
  fi

  # Finaler Fallback basierend auf Typ
  case "${prefix}" in
    "ERR") echo "Unknown error" ;;
    "MSG") echo "Unknown message" ;;
    "TXT") echo "Unknown text" ;;
    "TYPE") echo "Unknown type" ;;
    "LOG") echo "Unknown log event" ;;
    "CFG") echo "Unknown configuration" ;;
    "HELP") echo "Unknown help topic" ;;
    "PROG") echo "Unknown progress" ;;
    "INPUT") echo "Unknown input" ;;
    "MENU") echo "Unknown menu" ;;
    *) echo "Unknown code" ;;
  esac
}

init_globals() {
  # Ansonsten normale Options-Verarbeitung
  local lang=""
  local typs=""
  local load_only=false

  while [[ $# -gt 0 ]]; do
    case "${1,,}" in
      -l|--lang|--language)
        lang="$2"
        shift 2
        ;;
      -t|--type)
        typs="$2"
        shift 2
        ;;
      -lo|--ol|--load-only|--only-load)
        load_only=true
        shift
        ;;
      *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
  done

  [[ "$load_only" == true ]] && return 0

  [[ -z "$lang" ]] && get_system_language_code

  get_language "$LANG_CODE"
  set_language "$LANG_CODE" "$typs"
}

# Automatisch initialisieren
init_globals "$@"


# Wenn direkt ausgeführt: Hinweis anzeigen und beenden
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "⚠️  Dieses Script muss mit 'source' eingebunden werden:"
  echo "   source $(basename "$0")"
  echo ""
  echo "Beispiele:"
  echo "   source $(basename "$0")                     # Automatische Spracherkennung"
  echo "   source $(basename "$0") --lang de          # Deutsche Sprache"
  echo "   source $(basename "$0") --load-only        # Nur Funktionen laden"
  exit 1
fi
