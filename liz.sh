#!/usr/bin/env bash


COMMAND="$1"
shift

function liz_install_sshd() {
  echo "SSHD - install and configure"

  # Check it is not already installed
  if [ -f $PREFIX/bin/sshd ]; then
    echo "SSHD is already installed"
  else

    # install openssh
    pkg install -y openssh

    # change config if needed
    #
    SCONFIG="$PREFIX/etc/ssh/sshd_config"
    if grep -q 'MaxAuthTries' $SCONFIG; then
        echo '* sshd config OK'
    else
        echo '* tuning sshd config'
        echo "MaxAuthTries 10" >> $SCONFIG
    fi

    # set user password
    ME=$(whoami)
    echo "User: $ME"
    echo -n "Please type a password for the user $ME: "
    read -s password
    echo -e "$password\n$password" | (passwd $ME)

    # start sshd
    sshd
  fi
}

function liz_service_sshd() {
  SERVICE="sshd"

  # Stop if needed
  if pgrep "$SERVICE" >/dev/null
  then
    echo "$SERVICE is running"
    if [ "$1" = "stop" ] || [ "$1" = "restart" ]
    then
      echo "* Stop sshd"
      pkill sshd
    fi
  fi

  # Start if needed
  if [ "$1" = "start" ] || [ "$1" = "restart" ]
  then
    echo "* Start sshd"
    sshd
  fi
}

function liz_storage() {
  echo "Storage - configure termux setup storage"
  termux-setup-storage
}

function liz_update() {
  echo "Update - upgrade packages"
  pkg update -y
  pkg upgrade -y
  pkg autoclean
  echo ""
  echo ""
}

function liz_install_postgresql() {

  echo "PostgreSQL - install and configure"

  if [ -f $PREFIX/bin/pg_ctl ]; then
    echo "* PostgreSQL - package already installed"
    echo ""
    return
  fi

  echo "PostgreSQL - install needed packages"
  pkg install -y build-essential wget curl readline libiconv postgresql libxml2 libsqlite proj libgeos json-c libprotobuf-c gdal

  echo "PostgreSQL - install PostGIS"
  wget https://download.osgeo.org/postgis/source/postgis-3.1.0.tar.gz
  tar xfz postgis-3.1.0.tar.gz
  cd postgis-3.1.0
  ./configure --prefix=$PREFIX --with-projdir=$PREFIX
  make -j8
  make install
  cd ~
  rm postgis-3.1.0.tar.gz
  rm -rf postgis-3.1.0/

  echo "PostgreSQL - configure"
  mkdir -p $PREFIX/var/lib/postgresql
  initdb $PREFIX/var/lib/postgresql
  echo "listen_addresses = '*'" >> $PREFIX/var/lib/postgresql/postgresql.conf
  echo "host all all 0.0.0.0/0 md5" >> $PREFIX/var/lib/postgresql/pg_hba.conf

  echo "PostgreSQL - start server"
  pg_ctl -D $PREFIX/var/lib/postgresql start

  echo "PostgreSQL - create database gis"
  createdb gis
  psql -d gis -c "CREATE EXTENSION IF NOT EXISTS postgis;CREATE EXTENSION IF NOT EXISTS hstore;"

  echo "PostgreSQL - create the user 'gis'"
  echo -n "Please type a password for the user gis: "
  read -s PASSWORD
  psql -d gis -c "CREATE ROLE gis WITH SUPERUSER LOGIN PASSWORD '$PASSWORD'"

  echo "PostgreSQL - create service file"
  cat > .pg_service.conf <<EOF
  [gis]
  host=localhost
  dbname=gis
  user=gispassword
  port=5432
  password=gis
EOF
  sed -i "s/gispassword/$PASSWORD/g"

  echo "PostgreSQL - restart server"
  pg_ctl -D $PREFIX/var/lib/postgresql restart

  echo "PostgreSQL - clean packages"
  pkg remove -y build-essential
  pkg autoclean
}

function liz_service_postgresql() {
  echo "PostgreSQL - service $1"
  pg_ctl -D $PREFIX/var/lib/postgresql $1
}

function liz_ip() {
  echo "IP - Get IP addresses"
  mydevice="wlan0"
  myip=$(ip add | grep "global $mydevice" | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
  echo "* IP ADDRESS WLAN = $myip"

  mydevice="rndis0"
  myip=$(ip add | grep "global $mydevice" | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
  echo "* IP ADDRESS USB = $myip"

  # Show SSH username
  ME=$(whoami)
  echo "* Username for ssh: $ME"

  # PostgreSQL info
  echo "* PostgreSQL info - database gis, user gis"
}

function liz_backup() {
  echo "Backup - backup PostgreSQL gis database"

  DATA=/sdcard/postgresql_gis_database.backup
  if [ -f $DATA ]; then
     rm -f $DATA
  fi

  echo "* PostgreSQL backup started... wait please"
  cd ~
  echo "* backuping gis database..."
  $PREFIX/bin/pg_dump -Fc --no-acl --no-owner -d gis --create -f $DATA
  echo "* PostgreSQL backup completed !"

  echo "* Archive information:"
  ls -lh $DATA
}

function liz_restore() {
  echo "Restore - restore PostgreSQL gis database"

  DATA=/sdcard/postgresql_gis_database.backup

  # Confirm
  read -p "Restore database from $DATA ? This will delete all the local data and replace them by the backuped data. (y/n)?" CHOICE
  case "$CHOICE" in
    y|Y ) echo "* Restoration accepted";;
    * ) echo " Restoration canceled"; return;;
  esac

  if [ -f $DATA ]; then
    echo "PostgreSQL - restart server"
    pg_ctl -D $PREFIX/var/lib/postgresql restart

    echo "* Drop database gis"
    dropdb gis

    echo "* Create gis database and restore data"
    createdb gis
    $PREFIX/bin/pg_restore -j 4 -d gis $DATA

    echo "* Restoration completed"

  else
    echo "* no data archive found in path: $DATA"
  fi
}

