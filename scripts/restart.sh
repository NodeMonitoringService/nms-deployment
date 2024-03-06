#!/bin/bash

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
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
clear=$(tput setaf 7)

## Variables
readonly script_name="$(basename "$0")"
readonly script_path=$(dirname "$(realpath "$0")")
readonly compose_path="$script_path"/../docker-compose

# Display usage information
usage() {
    echo -e "Usage: $script_name [options]\n"
    sed -n '/^# USAGE:/,/^$/s/^# //p' "$0"
    exit 2
}

# Function to handle single service selection
single_service_selection() {
    if [ -z "${service+x}" ]; then
        services=($(ls "${compose_path}"/ | sed 's/.yml//g' | sort))
        echo "Available services:"
        for i in "${!services[@]}"; do
            echo "[$i] ${services[$i]}"
        done
        read -p "Select service by number: " sel
        service=${services[$sel]}
    fi
}

# Function to restart a service
single_service_restart() {
    echo "${green}Restarting ${service}...${reset}"
    container_name=$(grep '^name:' "${compose_path}/${service}.yml" | sed 's/name: //g')
    docker kill "${container_name}" && docker rm "${container_name}"

    if [ "${stop}" != "true" ]; then
        (cd "${compose_path}" && docker-compose -f "${service}.yml" up -d)
    else
        echo "${yellow}Service stopped. Skipping restart.${reset}"
    fi
}

# Function to restart all services
all_service_restart() {
    services=($(ls "${compose_path}"/ | sed 's/.yml//g' | sort))
    for service in ${services[@]}; do
        single_service_restart
        echo ""
    done
    echo "${green}All services have been restarted!${reset}"
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
if [ "${restart_all}" = true ]; then
    all_service_restart
else
    single_service_selection
    single_service_restart
fi
