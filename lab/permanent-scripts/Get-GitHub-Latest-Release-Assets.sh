#!/usr/bin/env bash
# https://developer.github.com/v3/repos/releases/
# https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#get-a-release

# output the TAG of the latest release of null 
function get_github_latest_release_assets() {
    local owner="$1";
    local repo="$2";
    local query="https://api.github.com/repos/$owner/$repo/releases/latest"
    local json=$(wget -q -nv --no-check-certificate -O - $query 2>/dev/null || curl -ksSL $query)
    local f='.assets | map({"url":.browser_download_url|tostring}) | map([.url] | join("|")) | join("\n") '
    local urlList=$(echo "$json" | jq -r "$f" )
    if [[ "$urlList" == *"/assets.json" ]]; then
      # example: microsoft/azure-pipelines-agent
      local prevUrlList="$urlList"
      local jsonNext="$(wget -q -nv --no-check-certificate -O - "$prevUrlList" 2>/dev/null || curl -ksSL "$prevUrlList")"
      local fNext='. | map({"url":.downloadUrl|tostring}) | map([.url] | join("|")) | join("\n") '
      local urlListNext="$(echo "$jsonNext" | jq -r "$fNext" )"
      urlList="$(echo $prevUrlList; echo "$urlListNext" | sort)"
    fi
    if [[ -n "${urlList:-}" && "$urlList" != "null" ]]; then
        echo "${urlList:-}" 
    fi;
}

if [[ "$1" == "" ]]; then
    echo "Usage Get-GitHub-Latest-Release-Assets microsoft azure-pipelines-agent"
    exit 0; 
fi

owner="$1"; owner=${owner:-microsoft}
repo="$2"; repo=${repo:-azure-pipelines-agent}

get_github_latest_release_assets "${owner:-}" "${repo:-}"

# bash Get-GitHub-Latest-Release-Assets.sh microsoft azure-pipelines-agent; bash Get-GitHub-Latest-Release-Assets.sh devizer w3top-bin
