#!/usr/bin/env bash

function install_imagemagick() {
  pushd /tmp

  if [[ "$(Is-RedHat 6)" ]]; then
    try-and-retry curl -ksSl -o epel-release-latest-6.noarch.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
    try-and-retry curl -ksSl -o remi-release-6.rpm https://rpms.remirepo.net/enterprise/remi-release-6.rpm
    rpm -Uvh remi-release-6.rpm epel-release-latest-6.noarch.rpm

    # for RHEL only
    command -v subscription-manager && subscription-manager repos --enable=rhel-6-server-optional-rpms || true
  fi


  if [[ "$(Is-RedHat 7)" ]]; then
    try-and-retry curl -ksSl -o epel-release-latest-7.noarch.rpm wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    try-and-retry curl -ksSl -o remi-release-7.rpm https://rpms.remirepo.net/enterprise/remi-release-7.rpm
    rpm -Uvh remi-release-7.rpm epel-release-latest-7.noarch.rpm

    # for RHEL only
    command -v subscription-manager && subscription-manager repos --enable=rhel-7-server-optional-rpms || true
  fi

  if [[ "$(Is-RedHat 8)" ]]; then
    try-and-retry sudo dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
  fi

  popd

  try-and-retry yum --enablerepo=remi,remi-test install -y ImageMagick6 # ImageMagick6-devel
  # OR: yum --enablerepo=remi,remi-test install -y ImageMagick7 # ImageMagick7-devel

}


function install_ffmpeg() {
  # On CentOS 7, you can install the Nux Dextop YUM repo with the following commands:
  if [[ "$(Is-RedHat 7)" ]]; then
    sudo rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
    sudo rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
  fi

  # For CentOS 6, you need to install another release:
  if [[ "$(Is-RedHat 6)" ]]; then
    sudo rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
    sudo rpm -Uvh http://li.nux.ro/download/nux/dextop/el6/x86_64/nux-dextop-release-0-2.el6.nux.noarch.rpm
  fi

  #Step 3: Install FFmpeg and FFmpeg development packages
  sudo yum install ffmpeg -y
  # Step 4: Test drive
  Say "FFMPEG Version: $(ffmpeg 2>&1 | head -1)"
  Say "FFMPEG codecs"
  ffmpeg -codecs
  Say "FFMPEG formats"
  ffmpeg -formats


  # VERSION IS 2.6.8
}

function install_console_tools() {
  # htop, ncdu, lsof nano tree iotop
  if [[ "$(Is-RedHat 6)" ]]; then
    urls='
        http://download-ib01.fedoraproject.org/pub/epel/6/x86_64/Packages/h/htop-1.0.3-1.el6.x86_64.rpm
        http://repo.openfusion.net/centos6-x86_64//ncdu-1.7-1.of.el6.x86_64.rpm
        http://download-ib01.fedoraproject.org/pub/epel/6/x86_64/Packages/p/p7zip-16.02-10.el6.x86_64.rpm
        http://download-ib01.fedoraproject.org/pub/epel/6/x86_64/Packages/p/p7zip-plugins-16.02-10.el6.x86_64.rpm
'
    for url in $urls; do
        Say "Installing $(basename $url) from [$url]"
        try-and-retry rpm -iv --nosignature $url
    done
  fi
  
  Say "Installing lsof nano tree iotop"
  try-and-retry yum install -y lsof nano tree iotop
}
  
install_imagemagick
install_ffmpeg
install_console_tools
