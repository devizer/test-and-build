# File-IO-Benchmark
echo -e "#!/usr/bin/env bash

# TODO: doesnt work in stable way 
# V2
SIZE=1000M
RUNTIME=7
RAMP_TIME=15

# --ramp_time=\$RAMP_TIME
ramp=\"--ramp_time=\$RAMP_TIME\"
# ramp=
fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=4k --iodepth=64 --size=\$SIZE --readwrite=randread  --runtime=\$RUNTIME \$ramp 

fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=4k --iodepth=64 --size=\$SIZE --readwrite=randwrite --runtime=\$RUNTIME \$ramp

fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=1024k --iodepth=64 --size=\$SIZE --readwrite=write --runtime=\$RUNTIME \$ramp

fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=1024k --iodepth=64 --size=\$SIZE --readwrite=read  --runtime=\$RUNTIME \$ramp


FILE=fiobnch.42
SIZE=100M

      function go_fio_1test() {
        local cmd=\$1
        local disk=\$2
        local caption=\"\$3\"
        pushd \"\$disk\" >/dev/null
        toilet -f term -F border \"\$caption (\$(pwd))\"
        echo \"File-IO-Benchmark folder is '\$(pwd)'\"
SIZE=1G
RUNTIME=30
RAMP_TIME=10
SIZE=100M
RUNTIME=5
RAMP_TIME=1
fio --name=RAND_READ  --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --filename=fiotest --bs=4k --iodepth=64 --size=\$SIZE --runtime=\$RUNTIME --ramp_time=\$RAMP_TIME --readwrite=randread  
fio --name=RAND_WRITE --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --filename=fiotest --bs=4k --iodepth=64 --size=\$SIZE --runtime=\$RUNTIME --ramp_time=\$RAMP_TIME --readwrite=randwrite

        fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --runtime=30 --ramp_time=10 \\
           --name=Read --stonewall --bs=1024k --iodepth=64 --size=\$SIZE --readwrite=read --runtime=30 --ramp_time=10 \\
           --name=Write --stonewall --bs=1024k --iodepth=64 --size=\$SIZE --readwrite=write --runtime=30 --ramp_time=10 \\
           --name=RandRead --stonewall --bs=4k --iodepth=64 --size=\$SIZE --readwrite=randread --runtime=30 --ramp_time=10 \\
           --name=RandWrite --stonewall --bs=4k --iodepth=64 --size=\$SIZE --readwrite=randwrite --runtime=30 --ramp_time=10
        
        if [[ \$cmd == \"rand\"* ]]; then
           fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=4k --iodepth=64 --size=2G --readwrite=\$cmd --runtime=30 --ramp_time=10
        else
           fio --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=1024k --size=2G --readwrite=\$cmd --runtime=30 --ramp_time=10
        fi
        popd >/dev/null
        echo \"\"
      }
      
      function go_fio_4tests() {
        local disk=\$1
        local caption=\$2
        go_fio_1test read      \$disk \"\${caption}: Sequential read\"
        go_fio_1test write     \$disk \"\${caption}: Sequential write\"
        go_fio_1test randread  \$disk \"\${caption}: Random read\"
        go_fio_1test randwrite \$disk \"\${caption}: Random write\"
        rm -f \$disk/fiotest
      }
      
      sudo chown -R \$(whoami) /mnt
      go_fio_4tests /mnt \"sdb1 (default)\"
      go_fio_4tests .    \"sda1\"
      
      file=/dev/sdb1
      path=\"/sdb1-accelerated\"
      echo \"Accelerating \$file as \$path\"
      sudo mkdir -p \"\$path\"
      sudo umount /mnt
      sudo mkfs.ext2 -L ext2-accelerated \"\$file\"
      sudo mount -t ext2 \"\$file\" \"\$path\" -o rw,noatime,nodiratime,errors=remount-ro
      sudo chown -R \$(whoami) \"\$path\"
      df -h -T
      echo \"\"
      
      go_fio_4tests \$path \"sdb1 (Accelerated)\"
      sudo umount \"\$path\"


" > /usr/local/bin/File-IO-Benchmark || 
echo -e "#!/usr/bin/env bash

# TODO: doesnt work in stable way 
# V2
SIZE=1000M
RUNTIME=7
RAMP_TIME=15

# --ramp_time=\$RAMP_TIME
ramp=\"--ramp_time=\$RAMP_TIME\"
# ramp=
fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=4k --iodepth=64 --size=\$SIZE --readwrite=randread  --runtime=\$RUNTIME \$ramp 

fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=4k --iodepth=64 --size=\$SIZE --readwrite=randwrite --runtime=\$RUNTIME \$ramp

fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=1024k --iodepth=64 --size=\$SIZE --readwrite=write --runtime=\$RUNTIME \$ramp

fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=1024k --iodepth=64 --size=\$SIZE --readwrite=read  --runtime=\$RUNTIME \$ramp


FILE=fiobnch.42
SIZE=100M

      function go_fio_1test() {
        local cmd=\$1
        local disk=\$2
        local caption=\"\$3\"
        pushd \"\$disk\" >/dev/null
        toilet -f term -F border \"\$caption (\$(pwd))\"
        echo \"File-IO-Benchmark folder is '\$(pwd)'\"
SIZE=1G
RUNTIME=30
RAMP_TIME=10
SIZE=100M
RUNTIME=5
RAMP_TIME=1
fio --name=RAND_READ  --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --filename=fiotest --bs=4k --iodepth=64 --size=\$SIZE --runtime=\$RUNTIME --ramp_time=\$RAMP_TIME --readwrite=randread  
fio --name=RAND_WRITE --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --filename=fiotest --bs=4k --iodepth=64 --size=\$SIZE --runtime=\$RUNTIME --ramp_time=\$RAMP_TIME --readwrite=randwrite

        fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --runtime=30 --ramp_time=10 \\
           --name=Read --stonewall --bs=1024k --iodepth=64 --size=\$SIZE --readwrite=read --runtime=30 --ramp_time=10 \\
           --name=Write --stonewall --bs=1024k --iodepth=64 --size=\$SIZE --readwrite=write --runtime=30 --ramp_time=10 \\
           --name=RandRead --stonewall --bs=4k --iodepth=64 --size=\$SIZE --readwrite=randread --runtime=30 --ramp_time=10 \\
           --name=RandWrite --stonewall --bs=4k --iodepth=64 --size=\$SIZE --readwrite=randwrite --runtime=30 --ramp_time=10
        
        if [[ \$cmd == \"rand\"* ]]; then
           fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=4k --iodepth=64 --size=2G --readwrite=\$cmd --runtime=30 --ramp_time=10
        else
           fio --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=1024k --size=2G --readwrite=\$cmd --runtime=30 --ramp_time=10
        fi
        popd >/dev/null
        echo \"\"
      }
      
      function go_fio_4tests() {
        local disk=\$1
        local caption=\$2
        go_fio_1test read      \$disk \"\${caption}: Sequential read\"
        go_fio_1test write     \$disk \"\${caption}: Sequential write\"
        go_fio_1test randread  \$disk \"\${caption}: Random read\"
        go_fio_1test randwrite \$disk \"\${caption}: Random write\"
        rm -f \$disk/fiotest
      }
      
      sudo chown -R \$(whoami) /mnt
      go_fio_4tests /mnt \"sdb1 (default)\"
      go_fio_4tests .    \"sda1\"
      
      file=/dev/sdb1
      path=\"/sdb1-accelerated\"
      echo \"Accelerating \$file as \$path\"
      sudo mkdir -p \"\$path\"
      sudo umount /mnt
      sudo mkfs.ext2 -L ext2-accelerated \"\$file\"
      sudo mount -t ext2 \"\$file\" \"\$path\" -o rw,noatime,nodiratime,errors=remount-ro
      sudo chown -R \$(whoami) \"\$path\"
      df -h -T
      echo \"\"
      
      go_fio_4tests \$path \"sdb1 (Accelerated)\"
      sudo umount \"\$path\"


" | sudo tee /usr/local/bin/File-IO-Benchmark >/dev/null 2>&1;
chmod +x /usr/local/bin/File-IO-Benchmark >/dev/null || sudo chmod +x /usr/local/bin/File-IO-Benchmark
if [[ -f /usr/local/bin/File-IO-Benchmark ]]; then echo "OK: File-IO-Benchmark"; else "Unable to extract File-IO-Benchmark"; fi

# Is-RedHat
echo -e "#!/usr/bin/env bash
# Usage 1: if [[ \"\$(Is-RedHat 6)\" ]]; then ... 
# Usage 2: if [[ \"\$(Is-RedHat 8)\" ]]; then ... 
# Usage 3: if [[ \"\$(Is-RedHat)\" ]]; then ...
 
if [ -e /etc/redhat-release ]; then
  redhatRelease=\$(</etc/redhat-release)
  case \$redhatRelease in 
    \"CentOS release 6.\"*)                           ret=6 ;;
    \"Red Hat Enterprise Linux Server release 6.\"*)  ret=6 ;;
  esac
fi

if [ -e /etc/os-release ]; then
  . /etc/os-release
  if [ \"\${ID:-}\" = \"rhel\" ] || [ \"\${ID:-}\" = \"centos\" ]; then
    case \"\${VERSION_ID:-}\" in
        \"7\"*)   ret=7 ;;
        \"8\"*)   ret=8 ;;
        \"9\"*)   ret=9 ;;
    esac
  fi
fi

arg=\"\$1\"
if [ \"\$arg\" = \"\" ]; then
    echo \"\$ret\"
    exit 0
elif [ \"\$arg\" = \"\$ret\" ]; then
    echo \"\$ret\"
    exit 0
else
    exit 1
fi

" > /usr/local/bin/Is-RedHat || 
echo -e "#!/usr/bin/env bash
# Usage 1: if [[ \"\$(Is-RedHat 6)\" ]]; then ... 
# Usage 2: if [[ \"\$(Is-RedHat 8)\" ]]; then ... 
# Usage 3: if [[ \"\$(Is-RedHat)\" ]]; then ...
 
if [ -e /etc/redhat-release ]; then
  redhatRelease=\$(</etc/redhat-release)
  case \$redhatRelease in 
    \"CentOS release 6.\"*)                           ret=6 ;;
    \"Red Hat Enterprise Linux Server release 6.\"*)  ret=6 ;;
  esac
fi

if [ -e /etc/os-release ]; then
  . /etc/os-release
  if [ \"\${ID:-}\" = \"rhel\" ] || [ \"\${ID:-}\" = \"centos\" ]; then
    case \"\${VERSION_ID:-}\" in
        \"7\"*)   ret=7 ;;
        \"8\"*)   ret=8 ;;
        \"9\"*)   ret=9 ;;
    esac
  fi
fi

arg=\"\$1\"
if [ \"\$arg\" = \"\" ]; then
    echo \"\$ret\"
    exit 0
elif [ \"\$arg\" = \"\$ret\" ]; then
    echo \"\$ret\"
    exit 0
else
    exit 1
fi

" | sudo tee /usr/local/bin/Is-RedHat >/dev/null 2>&1;
chmod +x /usr/local/bin/Is-RedHat >/dev/null || sudo chmod +x /usr/local/bin/Is-RedHat
if [[ -f /usr/local/bin/Is-RedHat ]]; then echo "OK: Is-RedHat"; else "Unable to extract Is-RedHat"; fi

# lazy-apt-update
echo -e "#!/usr/bin/env bash
# SMART lazy-apt-update - only for built-in Debian repos
# try-and-retry is NOT for here
ls -1 /var/lib/apt/lists/deb* >/dev/null 2>&1 || ls -1 /var/lib/apt/lists/lock >/dev/null 2>&1 || {
    Say \"Updating apt metadata (/var/lib/apt/lists/)\"
    sudo apt-get update --allow-unauthenticated -qq
}


" > /usr/local/bin/lazy-apt-update || 
echo -e "#!/usr/bin/env bash
# SMART lazy-apt-update - only for built-in Debian repos
# try-and-retry is NOT for here
ls -1 /var/lib/apt/lists/deb* >/dev/null 2>&1 || ls -1 /var/lib/apt/lists/lock >/dev/null 2>&1 || {
    Say \"Updating apt metadata (/var/lib/apt/lists/)\"
    sudo apt-get update --allow-unauthenticated -qq
}


" | sudo tee /usr/local/bin/lazy-apt-update >/dev/null 2>&1;
chmod +x /usr/local/bin/lazy-apt-update >/dev/null || sudo chmod +x /usr/local/bin/lazy-apt-update
if [[ -f /usr/local/bin/lazy-apt-update ]]; then echo "OK: lazy-apt-update"; else "Unable to extract lazy-apt-update"; fi

# list-packages
echo -e "#!/usr/bin/env bash
packages=\$(dpkg --get-selections | grep -v deinstall | awk \"{print \$1}\")
apt-cache --no-all-versions show \$packages |
  awk '
      \$1 == \"Package:\" { p = \$2; v=\"\" }
      \$1 == \"Version:\" { v = \$2 }
      \$1 == \"Size:\"    { printf(\"%10d %s %s\\n\", \$2, p, v) }
  ' | sort -k1 -n

" > /usr/local/bin/list-packages || 
echo -e "#!/usr/bin/env bash
packages=\$(dpkg --get-selections | grep -v deinstall | awk \"{print \$1}\")
apt-cache --no-all-versions show \$packages |
  awk '
      \$1 == \"Package:\" { p = \$2; v=\"\" }
      \$1 == \"Version:\" { v = \$2 }
      \$1 == \"Size:\"    { printf(\"%10d %s %s\\n\", \$2, p, v) }
  ' | sort -k1 -n

" | sudo tee /usr/local/bin/list-packages >/dev/null 2>&1;
chmod +x /usr/local/bin/list-packages >/dev/null || sudo chmod +x /usr/local/bin/list-packages
if [[ -f /usr/local/bin/list-packages ]]; then echo "OK: list-packages"; else "Unable to extract list-packages"; fi

# Reset-Target-Framework
echo -e "#!/usr/bin/env bash

function get_legacy_framework_version() {
  local fw=\"\$1\";
  case \$fw in
    net20)     echo \"v2.0\";;
    net30)     echo \"v3.0\";;
    net35)     echo \"v3.5\";;
    net40)     echo \"v4.0\";;
    net45)     echo \"v4.5\";;
    net451)    echo \"v4.5.1\";;
    net452)    echo \"v4.5.2\";;
    net46)     echo \"v4.6\";;
    net461)    echo \"v4.6.1\";;
    net462)    echo \"v4.6.2\";;
    net47)     echo \"v4.7\";;
    net471)    echo \"v4.7.1\";;
    net472)    echo \"v4.7.2\";;
    net48)     echo \"v4.8\";;
    *)         echo \"latest\";;
  esac
}

