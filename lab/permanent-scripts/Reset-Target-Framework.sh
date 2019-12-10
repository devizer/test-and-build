#!/usr/bin/env bash

function get_legacy_framework_version() {
  local fw="$1";
  case $fw in
    net20)     echo "v2.0";;
    net30)     echo "v3.0";;
    net35)     echo "v3.5";;
    net40)     echo "v4.0";;
    net45)     echo "v4.5";;
    net451)    echo "v4.5.1";;
    net452)    echo "v4.5.2";;
    net46)     echo "v4.6";;
    net461)    echo "v4.6.1";;
    net462)    echo "v4.6.2";;
    net47)     echo "v4.7";;
    net471)    echo "v4.7.1";;
    net472)    echo "v4.7.2";;
    net48)     echo "v4.8";;
    *)         echo "latest";;
  esac
}

TARGET_FRAMEWORK=
LANGUAGE=
REVERT=
DRY_RUN=
HELP=
POSITIONAL_PARAMETERS=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case ${key} in
        
        -fw|--framework)
        TARGET_FRAMEWORK="$2"
        shift; shift;;
        
        -l|--language)
        LANGUAGE="$2"
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
        POSITIONAL+=("$1")
        echo "Reset-Target-Framework: INFO. Unknown argument $1"  
        shift;;
    esac
done

if [[ -n "$HELP" ]]; then echo 'Usage:
Reset-Target-Framework \
    [-fw|--framework net40|net45|net451|net452|net46|net461|net452|net47|net471|net472|net48] \
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

echo "Solution/Project tree '$(pwd)'"

if [[ -n "$DRY_RUN" ]]; then 
    echo "Dry run - is a check only mode without any changes in project files"; 
fi

if [[ -n "$REVERT" ]]; then
    echo "Reverting project files from backups (didn't try git reset --hard; git clean -fx)" 
    find . | grep -E "\.csproj$" | while read csproj; do
      # echo "csproj: $csproj"
      if [[ -f "${csproj}.backup" ]]; then 
        echo "Reverting project File '${csproj}'"
        mv -f "${csproj}.backup" "${csproj}"; 
      fi
    done
    exit 0;
fi



if [[ -n "$TARGET_FRAMEWORK" ]]; then
    echo "Resetting <TargetFramework[s]> to '$TARGET_FRAMEWORK'"
    LEGACY_TARGET_FRAMEWORK="$(get_legacy_framework_version ${TARGET_FRAMEWORK})"
    echo "Resetting <TargetFrameworkVersion> to '$LEGACY_TARGET_FRAMEWORK'"
else
    echo "Keep <TargetFramework/TargetFrameworks/TargetFrameworkVersion> as is"
fi

if [[ -n "$LANGUAGE" ]]; then
    echo "Resetting <LangVersion> to '$LANGUAGE'"
else
    echo "Keep <LangVersion> as is"
fi

find . | grep -E "\.csproj$" | while read csproj; do
  # echo "csproj: $csproj"
  if [[ ! -f "${csproj}.backup" ]]; then cp "${csproj}" "${csproj}.backup"; fi
  lines=$(cat "${csproj}" | grep -E "<TargetFrameworks>")
  echo "Project File '${csproj}':"
  
  if [[ -n "$TARGET_FRAMEWORK" ]]; then
      # Check for <TargetFrameworks> 
      tfs_prev=$(cat "${csproj}" | grep -oP "<TargetFrameworks>(.*)</TargetFrameworks>"  | cut -d ">" -f 2 | cut -d "<" -f 1)
      if [[ -n "$tfs_prev" ]]; then
        printf "    TargetFrameworks: '$tfs_prev' --> '$TARGET_FRAMEWORK'\n"
        sed_cmd='/<TargetFrameworks>/c\<TargetFrameworks>'$TARGET_FRAMEWORK'<\/TargetFrameworks>'
        # printf "    sed cmd: [$sed_cmd]\n"
        sed -i "$sed_cmd" $csproj
      fi
      
      # Check for <TargetFramework>
      tf_prev=$(cat "${csproj}" | grep -oP "<TargetFramework>(.*)</TargetFramework>"  | cut -d ">" -f 2 | cut -d "<" -f 1)
      if [[ -n "$tf_prev" ]]; then
        echo "    TargetFramework: '$tf_prev' --> '$TARGET_FRAMEWORK'"
        sed_cmd='/<TargetFramework>/c\<TargetFramework>'$TARGET_FRAMEWORK'<\/TargetFramework>'
        # echo "    sed cmd: [$sed_cmd]"
        sed -i "$sed_cmd" $csproj
      fi
      
      # Check for <TargetFrameworkVersion>
      tfv_prev=$(cat "${csproj}" | grep -oP "<TargetFrameworkVersion>(.*)</TargetFrameworkVersion>"  | cut -d ">" -f 2 | cut -d "<" -f 1)
      if [[ -n "$tfv_prev" ]]; then
        echo "    TargetFrameworkVersion: '$tfv_prev' --> '$LEGACY_TARGET_FRAMEWORK'"
        sed_cmd='/<TargetFrameworkVersion>/c\<TargetFrameworkVersion>'$LEGACY_TARGET_FRAMEWORK'<\/TargetFrameworkVersion>'
        # echo "    sed cmd: [$sed_cmd]"
        sed -i "$sed_cmd" $csproj
      fi
      
      # Is nothing found?
      if [[ -z "$tfs_prev" && -z "$tf_prev" && -z "$tfv_prev" ]]; then
        echo "    Warning! Neither <TargetFrameworks> nor <TargetFramework> or <TargetFrameworkVersion> are found, but framework was specified as $TARGET_FRAMEWORK"
      fi
  fi
  
    if [[ -n "$LANGUAGE" ]]; then
      # Check for <LangVersion> 
      lang_prev=$(cat "${csproj}" | grep -oP "<LangVersion>(.*)</LangVersion>"  | cut -d ">" -f 2 | cut -d "<" -f 1)
      if [[ -n "$lang_prev" ]]; then
        printf "    <LangVersion>: '$lang_prev' --> '$LANGUAGE'\n"
        sed_cmd='/<LangVersion>/c\<LangVersion>'$LANGUAGE'<\/LangVersion>'
        # printf "    sed cmd: [$sed_cmd]\n"
        sed -i "$sed_cmd" $csproj
      else
        echo "    Warning! <LangVersion> not found, but language was specified as $LANGUAGE"
      fi
    fi

  
   

  # echo $lines
  # echo "TargetFrameworks: $fw"
  echo ""
done
