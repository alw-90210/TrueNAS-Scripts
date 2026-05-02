#!/bin/sh
set -e
# This script deletes files from a directory and subdirectory older than a specified number of days.
# The deletion code in the script is:
# find ${backups_path} -mtime +$days -type f ! -wholename ${logfile} -delete ;

### Parameters ###
helpFunction()
{
    printf "Usage: -d Days -p Path -l Logfile location\n"
    printf "\t-d Integer specifying number of days to keep\n"
    printf "\t-p String containing path to backups directory \n"
    printf "\t-l String containing location of logfile\n"
    exit 1 # Exit script after printing help
}

while getopts "d:p:l:" opt; do
    case ${opt} in
        d ) keep=${OPTARG} ;;
        p ) path_input=${OPTARG} ;;
        l ) location_input=${OPTARG} ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "${keep}" ] || [ -z "${path_input}" ] || [ -z "${location_input}" ]; then
    (
        printf "Some or all of the parameters are empty\n";
        helpFunction
    )
fi

backups_path=${path_input}
days=${keep}
report_temp="/tmp/recycle_temp.tmp"
logfile=${location_input}

### Create logfile ###
if [ ! -e "${logfile}" ]; then
    (
        printf "Logfile for deleted files at: ${backups_path}\n"
    ) > ${logfile}
fi

### Date ###
(
    printf "Date: $(date +%Y-%m-%d) $(date +%T) $(date +%Z)\n"
) > ${report_temp}

### Deleting Files and Folders ###
(
    file_count="$(find ${backups_path} -mtime +$days -type f ! -wholename ${logfile} | wc -l)"
    printf "Number of files that were deleted: %s \n" "$file_count"
) >> ${report_temp}

# Delete files
find ${backups_path} -mtime +$days -type f ! -wholename ${logfile} -delete ;

### Write files ###
cat ${report_temp} >> ${logfile}

### Clean Up ###
rm ${report_temp}
