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

Help() {

  declare -A config available_languages language_files language_names config_cache menu_order
  declare -a section_order menu_sections MENU_HISTORY

  # === VARIABLES ===

  NAME_KEY="help"
  HELP_FILES_DIR="./**/**/"

  # --- LOG Variable ---

  LOG_FILE="/tmp/help_system_$NAME_KEY.log"
  LOG=false

  # --- DEFAULT Variable ---

  DEFAULT_LANG="de"
  DEFAULT_LANG_FALLBACK="en"

  DEFAULT_BACKTITLE="Help System"
  DEFAULT_OPTION_ERROR="Option not found!"
  DEFAULT_FILE_ERROR="File not found or cannot be read!"
  DEFAULT_FILE_LABEL="File"
  DEFAULT_MENU_TEXT="Choose an option:"
  DEFAULT_BUTTON_LANG="Change Language"
  DEFAULT_BUTTON_OK="OK"
  DEFAULT_BUTTON_CANCEL="Cancel"
  DEFAULT_BUTTON_BACK="Back"
  DEFAULT_BUTTON_BACK_MAIN="To Main Menu"
  DEFAULT_BUTTON_EXIT="Exit"
  DEFAULT_BUTTON_NEXT="Next"
  DEFAULT_BUTTON_CLOSE="Close"

  # --- SIZE Variable ---

  MIN_WIDTH=50
  MAX_WIDTH=100
  MIN_HEIGHT=10
  MAX_HEIGHT=40
  PADDING=10

  # --- INTERN Variable ---

  CURRENT_LANG_FILE=""
  CURRENT_LANG_CODE=""
  CURRENT_LANG_NAME=""
  CURRENT_MENU=""
  CONFIG_LOADED=false

  INI_FILES=()

  INI_FILE_ERROR=false

  #!===


  # === CALCULATE DIMENSIONS ===

  # @description: This function calculates the optimal window size for Whiptail dialogs based on the text content or file length, taking into account terminal size limits and padding.
  #
  # @param:       $1 - content (text string or file path)
  # @return:      "width height" as string
  #
  # @use_by:      show_error, show_option_error, show_file_error, show_text_with_buttons, show_file_with_buttons
  # @use_not_directly: show_output_content, show_help_menu, show_language_menu
  #
  # @use:         NONE

  calculate_dimensions() {

    local content="$1"
    local TERM_WIDTH=$(tput cols)
    local TERM_HEIGHT=$(tput lines)
    local width height

    if [[ -f "$content" ]]; then

      #--- File Handling ---
      local max_len=$(awk '{if(length>m)m=length}END{print m}' "$content" 2>/dev/null || echo 0)
      width=$((max_len + PADDING*2))
      height=$(wc -l < "$content" 2>/dev/null || echo 0)
      height=$(echo "$height" | tr -d '[:space:]')
      height=$((height + PADDING*2))
    else
      #--- Text-Input Handling ---
      local line_count=0
      local max_len=0

      #--- Use process substitution for the while loop ---
      while IFS= read -r line; do
        (( ${#line} > max_len )) && max_len=${#line}
        ((line_count++))
      done < <(echo "$content")

      width=$((max_len + PADDING*2))
      height=$((line_count + PADDING*2))
    fi

    #--- Size limitations ---
    (( width < MIN_WIDTH )) && width=$MIN_WIDTH
    (( width > MAX_WIDTH )) && width=$MAX_WIDTH
    (( width > TERM_WIDTH - 10 )) && width=$((TERM_WIDTH - 10))
    (( height < MIN_HEIGHT )) && height=$MIN_HEIGHT
    (( height > MAX_HEIGHT )) && height=$MAX_HEIGHT
    (( height > TERM_HEIGHT - 5 )) && height=$((TERM_HEIGHT - 5))

    echo "$width $height"

  }

  #!===

  #=== BUILD BREADCUMB ===

  # @description: Builds a breadcrumb navigation path showing the user's current position in the menu hierarchy
  #
  # @param:       NONE
  # @return:      Breadcrumb string (e.g., "Help System › Main Menu › Settings")
  #
  # @use_by:      show_error, show_option_error, show_file_error, show_text_with_buttons, show_file_with_buttons, show_language_menu, show_help_menu
  # @use_not_directly: NONE
  #
  # @use:         NONE

  build_breadcrumb() {

    local bc=""

    #--- No history and no current menu -> use default backtitle ---
    if [[ ${#MENU_HISTORY[@]} -eq 0 && -z "$CURRENT_MENU" ]]; then
      bc="$DEFAULT_BACKTITLE"
    else
      #--- Start with BACKTITLE or default, then add history path ---
      bc="${BACKTITLE:-$DEFAULT_BACKTITLE}"
      for h in "${MENU_HISTORY[@]}"; do
        bc="$bc › ${h//_/ }"  # Replace underscores with spaces for display
      done
      #--- Add current menu if exists ---
      [[ -n "$CURRENT_MENU" ]] && bc="$bc › ${CURRENT_MENU//_/ }"
    fi

    #--- Fallback to default if breadcrumb contains no letters (invalid state) ---
    if [[ ! "$bc" =~ [a-zA-Z] ]]; then
      bc="$DEFAULT_BACKTITLE"
    fi

    echo "$bc"

  }

  #!===

  # === LOG MESSAGE ===

  # @description: Logs messages with timestamp and level to log file if logging is enabled
  #
  # @param:       $1 - log level (ERROR, WARN, DEBUG, etc.)
  # @param:       $2 - message to log
  # @return:      NONE
  #
  # @use_by:      show_error, show_option_error, show_file_error, parse_ini_file, find_available_languages, scan_help_dirs
  # @use_not_directly: NONE
  #
  # @use:         NONE

  log_message() {
    [[ "$LOG" != "true" ]] && return 0
    local level="$1" message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $level: $message" >> "$LOG_FILE"
  }

  #!===


  # === VALIDATE ===

  # --- FILE PATH ---
  # @description: Validates file path security and accessibility
  #
  # @param:       $1 - file path to validate
  # @return:      0 if valid, 1 if invalid
  #
  # @use_by:      show_file_with_buttons, show_output_content
  # @use_not_directly: NONE
  #
  # @use:         NONE

  validate_file_path() {
    local file="$1"
    [[ "$file" =~ \.\. ]] && show_error "security" "Invalid file path: $file" "exit"
    [[ -f "$file" && -r "$file" ]] || return 1
    return 0
  }


  # --- CONFIG ---
  # @description: Validates that essential configuration keys are present
  #
  # @param:       NONE (uses global config array)
  # @return:      NONE
  #
  # @use_by:      load_help_file
  # @use_not_directly: NONE
  #
  # @use:         NONE

  validate_config() {
    local required_keys=("meta.name" "meta.lang" "meta.lang_code")
    for key in "${required_keys[@]}"; do
      [[ -z "${config[$key]}" ]] && show_error "config" "Missing required configuration: $key" "exit"
    done
    return 0
  }

 #!===

  # === PASE INI TO ARRAYS ===

  # @description: Core INI parsing function that reads file and populates arrays with configuration data
  #
  # @param:       $1 - file path to parse
  # @param:       $2 - reference to config associative array
  # @param:       $3 - reference to section order array
  # @param:       $4 - reference to menu order associative array
  # @return:      NONE
  #
  # @use_by:      parse_ini_file, find_available_languages
  # @use_not_directly: NONE
  #
  # @use:         NONE

  parse_ini_to_arrays() {

    local file="$1"
    local -n temp_config_ref="$2"
    local -n temp_section_order_ref="$3"
    local -n temp_menu_order_ref="$4"

    # --- Initialize output arrays ---
    temp_config_ref=()
    temp_section_order_ref=()
    temp_menu_order_ref=()
    local current_section=""

    # --- Read file line by line ---
    while IFS= read -r line || [[ -n $line ]]; do
      # Trim leading and trailing whitespace
      line="${line#"${line%%[![:space:]]*}"}"
      line="${line%"${line##*[![:space:]]}"}"

      # --- Skip empty lines ---
      [[ -z "$line" ]] && continue

      case "$line" in
        # --- Skip comments (lines starting with # or ;) ---
        \#*|\;*) continue ;;

        # --- Section header: [section_name] ---
        \[*\])
          current_section="${line:1:-1}"
          temp_section_order_ref+=("$current_section")
          ;;

        # --- Key-value pair: key=value ---
        *=*)
          local key="${line%%=*}"
          local value="${line#*=}"

          # --- Store in section.key format if inside a section ---
          if [[ -n "$current_section" && -n "$key" ]]; then
            temp_config_ref["$current_section.$key"]="$value"
            # --- Track menu order (exclude 'type' key) ---
            [[ "$key" != "type" ]] && temp_menu_order_ref["$current_section"]="${temp_menu_order_ref["$current_section"]:-} $key"
          else
            # --- Global key-value (no section) ---
            temp_config_ref["$key"]="$value"
          fi
          ;;
      esac
    done < "$file"

  }

  #!===

  # === PARSE INI FILE ===

  # @description: Parses INI file with caching and validation, loads configuration into global arrays
  #
  # @param:       $1 - INI file path to parse
  # @return:      0 on success, 1 on invalid file
  #
  # @use_by:      load_help_file, find_available_languages
  # @use_not_directly: NONE
  #
  # @use:         parse_ini_to_arrays, log_message, show_error

  # parse_ini_file() {

  #   local file="$1"
  #   local cache_key="${file}_parsed"

  #   # --- Check cache first ---
  #   if [[ -n "${config_cache[$cache_key]}" ]]; then
  #     log_message "DEBUG" "Using cached config for: $file"
  #     return 0
  #   fi

  #   local -A temp_config=()
  #   local temp_section_order=()
  #   local -A temp_menu_order=()

  #   # --- Use centralized parsing function ---
  #   parse_ini_to_arrays "$file" temp_config temp_section_order temp_menu_order

  #   local lang_code="${temp_config[meta.lang_code]:-}"
  #   local lang_name="${temp_config[meta.lang]:-}"
  #   local name="${temp_config[meta.name]:-}"

  #   # --- Validate essential INI metadata ---
  #   if [[ -z "$lang_code" || -z "$lang_name" || -z "$name" || "$name" != "$NAME_KEY" ]]; then
  #     log_message "WARN" "Invalid INI file skipped: $file"
  #     return 1
  #   fi

  #   # --- Check if valid menu section exists ---
  #   local valid_menu=false
  #   for section in "${temp_section_order[@]}"; do
  #     if [[ "${temp_config[$section.type]}" == "menu" ]]; then
  #       for k in "${!temp_config[@]}"; do
  #         if [[ "$k" == "$section."* ]] && [[ "$k" != "$section.type" ]]; then
  #           valid_menu=true
  #           break 2
  #         fi
  #       done
  #     fi
  #   done

  #   # --- Skip files without valid menu structure ---
  #   if [[ "$valid_menu" != true ]]; then
  #     if [[ "$INI_FILE_ERROR" == false ]]; then
  #       show_error "menu" "INI '$file' does not contain a valid menu, will be skipped"
  #       INI_FILE_ERROR=true
  #     fi
  #     return 1
  #   fi

  #   # --- Transfer configuration to global arrays ---
  #   for key in "${!temp_config[@]}"; do
  #     config["$key"]="${temp_config[$key]}"
  #   done

  #   section_order=("${temp_section_order[@]}")
  #   for section in "${!temp_menu_order[@]}"; do
  #     menu_order["$section"]="${temp_menu_order[$section]}"
  #   done

  #   # --- Store in cache for future use ---
  #   config_cache["$cache_key"]=1
  #   log_message "DEBUG" "Cached config for: $file"
  #   return 0

  # }

create_auto_menu_from_outputs() {
    local -n temp_config_ref="$1"
    local -n temp_section_order_ref="$2"
    local -n temp_menu_order_ref="$3"

    local auto_menu_name="AutoMainMenu"

    # Füge Auto-Menu als erste Sektion hinzu
    temp_section_order_ref=("$auto_menu_name" "${temp_section_order_ref[@]}")
    temp_config_ref["$auto_menu_name.type"]="menu"

    # Füge jeden Output als Menu-Eintrag hinzu
    local index=0
    for section in "${temp_section_order_ref[@]}"; do
        if [[ "$section" != "$auto_menu_name" && "$section" != "meta" && "$section" != "Messages" && "$section" != "Buttons" && "${temp_config_ref[$section.type]}" == "output" ]]; then
            local menu_key="item$index"
            temp_config_ref["$auto_menu_name.$menu_key"]="$section"
            temp_menu_order_ref["$auto_menu_name"]="${temp_menu_order_ref[$auto_menu_name]:-} $menu_key"
            ((index++))
        fi
    done

    log_message "INFO" "Created auto-menu '$auto_menu_name' with $index items"
}

parse_ini_file() {

  local file="$1"
  local cache_key="${file}_parsed"

  # Cache prüfen
  if [[ -n "${config_cache[$cache_key]}" ]]; then
    log_message "DEBUG" "Using cached config for: $file"
    return 0
  fi

  local -A temp_config=()
  local temp_section_order=()
  local -A temp_menu_order=()

  # Verwende die ausgelagerte Funktion
  parse_ini_to_arrays "$file" temp_config temp_section_order temp_menu_order

  local lang_code="${temp_config[meta.lang_code]:-}"
  local lang_name="${temp_config[meta.lang]:-}"
  local name="${temp_config[meta.name]:-}"

  if [[ -z "$lang_code" || -z "$lang_name" || -z "$name" || "$name" != "$NAME_KEY" ]]; then
    log_message "WARN" "Invalid INI file skipped: $file"
    return 1
  fi

  # Prüfen, ob Menü-Sektionen existieren
  local has_menu_sections=false
  local has_output_sections=false

  for section in "${temp_section_order[@]}"; do
    if [[ "${temp_config[$section.type]}" == "menu" ]]; then
      has_menu_sections=true
      break
    elif [[ "${temp_config[$section.type]}" == "output" ]]; then
      has_output_sections=true
    fi
  done

  # Wenn keine Menu-Sektionen aber Output-Sektionen existieren -> Auto-Menu erstellen
  if [[ "$has_menu_sections" != true && "$has_output_sections" == true ]]; then
    create_auto_menu_from_outputs temp_config temp_section_order temp_menu_order
    has_menu_sections=true
  fi

  if [[ "$has_menu_sections" != true ]]; then
    log_message "WARN" "INI '$file' does not contain any menu sections, will be skipped"
    return 1
  fi

  # Konfiguration in globale Arrays übernehmen
  for key in "${!temp_config[@]}"; do
    config["$key"]="${temp_config[$key]}"
  done

  section_order=("${temp_section_order[@]}")
  for section in "${!temp_menu_order[@]}"; do
    menu_order["$section"]="${temp_menu_order[$section]}"
  done

  # In Cache speichern
  config_cache["$cache_key"]=1
  log_message "DEBUG" "Cached config for: $file"
  return 0
}

  #!===

  # === SCAN DIRS ===

  # @description: Scans directories for valid INI files and populates INI_FILES array
  #
  # @param:       NONE (uses global HELP_FILES_DIR)
  # @return:      NONE
  #
  # @use_by:      find_available_languages
  # @use_not_directly: NONE
  #
  # @use:         show_error, log_message

  scan_help_dirs() {

    local dir_pattern="$HELP_FILES_DIR"
    local valid_dirs=()
    local dirs_array=($dir_pattern)

    # --- Single explicit directory: exit immediately on errors ---
    if [[ ${#dirs_array[@]} -eq 1 ]]; then
      local dir="${dirs_array[0]}"

      # --- Check if directory exists ---
      if [[ ! -d "$dir" ]]; then
        show_error "Error Directory" "Directory does not exist: $dir" "exit"
      fi

      # --- Scan for INI files in the directory ---
      local ini_files=()
      for file in "$dir"/*.ini; do
        [[ -f "$file" ]] && ini_files+=("$file")
      done

      # --- Check if any INI files were found ---
      if [[ ${#ini_files[@]} -eq 0 ]]; then
        show_error "Error Directory" "Directory contains no INI files: $dir" "exit"
      fi

      valid_dirs+=("$dir")
    else
      # --- Wildcards/multiple directories: check all, only exit if all fail ---
      local errors=()

      # --- Process each directory matching the pattern ---
      for dir in $dir_pattern; do
        # Check directory existence
        if [[ ! -d "$dir" ]]; then
          errors+=("Directory does not exist: $dir")
          continue
        fi

        # --- Scan for INI files ---
        local ini_files=()
        for file in "$dir"/*.ini; do
          [[ -f "$file" ]] && ini_files+=("$file")
        done

        # --- Skip directories without INI files ---
        if [[ ${#ini_files[@]} -eq 0 ]]; then
          errors+=("Directory contains no INI files: $dir")
          continue
        fi

        valid_dirs+=("$dir")
      done

      # --- Exit if no valid directories were found ---
      if [[ ${#valid_dirs[@]} -eq 0 ]]; then
        local error_msg=""
        for err in "${errors[@]}"; do
          error_msg+="$err\n"
        done
        show_error "Error Directory" "${error_msg}No valid directories found!" "exit"
      fi

      # Log individual errors for debugging
      for err in "${errors[@]}"; do
        log_message "WARN" "$err"
      done
    fi

    # --- Update global INI_FILES array with valid directories ---
    INI_FILES=("${valid_dirs[@]}")

  }

  #!===

  # === FIND AVAILABLE LANGUAGES ===

  # @description: Discovers and validates available language files, sets current language based on defaults or availability
  #
  # @param:       NONE
  # @return:      NONE
  #
  # @use_by:      find_best_language_file, show_language_menu
  # @use_not_directly: NONE
  #
  # @use:         show_error, scan_help_dirs, parse_ini_to_arrays, log_message

  # find_available_languages() {

  #   available_languages=()
  #   language_files=()
  #   language_names=()

  #   # Validate that NAME_KEY is set before proceeding
  #   [[ -z "$NAME_KEY" ]] && show_error "config" "NAME_KEY must be set before calling find_available_languages!" "exit"

  #   # --- Scan directories for INI files ---
  #   scan_help_dirs

  #   local valid_dirs=("${INI_FILES[@]}")
  #   [[ ${#valid_dirs[@]} -eq 0 ]] && show_error "config" "No directories with INI files found!" "exit"

  #   local temp_current_lang_file=""
  #   local temp_current_lang_code=""
  #   local temp_current_lang_name=""

  #   # --- Process each directory and scan for language files ---
  #   for dir in "${valid_dirs[@]}"; do
  #     shopt -s nullglob  # Enable nullglob to handle empty directories
  #     for file in "$dir"/*.ini; do
  #       [[ -f "$file" ]] || continue

  #       # --- Use centralized parsing function to read INI file ---
  #       local -A file_config=()
  #       local -a file_section_order=()
  #       local -A file_menu_order=()

  #       parse_ini_to_arrays "$file" file_config file_section_order file_menu_order

  #       local lang_code="${file_config[meta.lang_code]:-}"
  #       local lang_name="${file_config[meta.lang]:-}"
  #       local name="${file_config[meta.name]:-}"

  #       # --- Skip invalid INI files (missing required metadata or wrong name key) ---
  #       if [[ -z "$lang_code" || -z "$lang_name" || -z "$name" || "$name" != "$NAME_KEY" ]]; then
  #         continue
  #       fi

  #       # --- Check if valid menu section exists in the INI file ---
  #       local valid_menu=false
  #       for section in "${file_section_order[@]}"; do
  #         if [[ "${file_config[$section.type]}" == "menu" ]]; then
  #           for k in "${!file_config[@]}"; do
  #             if [[ "$k" == "$section."* ]] && [[ "$k" != "$section.type" ]]; then
  #               valid_menu=true
  #               break 2
  #             fi
  #           done
  #         fi
  #       done

  #       # --- Skip files without valid menu structure ---
  #       if [[ "$valid_menu" != true ]]; then
  #         if [[ "$INI_FILE_ERROR" == false ]]; then
  #           show_error "menu" "INI '$file' does not contain a valid menu, will be skipped"
  #           INI_FILE_ERROR=true
  #         fi
  #         continue
  #       fi

  #       # --- Add valid language to available languages ---
  #       available_languages["$lang_code"]="$lang_name"
  #       language_files["$lang_code"]="$file"
  #       language_names["$lang_code"]="$name"

  #       # --- Remember if this is the default language ---
  #       if [[ "$lang_code" == "$DEFAULT_LANG" ]]; then
  #         temp_current_lang_file="$file"
  #         temp_current_lang_code="$lang_code"
  #         temp_current_lang_name="$lang_name"
  #       fi

  #     done
  #     shopt -u nullglob  # Disable nullglob
  #   done

  #   # --- Set current language: Default -> Fallback -> first available ---
  #   if [[ -n "$temp_current_lang_file" ]]; then
  #     CURRENT_LANG_FILE="$temp_current_lang_file"
  #     CURRENT_LANG_CODE="$temp_current_lang_code"
  #     CURRENT_LANG_NAME="$temp_current_lang_name"
  #   elif [[ -n "${language_files[$DEFAULT_LANG_FALLBACK]}" ]]; then
  #     CURRENT_LANG_FILE="${language_files[$DEFAULT_LANG_FALLBACK]}"
  #     CURRENT_LANG_CODE="$DEFAULT_LANG_FALLBACK"
  #     CURRENT_LANG_NAME="${available_languages[$DEFAULT_LANG_FALLBACK]}"
  #     show_error "config" "Default Language <$DEFAULT_LANG> not found! Load <$CURRENT_LANG_CODE>."
  #   else
  #     # --- Fallback to first available language ---
  #     for l in "${!language_files[@]}"; do
  #       CURRENT_LANG_FILE="${language_files[$l]}"
  #       CURRENT_LANG_CODE="$l"
  #       CURRENT_LANG_NAME="${available_languages[$l]}"
  #       show_error "config" "Default Language <$DEFAULT_LANG> & Fallback Language <$DEFAULT_LANG_FALLBACK> not found! Load <$CURRENT_LANG_CODE>"
  #       break
  #     done
  #   fi

  #   # --- Exit if no valid language files were found ---
  #   [[ ${#available_languages[@]} -eq 0 ]] && show_error "config" "No valid INI files found!" "exit"

  # }

find_available_languages() {
  available_languages=()
  language_files=()
  language_names=()
  [[ -z "$NAME_KEY" ]] && show_error "config" "NAME_KEY must be set before calling find_available_languages!" "exit"

  scan_help_dirs

  local valid_dirs=("${INI_FILES[@]}")
  [[ ${#valid_dirs[@]} -eq 0 ]] && show_error "config" "No directories with INI files found!" "exit"

  local temp_current_lang_file=""
  local temp_current_lang_code=""
  local temp_current_lang_name=""

  for dir in "${valid_dirs[@]}"; do
    shopt -s nullglob
    for file in "$dir"/*.ini; do
      [[ -f "$file" ]] || continue

      # Verwende die ausgelagerte Funktion
      local -A file_config=()
      local -a file_section_order=()
      local -A file_menu_order=()

      parse_ini_to_arrays "$file" file_config file_section_order file_menu_order

      local lang_code="${file_config[meta.lang_code]:-}"
      local lang_name="${file_config[meta.lang]:-}"
      local name="${file_config[meta.name]:-}"

      # Nur Meta-Daten prüfen - KEINE Menü-Validierung!
      if [[ -z "$lang_code" || -z "$lang_name" || -z "$name" || "$name" != "$NAME_KEY" ]]; then
        continue
      fi

      # Alle gültigen INIs aufnehmen - OHNE Menü-Prüfung!
      available_languages["$lang_code"]="$lang_name"
      language_files["$lang_code"]="$file"
      language_names["$lang_code"]="$name"

      # Wenn Default-Sprache passt, merken
      if [[ "$lang_code" == "$DEFAULT_LANG" ]]; then
        temp_current_lang_file="$file"
        temp_current_lang_code="$lang_code"
        temp_current_lang_name="$lang_name"
      fi

    done
    shopt -u nullglob
  done

  # Aktuelle Sprache setzen: Default -> Fallback -> erste verfügbare
  if [[ -n "$temp_current_lang_file" ]]; then
    CURRENT_LANG_FILE="$temp_current_lang_file"
    CURRENT_LANG_CODE="$temp_current_lang_code"
    CURRENT_LANG_NAME="$temp_current_lang_name"
  elif [[ -n "${language_files[$DEFAULT_LANG_FALLBACK]}" ]]; then
    CURRENT_LANG_FILE="${language_files[$DEFAULT_LANG_FALLBACK]}"
    CURRENT_LANG_CODE="$DEFAULT_LANG_FALLBACK"
    CURRENT_LANG_NAME="${available_languages[$DEFAULT_LANG_FALLBACK]}"
    show_error "config" "Default Language <$DEFAULT_LANG> not found! Load <$CURRENT_LANG_CODE>."
  else
    for l in "${!language_files[@]}"; do
      CURRENT_LANG_FILE="${language_files[$l]}"
      CURRENT_LANG_CODE="$l"
      CURRENT_LANG_NAME="${available_languages[$l]}"
      show_error "config" "Default Language <$DEFAULT_LANG> & Fallback Language <$DEFAULT_LANG_FALLBACK> not found! Load <$CURRENT_LANG_CODE>"
      break
    done
  fi

  [[ ${#available_languages[@]} -eq 0 ]] && show_error "config" "No valid INI files found!" "exit"
}


  #!===

  # === FIND BEST LANGAUAGE FILE ===

  # @description: Determines the best available language file based on defaults and fallbacks
  #
  # @param:       NONE
  # @return:      NONE
  #
  # @use_by:      load_help_file
  # @use_not_directly: NONE
  #
  # @use:         find_available_languages, show_error

  find_best_language_file() {

    # --- Return early if language file is already set ---
    [[ -n "$CURRENT_LANG_FILE" ]] && return

    # --- Discover available languages first ---
    find_available_languages

    local best_lang=""

    # --- Language selection priority: Default -> Fallback -> First available ---
    if [[ -n "$DEFAULT_LANG" ]] && [[ -n "${language_files[$DEFAULT_LANG]}" ]]; then
      best_lang="$DEFAULT_LANG"
    elif [[ -n "$DEFAULT_LANG_FALLBACK" ]] && [[ -n "${language_files[$DEFAULT_LANG_FALLBACK]}" ]]; then
      best_lang="$DEFAULT_LANG_FALLBACK"
    else
      # --- Fallback to first available language ---
      for l in "${!language_files[@]}"; do
        best_lang="$l"
        break
      done
    fi

    # --- Set current language variables if best language was found ---
    [[ -n "$best_lang" ]] && \
      CURRENT_LANG_FILE="${language_files[$best_lang]}" && \
      CURRENT_LANG_CODE="$best_lang" && \
      CURRENT_LANG_NAME="${available_languages[$best_lang]}" && \
      return

    # --- Exit if no language file could be determined ---
    show_error "config" "No language file found!" "exit"

  }

  #!===

  # === LOAD HELP FILE ===

  # @description: Loads and validates the help file configuration, sets up main menu and caches results
  #
  # @param:       NONE
  # @return:      NONE
  #
  # @use_by:      setup_config_variables
  # @use_not_directly: NONE
  #
  # @use:         find_best_language_file, show_error, parse_ini_file, validate_config

  load_help_file() {

    # --- Return early if configuration is already loaded ---
    $CONFIG_LOADED && return

    # --- Find and set the best available language file ---
    find_best_language_file || return 1
    [[ -z "$CURRENT_LANG_FILE" ]] && show_error "config" "No language file" "exit"

    # --- Check if this file is already cached ---
    local temp_cache_key="${CURRENT_LANG_FILE}_temp"
    [[ -n "${config_cache[$temp_cache_key]}" ]] && { CONFIG_LOADED=true; return 0; }

    # --- Parse configuration (uses caching internally) ---
    if ! parse_ini_file "$CURRENT_LANG_FILE"; then
      show_error "config" "Failed to parse language file: $CURRENT_LANG_FILE" "exit"
    fi

    # --- Find main menu section ---
    local found_menu=""
    for section in "${section_order[@]}"; do
      [[ "${config[$section.type]}" == "menu" ]] && { found_menu="$section"; break; }
    done
    # --- Fallback to first section if no menu found ---
    [[ -z "$found_menu" ]] && found_menu="${section_order[0]}"
    CURRENT_MENU="$found_menu"

    # --- Validate essential configuration ---
    validate_config

    # --- Cache successful load ---
    config_cache["$temp_cache_key"]=1
    CONFIG_LOADED=true

  }

  #!===

  # === SETUP CONFIG VARIABLES ===

  # @description: Sets up global configuration variables with fallbacks to defaults
  #
  # @param:       NONE
  # @return:      NONE
  #
  # @use_by:      find_menu_sections, show_language_menu, show_output_content, show_help_menu
  # @use_not_directly: NONE
  #
  # @use:         load_help_file

  setup_config_variables() {
    # Load help file configuration first
    load_help_file || return 1

    # Set configuration variables with fallback to defaults
    BACKTITLE="${config[meta.backtitle]:-$DEFAULT_BACKTITLE}"
    LANGUAGE="${config[meta.lang]:-$CURRENT_LANG_NAME}"
    LANGUAGE_CODE="${config[meta.lang_code]:-$CURRENT_LANG_CODE}"
    OPTION_ERROR="${config[Messages.option_error]:-$DEFAULT_OPTION_ERROR}"
    FILE_ERROR="${config[Messages.file_error]:-$DEFAULT_FILE_ERROR}"
    FILE_LABEL="${config[Messages.file_label]:-$DEFAULT_FILE_LABEL}"
    MENU_TEXT="${config[Messages.menu]:-$DEFAULT_MENU_TEXT}"
    BUTTON_LANG="${config[Buttons.language]:-$DEFAULT_BUTTON_LANG}"
    BUTTON_OK="${config[Buttons.ok]:-$DEFAULT_BUTTON_OK}"
    BUTTON_CANCEL="${config[Buttons.cancel]:-$DEFAULT_BUTTON_CANCEL}"
    BUTTON_BACK="${config[Buttons.back]:-$DEFAULT_BUTTON_BACK}"
    BUTTON_BACK_MAIN="${config[Buttons.back_main]:-$DEFAULT_BUTTON_BACK_MAIN}"
    BUTTON_EXIT="${config[Buttons.exit]:-$DEFAULT_BUTTON_EXIT}"
    BUTTON_NEXT="${config[Buttons.next]:-$DEFAULT_BUTTON_NEXT}"
    BUTTON_CLOSE="${config[Buttons.close]:-$DEFAULT_BUTTON_CLOSE}"
  }

  #!===

  # === FIND MENU SECTIONS ===

  # --- FIND MENU SECTIONS ---

  # @description: Discovers and collects all menu sections from the configuration
  #
  # @param:       NONE
  # @return:      NONE
  #
  # @use_by:      show_help_menu
  # @use_not_directly: NONE
  #
  # @use:         setup_config_variables
  find_menu_sections() {
    setup_config_variables || return 1
    menu_sections=()
    for s in "${section_order[@]}"; do
      [[ "${config[$s.type]}" == "menu" ]] && menu_sections+=("$s")
    done
  }

  # --- IS MENU SECTION ? ---

  # @description: Checks if a section is a menu section
  #
  # @param:       $1 - section name to check
  # @return:      0 if menu section, 1 otherwise
  #
  # @use_by:      show_help_menu
  # @use_not_directly: NONE
  #
  # @use:         NONE
  is_menu_section() { [[ "${config[$1.type]}" == "menu" ]]; }

  # --- IS OUTER SECTION ? ---

  # @description: Checks if a section is an output section (has text or file content)
  #
  # @param:       $1 - section name to check
  # @return:      0 if output section, 1 otherwise
  #
  # @use_by:      show_help_menu
  # @use_not_directly: NONE
  #
  # @use:         NONE
  is_output_section() { [[ -n "${config[$1.text]}" || -n "${config[$1.file]}" ]]; }

  #!===

  # === ERROR SECTION ===

  # --- SHOW ERROR ---

  # @description: Displays error messages in whiptail dialogs with appropriate titles and logging
  #
  # @param:       $1 - error type (config, file, menu, security)
  # @param:       $2 - error message to display
  # @param:       $3 - mode (optional, "exit" to terminate script)
  # @return:      NONE
  #
  # @use_by:      show_option_error, show_file_error, validate_file_path, validate_config, scan_help_dirs,
  #               find_available_languages, parse_ini_file, load_help_file, show_help_menu
  # @use_not_directly: NONE
  #
  # @use:         log_message, calculate_dimensions, build_breadcrumb, whiptail
  show_error() {

    local type="$1" msg="$2" mode="${3:-}"
    local title="" ok_button="${config[Buttons.ok]:-$DEFAULT_BUTTON_OK}"

    # Set title based on error type
    case "$type" in
      "config") title="Configuration Error" ;;
      "file") title="File Error" ;;
      "menu") title="Menu Error" ;;
      "security") title="Security Error" ;;
      *) title="$type" ;;
    esac

    log_message "ERROR" "$type: $msg"

    if [[ "$mode" == "exit" ]]; then
      read -r width height < <(calculate_dimensions "$msg")
      whiptail --backtitle "$(build_breadcrumb)" \
              --title "$title" \
              --ok-button "Close" \
              --msgbox "$msg" 0 $width
      exit 1
    else
      read -r width height < <(calculate_dimensions "$msg")
      whiptail --backtitle "$(build_breadcrumb)" \
              --title "$title" \
              --ok-button "$ok_button" \
              --msgbox "$msg" 0 $width
    fi

  }

  # --- SHOW OPTION ERROR ---

  # @description: Displays menu option errors with configurable message and mode
  #
  # @param:       $1 - error message (optional, uses config default if not provided)
  # @param:       $2 - mode (optional, "exit" to terminate script)
  # @return:      0 always
  #
  # @use_by:      show_help_menu, show_output_content
  # @use_not_directly: NONE
  #
  # @use:         show_error
  show_option_error() {
    local msg="${1:-${config[Messages.option_error]:-$DEFAULT_OPTION_ERROR}}"
    local mode="${2:-}"
    show_error "menu" "$msg" "$mode"
    return 0
  }

  # --- SHOW FILE ERROR ---

  # @description: Displays file-related errors with formatted message including file path
  #
  # @param:       $1 - file path that caused the error
  # @return:      0 always
  #
  # @use_by:      show_file_with_buttons
  # @use_not_directly: NONE
  #
  # @use:         show_error
  show_file_error() {
    local file_path="$1"
    local file_error_message="${config[Messages.file_error]:-$DEFAULT_FILE_ERROR}"
    local file_label="${config[Messages.file_label]:-$DEFAULT_FILE_LABEL}"
    local full_message="$file_error_message\n\n$file_label: $file_path"
    show_error "file" "$full_message"
    return 0
  }

  #!===

  # === SHOW CONTENT ===

  # --- SHOW TEXT BUTTONS ---

  # @description: Displays text content in a whiptail dialog with custom yes/no buttons
  #
  # @param:       $1 - dialog title
  # @param:       $2 - text content to display
  # @param:       $3 - yes button label
  # @param:       $4 - no button label
  # @return:      whiptail exit status
  #
  # @use_by:      show_output_content
  # @use_not_directly: NONE
  #
  # @use:         calculate_dimensions, build_breadcrumb, whiptail
  show_text_with_buttons() {
    local title="$1"
    local text="$2"
    local yes_button="$3"
    local no_button="$4"
    read -r width height < <(calculate_dimensions "$text")
    whiptail --backtitle "$(build_breadcrumb)" \
            --title "$title" \
            --yes-button "$yes_button" \
            --no-button "$no_button" \
            --yesno "$text" "$height" "$width"
  }

  # --- SHOW FILE BUTTONS ---

  # @description: Displays file content in a whiptail dialog with custom yes/no buttons
  #
  # @param:       $1 - dialog title
  # @param:       $2 - file path to display
  # @param:       $3 - yes button label
  # @param:       $4 - no button label
  # @return:      whiptail exit status, 1 if file error
  #
  # @use_by:      show_output_content
  # @use_not_directly: NONE
  #
  # @use:         validate_file_path, show_file_error, calculate_dimensions, build_breadcrumb, whiptail
  show_file_with_buttons() {
    local title="$1"
    local file="$2"
    local yes_button="$3"
    local no_button="$4"
    validate_file_path "$file" || { show_file_error "$file"; return 1; }
    local file_content=$(cat "$file")
    read -r width height < <(calculate_dimensions "$file_content")
    whiptail --backtitle "$(build_breadcrumb)" \
            --title "$title" \
            --yes-button "$yes_button" \
            --no-button "$no_button" \
            --yesno "$file_content" "$height" "$width"
  }

  #!===

  # === SHOE LANGUAGE MENU ===

  # @description: Displays language selection menu and handles language switching
  #
  # @param:       NONE
  # @return:      NONE
  #
  # @use_by:      show_help_menu
  # @use_not_directly: NONE
  #
  # @use:         find_available_languages, build_breadcrumb, setup_config_variables, find_menu_sections

  show_language_menu() {

    # --- Load available languages first ---
    find_available_languages

    local menu_items=()
    local default_item=""

    # --- Build menu items from available languages ---
    for code in "${!available_languages[@]}"; do
      local key=$(echo "$code" | tr '[:lower:]' '[:upper:]')
      menu_items+=("$key" "${available_languages[$code]}")
      # --- Set current language as default selection ---
      [[ "$code" == "$CURRENT_LANG_CODE" ]] && default_item="$key"
    done

    # --- Display language selection menu ---
    local choice
    choice=$(whiptail --backtitle "$(build_breadcrumb)" \
              --title "$LANGUAGE" \
              --ok-button "$BUTTON_OK" \
              --cancel-button "$BUTTON_BACK" \
              --default-item "$default_item" \
              --menu "$BUTTON_LANG:" \
              0 $MIN_WIDTH 0 \
              "${menu_items[@]}" 3>&1 1>&2 2>&3)
    local status=$?

    # --- Handle user selection ---
    if [[ $status -eq 0 ]] && [[ -n "$choice" ]]; then
      # --- Convert selection back to lowercase and update language ---
      local selected_lower=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
      CURRENT_LANG_FILE="${language_files[$selected_lower]}"
      CURRENT_LANG_CODE="$selected_lower"
      CURRENT_LANG_NAME="${available_languages[$selected_lower]}"

      # --- Reset configuration cache and reload ---
      CONFIG_LOADED=false
      config_cache=()
      CURRENT_MENU=""
      setup_config_variables
      find_menu_sections

    elif [[ $status -eq 1 ]]; then
      # --- User pressed Cancel/Back ---
      return 0
    elif [[ $status -eq 255 ]]; then
      # --- User pressed ESC ---
      exit 0
    fi
  }

  #!===

  # ===  SHOW OUTPUT CONTENT ===

  # @description: Displays content from a section with pagination and navigation controls
  #
  # @param:       $1 - section name to display content from
  # @return:      0 on success, 1 if no content found
  #
  # @use_by:      show_help_menu
  # @use_not_directly: NONE
  #
  # @use:         show_option_error, show_text_with_buttons, show_file_with_buttons

  show_output_content() {

    local section="$1"
    local title="${section//_/ }"

    # --- Collect all text/file content from the section ---
    local -a contents
    local -a content_types

    local current_file="$CURRENT_LANG_FILE"

    if [[ -f "$current_file" ]]; then
      local in_section=false
      local current_section=""

      # --- Parse the INI file to extract content from the specified section ---
      while IFS= read -r line || [[ -n $line ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # --- Detect section headers ---
        if [[ "$line" =~ ^\[.*\]$ ]]; then
          current_section="${line:1:-1}"
          if [[ "$current_section" == "$section" ]]; then
            in_section=true
          else
            in_section=false
          fi
          continue
        fi

        # --- Process key-value pairs within the target section ---
        if [[ "$in_section" == true ]] && [[ "$line" =~ ^[^#\;].*= ]]; then
          local key="${line%%=*}"
          local value="${line#*=}"

          # --- Collect text and file content ---
          if [[ "$key" =~ ^text[0-9]*$ ]]; then
            contents+=("$value")
            content_types+=("text")
          elif [[ "$key" =~ ^file[0-9]*$ ]]; then
            contents+=("$value")
            content_types+=("file")
          fi
        fi
      done < "$current_file"
    fi

    local total_contents=${#contents[@]}

    # --- Return error if no content found ---
    if [[ $total_contents -eq 0 ]]; then
      show_option_error "No content found for: $section"
      return 1
    fi

    local current_index=0

    # --- Display content with pagination ---
    while [[ $current_index -lt $total_contents ]]; do
      local page_number=$((current_index + 1))
      local page_title="$title (Page $page_number/$total_contents)"
      local content="${contents[$current_index]}"
      local content_type="${content_types[$current_index]}"

      # --- BUTTON LOGIC: ---
      if [[ $page_number -eq 1 ]]; then
        # PAGE 1: Close (left) and Next (right)
        if [[ "$content_type" == "text" ]]; then
          show_text_with_buttons "$page_title" "$content" "$BUTTON_CLOSE" "$BUTTON_NEXT"
        else
          show_file_with_buttons "$page_title" "$content" "$BUTTON_CLOSE" "$BUTTON_NEXT"
        fi
      elif [[ $page_number -eq $total_contents ]]; then
        # LAST PAGE: Back (left) and Close (right)
        if [[ "$content_type" == "text" ]]; then
          show_text_with_buttons "$page_title" "$content" "$BUTTON_BACK" "$BUTTON_CLOSE"
        else
          show_file_with_buttons "$page_title" "$content" "$BUTTON_BACK" "$BUTTON_CLOSE"
        fi
      else
        # MIDDLE PAGES: Back (left) and Next (right)
        if [[ "$content_type" == "text" ]]; then
          show_text_with_buttons "$page_title" "$content" "$BUTTON_BACK" "$BUTTON_NEXT"
        else
          show_file_with_buttons "$page_title" "$content" "$BUTTON_BACK" "$BUTTON_NEXT"
        fi
      fi

      # --- Navigation handling ---
      local exit_status=$?

      if [[ $exit_status -eq 0 ]]; then
        # OK Button (left) was pressed
        if [[ $page_number -eq 1 ]]; then
          # Page 1: Close - exit
          break
        else
          # Other pages: Back - go back
          ((current_index--))
        fi
      elif [[ $exit_status -eq 1 ]]; then
        # Cancel Button (right) was pressed
        if [[ $page_number -eq $total_contents ]]; then
          # Last page: Cancel - exit
          break
        else
          # Other pages: Next - continue
          ((current_index++))
        fi
      else
        # ESC key pressed
        break
      fi
    done

    return 0

  }

  #!===

  # === SHOW HELP MENU ===

  # @description: Main menu loop that displays navigation menu and handles user interactions
  #
  # @param:       NONE
  # @return:      NONE
  #
  # @use_by:      Script entry point
  # @use_not_directly: NONE
  #
  # @use:         setup_config_variables, show_error, find_menu_sections, build_breadcrumb,
  #               show_language_menu, show_output_content, show_option_error, whiptail

  show_help_menu() {

    while true; do
      # Load configuration variables
      setup_config_variables || {
        show_error "config" "Failed to load configuration" "exit"
      }

      local menu_items=()
      local -a ordered_keys

      # --- Determine menu item order ---
      if [[ -n "${menu_order[$CURRENT_MENU]}" ]]; then
        read -ra ordered_keys <<< "${menu_order[$CURRENT_MENU]}"
      else
        # --- Fallback: collect all keys for current menu ---
        for key in "${!config[@]}"; do
          if [[ "$key" == "$CURRENT_MENU."* && "$key" != "$CURRENT_MENU.type" ]]; then
            ordered_keys+=("${key#$CURRENT_MENU.}")
          fi
        done
      fi

      # --- Add menu items in determined order ---
      for key in "${ordered_keys[@]}"; do
        local full_key="$CURRENT_MENU.$key"
        [[ -n "${config[$full_key]}" ]] && menu_items+=("$key" "${config[$full_key]}")
      done

      # --- Fallback if no menu items found ---
      if [[ ${#menu_items[@]} -eq 0 ]]; then
        show_error "menu" "No menu items found for: $CURRENT_MENU"
        # Return to main menu
        find_menu_sections
        if [[ ${#menu_sections[@]} -gt 0 ]]; then
          CURRENT_MENU="${menu_sections[0]}"
          MENU_HISTORY=()
        else
          show_error "menu" "No valid menu sections found!" "exit"
        fi
        continue
      fi

      # --- Add language menu option only in main menu with multiple languages ---
      if [[ ${#MENU_HISTORY[@]} -eq 0 ]] && [[ ${#available_languages[@]} -gt 1 ]]; then
        local lang_upper=$(echo "$CURRENT_LANG_CODE" | tr '[:lower:]' '[:upper:]')
        local current_button_lang="${config[Buttons.language]:-$DEFAULT_BUTTON_LANG}"
        menu_items+=("$lang_upper" "$current_button_lang")
      fi

      # --- Set cancel button based on menu depth ---
      local cancel_button
      [[ ${#MENU_HISTORY[@]} -eq 0 ]] && cancel_button="$BUTTON_EXIT" || cancel_button="$BUTTON_BACK"

      # --- Calculate optimal menu dimensions ---
      local max_len=0
      for i in "${menu_items[@]}"; do (( ${#i} > max_len )) && max_len=${#i}; done
      local TERM_WIDTH=$(tput cols)
      local width=$((max_len + PADDING*2))
      (( width < MIN_WIDTH )) && width=$MIN_WIDTH
      (( width > MAX_WIDTH )) && width=$MAX_WIDTH
      (( width > TERM_WIDTH - 10 )) && width=$((TERM_WIDTH - 10))
      local height=${#menu_items[@]}
      (( height < MIN_HEIGHT )) && height=$MIN_HEIGHT
      (( height > MAX_HEIGHT )) && height=$MAX_HEIGHT
      local menu_height=$((height > 0 ? height : 10))

      # --- Display whiptail menu ---
      local choice
      choice=$(whiptail --backtitle "$(build_breadcrumb)" \
                --title "${CURRENT_MENU//_/ }" \
                --ok-button "$BUTTON_OK" \
                --cancel-button "$cancel_button" \
                --menu "$MENU_TEXT" \
                "$menu_height" "$width" 0 \
                "${menu_items[@]}" 3>&1 1>&2 2>&3)
      local status=$?

      # --- Handle user selection ---
      if [[ $status -eq 0 ]] && [[ -n "$choice" ]]; then
        # Language menu selection
        if [[ ${#MENU_HISTORY[@]} -eq 0 ]] && [[ "$choice" == "$(echo "$CURRENT_LANG_CODE" | tr '[:lower:]' '[:upper:]')" ]]; then
          show_language_menu
          continue
        fi

        # --- Find selected menu/output ---
        local selected_value="${config[${CURRENT_MENU}.${choice}]}"
        local selected_type="${config[${selected_value}.type]}"

        if [[ "$selected_type" == "menu" ]]; then
          # --- Navigate to submenu ---
          MENU_HISTORY+=("$CURRENT_MENU")
          CURRENT_MENU="$selected_value"
        elif [[ "$selected_type" == "output" ]]; then
          # --- Display output content with navigation ---
          show_output_content "$selected_value"
        else
          show_option_error
        fi

      elif [[ $status -eq 1 ]]; then
        # Back navigation
        if [[ ${#MENU_HISTORY[@]} -eq 0 ]]; then
          exit 0
        fi
        CURRENT_MENU="${MENU_HISTORY[-1]}"
        MENU_HISTORY=("${MENU_HISTORY[@]:0:$((${#MENU_HISTORY[@]}-1))}")
      elif [[ $status -eq 255 ]]; then
        # ESC key pressed
        exit 0
      fi
    done

  }

  #!===

# -------------------------------
# Start
# -------------------------------
show_help_menu


}


Help
