#!/usr/bin/env bash
# ========================================================================================
# Bash Language Management System
#
# Autor      : Marcel Gräfen
# Version    : 0.0.1
# Datum      : 2025-10-19
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

declare -A _LOADED_LANG_FILES=()

## BASIC INFO
declare -g LANG_CODE="en"
declare -g LANGUAGE_NAME="English"
declare -g LANGUAGE_NAME_EN="English"

# TEXT CODES (001000-001999) - UI ELEMENTS
declare -g TXT_001000="Continue"
declare -g TXT_001001="OK"
declare -g TXT_001002="Cancel"
declare -g TXT_001003="Exit"
declare -g TXT_001101="Yes"
declare -g TXT_001102="No"
declare -g TXT_001103="Back"
declare -g TXT_001104="Next"

# MESSAGE CODES (002000-002999) - USER MESSAGES
declare -g MSG_002000="Operation completed"
declare -g MSG_002100="Success"
declare -g MSG_002101="Operation completed successfully"
declare -g MSG_002200="Processing..."
declare -g MSG_002300="Warning"

# TYPE CODES (003000-003999) - CATEGORIES
declare -g TYPE_003000="General"
declare -g TYPE_003100="Configuration"
declare -g TYPE_003200="Directory"
declare -g TYPE_003300="File"
declare -g TYPE_003400="Network"
declare -g TYPE_003500="System"

# ERROR CODES (004000-004999) - ERROR MESSAGES
declare -g ERR_004000="An error occurred"
declare -g ERR_004100="Configuration error"
declare -g ERR_004200="Directory error"
declare -g ERR_004300="File error"
declare -g ERR_004400="Network error"
declare -g ERR_004500="System error"

# LOGGING CODES (005000-005999) - LOG FILES
declare -g LOG_005000="Event logged"
declare -g LOG_005100="Application started"
declare -g LOG_005101="Application shutdown"
declare -g LOG_005200="Configuration loaded"
declare -g LOG_005201="Configuration saved"
declare -g LOG_005300="File processed"
declare -g LOG_005301="File created"
declare -g LOG_005302="File deleted"

# CONFIGURATION CODES (006000-006999) - CONFIG UI
declare -g CFG_006000="Configuration"
declare -g CFG_006100="Settings"
declare -g CFG_006101="General settings"
declare -g CFG_006102="Network settings"
declare -g CFG_006103="Security settings"
declare -g CFG_006200="Setup wizard"
declare -g CFG_006201="Welcome to setup"
declare -g CFG_006202="Setup completed"

# HELP CODES (007000-007999) --help OUTPUT
declare -g HELP_007000="Help"
declare -g HELP_007100="Usage"
declare -g HELP_007101="Syntax"
declare -g HELP_007102="Parameters"
declare -g HELP_007103="Options"
declare -g HELP_007200="Examples"
declare -g HELP_007300="Description"

# PROGRESS CODES (008000-008999) - PROGRESS STATUS
declare -g PROG_008000="Progress"
declare -g PROG_008100="Installing..."
declare -g PROG_008101="Downloading..."
declare -g PROG_008102="Processing..."
declare -g PROG_008104="Initializing..."
declare -g PROG_008200="Complete"
declare -g PROG_008201="Installation complete"
declare -g PROG_008202="Download complete"

# INPUT CODES (009000-009999) - USER INPUT PROMPTS
declare -g INPUT_009000="Input required"
declare -g INPUT_009100="Enter value"
declare -g INPUT_009101="Enter path"
declare -g INPUT_009102="Enter name"
declare -g INPUT_009200="Confirmation"
declare -g INPUT_009201="Are you sure?"
declare -g INPUT_009202="Confirm deletion"

# MENU CODES (01000-01999) - MENU SYSTEM (hex für 10. Gruppe)
declare -g MENU_010000="Menu"
declare -g MENU_010100="Main menu"
declare -g MENU_010101="Settings menu"
declare -g MENU_010102="Tools menu"
declare -g MENU_010200="Select option"
declare -g MENU_010201="Navigation"

# === CODE_META_MAP

