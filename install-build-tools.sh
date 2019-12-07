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
        cmd="curl -ksSL -o /usr/local/bin/${f} $remote_file_url || wget --no-check-certificate -O /usr/local/bin/${f} $remote_file_url" 
        exec_cmd "$cmd" || exec_cmd "$cmd" || exec_cmd "$cmd"
        # eval $cmd || eval $cmd || eval $cmd
    fi
    sudo chmod +x /usr/local/bin/${f}
done
