#!/bin/sh

set -e

ACTION=$1

# Options
# Name
NAME=lftp_synchronisation
# Binary: full path only
DAEMON=$PREFIX/bin/lftp
# Current directory
DIRECTORY="`pwd`"

# Check ini file is there
FTPINI=./ftp.ini
if [ ! -f $FTPINI ]; then
    echo "No FTP ini file found. Cancel."
    exit 1
fi

# Check internet connection OK
wget -q --spider https://google.com
if [ ! $? -eq 0 ]; then
    echo "No internet connection !"
    exit 1
fi

# Get FTP options from the ini file
FTPPROT=$(sed -nr "/^\[FTP\]/ { :l /^protocol[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $FTPINI)
FTPHOST=$(sed -nr "/^\[FTP\]/ { :l /^host[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $FTPINI)
FTPPORT=$(sed -nr "/^\[FTP\]/ { :l /^port[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $FTPINI)
FTPUSER=$(sed -nr "/^\[FTP\]/ { :l /^user[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $FTPINI)
FTPLOCA=$(sed -nr "/^\[FTP\]/ { :l /^local_dir[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $FTPINI)
FTPREMO=$(sed -nr "/^\[FTP\]/ { :l /^remote_dir[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $FTPINI)

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
CONFIGFTP=./.config-lftp
echo "set ssl:verify-certificate no" > $CONFIGFTP
echo "set sftp:auto-confirm yes" >> $CONFIGFTP
echo "set ftp:ssl-allow false" >> $CONFIGFTP
echo "open $FTPPROT://$FTPUSER@$FTPHOST" >> $CONFIGFTP
echo "mirror -R --verbose --use-cache -x data/ --ignore-time --delete-first $FTPLOCA $FTPREMO" >> $CONFIGFTP
echo "quit" >> $CONFIGFTP
echo "bye" >> $CONFIGFTP

DAEMON_OPTS="-f $DIRECTORY/$CONFIGFTP"

# Run daemon
echo "$NAME: $ACTION"
./run_daemon.sh $ACTION $NAME $DAEMON "$DAEMON_OPTS"

exit 0
