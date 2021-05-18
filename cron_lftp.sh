#!/bin/sh

set -e

# Chosen action
ACTION=$1

# Options
# Name
NAME=cron_lftp
# Binary: full path only
DAEMON=$PREFIX/bin/lftp
# Current directory
DIRECTORY="`pwd`"

# Check ini file is there
LFTPINI=./lftp.ini
if [ ! -f $LFTPINI ]; then
    echo "No LFTP ini file found. Cancel."
    exit 1
fi

# Check internet connection OK
wget -q --spider https://google.com
if [ ! $? -eq 0 ]; then
    echo "No internet connection !"
    exit 1
fi

# Get FTP options from the ini file
FTPACTIVE=$(sed -nr "/^\[lftp\]/ { :l /^active[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $LFTPINI)
FTPPROT=$(sed -nr "/^\[lftp\]/ { :l /^protocol[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $LFTPINI)
FTPHOST=$(sed -nr "/^\[lftp\]/ { :l /^host[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $LFTPINI)
FTPPORT=$(sed -nr "/^\[lftp\]/ { :l /^port[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $LFTPINI)
FTPUSER=$(sed -nr "/^\[lftp\]/ { :l /^user[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $LFTPINI)
FTPLOCA=$(sed -nr "/^\[lftp\]/ { :l /^local_dir[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $LFTPINI)
FTPREMO=$(sed -nr "/^\[lftp\]/ { :l /^remote_dir[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $LFTPINI)
REPEAT=$(sed -nr "/^\[lftp\]/ { :l /^repeat_minutes[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $LFTPINI)

# Check if sync is active
if [ "$FTPACTIVE" != "true" ]
then
    echo "Action is not active. Cancel."
    exit 0
fi

# Check if current minute of date corresponds to the repeat_minutes given in configuration
current_minute=$(date '+%M')
re='^[0-9]+$'
if [[ $REPEAT =~ $re ]]
then
    if [ "$(( current_minute % REPEAT ))" -eq 0 ]
    then
        echo "Current minute does not correspond to given repeat minutes"
        exit 0
    fi
fi

# Check media directory has changed
DIRCHANGED=false
DIRSTAT=`du --null -sc $FTPLOCA | sed 's/[^0-9]//g'`
STATFILE="$PREFIX/var/run/$NAME.stat"
if [ ! -f $STATFILE ]
then
    DIRCHANGED=true
else
    OLD_DIRSTAT=`cat $STATFILE`
    if [ "$DIRSTAT" = "$OLD_DIRSTAT" ]
    then
        DIRCHANGED=false
    else
        DIRCHANGED=true
    fi
fi
echo $DIRSTAT > $STATFILE
if [ "$DIRCHANGED" = false ] && [ "$ACTION" = "start" ]
then
    echo "* No change detected in dir $FTPLOCA. Exit"
    exit 0
else
    echo "* Changes has been detected. Proceed"
fi

# LFTP options file
CONFIGFTP=".config-cron-lftp"
echo "set ssl:verify-certificate no" > $DIRECTORY/$CONFIGFTP
echo "set sftp:auto-confirm yes" >> $DIRECTORY/$CONFIGFTP
echo "set ftp:ssl-allow false" >> $DIRECTORY/$CONFIGFTP
echo "open $FTPPROT://$FTPUSER@$FTPHOST" >> $DIRECTORY/$CONFIGFTP
echo "mirror -R --verbose --use-cache --only-missing --ignore-time $FTPLOCA $FTPREMO" >> $DIRECTORY/$CONFIGFTP
echo "quit" >> $DIRECTORY/$CONFIGFTP
echo "bye" >> $DIRECTORY/$CONFIGFTP

DAEMON_OPTS="-f $DIRECTORY/$CONFIGFTP"

# Run daemon
echo "$NAME: $ACTION"
./run_daemon.sh $ACTION $NAME $DAEMON "$DAEMON_OPTS"

exit 0
