#!/bin/bash

# source ../global_new.sh


# get_system_language_code

# validate_language $LANG_CODE

# load_languages


# get_translation 8403


# ============================================================
#  FUNCTION: generate_language_map
# ------------------------------------------------------------
#  Description:
#    Automatically scans all language files in a specified
#    directory and extracts LANG_CODE, LANGUAGE_NAME, and
#    LANGUAGE_NAME_EN variables.
#    It then generates a LANGUAGE_MAP associative array file
#    with the following format:
#
#      declare -A LANGUAGE_MAP=(
#        ["de"]="Deutsch:German"
#        ["en"]="English:English"
#        ...
#      )
#
#  Usage:
#    generate_language_map <output_file> <lang_dir>
#
#  Example:
#    generate_language_map "./language_map.sh" "./lang"
#
#  Parameters:
#    output_file  – Target file path for the generated map
#    lang_dir     – Directory containing language .sh files
#
#  Behavior:
#    - Skips empty or invalid files.
#    - Executes each language file in a subshell to read vars.
#    - Writes formatted output to the specified file.
#    - Overwrites any existing file.
#
# ============================================================

generate_language_map() {
  local output_file="$1"
  local lang_dir="$2"

  # Basic parameter validation
  if [[ -z "$output_file" ]]; then
    echo "Usage: generate_language_map <output_file> <lang_dir>" >&2
    return 1
  fi

  if [[ ! -d "$lang_dir" ]]; then
    echo "Error: Language directory '$lang_dir' not found." >&2
    return 1
  fi

  # Start writing output file
  {
    echo "declare -A LANGUAGE_MAP=("
  } > "$output_file"

  # Iterate through all language files
  for lang_file in "$lang_dir"/*.sh; do
    # Skip empty or non-existent files
    [[ -s "$lang_file" ]] || continue

    # Extract the key language variables safely
    eval "$(
      grep -E '^(LANG_CODE|LANGUAGE_NAME|LANGUAGE_NAME_EN)=' "$lang_file"
    )"

    # Ensure all required variables are present
    [[ -n "$LANG_CODE" && -n "$LANGUAGE_NAME" && -n "$LANGUAGE_NAME_EN" ]] || continue

    # Write formatted line into the output file
    printf '  ["%s"]="%s:%s"\n' "$LANG_CODE" "$LANGUAGE_NAME" "$LANGUAGE_NAME_EN" >> "$output_file"
  done

  # Close the associative array
  echo ")" >> "$output_file"

  echo "✅ LANGUAGE_MAP written to: $output_file"
}
