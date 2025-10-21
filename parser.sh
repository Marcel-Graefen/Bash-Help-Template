#!/usr/bin/env bash

# =======================
# Globale Arrays
# =======================
declare -A META_NAME
declare -A META_LANGUAGE
declare -A META_LANGUAGE_EN
declare -A META_BACKTITLE

declare -A MENU_TITLE
declare -A MENU_CHILDREN
declare -A PARENT
declare -A CONTENT

declare -a LANG_CODES=()
declare -a MENU_ORDER=()
declare -a CHILD_ORDER=()
declare -a CONTENT_ORDER=()


parser() {

  INI_FILE="$1"

  local -A temp_lang

  local -A _meta_temp

  __pars_meta() {

    local in_meta=0

    while IFS= read -r line || [ -n "$line" ]; do
      # führende und abschließende Leerzeichen entfernen
      line="${line#"${line%%[![:space:]]*}"}"
      line="${line%"${line##*[![:space:]]}"}"
      [[ -z "$line" || "$line" =~ ^[\#\;] ]] && continue

      # Start Meta-Block
      if [[ "$line" =~ ^\[meta\]$ ]]; then
          in_meta=1
          continue
      fi

      if [[ $in_meta -eq 1 ]]; then
        # key=value auslesen
        if [[ "$line" =~ ^([a-zA-Z_]+)=(.*)$ ]]; then
          _meta_temp["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
        fi

        # Ende Meta-Block bei erstem anderen Section-Header
        if [[ "$line" =~ ^\[.*\]$ && ! "$line" =~ ^\[meta\]$ ]]; then
          break
        fi
      fi
    done < "$INI_FILE"

  }

  __pars_meta

  DAS="language_management_system"

  [[ "${#_meta_temp[@]}" -eq 0 ]] && echo "LLLLER"

  [[ -n "${_meta_temp[lang_code]}" ]] && temp_lang="${_meta_temp[lang_code]}" || return 1

  # Sprache hinzufügen
  [[ ! " ${LANG_CODES[*]} " =~ " ${temp_lang} " ]] && LANG_CODES+=("$temp_lang")

  if [[ -z "${_meta_temp[name]}" ]]; then
    echo "name nicht gesetzt"
    return 1
  elif [[ "${_meta_temp[name]}" == "$DAS" ]]; then
    META_NAME["$temp_lang"]="${_meta_temp[name]}"
  else
    echo "NIX gesetzt"
  fi

  [[ -n "${_meta_temp[language]}" ]] && META_LANGUAGE["$temp_lang"]="${_meta_temp[language]}" || echo "KEINE language"
  [[ -n "${_meta_temp[language_en]}" ]] && META_LANGUAGE_EN["$temp_lang"]="${_meta_temp[language_en]}" || echo "KEINE language_en"
  [[ -n "${_meta_temp[backtitle]}" ]] && META_BACKTITLE["$temp_lang"]="${_meta_temp[backtitle]}" || echo "KEINE backtitle"

  # -------------------------------------------------------------------------

  parse_menu_content() {

    local current_section=""
    local current_parent=""

    # Temporäre Container
    local -A _temp_menu_title _temp_menu_children _temp_parent _temp_content
    local -a _temp_menu_order _temp_child_order _temp_content_order

    # === Datei lesen ===
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line#"${line%%[![:space:]]*}"}"
      line="${line%"${line##*[![:space:]]}"}"
      [[ -z "$line" || "$line" =~ ^[\#\;] ]] && continue

      # Abschnittsbeginn
      if [[ "$line" =~ ^\[(.*)\]$ ]]; then
        current_section="${BASH_REMATCH[1]}"
        [[ "$current_section" == menu:* || "$current_section" == content:* ]] && current_parent="${current_section#*:}"
        continue
      fi

      # Key=Value
      if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
        local key="${BASH_REMATCH[1]}"
        local value="${BASH_REMATCH[2]}"
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        # === Menü-Struktur ===
        if [[ "$current_section" == menu:* ]]; then
          local menu_id="$current_parent"

          if [[ "$key" == "name" ]]; then
            _temp_menu_title["$menu_id"]="$value"
            _temp_menu_order+=("$menu_id")
          else
            # Child-Menü-ID erzeugen (z. B. 01 + 02 → 01-02)
            local child_id="${menu_id}-${key}"
            _temp_menu_children["$menu_id"]="${_temp_menu_children[$menu_id]} $child_id"
            _temp_parent["$child_id"]="$menu_id"
            _temp_child_order+=("$child_id")

            # Optional: Kindtitel als Pseudo-Menü (falls definiert)
            _temp_menu_title["$child_id"]="$value"
          fi
        fi

        # === Content-Struktur ===
        if [[ "$current_section" == content:* ]]; then
          local content_id="$current_parent"

          if [[ "$key" == "name" || "$key" == "text" || "$key" == "file" ]]; then
            _temp_content["$content_id,$key"]="$value"
            [[ "$key" == "name" ]] && _temp_content_order+=("$content_id")
          fi
        fi

      fi
    done < "$INI_FILE"

    # === Temp Arrays in globale Arrays übernehmen ===
    for k in "${!_temp_menu_title[@]}"; do
      MENU_TITLE["$temp_lang,$k"]="${_temp_menu_title[$k]}"
    done
    for k in "${!_temp_menu_children[@]}"; do
      MENU_CHILDREN["$temp_lang,$k"]="${_temp_menu_children[$k]}"
    done
    for k in "${!_temp_parent[@]}"; do
      PARENT["$temp_lang,$k"]="${_temp_parent[$k]}"
    done
    for k in "${!_temp_content[@]}"; do
      CONTENT["$temp_lang,$k"]="${_temp_content[$k]}"
    done

    MENU_ORDER+=("${_temp_menu_order[@]}")
    CHILD_ORDER+=("${_temp_child_order[@]}")
    CONTENT_ORDER+=("${_temp_content_order[@]}")

  }

  parse_menu_content

}


# ========================================================================================
# ========================================================================================
# ========================================================================================

# === Parser-Aufrufe ===
parser "./parser.de.ini"
# parser "./parser.en.ini"


# === Debug-Ausgabe ===
echo
echo "=== Meta ==="
echo "Sprachen: ${LANG_CODES[*]}"
echo

echo "=== Menü-Titel ==="
for k in "${MENU_ORDER[@]}"; do
  for l in "${LANG_CODES[@]}"; do
    echo "$l,$k -> ${MENU_TITLE[$l,$k]}"
  done
done
echo

echo "=== Menü-Kinder ==="
for l in "${LANG_CODES[@]}"; do
  for k in "${MENU_ORDER[@]}"; do
    echo "$l,$k -> ${MENU_CHILDREN[$l,$k]}"
  done
done
echo

echo "=== Parent ==="
for k in "${!PARENT[@]}"; do
  echo "$k -> ${PARENT[$k]}"
done
echo

echo "=== Content ==="
for k in "${CONTENT_ORDER[@]}"; do
  echo "$k -> name: ${CONTENT[$temp_lang,$k,name]}, text: ${CONTENT[$temp_lang,$k,text]}, file: ${CONTENT[$temp_lang,$k,file]}"
done
echo




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

  # FUNCTION NORMALIZE INPUT PATH
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

  # FUNCTION PROSESS SINGLE FILE
  # Alle Unterfunktionen innerhalb der Hauptfunktion definieren
  _process_single_file() {
    local file="$1"

    # Deny-Check
    if _is_denied "$file"; then
    # TODO LOG_MESSAGE
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
    # TODO LOG_MESSAGE
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

  # FUNCTION PROCESS DIRETORY
  _process_directory() {
    local dir="$1"

    # Deny-Check für gesamten Ordner
    if _is_denied "$dir"; then
    # TODO LOG_MESSAGE
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

  # FUNCTION PROZESS WILDCARD
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

  # FUNCTION PROCESS RECUSIVE
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

  # FUNCTION CHECK FILE SIZE
  _check_file_size() {
    local file="$1"
    local file_size=$(stat -c %s "$file" 2>/dev/null || echo 0)

    if [[ $file_size -gt $INT_MAX_FILE_SIZE ]]; then
    # TODO LOG_MESSAGE
      log_message "$TYPE_WARNING" "$TYPE_FILE ${TEXT_FILE_TOO_LARGE}: $file (${file_size} bytes)"
      return 1
    fi
    return 0
  }

  # FUNCTION VERITY FILES
  # Hier ist ein Zu
  local Call_Count=0
  local Error_Count=0
  _verify_file() {
    local file="$1"
    local -i call_count=0
    local -i error_count=0

    ((call_count++))

    verify_error_msg=""
    verify_error_line_msg=""
    verify_error_code=""

    if declare -f verify_file >/dev/null; then
      if verify_file "$file"; then
        return 0
      else
        ((error_count++))
        return 1
      fi
    else
      verify_error_code="700"
      ((error_count++))
      return 1
    fi
  }

  # TODO LOG_MESSAGE
  log_message "$TYPE_DEBUG" "${TEXT_SEARCH_START}: $INPUT"

  # Jeden normalisierten Input verarbeiten
  for normalized_input in "${normalized_inputs[@]}"; do
    # 1. Input-Typ erkennen und verarbeiten
    local resolved_path

    if [[ -f "$normalized_input" && "$normalized_input" == *.ini ]]; then
    # TODO LOG_MESSAGE
      log_message "$TYPE_DEBUG" "${TEXT_RECOGNIZED_SINGLE_FILE}"
      resolved_path=$(realpath "$normalized_input" 2>/dev/null || echo "$normalized_input")
      _process_single_file "$resolved_path"

    elif [[ -d "$normalized_input" ]]; then
    # TODO LOG_MESSAGE
      log_message "$TYPE_DEBUG" "${TEXT_RECOGNIZED_DIRECTORY}"
      resolved_path=$(realpath "$normalized_input" 2>/dev/null || echo "$normalized_input")
      _process_directory "$resolved_path"

    elif [[ "$normalized_input" == *"*"* ]]; then
    # TODO LOG_MESSAGE
      log_message "$TYPE_DEBUG" "${TEXT_RECOGNIZED_WILDCARD}"
      _process_wildcard "$normalized_input"

    elif [[ "$normalized_input" == *"**"* ]]; then
    # TODO LOG_MESSAGE
      log_message "$TYPE_DEBUG" "${TEXT_RECOGNIZED_RECURSIVE}"
      _process_recursive "$normalized_input"

    else
    # TODO LOG_MESSAGE
      log_message "$TYPE_ERROR" "${TEXT_INVALID_PATH}: $normalized_input"
      # TODO LANGUAGE SYSTEM
      show_error -h "$TYPE_FILE" -c "201" --info "$normalized_input" --exit
      return 1
    fi
  done
  # Übersichtliche Fehlerbehandlung
  # TODO LANGUAGE SYSTEM
  [[ $dirs_found -eq 0 ]] && { show_error -t "$TYPE_DIRECTORY" --code "203" --info "$INPUT" --exit; return 1; }
  [[ $files_found -eq 0 ]] && { show_error -t "$TYPE_FILE" --code "202" --info "$INPUT" --line "${TEXT_SEARCHED_DIRECTORY}:\n$(printf '%s\n' "${found_dirs[@]}")" --exit; return 1; }
  [[ $permission_errors -gt 0 && $files_verified -eq 0 ]] && { show_error -t "$TYPE_FILE" --code "204" --info "$INPUT" --exit; return 1; }

  if (( Call_Count > 0 && Call_Count == Error_Count )); then
  # TODO LANGUAGE SYSTEM
      show_error -t "$TYPE_VERIFY" --code "$verify_error_code" --info "$verify_error_msg" --line "$verify_error_line_msg" --exit
      return 1
  fi

  # Erfolgreiche Ergebnisse in globale Arrays schreiben
  OUTPUT_DIRS=("${found_dirs[@]}")
  OUTPUT_FILES=("${verified_files[@]}")

  # TODO LOG_MESSAGE
  log_message "$TYPE_DEBUG" "${TEXT_SUCCESS}: ${#found_dirs[@]} ${TEXT_DIRECTORIES}, ${#verified_files[@]} ${TEXT_FILES}"
  return 0

}
