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
PGCHECK=$(sed -n '/^[ \t]*\[postgresql\]/,/\[/s/^[ \t]*check_action_needed[ \t]*=[ \t]*//p' $PGINI)
PGACTION=$(sed -n '/^[ \t]*\[postgresql\]/,/\[/s/^[ \t]*run_action[ \t]*=[ \t]*//p' $PGINI)

if [ "$PGACTIVE" != "true" ]
then
    echo "Action is not active. Cancel."
    exit 0
fi

# Check audit table is not empty
$DAEMON $PGCONNECTION -t -c "$PGCHECK" > sup
CHECK=$(cat sup | sed 's/[^0-9]//g')
rm sup

# For actions other than start and restart
if [ "$ACTION" != "start" ] && [ "$ACTION" != "restart" ]
then
    CHECK=1
fi

# config
CONFIGPG=".config-cron-postgresql"
echo "$PGACTION" > $DIRECTORY/$CONFIGPG
# Options for the binary call
DAEMON_OPTS="$PGCONNECTION -f $DIRECTORY/$CONFIGPG"

# Run daemon
if [ $CHECK > 0 ]
then
    echo "$NAME: $ACTION"
    ./run_daemon.sh $ACTION $NAME $DAEMON "$DAEMON_OPTS"
else
    echo "Nothing to do"
fi

exit 0
