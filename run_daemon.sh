#!/bin/sh
# Example use
# ./run_daemon.sh start LFTP_SYNC "/bin/lftp" "-f ~/Documents/3liz/Infra/termux-postgis-script/media_synchronisation.lftp"
set -e

# Name
NAME=$2
# Binary: full path only
DAEMON=$3
# Options for the binary call
DAEMON_OPTS=$4
# PID file
PIDFILE=$PREFIX/var/run/$NAME.pid
# LOG file
LOGFILE=$PREFIX/var/run/$NAME.log
# check if binary file exists
if [ ! -f $DAEMON ]
then
    echo "* Binary file $DAEMON has not been found for the daemon $NAME"
    exit 1
fi

# check if daemon is running
RUNNING=false
if [ -e $PIDFILE ]
then
    currentpid=`cat $PIDFILE`
    if `ps -p $currentpid > /dev/null`
    then
        RUNNING=true
    else
        rm -f $PIDFILE
    fi
fi

case "$1" in
  start)
    date
    if $RUNNING
    then
        started=`date -r $PIDFILE`
        echo "* Daemon $NAME already started since $started, you need to stop it first"
    else
        echo -n "* Starting daemon: "$NAME
        nohup $DAEMON $DAEMON_OPTS 1>$LOGFILE 2>&1 &
        echo $! > $PIDFILE
        echo "."
    fi
    ;;
  stop)
    date
    if $RUNNING
    then
        echo -n "* Stopping daemon: "$NAME
        kill -9 `cat $PIDFILE`
        rm -f $PIDFILE
        echo "."
    else
        echo "* Daemon is not running, no need to stop it"
    fi
    ;;
  restart)
    date
        echo -n "* Restarting daemon: "$NAME
    if $RUNNING
    then
        kill -9 `cat $PIDFILE`
        rm -f $PIDFILE
    fi
    nohup $DAEMON $DAEMON_OPTS 1>$LOGFILE 2>&1 &
    echo $! > $PIDFILE
    echo "."
    ;;
  check)
    if $RUNNING
    then
        echo "* $NAME is running"
    else
        echo "* $NAME is not running"
    fi
    ;;

  *)
    echo "Usage: "$1" {start|stop|restart|check}"
    exit 1
esac

exit 0
