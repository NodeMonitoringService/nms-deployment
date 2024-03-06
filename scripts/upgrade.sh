#!/bin/bash
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
 red=`tput setaf 1`
 green=`tput setaf 2`
 yellow=`tput setaf 3`
 blue=`tput setaf 4`
 magenta=`tput setaf 5`
 cyan=`tput setaf 6`
 clear=`tput setaf 7`

## Variables
 github_url="https://github.com/NodeMonitoringService/NMS-Deployment"

## Functions