TARGET_FRAMEWORK=
LANGUAGE=
REVERT=
DRY_RUN=
HELP=
POSITIONAL_PARAMETERS=()
while [[ \$# -gt 0 ]]; do
    key=\"\$1\"
    case \${key} in
        
        -fw|--framework)
        TARGET_FRAMEWORK=\"\$2\"
        shift; shift;;
        
        -l|--language)
        LANGUAGE=\"\$2\"
        shift; shift;;

        -r|--revert)
        REVERT=true
        shift;;

        --dry-run)
        DRY_RUN=true
        shift;;

        -h|--help)
        HELP=true
        shift;;

        *)    
        POSITIONAL+=(\"\$1\")
        echo \"Reset-Target-Framework: INFO. Unknown argument \$1\"  
        shift;;
    esac
done

if [[ -n \"\$HELP\" ]]; then echo 'Usage:
Reset-Target-Framework \\
    [-fw|--framework net40|net45|net451|net452|net46|net461|net452|net47|net471|net472|net48] \\
    [-l|--language 1|2|3|..|7.0|7.1|7.2|8.0|latest]
    [--dry-run]

    The list of supported versions: csc /langversion:?
    
or 
Reset-Target-Framework -h|--help
    
or 
Reset-Target-Framework --revert
'
    exit 0;
fi

echo \"Solution/Project tree '\$(pwd)'\"

if [[ -n \"\$DRY_RUN\" ]]; then 
    echo \"Dry run - is a check only mode without any changes in project files\"; 
fi

if [[ -n \"\$REVERT\" ]]; then
    echo \"Reverting project files from backups (didn't try git reset --hard; git clean -fx)\" 
    find . | grep -E \"\\.csproj\$\" | while read csproj; do
      # echo \"csproj: \$csproj\"
      if [[ -f \"\${csproj}.backup\" ]]; then 
        echo \"Reverting project File '\${csproj}'\"
        mv -f \"\${csproj}.backup\" \"\${csproj}\"; 
      fi
    done
    exit 0;
fi



if [[ -n \"\$TARGET_FRAMEWORK\" ]]; then
    echo \"Resetting <TargetFramework[s]> to '\$TARGET_FRAMEWORK'\"
    LEGACY_TARGET_FRAMEWORK=\"\$(get_legacy_framework_version \${TARGET_FRAMEWORK})\"
    echo \"Resetting <TargetFrameworkVersion> to '\$LEGACY_TARGET_FRAMEWORK'\"
else
    echo \"Keep <TargetFramework/TargetFrameworks/TargetFrameworkVersion> as is\"
fi

if [[ -n \"\$LANGUAGE\" ]]; then
    echo \"Resetting <LangVersion> to '\$LANGUAGE'\"
else
    echo \"Keep <LangVersion> as is\"
fi

find . | grep -E \"\\.csproj\$\" | while read csproj; do
  # echo \"csproj: \$csproj\"
  if [[ ! -f \"\${csproj}.backup\" ]]; then cp \"\${csproj}\" \"\${csproj}.backup\"; fi
  lines=\$(cat \"\${csproj}\" | grep -E \"<TargetFrameworks>\")
  echo \"Project File '\${csproj}':\"
  
  if [[ -n \"\$TARGET_FRAMEWORK\" ]]; then
      # Check for <TargetFrameworks> 
      tfs_prev=\$(cat \"\${csproj}\" | grep -oP \"<TargetFrameworks>(.*)</TargetFrameworks>\"  | cut -d \">\" -f 2 | cut -d \"<\" -f 1)
      if [[ -n \"\$tfs_prev\" ]]; then
        printf \"    TargetFrameworks: '\$tfs_prev' --> '\$TARGET_FRAMEWORK'\\n\"
        sed_cmd='/<TargetFrameworks>/c\\<TargetFrameworks>'\$TARGET_FRAMEWORK'<\\/TargetFrameworks>'
        # printf \"    sed cmd: [\$sed_cmd]\\n\"
        sed -i \"\$sed_cmd\" \$csproj
      fi
      
      # Check for <TargetFramework>
      tf_prev=\$(cat \"\${csproj}\" | grep -oP \"<TargetFramework>(.*)</TargetFramework>\"  | cut -d \">\" -f 2 | cut -d \"<\" -f 1)
      if [[ -n \"\$tf_prev\" ]]; then
        echo \"    TargetFramework: '\$tf_prev' --> '\$TARGET_FRAMEWORK'\"
        sed_cmd='/<TargetFramework>/c\\<TargetFramework>'\$TARGET_FRAMEWORK'<\\/TargetFramework>'
        # echo \"    sed cmd: [\$sed_cmd]\"
        sed -i \"\$sed_cmd\" \$csproj
      fi
      
      # Check for <TargetFrameworkVersion>
      tfv_prev=\$(cat \"\${csproj}\" | grep -oP \"<TargetFrameworkVersion>(.*)</TargetFrameworkVersion>\"  | cut -d \">\" -f 2 | cut -d \"<\" -f 1)
      if [[ -n \"\$tfv_prev\" ]]; then
        echo \"    TargetFrameworkVersion: '\$tfv_prev' --> '\$LEGACY_TARGET_FRAMEWORK'\"
        sed_cmd='/<TargetFrameworkVersion>/c\\<TargetFrameworkVersion>'\$LEGACY_TARGET_FRAMEWORK'<\\/TargetFrameworkVersion>'
        # echo \"    sed cmd: [\$sed_cmd]\"
        sed -i \"\$sed_cmd\" \$csproj
      fi
      
      # Is nothing found?
      if [[ -z \"\$tfs_prev\" && -z \"\$tf_prev\" && -z \"\$tfv_prev\" ]]; then
        echo \"    Warning! Neither <TargetFrameworks> nor <TargetFramework> or <TargetFrameworkVersion> are found, but framework was specified as \$TARGET_FRAMEWORK\"
      fi
  fi
  
    if [[ -n \"\$LANGUAGE\" ]]; then
      # Check for <LangVersion> 
      lang_prev=\$(cat \"\${csproj}\" | grep -oP \"<LangVersion>(.*)</LangVersion>\"  | cut -d \">\" -f 2 | cut -d \"<\" -f 1)
      if [[ -n \"\$lang_prev\" ]]; then
        printf \"    <LangVersion>: '\$lang_prev' --> '\$LANGUAGE'\\n\"
        sed_cmd='/<LangVersion>/c\\<LangVersion>'\$LANGUAGE'<\\/LangVersion>'
        # printf \"    sed cmd: [\$sed_cmd]\\n\"
        sed -i \"\$sed_cmd\" \$csproj
      else
        echo \"    Warning! <LangVersion> not found, but language was specified as \$LANGUAGE\"
      fi
    fi

  
   

  # echo \$lines
  # echo \"TargetFrameworks: \$fw\"
  echo \"\"
done

" > /usr/local/bin/Reset-Target-Framework || 
echo -e "#!/usr/bin/env bash

function get_legacy_framework_version() {
  local fw=\"\$1\";
  case \$fw in
    net20)     echo \"v2.0\";;
    net30)     echo \"v3.0\";;
    net35)     echo \"v3.5\";;
    net40)     echo \"v4.0\";;
    net45)     echo \"v4.5\";;
    net451)    echo \"v4.5.1\";;
    net452)    echo \"v4.5.2\";;
    net46)     echo \"v4.6\";;
    net461)    echo \"v4.6.1\";;
    net462)    echo \"v4.6.2\";;
    net47)     echo \"v4.7\";;
    net471)    echo \"v4.7.1\";;
    net472)    echo \"v4.7.2\";;
    net48)     echo \"v4.8\";;
    *)         echo \"latest\";;
  esac
}

TARGET_FRAMEWORK=
LANGUAGE=
REVERT=
DRY_RUN=
HELP=
POSITIONAL_PARAMETERS=()
while [[ \$# -gt 0 ]]; do
    key=\"\$1\"
    case \${key} in
        
        -fw|--framework)
        TARGET_FRAMEWORK=\"\$2\"
        shift; shift;;
        
        -l|--language)
        LANGUAGE=\"\$2\"
        shift; shift;;

        -r|--revert)
        REVERT=true
        shift;;

        --dry-run)
        DRY_RUN=true
        shift;;

        -h|--help)
        HELP=true
        shift;;

        *)    
        POSITIONAL+=(\"\$1\")
        echo \"Reset-Target-Framework: INFO. Unknown argument \$1\"  
        shift;;
    esac
done

if [[ -n \"\$HELP\" ]]; then echo 'Usage:
Reset-Target-Framework \\
    [-fw|--framework net40|net45|net451|net452|net46|net461|net452|net47|net471|net472|net48] \\
    [-l|--language 1|2|3|..|7.0|7.1|7.2|8.0|latest]
    [--dry-run]

    The list of supported versions: csc /langversion:?
    
or 
Reset-Target-Framework -h|--help
    
or 
Reset-Target-Framework --revert
'
    exit 0;
fi

echo \"Solution/Project tree '\$(pwd)'\"

if [[ -n \"\$DRY_RUN\" ]]; then 
    echo \"Dry run - is a check only mode without any changes in project files\"; 
fi

if [[ -n \"\$REVERT\" ]]; then
    echo \"Reverting project files from backups (didn't try git reset --hard; git clean -fx)\" 
    find . | grep -E \"\\.csproj\$\" | while read csproj; do
      # echo \"csproj: \$csproj\"
      if [[ -f \"\${csproj}.backup\" ]]; then 
        echo \"Reverting project File '\${csproj}'\"
        mv -f \"\${csproj}.backup\" \"\${csproj}\"; 
      fi
    done
    exit 0;
fi



if [[ -n \"\$TARGET_FRAMEWORK\" ]]; then
    echo \"Resetting <TargetFramework[s]> to '\$TARGET_FRAMEWORK'\"
    LEGACY_TARGET_FRAMEWORK=\"\$(get_legacy_framework_version \${TARGET_FRAMEWORK})\"
    echo \"Resetting <TargetFrameworkVersion> to '\$LEGACY_TARGET_FRAMEWORK'\"
else
    echo \"Keep <TargetFramework/TargetFrameworks/TargetFrameworkVersion> as is\"
fi

if [[ -n \"\$LANGUAGE\" ]]; then
    echo \"Resetting <LangVersion> to '\$LANGUAGE'\"
else
    echo \"Keep <LangVersion> as is\"
fi

find . | grep -E \"\\.csproj\$\" | while read csproj; do
  # echo \"csproj: \$csproj\"
  if [[ ! -f \"\${csproj}.backup\" ]]; then cp \"\${csproj}\" \"\${csproj}.backup\"; fi
  lines=\$(cat \"\${csproj}\" | grep -E \"<TargetFrameworks>\")
  echo \"Project File '\${csproj}':\"
  
  if [[ -n \"\$TARGET_FRAMEWORK\" ]]; then
      # Check for <TargetFrameworks> 
      tfs_prev=\$(cat \"\${csproj}\" | grep -oP \"<TargetFrameworks>(.*)</TargetFrameworks>\"  | cut -d \">\" -f 2 | cut -d \"<\" -f 1)
      if [[ -n \"\$tfs_prev\" ]]; then
        printf \"    TargetFrameworks: '\$tfs_prev' --> '\$TARGET_FRAMEWORK'\\n\"
        sed_cmd='/<TargetFrameworks>/c\\<TargetFrameworks>'\$TARGET_FRAMEWORK'<\\/TargetFrameworks>'
        # printf \"    sed cmd: [\$sed_cmd]\\n\"
        sed -i \"\$sed_cmd\" \$csproj
      fi
      
      # Check for <TargetFramework>
      tf_prev=\$(cat \"\${csproj}\" | grep -oP \"<TargetFramework>(.*)</TargetFramework>\"  | cut -d \">\" -f 2 | cut -d \"<\" -f 1)
      if [[ -n \"\$tf_prev\" ]]; then
        echo \"    TargetFramework: '\$tf_prev' --> '\$TARGET_FRAMEWORK'\"
        sed_cmd='/<TargetFramework>/c\\<TargetFramework>'\$TARGET_FRAMEWORK'<\\/TargetFramework>'
        # echo \"    sed cmd: [\$sed_cmd]\"
        sed -i \"\$sed_cmd\" \$csproj
      fi
      
      # Check for <TargetFrameworkVersion>
      tfv_prev=\$(cat \"\${csproj}\" | grep -oP \"<TargetFrameworkVersion>(.*)</TargetFrameworkVersion>\"  | cut -d \">\" -f 2 | cut -d \"<\" -f 1)
      if [[ -n \"\$tfv_prev\" ]]; then
        echo \"    TargetFrameworkVersion: '\$tfv_prev' --> '\$LEGACY_TARGET_FRAMEWORK'\"
        sed_cmd='/<TargetFrameworkVersion>/c\\<TargetFrameworkVersion>'\$LEGACY_TARGET_FRAMEWORK'<\\/TargetFrameworkVersion>'
        # echo \"    sed cmd: [\$sed_cmd]\"
        sed -i \"\$sed_cmd\" \$csproj
      fi
      
      # Is nothing found?
      if [[ -z \"\$tfs_prev\" && -z \"\$tf_prev\" && -z \"\$tfv_prev\" ]]; then
        echo \"    Warning! Neither <TargetFrameworks> nor <TargetFramework> or <TargetFrameworkVersion> are found, but framework was specified as \$TARGET_FRAMEWORK\"
      fi
  fi
  
    if [[ -n \"\$LANGUAGE\" ]]; then
      # Check for <LangVersion> 
      lang_prev=\$(cat \"\${csproj}\" | grep -oP \"<LangVersion>(.*)</LangVersion>\"  | cut -d \">\" -f 2 | cut -d \"<\" -f 1)
      if [[ -n \"\$lang_prev\" ]]; then
        printf \"    <LangVersion>: '\$lang_prev' --> '\$LANGUAGE'\\n\"
        sed_cmd='/<LangVersion>/c\\<LangVersion>'\$LANGUAGE'<\\/LangVersion>'
        # printf \"    sed cmd: [\$sed_cmd]\\n\"
        sed -i \"\$sed_cmd\" \$csproj
      else
        echo \"    Warning! <LangVersion> not found, but language was specified as \$LANGUAGE\"
      fi
    fi

  
   

  # echo \$lines
  # echo \"TargetFrameworks: \$fw\"
  echo \"\"
done

" | sudo tee /usr/local/bin/Reset-Target-Framework >/dev/null 2>&1;
chmod +x /usr/local/bin/Reset-Target-Framework >/dev/null || sudo chmod +x /usr/local/bin/Reset-Target-Framework
if [[ -f /usr/local/bin/Reset-Target-Framework ]]; then echo "OK: Reset-Target-Framework"; else "Unable to extract Reset-Target-Framework"; fi

# Say
echo -e "#!/usr/bin/env bash

    function format2digits() {
      if [[ \$1 -gt 9 ]]; then echo \$1; else echo 0\$1; fi
    }

    function print_header() {
      theSYSTEM=\"\${theSYSTEM:-\$(uname -s)}\"
      if [[ \${theSYSTEM} != \"Darwin\" ]]; then
          uptime=\$(</proc/uptime);                  # 42645.93 240538.58
          IFS=' ' read -ra uptime <<< \"\$uptime\";    # 42645.93 240538.58
          uptime=\"\${uptime[0]}\";                    # 42645.93
          uptime=\$(printf \"%.0f\\n\" \"\$uptime\")       # 42645
          uptime=\$(TZ=UTC date -d \"@\${uptime}\" \"+%H:%M:%S\");
      else 
          # https://stackoverflow.com/questions/15329443/proc-uptime-in-mac-os-x
          boottime=\`sysctl -n kern.boottime | awk '{print \$4}' | sed 's/,//g'\`
\x09\x09  unixtime=\`date +%s\`
\x09\x09  timeAgo=\$((\$unixtime - \$boottime))
          seconds1=\$((timeAgo % 86400));
          seconds=\$((seconds1 % 60));
          minutes1=\$((seconds1 / 60));
          minutes=\$((minutes1 % 60));
          hours=\$((minutes1 / 60));
          # uptime=\`awk -v time=\$timeAgo 'BEGIN { seconds = time % 60; minutes = int(time / 60 % 60); hours = int(time / 60 / 60 % 24); days = int(time / 60 / 60 / 24); printf(\"%.0f days, %.0f hours, %.0f minutes, %.0f seconds\", days, hours, minutes, seconds); exit }'\`
          uptime=\"\$(format2digits \$hours):\$(format2digits \$minutes):\$(format2digits \$seconds)\"
      fi
      black_circle='\\xE2\\x97\\x8f'
      white_circle='\\xE2\\x97\\x8b'
      # BUILD_DEFINITIONNAME
      # if [[ -z \"\$BUILD_DEFINITIONNAME\" ]]; then 
      if [[ -z \"\$SAY_COLORLESS\" ]]; then # skip colors for azure pipelines
        Blue='\\033[1;34m'; Gray='\\033[1;37m'; LightGreen='\\033[1;32m'; Yellow='\\033[1;33m'; RED='\\033[0;31m'; NC='\\033[0m'; LightGray='\\033[1;2m';
      fi
      printf \"\${Blue}\${black_circle} \$(hostname)\${NC} \${LightGray}[\${uptime:-}]\${NC} \${LightGreen}\$1\${NC} \${Yellow}\$2\${NC}\\n\";
      echo \"\$(hostname) \${uptime:-} \$1 \$2\" >> \"/tmp/Said-by-\$(whoami).log\" 2>/dev/null 
    }

    function SayIt() { 
      user=\"\${LOGNAME:-\$(whoami)}\"
      file=\"/tmp/.\${user}-said-counter\"
      if [[ -e \"\$file\" ]]; then counter=\$(< \"\$file\"); else counter=1; fi
      print_header \"#\${counter}\" \"\$1\";
      counter=\$((counter+1));
      echo \$counter > \"\$file\"
    }; 

SayIt \"\$@\"

" > /usr/local/bin/Say || 
echo -e "#!/usr/bin/env bash

    function format2digits() {
      if [[ \$1 -gt 9 ]]; then echo \$1; else echo 0\$1; fi
    }

    function print_header() {
      theSYSTEM=\"\${theSYSTEM:-\$(uname -s)}\"
      if [[ \${theSYSTEM} != \"Darwin\" ]]; then
          uptime=\$(</proc/uptime);                  # 42645.93 240538.58
          IFS=' ' read -ra uptime <<< \"\$uptime\";    # 42645.93 240538.58
          uptime=\"\${uptime[0]}\";                    # 42645.93
          uptime=\$(printf \"%.0f\\n\" \"\$uptime\")       # 42645
          uptime=\$(TZ=UTC date -d \"@\${uptime}\" \"+%H:%M:%S\");
      else 
          # https://stackoverflow.com/questions/15329443/proc-uptime-in-mac-os-x
          boottime=\`sysctl -n kern.boottime | awk '{print \$4}' | sed 's/,//g'\`
\x09\x09  unixtime=\`date +%s\`
\x09\x09  timeAgo=\$((\$unixtime - \$boottime))
          seconds1=\$((timeAgo % 86400));
          seconds=\$((seconds1 % 60));
          minutes1=\$((seconds1 / 60));
          minutes=\$((minutes1 % 60));
          hours=\$((minutes1 / 60));
          # uptime=\`awk -v time=\$timeAgo 'BEGIN { seconds = time % 60; minutes = int(time / 60 % 60); hours = int(time / 60 / 60 % 24); days = int(time / 60 / 60 / 24); printf(\"%.0f days, %.0f hours, %.0f minutes, %.0f seconds\", days, hours, minutes, seconds); exit }'\`
          uptime=\"\$(format2digits \$hours):\$(format2digits \$minutes):\$(format2digits \$seconds)\"
      fi
      black_circle='\\xE2\\x97\\x8f'
      white_circle='\\xE2\\x97\\x8b'
      # BUILD_DEFINITIONNAME
      # if [[ -z \"\$BUILD_DEFINITIONNAME\" ]]; then 
      if [[ -z \"\$SAY_COLORLESS\" ]]; then # skip colors for azure pipelines
        Blue='\\033[1;34m'; Gray='\\033[1;37m'; LightGreen='\\033[1;32m'; Yellow='\\033[1;33m'; RED='\\033[0;31m'; NC='\\033[0m'; LightGray='\\033[1;2m';
      fi
      printf \"\${Blue}\${black_circle} \$(hostname)\${NC} \${LightGray}[\${uptime:-}]\${NC} \${LightGreen}\$1\${NC} \${Yellow}\$2\${NC}\\n\";
      echo \"\$(hostname) \${uptime:-} \$1 \$2\" >> \"/tmp/Said-by-\$(whoami).log\" 2>/dev/null 
    }

    function SayIt() { 
      user=\"\${LOGNAME:-\$(whoami)}\"
      file=\"/tmp/.\${user}-said-counter\"
      if [[ -e \"\$file\" ]]; then counter=\$(< \"\$file\"); else counter=1; fi
      print_header \"#\${counter}\" \"\$1\";
      counter=\$((counter+1));
      echo \$counter > \"\$file\"
    }; 

SayIt \"\$@\"

" | sudo tee /usr/local/bin/Say >/dev/null 2>&1;
chmod +x /usr/local/bin/Say >/dev/null || sudo chmod +x /usr/local/bin/Say
if [[ -f /usr/local/bin/Say ]]; then echo "OK: Say"; else "Unable to extract Say"; fi

# Show-System-Stat
echo -e "#!/usr/bin/env bash
function uname_system() {
  cached_uname_system=\${cached_uname_system:-\$(uname -s)}
  echo \$cached_uname_system
}

function format_seconds() {
  local elapsed=\$1
  local days=\$((elapsed/86400))
  if [[ \"\$(uname_system)\" != Darwin ]]; then
     elapsed=\$(TZ=UTC date -d \"@\${elapsed}\" \"+%H:%M:%S\");
  else 
     elapsed=\$(TZ=UTC date -r \"\${elapsed}\" \"+%H:%M:%S\");
  fi
  if [[ \${days} -eq 0 ]]; then 
    echo \${elapsed}
  elif [[ \${days} -eq 1 ]]; then
    echo \"1 day, \$elapsed\"
  else
    echo \"\$days days, \$elapsed\"
  fi
}

function GetUptimeInSeconds() {
   local uptime=\$(</proc/uptime);                  # 42645.93 240538.58
   IFS=' ' read -ra uptime <<< \"\$uptime\";    # 42645.93 240538.58
   uptime=\"\${uptime[0]}\";                    # 42645.93
   uptime=\$(printf \"%.0f\\n\" \"\$uptime\")       # 42645
   echo \$uptime
}

function ShowSystemStat() {
  if [[ \"\$(uname_system)\" == Darwin || ! -f /proc/stat ]]; then
    uptime
    return;
  fi
  
  local first_line=\$(cat /proc/stat | sed -n 1p)
  local user_normal=\$(echo \$first_line | awk '{print \$2}')
  user_normal=\$((user_normal/100))
  local user_nice=\$(echo \$first_line | awk '{print \$3}')
  user_nice=\$((user_nice/100))
  local system=\$(echo \$first_line | awk '{print \$4}')
  system=\$((system/100))
  local total=\$((user_normal + user_nice + system))
  local uptime=\$(GetUptimeInSeconds)
  # echo uptime in seconds: \$uptime 
  
  local user_normal_formatted=\"\$(format_seconds \${user_normal})\"
  local user_nice_formatted=\"\$(format_seconds \${user_nice})\"
  local system_formatted=\"\$(format_seconds \${system})\"
  local total_formatted=\"\$(format_seconds \${total})\"
  local uptime_formatted=\"\$(format_seconds \${uptime})\"
  
  
  echo \"User CPU Usage (normal priority) ..... \$user_normal_formatted
User CPU Usage (low priority) ........ \$user_nice_formatted
System CPU Usage ..................... \$system_formatted
--------------------------------------
Total CPU Usage ...................... \$total_formatted
Uptime ............................... \$uptime_formatted\"
}

function FormatBytes() {
    local bytes=\$1
    if [[ \"\$bytes\" -lt 9000 ]]; then bytes=\"\$bytes bytes\"; 
    elif [[ \"\$bytes\" -lt 9000000 ]]; then bytes=\$((bytes/1024)); bytes=\"\$bytes Kb\";
    elif [[ \"\$bytes\" -lt 9000000000 ]]; then bytes=\$((bytes/1048576)); bytes=\"\$bytes Mb\";
    else bytes=\$((bytes/1073741824)); bytes=\"\$bytes Gb\";
    fi
    echo \$bytes
}

function ShowNetStat() {
    if [[ ! -f /proc/net/dev ]]; then return; fi
    local line
    cat /proc/net/dev | sed -n '3,\$p' | sort | while read line; do
        local name=\$(echo \$line | awk '{print \$1}')
        # echo \"NET [\$name]\"
        if [[ \"\$name\" == *\":\" ]]; then
            local recv=\$(echo \$line | awk '{print \$2}')
            local sent=\$(echo \$line | awk '{print \$10}')
            name=\"\${name} \";local n=0; while [[ \$n -lt 55 && \"\${#name}\" -lt 38 ]]; do n=\$((n+1));name=\"\${name}.\"; done
            if [[ \"\$sent\" -gt 0 && \"\$recv\" -gt 0 ]]; then
                sent=\$(FormatBytes \$sent)
                recv=\$(FormatBytes \$recv)
                local sent_formatted=\`printf %-7s \"\$sent\"\`
                local recv_formatted=\`printf %-7s \"\$recv\"\`
                echo \"\$name \${sent_formatted} [sent] + \${recv_formatted} [recieved]\"
            fi  
        fi 
        
    done
}

# while true; do clear; ShowSystemStat; sleep 2; done
ShowSystemStat
ShowNetStat

" > /usr/local/bin/Show-System-Stat || 
echo -e "#!/usr/bin/env bash
function uname_system() {
  cached_uname_system=\${cached_uname_system:-\$(uname -s)}
  echo \$cached_uname_system
}

function format_seconds() {
  local elapsed=\$1
  local days=\$((elapsed/86400))
  if [[ \"\$(uname_system)\" != Darwin ]]; then
     elapsed=\$(TZ=UTC date -d \"@\${elapsed}\" \"+%H:%M:%S\");
  else 
     elapsed=\$(TZ=UTC date -r \"\${elapsed}\" \"+%H:%M:%S\");
  fi
  if [[ \${days} -eq 0 ]]; then 
    echo \${elapsed}
  elif [[ \${days} -eq 1 ]]; then
    echo \"1 day, \$elapsed\"
  else
    echo \"\$days days, \$elapsed\"
  fi
}

function GetUptimeInSeconds() {
   local uptime=\$(</proc/uptime);                  # 42645.93 240538.58
   IFS=' ' read -ra uptime <<< \"\$uptime\";    # 42645.93 240538.58
   uptime=\"\${uptime[0]}\";                    # 42645.93
   uptime=\$(printf \"%.0f\\n\" \"\$uptime\")       # 42645
   echo \$uptime
}

function ShowSystemStat() {
  if [[ \"\$(uname_system)\" == Darwin || ! -f /proc/stat ]]; then
    uptime
    return;
  fi
  
  local first_line=\$(cat /proc/stat | sed -n 1p)
  local user_normal=\$(echo \$first_line | awk '{print \$2}')
  user_normal=\$((user_normal/100))
  local user_nice=\$(echo \$first_line | awk '{print \$3}')
  user_nice=\$((user_nice/100))
  local system=\$(echo \$first_line | awk '{print \$4}')
  system=\$((system/100))
  local total=\$((user_normal + user_nice + system))
  local uptime=\$(GetUptimeInSeconds)
  # echo uptime in seconds: \$uptime 
  
  local user_normal_formatted=\"\$(format_seconds \${user_normal})\"
  local user_nice_formatted=\"\$(format_seconds \${user_nice})\"
  local system_formatted=\"\$(format_seconds \${system})\"
  local total_formatted=\"\$(format_seconds \${total})\"
  local uptime_formatted=\"\$(format_seconds \${uptime})\"
  
  
  echo \"User CPU Usage (normal priority) ..... \$user_normal_formatted
User CPU Usage (low priority) ........ \$user_nice_formatted
System CPU Usage ..................... \$system_formatted
--------------------------------------
Total CPU Usage ...................... \$total_formatted
Uptime ............................... \$uptime_formatted\"
}

function FormatBytes() {
    local bytes=\$1
    if [[ \"\$bytes\" -lt 9000 ]]; then bytes=\"\$bytes bytes\"; 
    elif [[ \"\$bytes\" -lt 9000000 ]]; then bytes=\$((bytes/1024)); bytes=\"\$bytes Kb\";
    elif [[ \"\$bytes\" -lt 9000000000 ]]; then bytes=\$((bytes/1048576)); bytes=\"\$bytes Mb\";
    else bytes=\$((bytes/1073741824)); bytes=\"\$bytes Gb\";
    fi
    echo \$bytes
}

function ShowNetStat() {
    if [[ ! -f /proc/net/dev ]]; then return; fi
    local line
    cat /proc/net/dev | sed -n '3,\$p' | sort | while read line; do
        local name=\$(echo \$line | awk '{print \$1}')
        # echo \"NET [\$name]\"
        if [[ \"\$name\" == *\":\" ]]; then
            local recv=\$(echo \$line | awk '{print \$2}')
            local sent=\$(echo \$line | awk '{print \$10}')
            name=\"\${name} \";local n=0; while [[ \$n -lt 55 && \"\${#name}\" -lt 38 ]]; do n=\$((n+1));name=\"\${name}.\"; done
            if [[ \"\$sent\" -gt 0 && \"\$recv\" -gt 0 ]]; then
                sent=\$(FormatBytes \$sent)
                recv=\$(FormatBytes \$recv)
                local sent_formatted=\`printf %-7s \"\$sent\"\`
                local recv_formatted=\`printf %-7s \"\$recv\"\`
                echo \"\$name \${sent_formatted} [sent] + \${recv_formatted} [recieved]\"
            fi  
        fi 
        
    done
}

# while true; do clear; ShowSystemStat; sleep 2; done
ShowSystemStat
ShowNetStat

" | sudo tee /usr/local/bin/Show-System-Stat >/dev/null 2>&1;
chmod +x /usr/local/bin/Show-System-Stat >/dev/null || sudo chmod +x /usr/local/bin/Show-System-Stat
if [[ -f /usr/local/bin/Show-System-Stat ]]; then echo "OK: Show-System-Stat"; else "Unable to extract Show-System-Stat"; fi

# smart-apt-install
echo -e "#!/usr/bin/env bash

    try-and-retry lazy-apt-update
    Say \"Downloading deb-package(s): \$*\"
    try-and-retry sudo apt-get -qq -d --allow-unauthenticated install \"\$@\" 
    Say \"Installing deb-package(s): \$*\"
    sudo DEBIAN_FRONTEND=noninteractive apt-get --allow-unauthenticated install \"\$@\" -y -q
    sudo DEBIAN_FRONTEND=noninteractive apt-get clean

" > /usr/local/bin/smart-apt-install || 
echo -e "#!/usr/bin/env bash

    try-and-retry lazy-apt-update
    Say \"Downloading deb-package(s): \$*\"
    try-and-retry sudo apt-get -qq -d --allow-unauthenticated install \"\$@\" 
    Say \"Installing deb-package(s): \$*\"
    sudo DEBIAN_FRONTEND=noninteractive apt-get --allow-unauthenticated install \"\$@\" -y -q
    sudo DEBIAN_FRONTEND=noninteractive apt-get clean

" | sudo tee /usr/local/bin/smart-apt-install >/dev/null 2>&1;
chmod +x /usr/local/bin/smart-apt-install >/dev/null || sudo chmod +x /usr/local/bin/smart-apt-install
if [[ -f /usr/local/bin/smart-apt-install ]]; then echo "OK: smart-apt-install"; else "Unable to extract smart-apt-install"; fi

# try-and-retry
echo -e "#!/usr/bin/env bash

  ANSI_RED='\\033[0;31m'; 
  ANSI_RESET='\\033[0m';
  result=0
  count=1
  while [ \$count -le 3 ]; do
    [ \$result -ne 0 ] && {
      echo -e \"\\n\${ANSI_RED}The command \\\"\$@\\\" failed. Retrying, \$count of 3.\${ANSI_RESET}\\n\" >&2
    }
    # ! { } ignores set -e, see https://stackoverflow.com/a/4073372
    ! { \"\$@\"; result=\$?; }
    [ \$result -eq 0 ] && break
    count=\$((\$count + 1))
    sleep 1
  done

  [ \$count -gt 3 ] && {
    echo -e \"\\n\${ANSI_RED}The command \\\"\$@\\\" failed 3 times.\${ANSI_RESET}\\n\" >&2
  }

  exit \$result



" > /usr/local/bin/try-and-retry || 
echo -e "#!/usr/bin/env bash

  ANSI_RED='\\033[0;31m'; 
  ANSI_RESET='\\033[0m';
  result=0
  count=1
  while [ \$count -le 3 ]; do
    [ \$result -ne 0 ] && {
      echo -e \"\\n\${ANSI_RED}The command \\\"\$@\\\" failed. Retrying, \$count of 3.\${ANSI_RESET}\\n\" >&2
    }
    # ! { } ignores set -e, see https://stackoverflow.com/a/4073372
    ! { \"\$@\"; result=\$?; }
    [ \$result -eq 0 ] && break
    count=\$((\$count + 1))
    sleep 1
  done

  [ \$count -gt 3 ] && {
    echo -e \"\\n\${ANSI_RED}The command \\\"\$@\\\" failed 3 times.\${ANSI_RESET}\\n\" >&2
  }

  exit \$result



" | sudo tee /usr/local/bin/try-and-retry >/dev/null 2>&1;
chmod +x /usr/local/bin/try-and-retry >/dev/null || sudo chmod +x /usr/local/bin/try-and-retry
if [[ -f /usr/local/bin/try-and-retry ]]; then echo "OK: try-and-retry"; else "Unable to extract try-and-retry"; fi

