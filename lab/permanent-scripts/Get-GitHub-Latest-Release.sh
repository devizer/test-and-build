#!/usr/bin/env bash
# https://developer.github.com/v3/repos/releases/

# output the TAG of the latest release of null 
function get_github_latest_release() {
    local owner="$1";
    local repo="$2";
    local query="https://api.github.com/repos/$owner/$repo/releases/latest"
    if [[ "${3:-}" == "--pre"* ]]; then query="https://api.github.com/repos/$owner/$repo/releases"; fi
    local header_Accept="Accept: application/vnd.github+json"
    local header_Version="X-GitHub-Api-Version: 2022-11-28"
    local json=$(wget -q --header="$header_Accept" --header="$header_Version" -nv --no-check-certificate -O - $query 2>/dev/null || curl -ksSL $query -H "$header_Accept" -H "$header_Version")
    local tag
    if [[ -n "$(command -v jq)" ]]; then
      tag=$(echo "$json" | jq -r ".tag_name" 2>/dev/null)
    fi
    if [[ -z "${tag:-}" ]]; then
       # V1: OK
       # tag=$(echo "$json" | grep -E '"tag_name": "[a-zA-Z0-9_.-]+"' | sed 's/.*"tag_name": "\(.*\)".*/\1/')
       # V2
       # json="$(echo $json | tr '\n' ' ' | tr '\r' ' ')"
       # echo -e "$json\n\n" >&2
       tag=$(echo "$json" | grep -oE '"tag_name": *"[a-zA-Z0-9_.-]+"' | sed 's/.*"tag_name": *"//;s/"//' | head -1)
    fi
    if [[ -n "${tag:-}" && "$tag" != "null" ]]; then 
        echo "${tag:-}" 
    fi;
}
# echo "Tag devizer/Universe.SqlInsights: [$(get_github_latest_release devizer Universe.SqlInsights)]"
# echo "Tag devizer/Universe.SqlInsights (beta): [$(get_github_latest_release devizer Universe.SqlInsights --pre)]"
# echo "Tag powershell/powershell: [$(get_github_latest_release powershell powershell)]"
# echo "Tag powershell/powershell (beta): [$(get_github_latest_release powershell powershell --pre)]"

if [[ "$1" == "" ]]; then
    echo "Usage Get-GitHub-Latest-Release microsoft azure-pipelines-agent"
    exit 0; 
fi

owner="$1"; owner=${owner:-microsoft}
repo="$2"; repo=${repo:-azure-pipelines-agent}

get_github_latest_release "${owner:-}" "${repo:-}" "${3:-}"


# codePython="import sys; import json; data = json.load(sys.stdin); print(data.get('tag_name') or '')"
# echo "RESULT: [$(echo '{ "tag_name": 42 }' | python -c "$codePython")]"

