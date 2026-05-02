#!/bin/sh
set -e  # Exit on any error

cleanup() {
    status=$?
    if [ "${status}" -ne 0 ]; then
        printf "Error occurred with Exit status ${status}"
    fi
}

trap cleanup EXIT

### Parameters ###
helpFunction()
{
    printf "Usage: -b Backup Path -l Logfile Path\n"
    printf "\t-b String containing path to backup directory\n"
    printf "\t-l String containing location of logfile\n"
    exit 1 # Exit script after printing help
}

while getopts "b:l:" opt; do
    case ${opt} in
        b ) backup_path_input=${OPTARG} ;;
        l ) logfile_path_input=${OPTARG} ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "${backup_path_input}" ] || [ -z "${logfile_path_input}" ]; then
    (
        printf "Some or all of the parameters are empty\n";
        helpFunction
    )
fi

temp_logfile="/tmp/config_backup.tmp"
logfile=${logfile_path_input}
tarfile="/tmp/config_backup_$(date +%Y-%m-%d_%H%M%S_%Z).tar.gz"
filename="$(date "+TrueNAS_Config_%Y-%m-%d_%H%M%S_%Z")"
backup_path=${backup_path_input}

### Create logfile ###
if [ ! -e "${logfile}" ]; then
    (
        printf "Logfile for TrueNAS config backups\n"
    ) > ${logfile}
fi

### Date ###
(
    printf "Date: $(date +%Y-%m-%d) $(date +%T) $(date +%Z)\n"
) > ${temp_logfile}

if [ -f /data/freenas-v1.db ] && [ "$( sqlite3 /data/freenas-v1.db "pragma integrity_check;" )" = "ok" ]; then
### Save config backup ###
    cp /data/freenas-v1.db "/tmp/${filename}.db"
    ### cd to /tmp to make .md5 and .sha256 files look good.
    cd /tmp/
    md5sum ${filename}.db > config_backup.md5
    sha256sum ${filename}.db > config_backup.sha256
    tar -czf "${tarfile}" ./${filename}.db ./config_backup.md5 ./config_backup.sha256
    cp ${tarfile} ${backup_path}
    (
        printf "Config backup of TrueNAS successful.\n"
        printf "Config backup saved to ${backup_path}\n" 
    ) >> ${temp_logfile}
    rm "/tmp/${filename}.db"
    rm /tmp/config_backup.md5
    rm /tmp/config_backup.sha256
    rm "${tarfile}"
else

### Error message ###
    (
        printf "\-\-\-\-\-\-\- ALERT \-\-\-\-\-\-\-\n"
        printf "Automatic backup of TrueNAS config failed!\n"
        printf "The config file is corrupted!\n"
    ) >> ${temp_logfile}
fi

### Write logfile ###
cat ${temp_logfile} >> ${logfile}
rm ${temp_logfile}