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
    printf "Usage: -r Report Directory -w Warning Temperature\n"
    printf " -c Critical Temperature -s Critical Sectors -t Test Age Warning\n"
    printf "\t-r String specifying directory to place report\n"
    printf "\t-w Integer specifying warning tempearture\n"
    printf "\t-c Integer specifying critical tempearture\n"
    printf "\t-s Integer specifying critical sectors\n"
    printf "\t-t Integer specifying test age warning\n"
    exit 1 # Exit script after printing help
}

while getopts "r:w:c:s:t:" opt; do
    case ${opt} in
        r ) report_input=${OPTARG} ;;
        w ) tempWarn_input=${OPTARG} ;;
        c ) tempCrit_input=${OPTARG} ;;
        s ) sectorsCrit_input=${OPTARG} ;;
        t ) testAgeWarn_input=${OPTARG} ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "${report_input}" ] || [ -z "${tempWarn_input}" ] || [ -z "${tempCrit_input}" ] || [ -z "${sectorsCrit_input}" ] || [ -z "${testAgeWarn_input}" ]; then
    (
        printf "Some or all of the parameters are empty\n";
        helpFunction
    )
fi

logfile="/tmp/smart_report.tmp"
drives=$(lsblk -nldo NAME | grep "sd")
tempWarn=${tempWarn_input}
tempCrit=${tempCrit_input}
sectorsCrit=${sectorsCrit_input}
testAgeWarn=${testAgeWarn_input}
warnSymbol="?"
critSymbol="!"
local_logfile="${report_input}/SMART_status_report_$(date +%Y-%m-%d_%H%M%S_%Z).txt"

###### summary ######
(
    printf "Date: $(date +%Y-%m-%d) $(date +%T) $(date +%Z)\n"
) > ${logfile}
(
    printf "\n"
    printf "########## SMART status report summary for all drives ##########\n"
    printf "\n"
    printf "+------+---------------+----+-----+-----+-----+-------+-------+--------+------+------+------+-------+----+\n"
    printf "|Device|Serial         |Temp|Power|Start|Spin |ReAlloc|Current|Offline |UDMA  |Seek  |High  |Command|Last|\n"
    printf "|      |               |    |On   |Stop |Retry|Sectors|Pending|Uncorrec|CRC   |Errors|Fly   |Timeout|Test|\n"
    printf "|      |               |    |Hours|Count|Count|       |Sectors|Sectors |Errors|      |Writes|Count  |Age |\n"
    printf "+------+---------------+----+-----+-----+-----+-------+-------+--------+------+------+------+-------+----+\n"
) >> ${logfile}
for drive in ${drives}
do
    (
        smartctl -A -i -v 7,hex48 /dev/"$drive" | \
        awk -v device="$drive" -v tempWarn="$tempWarn" -v tempCrit="$tempCrit" -v sectorsCrit="$sectorsCrit" \
        -v testAgeWarn="$testAgeWarn" -v warnSymbol="$warnSymbol" -v critSymbol="$critSymbol" \
        -v lastTestHours="$(smartctl -l selftest /dev/"$drive" | grep "# 1 " | awk '{print $9}')" '\
        /Serial Number:/{serial=$3} \
        /Temperature_Celsius/{temp=$10} \
        /Power_On_Hours/{onHours=$10} \
        /Start_Stop_Count/{startStop=$10} \
        /Spin_Retry_Count/{spinRetry=$10} \
        /Reallocated_Sector/{reAlloc=$10} \
        /Current_Pending_Sector/{pending=$10} \
        /Offline_Uncorrectable/{offlineUnc=$10} \
        /UDMA_CRC_Error_Count/{crcErrors=$10} \
        /Seek_Error_Rate/{seekErrors=("0x" substr($10,3,4));totalSeeks=("0x" substr($10,7))} \
        /High_Fly_Writes/{hiFlyWr=$10} \
        /Command_Timeout/{cmdTimeout=$10} \
        END {
            testAge=sprintf("%.0f", ((onHours % 65535) - lastTestHours) / 24);
            if (temp > tempCrit || reAlloc > sectorsCrit || pending > sectorsCrit || offlineUnc > sectorsCrit)
                device=device " " critSymbol;
            else if (temp > tempWarn || reAlloc > 0 || pending > 0 || offlineUnc > 0 || testAge > testAgeWarn)
                device=device " " warnSymbol;
            seekErrors=sprintf("%d", seekErrors);
            totalSeeks=sprintf("%d", totalSeeks);
            if (totalSeeks == "0") {
                seekErrors="N/A";
                totalSeeks="N/A";
            }
            if (hiFlyWr == "") hiFlyWr="N/A";
            if (cmdTimeout == "") cmdTimeout="N/A";
            printf "|%-6s|%-15s| %s |%5s|%5s|%5s|%7s|%7s|%8s|%6s|%6s|%6s|%7s|%4s|\n",
            device, serial, temp, onHours, startStop, spinRetry, reAlloc, pending, offlineUnc, \
            crcErrors, seekErrors, hiFlyWr, cmdTimeout, testAge;
        }'
    ) >> ${logfile}
done
(
    printf "+------+---------------+----+-----+-----+-----+-------+-------+--------+------+------+------+-------+----+\n"
    printf "\n"
    printf "\n"
) >> ${logfile}

###### for each drive ######
for drive in ${drives}
do
    brand="$(smartctl -i /dev/"$drive" | grep "Model Family" | awk '{print $3, $4, $5}')"
    serial="$(smartctl -i /dev/"$drive" | grep "Serial Number" | awk '{print $3}')"
    (
        printf "\n"
        printf "########## SMART status report for ${drive} drive (${brand}: ${serial}) ##########\n"
        printf "$(smartctl -H -A -l error /dev/"${drive}")"
        printf "\n"
        printf "\n"
        smartctl -l selftest /dev/"$drive" | grep "# 1 \|Num" | cut -c6-
        printf "\n"
        printf "\n"
    ) >> ${logfile}
done

sed -i -e '/Copyright/d' ${logfile}
sed -i -e '/=== START OF READ/d' ${logfile}
sed -i -e '/SMART Attributes Data/d' ${logfile}
sed -i -e '/Vendor Specific SMART/d' ${logfile}
sed -i -e '/SMART Error Log Version/d' ${logfile}

cat ${logfile} >> ${local_logfile}

### Clean Up ###
rm ${logfile}
