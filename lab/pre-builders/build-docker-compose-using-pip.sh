# https://github.com/linux-on-ibm-z/docs/wiki/Building-Docker-Compose

sudo apt-get update
function install_docker_compose_using_pip() {
    sudo apt-get install -y python3-pip libffi-dev libssl-dev
    # optional
    sudo -H pip3 install --upgrade pip
    # build/install
    time sudo pip3 install docker-compose==1.25.4 || time sudo pip3 install docker-compose==1.21.2
}

time install_docker_compose_using_pip
