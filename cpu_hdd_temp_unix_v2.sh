#!/bin/sh
set -e  # Exit on any error

cleanup() {
    status=$?
    if [ "${status}" -ne 0 ]; then
        printf "Error occurred with Exit status ${status}"
    fi
}

trap cleanup EXIT

# Modified Bidule0hm's Display CPU and HDD temperatures script from:
# https://forums.freenas.org/index.php?threads/scripts-to-report-smart-zpool-and-ups-status-hdd-cpu-t%C2%B0-hdd-identification-and-backup-the-config.27365/

### Parameters ###
helpFunction()
{
    printf "Usage: -c CPU Log -h HDD Log\n"
    printf "\t-l String containing location of CPU logfile\n"
    printf "\t-h String containing location of HDD logfile\n"
    exit 1 # Exit script after printing help
}

while getopts "c:h:" opt; do
    case ${opt} in
        c ) cpu_log_input=${OPTARG} ;;
        h ) hdd_log_input=${OPTARG} ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "${cpu_log_input}" ] || [ -z "${hdd_log_input}" ]; then
    (
        printf "Some or all of the parameters are empty\n";
        helpFunction
    )
fi

cores=$(nproc)
cores=$((cores-1))
drives=$(lsblk -nldo NAME | grep "sd")
cpu_temp="/tmp/cpu_csv.tmp"
cpu_log=${cpu_log_input}
hdd_temp="/tmp/hdd_csv.tmp"
hdd_log=${hdd_log_input}

### CPU Temps to .csv ###
if [ ! -e "${cpu_log}" ]; then
    (
        printf "Date","Time","Zone",
    ) > ${cpu_log}
    for core in $(seq 0 $cores); do
        (
            printf "Core $core",
        ) >> ${cpu_log}
    done
fi

(
    printf "\n$(date +%Y-%m-%d)","$(date +%T)","$(date +%Z)",
) >> ${cpu_temp}

for core in $(seq 0 $cores); do
    (
        cpu_temp="$(sensors | grep "Core ${core}:" | cut -c16-19 | tr -d "\n")"
        printf "$cpu_temp",
    ) >> ${cpu_temp}
done

### Disk Temps to .csv ###
if [ ! -e "$hdd_log" ]; then
    (
        printf "Date","Time","Zone",
    ) > ${hdd_log}
    for drive in $drives; do
        (
            printf "Drive: ${drive}","Temperature (C)","Rotaton Rate", 
        ) >> ${hdd_log}
    done
fi

(
    printf "\n$(date +%Y-%m-%d)","$(date +%T)","$(date +%Z)",
) >> ${hdd_temp}

for drive in $drives; do
    (
        serial="$(smartctl -i /dev/${drive} | grep "Serial Number" | awk '{print $3}')"
        temp="$(smartctl -A /dev/${drive} | grep "Temperature_Celsius" | awk '{print $10}')"
        #Format: Rotation Rate:    NNNN rpm or Rotation Rate:    Solid State Device, need to pull rotation rate and trim spaces
        rotation="$(smartctl -i /dev/${drive} | grep "Rotation Rate" | awk '{$1=$2=""; printf substr($0,3)}')"
        printf "${serial},${temp}","${rotation}",
    ) >>${hdd_temp}
done

### Write .csv files ###
cat ${cpu_temp} >> ${cpu_log}
cat ${hdd_temp} >> ${hdd_log}

### Clean Up ###
rm ${cpu_temp}
rm ${hdd_temp}
