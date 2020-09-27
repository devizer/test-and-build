#!/usr/bin/env bash
# https://developer.github.com/v3/repos/releases/#list-releases

function get_github_releases() {
    local owner="$1";
    local repo="$2";
    local need_pre_release="$3"; 
    if [[ "$need_pre_release" == "pre"* || "$need_pre_release" == "--pre"* ]]; then 
        need_pre_release=true; else need_pre_release=false; 
    fi
    
    local query="https://api.github.com/repos/$owner/$repo/releases"
    local jqFilter;
    if [[ $need_pre_release == "true" ]]; then 
        jqFilter="";
    else
        jqFilter='map(select(.prerelease == false))' # array
    fi;
    local jsonFull=$(wget -q -nv --no-check-certificate -O - $query 2>/dev/null || curl -ksSL $query)
    local json=$(echo $jsonFull | jq "$jqFilter")
    # jq ".[] | select(.prerelease == false)"
    echo $json
}

if [[ "$1" == "" ]]; then
    echo "Usage: Get-GitHub-Releases PowerShell PowerShell [--pre-release]"
    exit 0; 
fi

owner="$1"; owner=${owner:-PowerShell}
repo="$2"; repo=${repo:-PowerShell}
need_pre_release="$3"

get_github_releases "${owner:-}" "${repo:-}" "${need_pre_release:-}"
