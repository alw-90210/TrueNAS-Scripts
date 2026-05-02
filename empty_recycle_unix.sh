#!/bin/sh
set -e  # Exit on any error

cleanup() {
    status=$?
    if [ "${status}" -ne 0 ]; then
        printf "Error occurred with Exit status ${status}"
    fi
}

trap cleanup EXIT

# This script emptys the recycle bin periodically.
# The deletion code in the script is:
# find ${pool_path}*/.recycle/* -atime +{days} -delete
# and
# find ${pool_path}*/.recycle/ -type d -empty -delete
# Deletion code taken from matejz's comment at:
# https://forums.freenas.org/index.php?threads/empty-recycle-bin.7850/
# 29.04.2017 20:02:58

### Parameters ###
helpFunction()
{
    printf "Usage: -d Days -p Pool -l Logfile location\n"
    printf "\t-d Integer specifying days last accessed for files to delete\n"
    printf "\t-p String containing path to pool\n"
    printf "\t-l String containing location of logfile\n"
    exit 1 # Exit script after printing help
}

while getopts "d:p:l:" opt; do
    case ${opt} in
        d ) days_input=${OPTARG} ;;
        p ) pool_input=${OPTARG} ;;
        l ) location_input=${OPTARG} ;;
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
days=${days_input}
dir_count=0
report_temp="/tmp/recycle_temp.tmp"
recycle_report=${location_input}

### Make CSV for logging deleted files and directories ###
if [ ! -e "$recycle_report" ]; then
    (
        printf "Date,Time,Zone,Files,Directories,"
    ) > ${recycle_report}
fi

### Date ###
(
    printf "\n$(date +%Y-%m-%d)","$(date +%T)","$(date +%Z)",
) > ${report_temp}

### Deleting Files and Folders ###
(
    file_count="$(find ${pool_path}/.recycle/* -atime +${days} | wc -l)"
    printf "${file_count},"
) >> ${report_temp}

# Delete files
find ${pool_path}/.recycle/* -atime +${days} -delete;

(
    dir_count="$(find ${pool_path}/.recycle/* -type d -empty | wc -l)"
    printf "${dir_count},"
) >> ${report_temp}

# Delete folders
find ${pool_path}/.recycle/ -depth -type d -empty -delete;

### Write files ###
cat ${report_temp} >> ${recycle_report}

### Clean Up ###
rm ${report_temp}
