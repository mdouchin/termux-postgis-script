#!/bin/sh

set -e

ACTION=$1

# Options
# Name
NAME=lizsync_synchronisation
# Binary: full path only
DAEMON="$PREFIX/bin/psql"
# Current directory
DIRECTORY="`pwd`"

# Check internet connection OK
wget -q --spider https://google.com
if [ ! $? -eq 0 ]; then
    echo "No internet connection !"
    exit 1
else
    echo "connection ok"
fi

# Check audit table is not empty
$DAEMON service=geopoppy -t -c 'SELECT event_id FROM audit.logged_actions LIMIT 1' > sup
CHECK=$(cat sup | sed 's/[^0-9]//g')
rm sup

# For actions other than start and restart
if [ "$ACTION" != "start" ] && [ "$ACTION" != "restart" ]
then
    CHECK=1
fi

# config
CONFIGLIZSYNC=./.config-lizsync
echo "SELECT * FROM lizsync.synchronize()" > $CONFIGLIZSYNC
# Options for the binary call
DAEMON_OPTS="service=geopoppy -f $DIRECTORY/$CONFIGLIZSYNC"

# Run daemon
if [ $CHECK > 0 ]
then
    echo "$NAME: $ACTION"
    ./run_daemon.sh $ACTION $NAME $DAEMON "$DAEMON_OPTS"
else
    echo "Nothing to do"
fi

exit 0