declare -A CODE_META_MAP=(
  # UI Texts (010000–019999)
  [001]="TXT:Unknown text"
  [002]="MSG:Unknown message"
  [003]="TYPE:Unknown type"

  # Errors, Logging, Config (040000–069999)
  [004]="ERR:Unknown error"
  [005]="LOG:Unknown log event"
  [006]="CFG:Unknown configuration"

  # Help, Progress, Input, Menu (070000–100000)
  [007]="HELP:Unknown help topic"
  [008]="PROG:Unknown progress"
  [009]="INPUT:Unknown input"
  [010]="MENU:Unknown menu"
)

#!===


# === LANGUAGE MAP

# This map lists all the languages for which there are default variables.
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

#!===

# === GET SSYSTEM LANGUAGE

# Detects the system language code (e.g., "en", "de", "fr") from environment
# variables such as LANG, LC_MESSAGES, LC_ALL, or LANGUAGE. If no valid language
# is found, the existing default value of LANG_CODE remains unchanged.
get_system_language_code() {
  local lang=""

  # Check common language-related environment variables in a reasonable order
  for env_var in LANG LC_MESSAGES LC_ALL LANGUAGE; do
    if [[ -n "${!env_var}" ]]; then
      lang="${!env_var%%_*}"      # Part before underscore, e.g. "de_DE" → "de"
      lang="${lang%%.*}"          # Remove optional ".UTF-8" suffix
      lang="${lang,,}"            # Convert to lowercase (bash ≥ 4)
      [[ -n "$lang" ]] && break
    fi
  done

  # Fallback using locale command if nothing was found above
  if [[ -z "$lang" ]] && command -v locale &>/dev/null; then
    lang=$(locale 2>/dev/null | grep -E '^(LANG|LC_MESSAGES)=' | head -n1 | cut -d= -f2)
    lang="${lang%%_*}"
    lang="${lang%%.*}"
    lang="${lang,,}"
  fi

  # Only overwrite LANG_CODE if a valid language was detected
  [[ -n "$lang" ]] && LANG_CODE="$lang"

  return 0
}

#!===


# === VALIDATE LANGUAGE

# Sets the global LANG_CODE and language names based on a given language code.
# It uses LANGUAGE_MAP to translate codes into the language name (native) and English name.
# If no valid code is provided, the default is "en".
validate_language() {
  # Use the provided language code, default to "en"
  local lang="${1:-en}"
  lang="${lang,,}"  # convert to lowercase

  # Check if the code exists in LANGUAGE_MAP
  if [[ -n "${LANGUAGE_MAP[$lang]}" ]]; then
    # Split the value from LANGUAGE_MAP into native and English names
    IFS=':' read -r LANGUAGE_NAME LANGUAGE_NAME_EN <<< "${LANGUAGE_MAP[$lang]}"
    # Set the global LANG_CODE to the valid language code
    LANG_CODE="$lang"
  fi

  return 0
}

#!===



# === LANGUAGE MANAGEMENT SYSTEM

# Provides:
#   - load_languages()       → Load language files from all modules dynamically
#   - reset_loaded_languages() → Clear loaded file cache (for debugging)
#   - debug_language_paths()   → Show which paths would be used

# Global cache: tracks which language files were already loaded
# declare -A _LOADED_LANG_FILES=()

# --- reset_loaded_languages

# Clears the global cache of loaded language files.
# Useful if you want to reload all language files manually.
reset_loaded_languages() {
  unset _LOADED_LANG_FILES
  declare -gA _LOADED_LANG_FILES=()
  [[ "$verbose" == true ]] && echo " Language cache cleared."
}


# --- debug_language_paths

# Prints all directories that load_languages() would scan, based on the current
# ${BASH_SOURCE[@]} call stack. Useful for verifying setup.
debug_language_paths() {
  local types="${1:-}"
  local -a all_lang_dirs=()

  echo "🔍 Debug: Detected language search paths"
  echo "----------------------------------------"

  for src in "${BASH_SOURCE[@]}"; do
    local base_dir
    base_dir="$(cd "$(dirname "$src")" && pwd -P)"
    echo "• From: $src"
    echo "  Base: $base_dir"

    if [[ -d "$base_dir/lang" ]]; then
      echo "  → $base_dir/lang"
      all_lang_dirs+=("$base_dir/lang")
    fi

    if [[ -n "$types" ]]; then
      IFS=',' read -ra extra_types <<< "$types"
      for t in "${extra_types[@]}"; do
        if [[ -d "$base_dir/$t" ]]; then
          echo "  → $base_dir/$t"
          all_lang_dirs+=("$base_dir/$t")
        else
          echo "  ⚠ Missing optional: $base_dir/$t"
        fi
      done
    fi
    echo
  done

  # Remove duplicates for clarity
  mapfile -t all_lang_dirs < <(printf '%s\n' "${all_lang_dirs[@]}" | awk '!seen[$0]++')

  echo "----------------------------------------"
  echo "✅ Effective unique search dirs:"
  printf '  %s\n' "${all_lang_dirs[@]}"
  echo
}



