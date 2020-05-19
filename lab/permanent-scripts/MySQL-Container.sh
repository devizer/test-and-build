#!/usr/bin/env bash
MYSQL_CONTAINER_PORT=${MYSQL_CONTAINER_PORT:-3306}
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-pass}"
MYSQL_DATABASE="${MYSQL_DATABASE:-app}"
MYSQL_USER="${MYSQL_USER:-user}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-pass}"
MYSQL_VERSION="${MYSQL_VERSION:-5.7}"
MYSQL_CONTAINER_NAME="${MYSQL_CONTAINER_NAME:-mysql-$MYSQL_VERSION-for-azure-pipelines-agent}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-42}"

 # MySQL-Container start wait-for exec "SHOW VARIABLES LIKE 'version';" 
 
 # raw example for default parameter
 # time MYSQL_PWD=pass mysql --protocol=TCP -h localhost -u root -P 3306 -B -N -e "SHOW VARIABLES LIKE 'version';" | cat
 
 
# arm|arm64|amd64
function get_docker_arch() {
    local dockerArch=$(sudo docker version --format '{{.Server.Arch}}') 
    echo "${dockerArch:-unknown}"
}

function is_container_exists() {
    local name=$1
    local exists="true"; 
    sudo docker logs "$name" >/dev/null 2>&1 || exists=false
    echo "$exists"
}

function is_container_running() {
    local name=$1
    local isRunning="false"
    # TODO: filter by names only
    if [[ -n "$(docker ps | grep $name || true)" ]]; then
        isRunning=true
    fi
    echo $isRunning
}

function stop_container() {
    local name=$1
    if [[ "$(is_container_running ${name})" != true ]]; then
        Say "Container $name is not running"
    elif [[ "$(is_container_exists ${name})" == true ]]; then
        Say "Container $name is absent"
    else
        Say "Stopping container $name"
        sudo docker stop "$name"
    fi
}

function delete_container() {
    local name=$1
    if [[ "$(is_container_exists ${name})" == true ]]; then
        Say "Deleting existing container $name"
        sudo docker rm -f "$name"
    else
        Say "Skip deleting container $name. It does not exists"
    fi
}

function get_mysql_image_name() {
    local image
    if [[ "$(get_docker_arch)" == arm ]]; then
        # https://github.com/beercan1989/docker-arm-mysql
        image="beercan1989/arm-mysql:latest"
    else 
        image="mysql/mysql-server:${MYSQL_VERSION}"
    fi
    echo $image
}

function delete_image() {
    local image=$1
    Say "Deleting the $image image" 
    docker rmi -f "$image"
}

function start_mysql_container() {
    local image=$(get_mysql_image_name)
    
    if [[ "$(is_container_exists $MYSQL_CONTAINER_NAME)" != true ]]; then
        # container is absent
        Say "Pulling the $image image if required"
        sudo docker pull "$image"
        
        Say "Creating $MYSQL_CONTAINER_NAME container"
        docker run -d \
          -e "MYSQL_ROOT_HOST=%" \
          -e "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" \
          -e "MYSQL_DATABASE=${MYSQL_DATABASE}" \
          -e "MYSQL_USER=${MYSQL_USER}" \
          -e "MYSQL_PASSWORD=${MYSQL_PASSWORD}}" \
          -p "${MYSQL_CONTAINER_PORT}:3306" \
          --name $MYSQL_CONTAINER_NAME \
          "$image"
    elif [[ "$(is_container_running $MYSQL_CONTAINER_NAME)" == false ]]; then
        # container exists but stopped
        Say "Starting existing $MYSQL_CONTAINER_NAME container"
        docker start $MYSQL_CONTAINER_NAME
    else 
        Say "Container $MYSQL_CONTAINER_NAME already running"
    fi
    
    # TODO: wait for connection
}

function exec_statement(){
    local cmd=$1
    MYSQL_PWD="${MYSQL_PASSWORD}" mysql --protocol=TCP -h $(Get-Local-Docker-Ip) -u root -P ${MYSQL_CONTAINER_PORT} -B -N -e "$cmd" | cat
}

function wait_for_mysql() {
    local name=$1 port=$2 counter=0 total=$WAIT_TIMEOUT started=""
    Say "Waiting for $name on port $port"
    while [ $counter -lt $total ]; do
        counter=$((counter+1));
        # mysql --protocol=TCP -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" -P $p -e "Select 1;" 2>/dev/null 1>&2 && started="yes" || true
        docker exec -t $name mysql --protocol=TCP -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" -P 3306 -e "Select 1;" 2>/dev/null 1>&2 && started="yes" || true
        if [ -n "$started" ]; then printf " OK"; break; else (sleep 1; printf "${counter}."); fi
    done
    if [ -z "$started" ]; then printf " Fail\n"; else
        ver=$(docker exec -t $name sh -c "MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysql -s -N --protocol=TCP -h localhost -u root -P 3306 -e 'Select version();' 2>&1")
        printf ", Ver is $ver\n"
    fi
}


while [ $# -ne 0 ]; do
    param="$1"
    case "$param" in
        start) start_mysql_container ;;
        reset) delete_container $MYSQL_CONTAINER_NAME; start_mysql_container ;;
        stop) stop_container $MYSQL_CONTAINER_NAME ;;
        delete) delete_container $MYSQL_CONTAINER_NAME ;;
        "delete-image") delete_image $(get_mysql_image_name) ;;
        exec) cmd="$2"; shift; exec_statement "$cmd" ;;
        "wait-for") wait_for_mysql "$MYSQL_CONTAINER_NAME" $MYSQL_CONTAINER_PORT ;; 
    esac
    shift
done
# 12:43