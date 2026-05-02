#!/bin/sh
set -e  # Exit on any error

cleanup() {
    status=$?
    if [ "${status}" -ne 0 ]; then
        printf "Error occurred with Exit status ${status}"
    fi
}

trap cleanup EXIT

# This returns the files that will be deleted from the recycle bin.
# This is meant to work in concert with the empty_recycle_unix.sh script which empties the recycle bin.
# 30.04.2017 09:26:51

### Parameters ###
helpFunction()
{
    printf "Usage: -d Days -p Pool -r Warn Report Path\n"
    printf "\t-d Integer specifying days last accessed for files to delete\n"
    printf "\t-p String containing path to pool\n"
    printf "\t-r String specifying directory to place warning report\n"
    exit 1 # Exit script after printing help
}

while getopts "d:p:r:" opt; do
    case ${opt} in
        d ) days_input=${OPTARG} ;;
        p ) pool_input=${OPTARG} ;;
        r ) location_input=${OPTARG} ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "${days_input}" ] || [ -z "${pool_input}" ] || [ -z "${location_input}" ]; then
    (
        printf "Some or all of the parameters are empty\n";
        helpFunction
    )
fi

pool_path=${pool_input}
warn=${days_input}
recycle_warning="${location_input}/recycle_warning_$(date +%Y-%m-%d_%H%M%S_%Z).txt"

### Date ###
(
    printf "$(date +%Y-%m-%d) $(date +%T) $(date +%Z)\n"
) > ${recycle_warning}

### Early Report ###
(
    file_count="$(find ${pool_path}/.recycle/* -atime +${warn} | wc -l)"
    printf "\nNumber of files that will be deleted in %s days: %s \n" "${warn}" "${file_count}"
    file_name="$(find ${pool_path}/.recycle/* -atime +${warn})"
    printf "\nThese files will be deleted in %s days: \n" "${warn}"
    printf "\n%s \n" "${file_name}"
) >> ${recycle_warning}