# === LOAD LANGUAGES

# Loads all available language files (*.sh) for the given language code from
# each relevant module folder (determined via ${BASH_SOURCE[@]}).
# If a folder lacks the requested language, it falls back to FALLBACK_LANG
# (default: "en"). Each file is loaded only once (deduplication via cache).
#
# Usage:
#   load_languages "de" "help,messages"
#
# Globals:
#   VERBOSE=true → enables log output
load_languages() {

  local lang="${1:-$LANG_CODE}"
  local types="${2:-}"                  # Optional additional subfolder types
  local FALLBACK_LANG="en"
  local verbose="${VERBOSE:-false}"
  local default_dir="lang"
  local default_file_type="sh"

  local lang_found=0
  local -a all_lang_dirs=()

  # --- Set Directorys
  # Collect all base directories from call chain (${BASH_SOURCE[@]})
  for src in "${BASH_SOURCE[@]}"; do
    local base_dir
    base_dir="$(cd "$(dirname "$src")" && pwd -P)"
    [[ -d "$base_dir" ]] || continue

    # Always check the default /$default_dir/ directory
    if [[ -d "$base_dir/$default_dir" ]]; then
      all_lang_dirs+=("$base_dir/$default_dir")
    fi

    # Add optional folders (types)
    if [[ -n "$types" ]]; then
      IFS=',' read -ra extra_types <<< "$types"
      for t in "${extra_types[@]}"; do
        if [[ -d "$base_dir/$t" ]]; then
          all_lang_dirs+=("$base_dir/$t")
        elif [[ "$verbose" == true ]]; then
          echo "[verbose] Missing optional folder: $base_dir/$t" >&2
        fi
      done
    fi
  done

  # Remove duplicate directories
  mapfile -t all_lang_dirs < <(printf '%s\n' "${all_lang_dirs[@]}" | awk '!seen[$0]++')

  if [[ "${#all_lang_dirs[@]}" -eq 0 ]]; then
    echo "Error: No valid language folders found via call chain." >&2
    return 1
  fi

  # --- Load Language files
  # Try to load requested language for each directory (skip already loaded)
  local -a fallback_dirs=()
  for dir in "${all_lang_dirs[@]}"; do
    local lang_file="$dir/${lang}.${default_file_type}"

    if [[ -f "$lang_file" ]]; then
      if [[ -n "${_LOADED_LANG_FILES["$lang_file"]}" ]]; then
        [[ "$verbose" == true ]] && echo "[verbose] Skipped (already loaded): $lang_file"
      else
        [[ "$verbose" == true ]] && echo "[verbose] Loaded: $lang_file"
        # shellcheck disable=SC1090
        source "$lang_file"
        _LOADED_LANG_FILES["$lang_file"]=1
        ((lang_found++))
      fi
    else
      fallback_dirs+=("$dir")
    fi
  done

  # --- Load Fallback
  # Fallback: load FALLBACK_LANG only where the requested one is missing
  for dir in "${fallback_dirs[@]}"; do
    local fb_file="$dir/${FALLBACK_LANG}.${default_file_type}"

    if [[ -f "$fb_file" ]]; then
      if [[ -n "${_LOADED_LANG_FILES["$fb_file"]}" ]]; then
        [[ "$verbose" == true ]] && echo "[verbose] Skipped fallback (already loaded): $fb_file"
      else
        [[ "$verbose" == true ]] && echo "[verbose] Fallback: $fb_file (missing ${lang}.${default_file_type})"
        # shellcheck disable=SC1090
        source "$fb_file"
        _LOADED_LANG_FILES["$fb_file"]=1
      fi
    else
      [[ "$verbose" == true ]] && echo "[verbose] Missing both ${lang}.${default_file_type} and ${FALLBACK_LANG}.${default_file_type} in $dir" >&2
    fi
  done

  # --- Summary
  if [[ "$verbose" == true ]]; then
    echo "[verbose] Language load complete: '${lang}' (fallback: '${FALLBACK_LANG}')"
  fi

  return 0
}


