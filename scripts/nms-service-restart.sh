#!/usr/bin/env bash

### DESCRIPTION: This script stops/restarts NMS docker containers.
###
### AUTHOR: NMS
###
### OPTIONS: -h  Display information header.
###          -a  Restart all services.
###          -n  Bypass service selection to restart the given service with name.
###          -s  Stop the container/s
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
readonly compose_path="$script_path"/../docker-compose

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

# Function to handle single service selection
single_service_selection() {
    if [ -z "${service+x}" ]; then
        services=($(ls "${compose_path}"/ | sed 's/.yml//g' | sort))
        echo "Available services:"
        for i in "${!services[@]}"; do
            echo "[$i] ${services[$i]}"
        done
        read -p "Select service to restart by number: " sel
        service=${services[$sel]}
    fi
}

# Function to restart a service
single_service_restart() {
    log "info" "Restarting ${service}..." false
    container_name=$(grep '^name:' "${compose_path}/${service}.yml" | sed 's/name: //g')
    docker kill "${container_name}" && docker rm "${container_name}"

    if [ "${stop}" != "true" ]; then
        (cd "${compose_path}" && docker compose -f "${service}.yml" up -d)
    else
        log "info" "Service stopped. Skipping restart." false
    fi
}

# Function to restart all services
all_service_restart() {
    services=($(ls "${compose_path}"/ | sed 's/.yml//g' | sort))
    for service in ${services[@]}; do
        single_service_restart
        echo ""
    done
    die "info" "All services have been restarted." false
}

# Parse command-line options
while getopts ":hasn:" option; do
    case "${option}" in
        h) usage;;
        a) restart_all=true;;
        n) service=${OPTARG};;
        s) stop=true;;
        *) usage;;
    esac
done

# Main script execution
echo "${CYAN}NMS Tools Restart${RESET}"
if [ "${restart_all}" = true ]; then
    all_service_restart
else
    single_service_selection
    single_service_restart
fi