function liz_add_startup_script() {
  # Add startup script in bash_profile
  BPROFILE=~/.bash_profile
  if [ -f $BPROFILE ]; then
    echo "* Startup .bash_profile is already installed"
  else
    echo "* Add startup .bash_profile script"
    echo "echo '######## LIZ ##########'" > $BPROFILE
    echo "echo 'Welcome'" >> $BPROFILE
    echo "~/liz.sh st" >> $BPROFILE
    echo "echo '#######################'" >> $BPROFILE
    echo "" >> $BPROFILE
  fi

  # Add logout script
  BLOGOUT=~/.bash_logout
  if [ -f $BLOGOUT ]; then
    echo "* Logout file .bash_logout is already installed"
  else
    echo "echo '######## LIZ ##########'" > $BLOGOUT
    echo "echo 'Goodbye !'" > $BLOGOUT
    echo "termux-wake-unlock" > $BLOGOUT
    echo "echo '#######################'" >> $BLOGOUT
  fi
}

function add_extra_keys() {
  EXTRAKEYS="extra-keys = [['ESC','/','-','HOME','UP','END','PGUP'],['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN']]"
  PROPERTYFILE=~/.termux/termux.properties
  echo "" >> $PROPERTYFILE
  echo $EXTRAKEYS >> $PROPERTYFILE
  termux-reload-settings
  echo "Install - Extra keys added to the terminal interface"
}

function liz_install_cron() {

  # check if it is already installed
  echo "Crontab - Install packages"
  if [ -f $PREFIX/bin/crontab ]; then
    echo "* Crontab - package already installed"
    echo ""
    return
  fi

  # Install packages
  pkg install -y termux-services cronie
  sv-enable crond

  # Add crontab
  echo "Crontab - Get PostgreSQL and LFTP cron actions"
  wget https://raw.githubusercontent.com/mdouchin/termux-postgis-script/main/cron_postgresql.sh -O cron_postgresql.sh
  wget https://raw.githubusercontent.com/mdouchin/termux-postgis-script/main/cron_lftp.sh -O cron_lftp.sh
  chmod +x cron_*.sh
  echo "* PostgreSQL and LFTP actions installed"

  # Activate crontab actions
  echo "Crontab - Add cron actions"
  echo '*/5 * * * * echo "$(date)" > /data/data/com.termux/files/home/test_cron' > ~/crontab.txt
  echo '*/5 * * * * /data/data/com.termux/files/home/cron_postgresql.sh start' >> ~/crontab.txt
  echo '*/5 * * * * /data/data/com.termux/files/home/cron_lftp.sh start' >> ~/crontab.txt
  crontab ~/crontab.txt
  rm ~/crontab.txt
  echo "* Crontab actions installed"
  crontab -l

}


function liz_instal_lftp() {
  echo "LFTP - Install package"
  pkg install -y lftp
}

function liz_install() {

  # Update packages
  liz_update

  # Install PostgreSQL
  liz_install_postgresql

  # Install sshd
  liz_install_sshd

  # Install lftp
  liz_instal_lftp

  # Add startup script
  liz_add_startup_script

  # Add terminal extra-keys
  add_extra_keys

  # Add cron and daemons
  liz_install_cron

}

function liz_startup() {
  # Start sshd
  # Do not restart to avoid being kicked out any time you connect
  liz_service_sshd start

  # Start PostgreSQL server
  liz_service_postgresql restart

  # Show IP and username
  liz_ip

  # Acquire wakelock
  termux-wake-lock
}



case $COMMAND in
  pe)
    liz_storage
    ;;
  up)
    liz_update
    ;;
  in)
    liz_install
    ;;
  pg)
    liz_service_postgresql $1
    ;;
  ip)
    liz_ip
    ;;
  bk)
    liz_backup
    ;;
  re)
    liz_restore
    ;;
  st)
    liz_startup
    ;;
  *)
    echo "Available commands: pe (permission), up (upgrade), in (install postgresql), pg (service postgresql), ip (get ip), bk (backup PostgreSQL), re (restore PostgreSQL) & st (Startup script)"
    exit 2
    ;;
esac
