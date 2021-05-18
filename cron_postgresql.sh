#!/bin/sh

set -e

# Chosen action
ACTION=$1

# Options
# Name
NAME=cron_postgresql
# Binary: full path only
DAEMON="$PREFIX/bin/psql"
# Current directory
DIRECTORY="`pwd`"

# Check INI file is there
PGINI=./postgresql.ini
if [ ! -f $PGINI ]; then
    echo "No PostgreSQL INI file found. Cancel."
    exit 1
fi

# Check internet connection OK
wget -q --spider https://google.com
if [ ! $? -eq 0 ]; then
    echo "No internet connection !"
    exit 1
else
    echo "connection ok"
fi

# Get PostgreSQL queries options from the ini file
PGACTIVE=$(sed -n '/^[ \t]*\[postgresql\]/,/\[/s/^[ \t]*active[ \t]*=[ \t]*//p' $PGINI)
PGCONNECTION=$(sed -n '/^[ \t]*\[postgresql\]/,/\[/s/^[ \t]*connection[ \t]*=[ \t]*//p' $PGINI)
PGACTION=$(sed -n '/^[ \t]*\[postgresql\]/,/\[/s/^[ \t]*run_action[ \t]*=[ \t]*//p' $PGINI)
REPEAT=$(sed -n '/^[ \t]*\[postgresql\]/,/\[/s/^[ \t]*repeat_minutes[ \t]*=[ \t]*//p' $PGINI)

# Check if synchro is active
if [ "$PGACTIVE" != "true" ]
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

# config
CONFIGPG=".config-cron-postgresql"
echo "$PGACTION" > $DIRECTORY/$CONFIGPG
# Options for the binary call
DAEMON_OPTS="$PGCONNECTION -f $DIRECTORY/$CONFIGPG"

# Run daemon
echo "$NAME: $ACTION"
./run_daemon.sh $ACTION $NAME $DAEMON "$DAEMON_OPTS"


exit 0
