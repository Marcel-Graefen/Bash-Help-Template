  local Call_Count=0
  local Error_Count=0
  _verify_file() {
    local file="$1"

    ((Call_Count++))

    if declare -f verify_file >/dev/null; then

      if verify_file "$file"; then || ((Error_Count++))

    else
      # ERROR mit globalem Error-Code
      verify_error_msg=""
      verify_error_code="700"
      return 1
    fi

  }

 [[ "$Call_Count" == "$Error_Cound" ]] && { show_error -t "$TYPE_VERIFY" --code "$verify_error_code" --line "$verify_error_msg" --exit; return 1; }
