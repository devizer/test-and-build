#!/usr/bin/env bash
# https://developer.github.com/v3/repos/releases/

# output the TAG of the latest release of null 
function get_github_latest_release() {
    local owner="$1";
    local repo="$2";
    local query="https://api.github.com/repos/$owner/$repo/releases/latest"
    local json=$(wget -q -nv --no-check-certificate -O - $query 2>/dev/null || curl -ksSL $query)
    local tag=$(echo "$json" | jq -r ".tag_name" )
    if [[ -n "${tag:-}" && "$tag" != "null" ]]; then 
        echo "${tag:-}" 
    fi;
}

if [[ "$1" == "" ]]; then
    echo "Usage Get-GitHub-Latest-Release microsoft azure-pipelines-agent"
    exit 0; 
fi

owner="$1"; owner=${owner:-microsoft}
repo="$2"; repo=${repo:-azure-pipelines-agent}

get_github_latest_release "${owner:-}" "${repo:-}"