#!===
#!===


# === TRANSLATION MY VARIABLES
# Returns the translation text for a given numeric code using CODE_META_MAP.
# Features:
#   - Configurable min/max code length
#   - Pads code to fixed length
#   - Dynamic hierarchical fallback (per-digit or configurable step)
#   - Final default text from CODE_META_MAP
#
# Globals:
#   CODE_META_MAP → contains prefix and default text as PREFIX:Text
#   VERBOSE → enable debug output
#   CODE_MIN_LENGTH → minimal valid code length (default 4)
#   CODE_MAX_LENGTH → maximal valid code length (default 6)
#   FALLBACK_STEP → how many digits to zero at once during fallback (default 1)

get_translation() {

  local code="$1"

  local verbose="${VERBOSE:-false}"
  local min_len="${CODE_MIN_LENGTH:-4}"
  local max_len="${CODE_MAX_LENGTH:-6}"
  local major_len="${MAJOR_LENGTH:-3}"
  local fallback_step="${FALLBACK_STEP:-1}"

  # Check numeric
  if ! [[ "$code" =~ ^[0-9]+$ ]]; then
    [[ "$verbose" == true ]] && echo "Error: Code must be numeric, got '$code'" >&2
    return 1
  fi

  # Check length
  if [[ ${#code} -lt $min_len || ${#code} -gt $max_len ]]; then
    [[ "$verbose" == true ]] && echo "Error: Invalid code length '${code}', must be $min_len-$max_len digits" >&2
    return 1
  fi

  # Pad to fixed length
  if [[ "${#code}" != "$max_len" ]]; then
    while [[ ${#code} -lt $max_len ]]; do
      code="0${code}"
    done
  fi

  # Determine major group = first 3 digits
  local major="${code:0:$major_len}"
  local map_key=""

  if [[ -n "${CODE_META_MAP[$major]}" ]]; then
    map_key="$major"
  else
    [[ "$verbose" == true ]] && echo "Error: No CODE_META_MAP entry for major group '$major'" >&2
    echo "${ERR_004000:-Unknown ERROR}"
    return 1
  fi

  local code_entry="${CODE_META_MAP[$map_key]}"
  local prefix="${code_entry%%:*}"
  local default_text="${code_entry#*:}"

  # Construct dynamic variable name
  local var_name="${prefix}_${code}"

  # Direct match
  if [[ -n "${!var_name}" ]]; then
    echo "${!var_name}"
    return 0
  fi

  local fallback_code="$code"

  for ((i=0; i<=max_len-major_len; i+=fallback_step)); do
    # Last fallback_step Numbern set to 0
    fallback_code="${fallback_code:0:${#fallback_code}-fallback_step}$(printf '%0*d' "$fallback_step" 0)"

    local fb_var="${prefix}_${fallback_code}"

    # Check if Variable Exist
    if [[ -n "${!fb_var}" ]]; then
      echo "${!fb_var}"
      return 0
    fi
  done

  # Nothing found → Default text from CODE_META_MAP
  echo "${default_text:-Unknown code}"

}


#!===


# Scripts
# ├─ Global
# │  ├─ language
# │  │  ├─ lang
# │  │  │  ├─ en.sh
# │  │  │  ├─ de.sh
# │  │  │  └─ fr.sh
# │  │  └─ language.sh
# │  └─ bash_deny.sh
# │
# ├─ Caller
# │  ├─ caller.sh
# │  ├─ lang
# │  │  ├─ en.sh
# │  │  ├─ de.sh
# │  │  └─ fr.sh
# │  └─ help
# │     ├─ en.sh
# │     ├─ de.sh
# │     └─ fr.sh
# │
# ├─ Writer
# │  └─ writer.sh
