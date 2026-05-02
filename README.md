# TrueNAS-Scripts
Scripts that I use for cron jobs on TrueNAS. I started using some of these scripts in 2016 and have been adding to the scripts over the years. Most of them are from the Freenas Forums thread by Bidule0hm: [Scripts to report SMART, ZPool and UPS status, HDD/CPU T°, HDD identification and backup the config](https://www.truenas.com/community/threads/scripts-to-report-smart-zpool-and-ups-status-hdd-cpu-t%C2%B0-hdd-identification-and-backup-the-config.27365/). Please take and modify/use as needed. 

### Compatibility
I am currently using these under:
* TrueNAS 25.10.3

## config_backup_unix_v2.sh
Saves a copy of the TrueNAS config file at a specified location.

Usage Example: `sh /.../config_backup_unix_v2.sh -b /.../backup_directory -l /.../logfile.log`
```
    -b Path to directory where config backup file is placed (String)
    -l Logfile (String)
```

If logfile does not exist a new logfile will be created.

## cpu_hdd_temp_unix_v2.sh
Saves the CPU temperatures and SATA drive serial numbers, temperatures, and rotation rate. Setup for saving into .csv files for easier viewing.

Usage Example: `sh /.../cpu_hdd_temp_unix_v2.sh -c /.../cpu_temperatures.csv -h /.../hdd_temperatures.csv`
```
    -c Path to file to write CPU temperatures (String)
    -h Path to file to write HDD temperatures (String)
```  

If files do not exist new files will be created.

## delete_ha_backups.sh
Deletes files older than a specified number of days in a directory and subdirectories.

Usage Example: `sh /.../delete_ha_backups.sh -d N_DAYS -p /.../directory/ -l /.../logfile.log`
```
    -d Delete files older than this many days (Integer)
    -p Path to directory where files are located (String)
    -l Logfile (String)
```

If logfile does not exist a new logfile will be created.

This is the code that deletes the files: `find ${backups_path} -mtime +${days} -type f ! -wholename ${logfile} -delete`

If the logfile is in the directory it will not be deleted.

## empty_recycle_unix.sh
Deletes files in the `.recycle` directory that have not been accessed for a specified number of days along with empty directories. The `.recycle` directory is created if the `Export Recycle Bin` setting is selected when a SMB share is created and is located at:
> Either the root of the SMB share if the path is the same dataset as the SMB share (default is share and dataset have the same name), or at the root of the current dataset if datasets are nested. 

Usage Example: `sh /.../empty_recycle_unix.sh -d N_DAYS -p /.../share -l /.../recycle_log.csv`
```
    -d Delete files that have not been accessed in this many days (Integer)
    -p Path to directory where .recycle directory is located (String)
    -l Logfile (String)
```

If logfile does not exist a new logfile will be created. Logfile is setup for saving as a .csv file for easier viewing.

This is the code that deletes the files: `find ${pool_path}/.recycle/* -atime +${days} -delete`
This is the code that deletes empty directories: `find ${pool_path}/.recycle/ -depth -type d -empty -delete`

## empty_recycle_warn.sh
Provides a file containing a report of the files in the `.recycle` directory that have not been accessed for a specified number of days. Can be used to warn of files that will be deleted by `empty_recycle_unix.sh`.

Usage Example: `sh /.../empty_recycle_warn.sh -d N_DAYS -p /.../share -r /.../report_directory`
```
    -d Number of days files have not been accessed (Integer)
    -p Path to directory where .recycle directory is located (String)
    -r Path to directory to place the report file (String)
```

Report will be named: `recycle_warning_YYYY-MM-DD_HHMMSS_TMZ.txt`

## smart_report_unix.sh
Provides a file containing a report of the SMART status of installed SATA drives. A warning condition is represented as `?` and a critical condition is represented as `!`.

Usage Example: `sh /.../smart_report_unix.sh -r /.../report_directory -w WARN_TEMP -c CRIT_TEMP -s N_CRIT_SECTORS -t TEST_AGE_WARN`
```
    -r Path to directory to place the report file (String)
    -w Drive warning temperature (Integer)
    -c Drive critical temperature (Integer)
    -s Number of sectors for critical condition (Integer)
    -t Number of days since last SMART test for warning condition (Integer)
```

I use the following parameters: `-w 40` `-c 45` `-s 10` `-t 1`

Report will be named: `SMART_status_report_YYYY-MM-DD_HHMMSS_TMZ.txt`

## update_pi.sh
Establishes ssh connection using default port 22 with Raspberry Pi(s), updates installed software, and reboots. Requires ssh keys to be setup between TrueNAS and Raspberry Pi(s). Saves terminal output to file.

Usage Example: `sh /.../update_pi.sh -h "pi@127.0.0.1 pi@127.0.0.2" -l /.../output_directory`
```
    -h username@ip (String)
    -l Path to directory to save terminal output (String)
```

Output will be saved as: `username@ip_Update_YYYY-MM-DD_HH-MM-SS.log`

## update_pihole.sh
Establishes ssh connection to Raspberry Pi(s) running Pi-hole and runs Pi-hole update command `sudo pihold-up`. Requires ssh keys to be setup between TrueNAS and Raspberry Pi(s). Saves terminal output to file.

Usage Example: `sh /.../update_pihole.sh -h "pi@127.0.0.1 pi@127.0.0.2" -l /.../output_directory`
```
    -h username@ip (String)
    -l Path to directory to save terminal output (String)
```

Output will be saved as: `username@ip_Update_Pihole_YYYY-MM-DD_HH-MM-SS.log`    

## ups_unix_v2.sh
Saves selected UPS status parameters to a file. Setup for saving into a .csv file for easier viewing. UPS name can be found in: `System -> Services -> UPS`.

The following status parameters are saved:
|Parameter               |
|:----------------------:|
|UPS Status              |
|UPS Load (%)            |
|Battery Voltage (V)     |
|Battery Runtime (s)     |
|Battery Charge (%)      |
|Input Voltage (V)       |
|Beeper Status           |
|Battery Mfr Date        |
|UPS Delay Shutdown (s)  |

Usage Example: `sh /.../ups_unix_v2.sh -n UPS_NAME -l /.../ups.csv`
```
    -n Name of UPS (String)
    -l Path to file to write UPS status parameters (String)
```

If file does not exist a new file will be created.

## zpool_report_unix.sh
Provides a file containing a report of the status of ZPools. A warning condition is represented as `?` and a critical condition is represented as `!`.

Usage Example: `sh /.../zpool_report_unix.sh -r /.../report_directory -u USED_SPACE_WARN -c USED_SPACE_CRIT -s SCRUB_AGE_WARN`
```
    -r Path to directory to place the report file (String)
    -u Percentage of used space warning condition (Integer)
    -c Percentage of used space critical condition (Integer)
    -s Days since last scrub warning condition (Integer)
```

I use the following parameters: `-u 75` `-c 90` `-s 30`

Report will be named: `zpool_report_YYYY-MM-DD_HHMMSS_TMZ.txt`