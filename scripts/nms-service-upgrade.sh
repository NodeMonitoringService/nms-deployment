#!/usr/bin/env bash

### DESCRIPTION: Script for updating the total monitoring stack with new stable versions
###
### AUTHOR: LinkRiver
###
### OPTIONS:    -h  Display information header.
###             -a  Upgrade all services.
###             -n  Bypass service selection to upgrade the given service with name.
###

## Debug
# set -x # Uncomment for debug output

## Color variables
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
RESET=`tput setaf 7`

## Variables
readonly script_name="$(basename "$0")"
readonly script_path=$(dirname "$(realpath "$0")")
readonly current_env="$script_path"/../.env
readonly versions_env_url="https://raw.githubusercontent.com/NodeMonitoringService/nms-deployment-files/main/versions.env"
readonly log_file="/tmp/nms-upgrade.log"

## Functions
usage () {
    [ "\$*" ] && echo "\$0: \$*"
    sed -n '/^###/,/^$/s/^### \{0,1\}//p' "\$0"
    exit 2
} 2>/dev/null

log() {
    local logLevel="${1}"
    local message="${2}"
    local logToFile="${3:-false}"
    
    # Define message prefixes based on logLevel
    local prefix
    case "$logLevel" in
        "info")
            prefix="${GREEN}[INFO]${RESET}"
        ;;
        "warn")
            prefix="${YELLOW}[WARN]${RESET}"
        ;;
        "error")
            prefix="${RED}[ERROR]${RESET}"
        ;;
        *)
            prefix="[UNKNOWN]"
        ;;
    esac
    
    # Print to stderr for errors
    if [ "$logLevel" = "error" ]; then
        echo -e "$prefix $message" >&2
    else
        echo -e "$prefix $message"
    fi
    
    # Optionally log to file
    if [ "$logToFile" = true ]; then
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        echo -e "[$timestamp] $prefix $message" | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' >> "$log_file"
    fi
}

die() {
    local level="${1}"
    local msg="${2}"
    local logToFile="${3:-false}"
    local code

    # Determine exit code based on log level
    if [ "$level" = "error" ]; then
        code=1
    else
        code=0
    fi

    # Use log function to output message
    log "$level" "$msg" "$logToFile"

    # Exit with the determined code
    exit "$code"
}

fetch_and_compare_env() {
    # Fetch latest versions.env into a variable
    new_versions_env=$(curl -s "$versions_env_url")
    if [[ $? -ne 0 ]]; then
        die "error" "Failed to fetch new versions from $versions_env_url" true
    fi

    if [[ "$new_versions_env" != "$current_env" ]]; then
        log "info" "New versions for NMS tools detected." false
        echo "Current versions:"
        echo "$current_env"
        echo "New versions available:"
        echo "$new_versions_env"
        log "info" "If you are not using all the tools, you may not need to upgrade." false
        read -p "Do you want to upgrade and restart the containers? [Y/n]: " answer
        case $answer in
            [Yy]* )
                echo "$new_versions_env" > "$current_env"
                bash ${script_path}/nms-service-restart.sh -a
                die "info" "Successfully upgraded to latest supported versions." false
            ;;
            [Nn]* )
                die "info" "Upgrade aborted." false
            ;;
            * )
                echo "Please answer yes or no."
            ;;
        esac
    else
        die "info" "Your NMS tools are running on the latest supported versions." false
    fi
}

# Main script execution
log "info" "Starting the upgrade process..." false
fetch_and_compare_env
