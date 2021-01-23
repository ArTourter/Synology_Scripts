#!/bin/ash

# This script uses rsync to backup a named Raspberry Pi at a given IP address
# Three rotating backups are kept. If rsync fails then the preceding backups are retained.
# from https://www.cososo.co.uk/2015/09/backup-and-restore-raspberry-pi-to-synology-diskstation/

if (( $# != 2 )) ; then
    echo “Usage: 2 arguments required: $0 SERVERNAME IP” >&2
    exit 1
fi

# Set up string variables
SERVER=$1
ADDRESS=$2
NOW=$(date --iso)
RPI_BACKUP=”/volume1/rpi_backup”
LOGFILE=”$RPI_BACKUP/logs/$SERVER-$NOW.log”
SERVERDIR=”$RPI_BACKUP/$SERVER”
BASENAME=”$SERVERDIR/$SERVER”

# Paths to common commands used
MV=/bin/mv;
RM=/bin/rm;
MKDIR=/bin/mkdir;
PING=/bin/ping;
RSYNC=/bin/rsync

#Function to check for command failure and exit if there has been one. This is done
# so that when invoked from cron the error is reported
check_exit_code() {
    exit_code=$?
    if [ “$exit_code” -ne “0” ] ; then
        echo “$1”
        echo “exit with exitcode $exit_code”
        exit 1
    fi
}

#Ping the RPI a few times to ensure the interface is up (I’ve not seen this fail)
$PING $ADDRESS -c 3 >> $LOGFILE

# Ensure we have a top level backup directory for this server
if ! [ -d $SERVERDIR ] ; then
    $MKDIR -p $SERVERDIR
fi

# RSYNC via SSH from the RPI as an incremental against the previous backup.
$RSYNC -av \
    –delete \
    –exclude-from=$RPI_BACKUP/scripts/backup_pi_exclude \
    –link-dest $BASENAME-$NOW \
    -e “ssh -p 22” root@$ADDRESS:/ \
    $BASENAME-$NOW >> $LOGFILE 2>&1

# If RSYNC failed in any way, don’t trust the backup, exit the script
check_exit_code “RSYNC Failed”

# Rotate the existing backups


# vim: ts=4 sw=4 et 
