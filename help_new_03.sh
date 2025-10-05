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

DEFAULT_LANG="$CURRENT_LANG"

DEFAULT_LANG_FALLBACK="en"

# VARIABLEN-DEKLARATIONEN
declare -A config available_languages language_files language_names config_cache menu_order
declare -a section_order menu_sections MENU_HISTORY
declare -A _temp_config _temp_menu_order
declare -a _temp_section_order

# KONSTANTEN
NAME_KEY="help"
HELP_FILES_DIR="./**/**/"
LOG=true

# FEHLENDE GLOBAL-VARIABLEN
[[ -z "${TEXT_MENU_PROMPT+x}" ]] && TEXT_MENU_PROMPT="Choose an option:"
[[ -z "${BTN_LANGUAGE+x}" ]] && BTN_LANGUAGE="Language"
[[ -z "${SYS_LOG_FILE+x}" ]] && SYS_LOG_FILE="/tmp/help_system.log"

# INTERNE VARIABLEN
CURRENT_LANG_FILE=""
CURRENT_LANG_CODE=""
CURRENT_LANG_NAME=""
CURRENT_MENU=""
CONFIG_LOADED=false
INI_FILES=()
BLOCKED_PATHS=()


  # === HELPER FUNKTIONS ===

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

  # === VALIDATE ===

  # FUNCTION VALIDATE FILE PATH

  validate_file_path() {
    local file="$1"

    # Security check for path traversal
    [[ "$file" =~ \.\. ]] && show_error -t "Security Error" -c 400 -i "$file" -x

    # Check if file exists and is readable
    [[ -f "$file" && -r "$file" ]] || return 1

    return 0
  }

  validate_config() {
    local required_keys=("meta.name" "meta.lang_code")

    for key in "${required_keys[@]}"; do
        [[ -z "${config[$key]}" ]] && show_error -t "Configuration Error" -c 100 -i "$key" -x
    done

    return 0
  }


  # FUNCTION CALIDATE INI STRUCTURE

  validate_ini_structure() {

    local file="$1"
    local has_menu_sections=false
    local has_output_sections=false

    for section in "${_temp_section_order[@]}"; do
      local section_type="${_temp_config[$section.type]}"
      if [[ "$section_type" == "menu" ]]; then
        has_menu_sections=true
        break
      elif [[ "$section_type" == "output" ]]; then
        has_output_sections=true
      fi
    done

    if [[ "$has_menu_sections" != true && "$has_output_sections" == true ]]; then
      create_auto_menu_from_outputs
      has_menu_sections=true
    fi

    if [[ "$has_menu_sections" != true ]]; then
      show_error -t "Configuration Error" -c 101 -i "$file" -l "$ERR_104"
      BLOCKED_PATHS+=("$file")
      return 1
    fi

    return 0

  }

  #!===

  # FUNCTION APPLY CONFIG OVERRIDES

  apply_config_overrides() {
    # META - Überschreibungen
    [[ -n "${config[meta.backtitle]}" ]] && TEXT_BACKTITLE="${config[meta.backtitle]}"

    # TEXTE - Überschreibungen
    [[ -n "${config[Messages.menu]}" ]] && TEXT_MENU_PROMPT="${config[Messages.menu]}"
    [[ -n "${config[Messages.file_label]}" ]] && TEXT_FILE_LABEL="${config[Messages.file_label]}"

    # BUTTONS - Überschreibungen
    [[ -n "${config[Buttons.language]}" ]] && BTN_LANGUAGE="${config[Buttons.language]}"
    [[ -n "${config[Buttons.ok]}" ]] && BTN_OK="${config[Buttons.ok]}"
    [[ -n "${config[Buttons.cancel]}" ]] && BTN_CANCEL="${config[Buttons.cancel]}"
    [[ -n "${config[Buttons.close]}" ]] && BTN_CLOSE="${config[Buttons.close]}"
    [[ -n "${config[Buttons.back]}" ]] && BTN_BACK="${config[Buttons.back]}"
    [[ -n "${config[Buttons.prev]}" ]] && BTN_PREV="${config[Buttons.prev]}"
    [[ -n "${config[Buttons.next]}" ]] && BTN_NEXT="${config[Buttons.next]}"
    [[ -n "${config[Buttons.home]}" ]] && BTN_HOME="${config[Buttons.home]}"
    [[ -n "${config[Buttons.exit]}" ]] && BTN_EXIT="${config[Buttons.exit]}"
    [[ -n "${config[Buttons.help]}" ]] && BTN_HELP="${config[Buttons.help]}"
  }

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

  # FUNCTION SCAN DIRS

  scan_dirs() {

    local dir_pattern="$HELP_FILES_DIR"
    local valid_dirs=()

    local dirs_array=($dir_pattern)

    # Single explicit directory: exit immediately on errors
    if [[ ${#dirs_array[@]} -eq 1 ]]; then
      local dir="${dirs_array[0]}"
      dir="${dir//\/\//\/}"  # Clean double slashes

      # Check if directory exists
      if [[ ! -d "$dir" ]]; then
        show_error -t "Directory Error" -c 203 -i "$dir" -x
      fi

      # Scan for INI files in the directory
      local ini_files=()
      for file in "$dir"/*.ini; do
        # Check if file is blocked
        local skip_file=false
        for blocked in "${BLOCKED_PATHS[@]}"; do
          if [[ "$file" == *"$blocked"* ]]; then
            skip_file=true
            break
          fi
        done
        [[ $skip_file == true ]] && continue

        [[ -f "$file" ]] && ini_files+=("$file")
      done

      # Check if any INI files were found
      if [[ ${#ini_files[@]} -eq 0 ]]; then
        show_error -t "Directory Error" -c 202 -i "$dir" -x
      fi

      valid_dirs+=("$dir")
    else
      # Wildcards/multiple directories: check all, only exit if all fail
      local errors=()

      # Process each directory matching the pattern
      for dir in $dir_pattern; do
        dir="${dir//\/\//\/}"  # Clean double slashes from expanded wildcard paths

        # Check directory existence
        if [[ ! -d "$dir" ]]; then
          errors+=("Directory does not exist: $dir")
          continue
        fi

        # Scan for INI files
        local ini_files=()
        for file in "$dir"/*.ini; do
          # Check if file is blocked
          local skip_file=false
          for blocked in "${BLOCKED_PATHS[@]}"; do
            if [[ "$file" == *"$blocked"* ]]; then
              skip_file=true
              break
            fi
          done
          [[ $skip_file == true ]] && continue

          [[ -f "$file" ]] && ini_files+=("$file")
        done

        # Skip directories without INI files
        if [[ ${#ini_files[@]} -eq 0 ]]; then
          errors+=("Directory contains no INI files: $dir")
          continue
        fi

        valid_dirs+=("$dir")
      done

      # Exit if no valid directories were found
      if [[ ${#valid_dirs[@]} -eq 0 ]]; then
        local error_msg=""
        for err in "${errors[@]}"; do
          error_msg+="$err\n"
        done
        show_error -t "Directory Error" -c 102 -l "$error_msg" -x
      fi

      # Log individual errors for debugging
      for err in "${errors[@]}"; do
        log_message "WARN" "$err"
      done
    fi

    # Clean all paths in valid_dirs array
    for i in "${!valid_dirs[@]}"; do
      valid_dirs[$i]="${valid_dirs[$i]//\/\//\/}"
    done

    # Update global INI_FILES array with valid directories
    INI_FILES=("${valid_dirs[@]}")

  }

  #!===

  # FUNCTION PARSE INI TO ARRAYS

  parse_ini_to_arrays() {

    local file="$1"

    # Initialize global temporary arrays
    _temp_config=()
    _temp_section_order=()
    _temp_menu_order=()
    local current_section=""

    # Read file line by line
    while IFS= read -r line || [[ -n $line ]]; do
      # Trim leading and trailing whitespace
      line="${line#"${line%%[![:space:]]*}"}"
      line="${line%"${line##*[![:space:]]}"}"

      # Skip empty lines
      [[ -z "$line" ]] && continue

      case "$line" in
        # Skip comments (lines starting with # or ;)
        \#*|\;*) continue ;;

        # Section header: [section_name]
        \[*\])
          current_section="${line:1:-1}"
          _temp_section_order+=("$current_section")
          ;;

        # Key-value pair: key=value
        *=*)
          local key="${line%%=*}"
          local value="${line#*=}"

          # Store in section.key format if inside a section
          if [[ -n "$current_section" && -n "$key" ]]; then
            _temp_config["$current_section.$key"]="$value"
            # Track menu order (exclude 'type' key)
            [[ "$key" != "type" ]] && _temp_menu_order["$current_section"]="${_temp_menu_order["$current_section"]:-} $key"
          else
            # Global key-value (no section)
            _temp_config["$key"]="$value"
          fi
          ;;
      esac
    done < "$file"

  }

  #!===

  create_auto_menu_from_outputs() {

    local auto_menu_name="Auto Main Menu"

    # Add Auto-Menu as first section
    _temp_section_order=("$auto_menu_name" "${_temp_section_order[@]}")
    _temp_config["$auto_menu_name.type"]="menu"

    # Add each output section as menu entry
    local index=0
    for section in "${_temp_section_order[@]}"; do
        if [[ "$section" != "$auto_menu_name" && "$section" != "meta" && "$section" != "Messages" && "$section" != "Buttons" && "${_temp_config[$section.type]}" == "output" ]]; then
            local menu_key="$index"
            _temp_config["$auto_menu_name.$menu_key"]="$section"
            _temp_menu_order["$auto_menu_name"]="${_temp_menu_order[$auto_menu_name]:-} $menu_key"
            ((index++))
        fi
    done

    log_message "INFO" "Created auto-menu '$auto_menu_name' with $index items"

  }

  #!===

  load_and_cache_config() {

    local file="$1"
    local cache_key="${file}_parsed"

    # Check cache first
    if [[ -n "${config_cache[$cache_key]}" ]]; then
      log_message "DEBUG" "Using cached config for: $file"
      return 0
    fi

    # Use centralized parsing function
    parse_ini_to_arrays "$file"

    # Validate INI structure
    if ! validate_ini_structure "$file"; then
      return 1
    fi

    # Transfer configuration to global arrays
    for key in "${!_temp_config[@]}"; do
      config["$key"]="${_temp_config[$key]}"
    done

    section_order=("${_temp_section_order[@]}")
    for section in "${!_temp_menu_order[@]}"; do
      menu_order["$section"]="${_temp_menu_order[$section]}"
    done

    # Store in cache for future use
    config_cache["$cache_key"]=1
    log_message "DEBUG" "Cached config for: $file"
    return 0

  }

  #!===

  # === LAGUAGE ===

  # FUNCTION FIND AVAILABLE LANGUAGES

  find_available_languages() {
    # Arrays leeren
    available_languages=()
    language_files=()

    # Validate that NAME_KEY is set before proceeding
    [[ -z "$NAME_KEY" ]] && show_error -t "Configuration Error" -c 100 -i "NAME_KEY" -x

    # Scan directories for INI files
    scan_dirs

    local valid_dirs=("${INI_FILES[@]}")
    [[ ${#valid_dirs[@]} -eq 0 ]] && show_error -t "Configuration Error" -c 102 -x

    # Process each directory and scan for language files
    for dir in "${valid_dirs[@]}"; do
      shopt -s nullglob
      for file in "$dir"*.ini; do
        [[ -f "$file" ]] || continue

        # Parse INI file to get metadata
        parse_ini_to_arrays "$file"

        local lang_code="${_temp_config[meta.lang_code]:-}"
        local name="${_temp_config[meta.name]:-}"

        # Skip invalid INI files (missing required metadata or wrong name key)
        if [[ -z "$lang_code" || -z "$name" || "$name" != "$NAME_KEY" ]]; then
          continue
        fi

        # Add valid language to available languages
        available_languages["$lang_code"]="$lang_code"
        language_files["$lang_code"]="$file"
      done
      shopt -u nullglob
    done

    # Exit if no valid language files were found
    [[ ${#available_languages[@]} -eq 0 ]] && show_error -t "Configuration Error" -c 102 -x
  }

  #!===

  find_best_language_file() {

    # Return early if language file is already set
    [[ -n "$CURRENT_LANG_FILE" ]] && return

    # Discover available languages first
    find_available_languages

    local best_lang=""

    # 1. Prüfe ob CURRENT_LANG verfügbar ist
    if [[ -n "$CURRENT_LANG" ]] && [[ -n "${language_files[$CURRENT_LANG]}" ]]; then
      best_lang="$CURRENT_LANG"
    else
      # 2. CURRENT_LANG nicht verfügbar → FEHLER anzeigen
      if [[ -n "$CURRENT_LANG" ]]; then
        # Fallback Sprache laden für Fehlermeldung
        best_lang="$DEFAULT_LANG_FALLBACK"
        source "./globals.sh" "$best_lang"
        show_error -t "Language Error" -c 502 -i "$DEFAULT_LANG" -l "Using fallback language: $best_lang"
      else
        # 3. CURRENT_LANG nicht gesetzt → INFO anzeigen
        best_lang="$DEFAULT_LANG_FALLBACK"
        source "./globals.sh" "$best_lang"
        show_error -t "Language Info" -c 103 -i "$DEFAULT_LANG & $DEFAULT_LANG_FALLBACK not Found!" -l "Using fallback language: $best_lang"
      fi
    fi

    # Set current language variables if best language was found
    if [[ -n "$best_lang" ]]; then
      CURRENT_LANG_FILE="${language_files[$best_lang]}"
      CURRENT_LANG_CODE="$best_lang"
      # CURRENT_LANG_NAME aus INI holen
      parse_ini_to_arrays "$CURRENT_LANG_FILE"
      CURRENT_LANG_NAME="${_temp_config[meta.language]:-$best_lang}"
      return
    fi

    # Exit if no language file could be determined
    show_error -t "Configuration Error" -c 102 -x
  }
  #!===

  load_help_file() {
    # Return early if configuration is already loaded
    $CONFIG_LOADED && return

    # ✅ ERST: Sprache finden und CURRENT_LANG_FILE setzen
    find_best_language_file || return 1
    [[ -z "$CURRENT_LANG_FILE" ]] && show_error -t "Configuration Error" -c 500 -x

    # Check if this file is already cached
    local temp_cache_key="${CURRENT_LANG_FILE}_temp"
    [[ -n "${config_cache[$temp_cache_key]}" ]] && { CONFIG_LOADED=true; return 0; }

    # ✅ DANACH: Konfiguration laden
    if ! load_and_cache_config "$CURRENT_LANG_FILE"; then
      return 1
    fi

    # Find main menu section
    local found_menu=""
    for section in "${section_order[@]}"; do
      [[ "${config[$section.type]}" == "menu" ]] && { found_menu="$section"; break; }
    done
    # Fallback to first section if no menu found
    [[ -z "$found_menu" ]] && found_menu="${section_order[0]}"
    CURRENT_MENU="$found_menu"

    # Validate essential configuration
    validate_config

    # Cache successful load
    config_cache["$temp_cache_key"]=1
    CONFIG_LOADED=true
  }

  #!===

  setup_config_variables() {
    load_help_file || return 1
    apply_config_overrides
    return 0
  }
  #!===

  # === FIND MENU SECTIONS ===

  find_menu_sections() {
    setup_config_variables || return 1
    menu_sections=()
    for s in "${section_order[@]}"; do
      [[ "${config[$s.type]}" == "menu" ]] && menu_sections+=("$s")
    done
  }

  is_menu_section() { [[ "${config[$1.type]}" == "menu" ]]; }

  is_output_section() { [[ -n "${config[$1.text]}" || -n "${config[$1.file]}" ]]; }

  #!===

  # === SHOW CONTENT NAVIGATION BUTTINS ===

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

  #!===

  show_language_menu() {

    # Load available languages first
    find_available_languages

    local menu_items=()
    local default_item=""

    # Build menu items from available languages
    for code in "${!available_languages[@]}"; do
      # Für jede Sprache die Namen aus deren INI holen
      local lang_file="${language_files[$code]}"
      parse_ini_to_arrays "$lang_file"

      # ✅ KEY = meta.language_en (internationaler Name)
      local key="${_temp_config[meta.language_en]:-$code}"
      # ✅ VALUE = meta.language (lokaler Name)
      local display_name="${_temp_config[meta.language]:-$code}"

      menu_items+=("$key" "$display_name")
      # Set current language as default selection
      [[ "$code" == "$CURRENT_LANG_CODE" ]] && default_item="$key"
    done

    # Display language selection menu
    local choice
    choice=$(whiptail --backtitle "$(build_breadcrumb)" \
              --title "$CURRENT_LANG_NAME" \
              --ok-button "$BTN_OK" \
              --cancel-button "$BTN_BACK" \
              --default-item "$default_item" \
              --menu "$BTN_LANGUAGE:" \
              0 $SYS_MIN_WIDTH 0 \
              "${menu_items[@]}" 3>&1 1>&2 2>&3)
    local status=$?

    # Handle user selection
    if [[ $status -eq 0 ]] && [[ -n "$choice" ]]; then
      # Jetzt müssen wir den Sprachcode anhand des internationalen Namens finden
      local selected_code=""
      for code in "${!available_languages[@]}"; do
        local lang_file="${language_files[$code]}"
        parse_ini_to_arrays "$lang_file"
        local lang_en="${_temp_config[meta.language_en]:-$code}"
        if [[ "$lang_en" == "$choice" ]]; then
          selected_code="$code"
          break
        fi
      done

      if [[ -n "$selected_code" ]]; then
        CURRENT_LANG_FILE="${language_files[$selected_code]}"
        CURRENT_LANG_CODE="$selected_code"

        # ✅ WICHTIG: GLOBAL-System mit der NEUEN Sprache laden
        source "./globals.sh" "$selected_code"

        # Jetzt erst den Sprachnamen aus der INI holen
        parse_ini_to_arrays "$CURRENT_LANG_FILE"
        CURRENT_LANG_NAME="${_temp_config[meta.language]:-$selected_code}"

        # Reset configuration cache and reload
        CONFIG_LOADED=false
        config_cache=()
        CURRENT_MENU=""
        load_help_file
        apply_config_overrides
      fi

    elif [[ $status -eq 1 ]]; then
      # User pressed Cancel/Back
      return 0
    elif [[ $status -eq 255 ]]; then
      # User pressed ESC
      exit 0
    fi
  }
  # FUNCTION  SHOW OUTPUT CONTENT

  show_output_content() {

    local section="$1"
    local title="${section//_/ }"

    # Collect all text/file content from the section
    local -a contents
    local -a content_types

    local current_file="$CURRENT_LANG_FILE"

    if [[ -f "$current_file" ]]; then
      local in_section=false
      local current_section=""

      # Parse the INI file to extract content from the specified section
      while IFS= read -r line || [[ -n $line ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Detect section headers
        if [[ "$line" =~ ^\[.*\]$ ]]; then
          current_section="${line:1:-1}"
          if [[ "$current_section" == "$section" ]]; then
            in_section=true
          else
            in_section=false
          fi
          continue
        fi

        # Process key-value pairs within the target section
        if [[ "$in_section" == true ]] && [[ "$line" =~ ^[^#\;].*= ]]; then
          local key="${line%%=*}"
          local value="${line#*=}"

          # Collect text and file content
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

    # Return error if no content found
    if [[ $total_contents -eq 0 ]]; then
      show_error -t "Content Error" -c 600 -i "$section"
      return 1
    fi

    local current_index=0

    # Display content with pagination
    while [[ $current_index -lt $total_contents ]]; do
      local page_number=$((current_index + 1))

      # Title logic: Only show page numbers if more than 1 page
      local page_title="$title"
      if [[ $total_contents -gt 1 ]]; then
        page_title="$title (Page $page_number/$total_contents)"
      fi

      local content="${contents[$current_index]}"
      local content_type="${content_types[$current_index]}"

      # BUTTON LOGIC:
      if [[ $total_contents -eq 1 ]]; then
        # SINGLE PAGE: Only Close button (empty second button)
        if [[ "$content_type" == "text" ]]; then
          show_text_with_buttons "$page_title" "$content" "$BTN_CLOSE" ""
        else
          show_file_with_buttons "$page_title" "$content" "$BTN_CLOSE" ""
        fi
      elif [[ $page_number -eq 1 ]]; then
        # FIRST PAGE (multiple): Close and Next
        if [[ "$content_type" == "text" ]]; then
          show_text_with_buttons "$page_title" "$content" "$BTN_CLOSE" "$BTN_NEXT"
        else
          show_file_with_buttons "$page_title" "$content" "$BTN_CLOSE" "$BTN_NEXT"
        fi
      elif [[ $page_number -eq $total_contents ]]; then
        # LAST PAGE: Back and Close
        if [[ "$content_type" == "text" ]]; then
          show_text_with_buttons "$page_title" "$content" "$BTN_BACK" "$BTN_CLOSE"
        else
          show_file_with_buttons "$page_title" "$content" "$BTN_BACK" "$BTN_CLOSE"
        fi
      else
        # MIDDLE PAGES: Back and Next
        if [[ "$content_type" == "text" ]]; then
          show_text_with_buttons "$page_title" "$content" "$BTN_BACK" "$BTN_NEXT"
        else
          show_file_with_buttons "$page_title" "$content" "$BTN_BACK" "$BTN_NEXT"
        fi
      fi

      # Navigation handling
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

  show_help_menu() {

    while true; do
      # Load configuration first
      setup_config_variables || {
        continue
      }

      local menu_items=()
      local -a ordered_keys

      # Determine menu item order
      # FIX: Prüfe ob menu_order für CURRENT_MENU existiert
      if [[ -n "${menu_order[$CURRENT_MENU]+exists}" ]]; then
        read -ra ordered_keys <<< "${menu_order[$CURRENT_MENU]}"
      else
        # Fallback: collect all keys for current menu
        for key in "${!config[@]}"; do
          if [[ "$key" == "$CURRENT_MENU."* && "$key" != "$CURRENT_MENU.type" ]]; then
            ordered_keys+=("${key#$CURRENT_MENU.}")
          fi
        done
      fi

      # Add menu items in determined order
      for key in "${ordered_keys[@]}"; do
        local full_key="$CURRENT_MENU.$key"
        [[ -n "${config[$full_key]}" ]] && menu_items+=("$key" "${config[$full_key]}")
      done

      # Fallback if no menu items found
      if [[ ${#menu_items[@]} -eq 0 ]]; then
        show_error -t "Menu Error" -c 301 -i "$CURRENT_MENU"
        # Return to main menu
        find_menu_sections
        if [[ ${#menu_sections[@]} -gt 0 ]]; then
          CURRENT_MENU="${menu_sections[0]}"
          MENU_HISTORY=()
        else
          show_error -t "Menu Error" -c 302 -x
        fi
        continue
      fi

      # Add language menu option only in main menu with multiple languages
      if [[ ${#MENU_HISTORY[@]} -eq 0 ]] && [[ ${#available_languages[@]} -gt 1 ]]; then
        local lang_upper=$(echo "$CURRENT_LANG_CODE" | tr '[:lower:]' '[:upper:]')
        menu_items+=("$lang_upper" "$BTN_LANGUAGE")
      fi

      # Set cancel button based on menu depth
      local cancel_button
      [[ ${#MENU_HISTORY[@]} -eq 0 ]] && cancel_button="$BTN_EXIT" || cancel_button="$BTN_BACK"

      # Calculate optimal menu dimensions
      local max_len=0
      for i in "${menu_items[@]}"; do (( ${#i} > max_len )) && max_len=${#i}; done
      local TERM_WIDTH=$(tput cols)
      local width=$((max_len + SYS_PADDING*2))
      (( width < SYS_MIN_WIDTH )) && width=$SYS_MIN_WIDTH
      (( width > SYS_MAX_WIDTH )) && width=$SYS_MAX_WIDTH
      (( width > TERM_WIDTH - 10 )) && width=$((TERM_WIDTH - 10))
      local height=${#menu_items[@]}
      (( height < SYS_MIN_HEIGHT )) && height=$SYS_MIN_HEIGHT
      (( height > SYS_MAX_HEIGHT )) && height=$SYS_MAX_HEIGHT
      local menu_height=$((height > 0 ? height : 10))

      # Display whiptail menu
      local choice
      choice=$(whiptail --backtitle "$(build_breadcrumb)" \
                --title "${CURRENT_MENU//_/ }" \
                --ok-button "$BTN_OK" \
                --cancel-button "$cancel_button" \
                --menu "$TEXT_MENU_PROMPT" \
                "$menu_height" "$width" 0 \
                "${menu_items[@]}" 3>&1 1>&2 2>&3)
      local status=$?

      #dle user selection
      if [[ $status -eq 0 ]] && [[ -n "$choice" ]]; then
        # Language menu selection
        if [[ ${#MENU_HISTORY[@]} -eq 0 ]] && [[ "$choice" == "$(echo "$CURRENT_LANG_CODE" | tr '[:lower:]' '[:upper:]')" ]]; then
          show_language_menu
          continue
        fi

        # Find selected menu/output
        local selected_value="${config[${CURRENT_MENU}.${choice}]}"
        local selected_type="${config[${selected_value}.type]}"

        if [[ "$selected_type" == "menu" ]]; then
          # Navigate to submenu
          MENU_HISTORY+=("$CURRENT_MENU")
          CURRENT_MENU="$selected_value"
        elif [[ "$selected_type" == "output" ]]; then
          # Display output content with navigation
          show_output_content "$selected_value"
        else
          show_error -t "Menu Error" -c 300
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

# -------------------------------
# Start
# -------------------------------
show_help_menu
