#!/usr/bin/env bash

# ========================================================================================
# GLOBALE KONFIGURATION - Help System
#
# @author      : Marcel Gräfen
# @version     : 0.0.1
# @date        : 2025-10-04
# @license     : MIT License
# ========================================================================================

 # === SIZE ===
declare -g MIN_WIDTH=50
declare -g MAX_WIDTH=100
declare -g MIN_HEIGHT=10
declare -g MAX_HEIGHT=40
declare -g PADDING=10

# === SYSTEM LANGUAGE ===
declare -g LANGUAGE_NAME="English"
declare -g LANGUAGE_NAME_EN="English"

# === TEXT ===

declare -g TEXT_BACKTITLE="Help System"
declare -g TEXT_PROMPT="Choose an option:"

declare -g TEXT_SKIPPED_DENY="skipped (Deny)"
declare -g TEXT_NO_READ_PERMISSION="No read permission"
declare -g TEXT_FILE_TOO_LARGE="File too large"
declare -g TEXT_SEARCH_START="Starting search in"
declare -g TEXT_RECOGNIZED_SINGLE_FILE="Recognized: Single INI file"
declare -g TEXT_RECOGNIZED_DIRECTORY="Recognized: Directory"
declare -g TEXT_RECOGNIZED_WILDCARD="Recognized: Wildcard pattern"
declare -g TEXT_RECOGNIZED_RECURSIVE="Recognized: Recursive pattern"
declare -g TEXT_INVALID_PATH="Invalid path"
declare -g TEXT_SEARCHED_DIRECTORY="Searched directories"
declare -g TEXT_SUCCESS="Success"
declare -g TEXT_DIRECTORIES="directories"
declare -g TEXT_FILES="files"

# === SYSTEM KONSTANTEN ===
declare -g SYS_NAME="Help System"
declare -g SYS_VERSION="1.0.0"
declare -g SYS_MIN_WIDTH=50
declare -g SYS_MAX_WIDTH=100
declare -g SYS_MIN_HEIGHT=10
declare -g SYS_MAX_HEIGHT=40
declare -g SYS_PADDING=10
declare -g SYS_LOG="/tmp/help.log"

# === AKTUELLE SPRACHVARIABLEN (ENGLISH FALLBACK) ===
declare -g CURRENT_LANG="en"
declare -g TEXT_LABEL="File"
declare -g BTN_OK="OK"
declare -g BTN_CANCEL="Cancel"
declare -g BTN_CLOSE="Close"
declare -g BTN_BACK="Back"
declare -g BTN_PREV="Previous"
declare -g BTN_NEXT="Next"
declare -g BTN_HOME="Main Menu"
declare -g BTN_EXIT="Exit"
declare -g BTN_LANGUAGE="Language"
declare -g BTN_HELP="Help"

# === FEHLERCODES (ENGLISH FALLBACK) ===

declare -g ERR_100="Missing required configuration"
declare -g ERR_101="Invalid INI structure in file"
declare -g ERR_102="No language files found"
declare -g ERR_103="Default language not available"
declare -g ERR_104="Main menu section not found"
declare -g ERR_105="Invalid configuration format"
declare -g ERR_200="File not found or unreadable"
declare -g ERR_201="Invalid file path"
declare -g ERR_202="Directory contains no INI files"
declare -g ERR_203="Directory does not exist"
declare -g ERR_204="File access denied"
declare -g ERR_300="Menu option not found"
declare -g ERR_301="No menu items found for"
declare -g ERR_302="No valid menu sections found"
declare -g ERR_303="Invalid menu navigation"
declare -g ERR_304="Empty menu structure"
declare -g ERR_400="Invalid file path detected"
declare -g ERR_401="Access violation detected"
declare -g ERR_402="Path traversal attempt blocked"
declare -g ERR_500="Language file could not be loaded"
declare -g ERR_501="Invalid language configuration"
declare -g ERR_502="Unsupported language code"
declare -g ERR_600="No content found for"
declare -g ERR_601="Content file not readable"
declare -g ERR_602="Invalid content format"
declare -g ERR_700="Internal system error"
declare -g ERR_701="Whiptail not available"
declare -g ERR_702="Terminal size too small"

# === TYPE  ===
declare -g TYPE_CONFIG="Configuration"
declare -g TYPE_CONTENT="Content"
declare -g TYPE_ERROR="Error"
declare -g TYPE_FILE="File"
declare -g TYPE_LANGUAGE="Language"
declare -g TYPE_MENU="Menu"
declare -g TYPE_SYSTEM="System"
declare -g TYPE_VERIFY="Verification"

# === STATUS TYPES ===
declare -g TYPE_STATUS_COMPLETED="Completed"
declare -g TYPE_STATUS_FAILED="Failed"
declare -g TYPE_STATUS_PENDING="Pending"
declare -g TYPE_STATUS_VERIFIED="Verified"

# === OPERATION TYPES ===
declare -g TYPE_OPERATION_READ="Read Operation"
declare -g TYPE_OPERATION_VALIDATE="Validation Operation"
declare -g TYPE_OPERATION_VERIFY="Verification Operation"

# === MODULE TYPES ===
declare -g TYPE_MODULE_CORE="Core Module"
declare -g TYPE_MODULE_FILE="File Module"
declare -g TYPE_MODULE_VERIFY="Verification Module"

# === SYSTEMSPRACHE ERKENNEN ===
detect() {
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

    echo "${lang:-en}"
}

# === VERFÜGBARE SPRACHEN PRÜFEN ===
get_availables() {
    local lang_dir="$(dirname "${BASH_SOURCE[0]}")/lang"
    local languages=()

    if [[ -d "$lang_dir" ]]; then
        for file in "$lang_dir"/*.sh; do
            [[ -f "$file" ]] && languages+=("$(basename "$file" .sh)")
        done
    fi

    echo "${languages[@]}"
}

# === BESTE SPRACHE FINDEN ===
find_best() {
    local preferred_lang="${1:-}"
    local system_lang=$(detect)
    local availables=($(get_availables))

    if [[ -n "$preferred_lang" ]]; then
        for lang in "${availables[@]}"; do
            if [[ "$lang" == "$preferred_lang" ]]; then
                echo "$lang"
                return 0
            fi
        done
    fi

    for lang in "${availables[@]}"; do
        if [[ "$lang" == "$system_lang" ]]; then
            echo "$lang"
            return 0
        fi
    done

    for lang in "${availables[@]}"; do
        if [[ "$lang" == "en" ]]; then
            echo "en"
            return 0
        fi
    done

    if [[ ${#availables[@]} -gt 0 ]]; then
        echo "${availables[0]}"
        return 0
    fi

    echo "en"
}

# === SPRACH-SETZEN ===
set() {
    local lang="${1:-}"
    local lang_file="$(dirname "${BASH_SOURCE[0]}")/lang/${lang}.sh"

    if [[ -f "$lang_file" ]]; then
        source "$lang_file"
        CURRENT_LANG="$lang"  # ✅ Setzt CURRENT_LANG auf SPRACHCODE!
        return 0
    else
        return 1
    fi
}

# === FEHLERMELDUNG HOLEN ===
get_error_message() {
    local error_type="$1"
    local error_code="$2"

    local var_name="ERR_${error_type^^}_${error_code}"
    if [[ -n "${!var_name}" ]]; then
        echo "${!var_name}"
    else
        echo "Unknown error: $error_type.$error_code"
    fi
}

# === INIT ===
init_globals() {
    local preferred_lang="${1:-}"
    local best_lang=$(find_best "$preferred_lang")
    set "$best_lang"
}

# Automatisch initialisieren
init_globals "$@"
