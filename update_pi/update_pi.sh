#!/bin/bash

# set -e  # Expect Exit Code 255 when host reboots

# cleanup() {
#     status=$?
#     if [ "${status}" -ne 0 ] || [ "${status}" -ne 255 ]; then
#         printf "Error occurred with Exit status ${status}"
#     fi
# }

# trap cleanup EXIT

### Parameters ###
helpFunction()
{
    printf "Usage: -h Hosts -l Logfile Directory\n"
    printf "\t-h String with host(s)\n"
    printf "\t-l String specifying directory to place logfile\n"
    exit 1 # Exit script after printing help
}

# Example: -h pi@127.0.0.1
while getopts "h:l:" opt; do
    case ${opt} in
        h) HOSTS=${OPTARG} ;;
        l) LOGFILE_PATH=${OPTARG} ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "${HOSTS}" ] || [ -z "${LOGFILE_PATH}" ]; then
    (
        printf "Some or all of the parameters are empty.\n";
        helpFunction
    )
fi

OUTPUT_LOG=${LOGFILE_PATH}
UPDATE_SCRIPT='DEBIAN_FRONTEND=noninteractive sudo apt-get update -y && DEBIAN_FRONTEND=noninteractive sudo apt-get dist-upgrade -y && DEBIAN_FRONTEND=noninteractive sudo apt-get autoremove -y && DEBIAN_FRONTEND=noninteractive sudo apt-get clean -y && DEBIAN_FRONTEND=noninteractive sudo reboot'

date=`date '+%Y-%m-%d'`
time=`date '+%H-%M-%S'`

for host in ${HOSTS}; do
    (
        ssh ${host} ${UPDATE_SCRIPT} > ${OUTPUT_LOG}/${host}_Update_${date}_${time}.log
    )
done
