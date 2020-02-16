#!/usr/bin/env sh
# script=https://raw.githubusercontent.com/devizer/test-and-build/master/install-build-tools.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash

function exec_cmd() {
  cmd="$1"
  sudo true >/dev/null 2>&1 && eval "sudo $cmd" || eval "$cmd"
}

for f in "Reset-Target-Framework" "Say" "Show-System-Stat" "try-and-retry" "smart-apt-install" "lazy-apt-update" "list-packages" "Is-RedHat"; do
    if [ -f permanent-scripts/${f}.sh ]; then
        sudo cp permanent-scripts/${f}.sh /usr/local/bin/${f}
    else
        remote_file_url="https://raw.githubusercontent.com/devizer/test-and-build/master/lab/permanent-scripts/${f}.sh"
        echo "Downloading $remote_file_url"
        cmd="curl -ksSL -o /usr/local/bin/${f} $remote_file_url || wget --no-check-certificate --quiet -O /usr/local/bin/${f} $remote_file_url"
        exec_cmd "$cmd" || exec_cmd "$cmd" || exec_cmd "$cmd"
        # eval $cmd || eval $cmd || eval $cmd
    fi
    exec_cmd "chmod +x /usr/local/bin/${f}"
done

usystem="$(uname -s)"
if [[ "$usystem" == "Linux" ]]; then
  cmd_drop_cache="sync; sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null"
elif [[ "$usystem" == "Darwin" ]]; then
  cmd_drop_cache="sync; sudo sync; sudo purge"
else 
  cmd_drop_cache="echo 'Drop-FS-Cache: Only Linux and macOS are currently supported'"
fi

if [[ -n "$cmd_drop_cache" ]]; then
  echo "Creating Drop-FS-Cache at /usr/local/bin"
  body="#!/usr/bin/env bash\n\n$cmd_drop_cache\n"
  echo -e $body | exec_cmd "tee /usr/local/bin/Drop-FS-Cache >/dev/null"
  exec_cmd "chmod +x /usr/local/bin/Drop-FS-Cache"
fi



