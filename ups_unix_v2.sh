#!/bin/sh

# Modified Bidule0hm's UPS report email script from:
# https://forums.freenas.org/index.php?threads/scripts-to-report-smart-zpool-and-ups-status-hdd-cpu-t%C2%B0-hdd-identification-and-backup-the-config.27365/
# 29.04.2017 17:15:37

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
    printf "Usage: -n UPS Name -l Logfile\n"
    printf "\t-n String containing UPS Name\n"
    printf "\t-l String specifying logfile and path to logfile\n"
    exit 1 # Exit script after printing help
}

while getopts "n:l:" opt; do
    case ${opt} in
        n ) name_input=${OPTARG} ;;
        l ) logfile_input=${OPTARG} ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameter is empty
if [ -z "${logfile_input}" ]; then
    (
        printf "The parameter is empty\n";
        helpFunction
    )
fi

### Parameters ###
logfile="/tmp/ups_report.tmp"
ups="${name_input}@localhost"
ups_temp="/tmp/ups_csv.tmp"
ups_log=${logfile_input}

### UPS Parameters ###
# You can heavily personalize the attributes depending on your particular UPS, use upsc your_ups_name@localhost
# to see all the attributes and pick the ones you want

# UPS settings can be changed by adding a user. See instructions here: 
# https://www.truenas.com/community/threads/how-to-disable-ups-battery-power-beep.87551/

# battery.charge 
# battery.charge.low 
# battery.charge.warning 
# battery.date 
# battery.mfr.date 
# battery.runtime 
# battery.runtime.low
# battery.type 
# battery.voltage 
# battery.voltage.nominal 
# device.mfr 
# device.model 
# device.serial 
# device.type 
# driver.name 
# driver.parameter.pollfreq
# driver.parameter.pollinterval 
# driver.parameter.port 
# driver.parameter.synchronous 
# driver.version 
# driver.version.data 
# driver.version.internal
# input.sensitivity 
# input.transfer.high 
# input.transfer.low 
# input.voltage 
# input.voltage.nominal 
# ups.beeper.status 
# ups.delay.shutdown 
# ups.firmware
# ups.firmware.aux 
# ups.load 
# ups.mfr 
# ups.mfr.date 
# ups.model 
# ups.productid 
# ups.serial 
# ups.status 
# ups.timer.reboot 
# ups.timer.shutdown 
# ups.vendorid

### Create .csv file ### 
if [ ! -e "${ups_log}" ]
    then
        (
            printf "Date","Time","Zone",
            printf "Status",
            printf "UPS Load (%%)",
            printf "Battery Voltage (V)",
            printf "Battery Runtime (s)",
            printf "Battery Charge (%%)",
            printf "Input Voltage (V)",
            printf "Beeper Status",
            printf "Battery Mfr Date",
            printf "UPS Delay Shutdown (s)",
        ) > ${ups_log}
fi

(
    printf "\n$(date +%Y-%m-%d)","$(date +%T)","$(date +%Z)",
    printf "`upsc ${ups} ups.status`",
    printf "`upsc ${ups} ups.load`",
    printf "`upsc ${ups} battery.voltage`",
    printf "`upsc ${ups} battery.runtime`",
    printf "`upsc ${ups} battery.charge`",
    printf "`upsc ${ups} input.voltage`",
    printf "`upsc ${ups} ups.beeper.status`",
    printf "`upsc ${ups} ups.mfr.date`",
    printf "`upsc ${ups} ups.delay.shutdown`",
) > ${ups_temp}

### Write .csv file ###
cat ${ups_temp} >> ${ups_log}

### Clean Up ###
rm ${ups_temp}
