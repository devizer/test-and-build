Native-Combine-Path-Implementation() {
  local ret=""
  local system="$(uname -s 2>/dev/null)"
  local separator="/"; [[ "$system" == "MSYS"* || "$system" == "MINGW"* ]] && separator='\'
  for part in "$@"; do
    if [[ -n "$part" ]]; then
      [[ -n "$ret" ]] && ret="${ret}${separator}"
      ret="${ret}${part}"
    fi
  done
  # if no arguments then return native current folder?
  if [[ -z "$ret" ]]; then 
    if [[ "$separator" == "/" ]]; then
      ret="$PWD"
    else
      ret="$(cmd.exe //c echo "%CD%")"
    fi
  fi
  echo "$ret"
}

Native-Combine-Path-Implementation "$@"
