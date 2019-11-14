

    function print_header() {
      # if [[ -e /tmp/
      # user=
      SYSTEM="${SYSTEM:-$(uname -s)}"
      if [[ ${SYSTEM} != Darwin ]]; then
          uptime=$(</proc/uptime);                  # 42645.93 240538.58
          IFS=' ' read -ra uptime <<< "$uptime";    # 42645.93 240538.58
          uptime="${uptime[0]}";                    # 42645.93
          uptime=$(printf "%.0f\n" "$uptime")       # 42645
          uptime=$(TZ=UTC date -d "@${uptime}" "+%_H:%M:%S");
      fi
      LightGreen='\033[1;32m'; Yellow='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'; LightGray='\033[1;2m';
      printf "${LightGray}${uptime:-}${NC} ${LightGreen}$1${NC} ${Yellow}$2${NC}\n"; 
    }
    counter=0; 
    function Say() { counter=$((counter+1)); print_header " #$counter" "$1"; }; 
    Say "" >/dev/null;
    counter=0;
