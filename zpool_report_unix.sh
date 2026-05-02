#!/bin/sh

# Updated to support Freenas 11.1 dates. See: 
#    https://forums.freenas.org/index.php?threads/scripts-to-report-smart-zpool-and-ups-status-hdd-cpu-t%C2%B0-hdd-identification-and-backup-the-config.27365/page-33
#    for more details.

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
    printf "Usage: -r Report Directory -u Used Space Warning\n"
    printf " -c Used Space Critical -s Scrub Age Warning\n"
    printf "\t-r String specifying directory to place report\n"
    printf "\t-u Integer specifying used space warning value\n"
    printf "\t-c Integer specifying used space critical value\n"
    printf "\t-s Integer specifying scrub age warning value\n"
    exit 1 # Exit script after printing help
}

while getopts "r:u:c:s:" opt; do
    case ${opt} in
        r ) report_input=${OPTARG} ;;
        u ) usedWarn_input=${OPTARG} ;;
        c ) usedCrit_input=${OPTARG} ;;
        s ) scrubAgeWarn_input=${OPTARG} ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "${report_input}" ] || [ -z "${usedWarn_input}" ] || [ -z "${usedCrit_input}" ] || [ -z "${scrubAgeWarn_input}" ]; then
    (
        printf "Some or all of the parameters are empty.\n";
        helpFunction
    )
fi

### Parameters ###
logfile="${report_input}/zpool_report_$(date +%Y-%m-%d_%H%M%S_%Z).txt"
pools=$(zpool list -Ho name)
usedWarn=${usedWarn_input}
usedCrit=${usedCrit_input}
scrubAgeWarn=${scrubAgeWarn_input}
warnSymbol="?"
critSymbol="!"

###### summary ######
(
    printf "Date: $(date +%Y-%m-%d) $(date +%T) $(date +%Z)\n"
) > ${logfile}
(
    printf "\n"
    printf "########## ZPool status report summary for all pools ##########\n"
    printf "\n"
    printf "+--------------+--------+------+------+------+----+--------+------+-----+\n"
    printf "|Pool Name     |Status  |Read  |Write |Cksum |Used|Scrub   |Scrub |Last |\n"
    printf "|              |        |Errors|Errors|Errors|    |Repaired|Errors|Scrub|\n"
    printf "|              |        |      |      |      |    |Bytes   |      |Age  |\n"
    printf "+--------------+--------+------+------+------+----+--------+------+-----+\n"
) >> ${logfile}
for pool in ${pools}; do
    status="$(zpool list -H -o health "${pool}")"
    errors="$(zpool status "${pool}" | egrep "(ONLINE|DEGRADED|FAULTED|UNAVAIL|REMOVED)[ \t]+[0-9]+")"
    readErrors=0
    for err in $(echo "${errors}" | awk '{print $3}'); do
        if echo "$err" | egrep -q "[^0-9]+"; then
            readErrors=1000
            break
        fi
        readErrors=$((readErrors + err))
    done
    writeErrors=0
    for err in $(echo "${errors}" | awk '{print $4}'); do
        if echo "$err" | egrep -q "[^0-9]+"; then
            writeErrors=1000
            break
        fi
        writeErrors=$((writeErrors + err))
    done
    cksumErrors=0
    for err in $(echo "${errors}" | awk '{print $5}'); do
        if echo "$err" | egrep -q "[^0-9]+"; then
            cksumErrors=1000
            break
        fi
        cksumErrors=$((cksumErrors + err))
    done
    if [ "$readErrors" -gt 999 ]; then readErrors=">1K"; fi
    if [ "$writeErrors" -gt 999 ]; then writeErrors=">1K"; fi
    if [ "$cksumErrors" -gt 999 ]; then cksumErrors=">1K"; fi
    used="$(zpool list -H -p -o capacity "${pool}")"
    scrubRepBytes="N/A"
    scrubErrors="N/A"
    scrubAge="N/A"
    if [ "$(zpool status "${pool}" | grep "scan" | awk '{print $2}')" = "scrub" ]; then
        scrubRepBytes="$(zpool status "${pool}" | grep "scan" | awk '{print $4}')"
        scrubErrors="$(zpool status "${pool}" | grep "scan" | awk '{print $8}')"
        #scrubErrors="$(zpool status "$pool" | grep "scan" | awk '{print $10}')" # Updated for Freenas 11.1 not compatible with Trunas 12.2
        scrubDate="$(zpool status "${pool}" | grep "scan" | awk '{print $13" "$12" "$15" "$14}')"
        #scrubDate="$(zpool status "$pool" | grep "scan" | awk '{print $17"-"$14"-"$15"_"$16}')" # Updated for Freenas 11.1 not compatible with Trunas 12.2
        scrubTS="$(date -d "${scrubDate}" "+%s")"
        currentTS="$(date "+%s")"
        scrubAge=$((((currentTS - scrubTS) + 43200) / 86400))
    fi
    if [ "${status}" = "FAULTED" ] \
    || [ "${used}" -gt "${usedCrit}" ] \
    || ( [ "${scrubErrors}" != "N/A" ] && [ "${scrubErrors}" != "0" ] )
    then
        symbol="${critSymbol}"
    elif [ "${status}" != "ONLINE" ] \
    || [ "${readErrors}" != "0" ] \
    || [ "${writeErrors}" != "0" ] \
    || [ "${cksumErrors}" != "0" ] \
    || [ "${used}" -gt "${usedWarn}" ] \
    || [ "${scrubRepBytes}" != "0B" ] \
    || [ "$(echo "${scrubAge}" | awk '{print int($1)}')" -gt "${scrubAgeWarn}" ]
    then
        symbol="${warnSymbol}"
    else
        symbol=" "
    fi
    (
        printf "|%-12s %1s|%-8s|%6s|%6s|%6s|%3s%%|%8s|%6s|%5s|\n" \
        "${pool}" "${symbol}" "${status}" "${readErrors}" "${writeErrors}" "${cksumErrors}" \
        "${used}" "${scrubRepBytes}" "${scrubErrors}" "${scrubAge}"
    ) >> ${logfile}
done
(
    printf "+--------------+--------+------+------+------+----+--------+------+-----+\n"
    printf "\n"
    printf "\n"
) >> ${logfile}

###### for each pool ######
for pool in $pools; do
    (
        printf "\n"
        printf "########## ZPool status report for ${pool} ##########\n"
        printf "\n"
        zpool status -v "$pool"
        printf "\n"
        printf "\n"
    ) >> ${logfile}
done
