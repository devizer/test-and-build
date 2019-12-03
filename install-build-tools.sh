#!/usr/bin/env sh
# script=https://raw.githubusercontent.com/devizer/test-and-build/master/install-build-tools.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash
for f in "Say" "Show-System-Stat" "try-and-retry" "smart-apt-install" "lazy-apt-update" "list-packages"; do
    if [ -f permanent-scripts/${f}.sh ]; then
        sudo cp permanent-scripts/${f}.sh /usr/local/bin/${f}
    else
        echo "Downloading https://raw.githubusercontent.com/devizer/test-and-build/master/lab/permanent-scripts/${f}.sh"
        cmd="sudo curl -ksSL -o /usr/local/bin/${f} https://raw.githubusercontent.com/devizer/test-and-build/master/lab/permanent-scripts/${f}.sh"
        eval $cmd || eval $cmd || eval $cmd
    fi
    sudo chmod +x /usr/local/bin/${f}
done
