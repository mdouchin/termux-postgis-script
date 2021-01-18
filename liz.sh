#!/usr/bin/env bash


COMMAND="$1"
shift

function liz_storage() {
  echo "Storage - configure termux setup storage"
  termux-setup-storage
}

function liz_update() {
  echo "Update - upgrade packages"
  pkg update -y
  pkg upgrade -y
  pkg autoclean
}

function liz_install_postgresql() {
  echo "PostgreSQL - install needed packages"
  pkg install -y build-essential
  pkg install -y wget curl readline libiconv postgresql libxml2 libsqlite proj libgeos json-c libprotobuf-c gdal

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
  psql -d gis -c "CREATE ROLE gis WITH SUPERUSER LOGIN PASSWORD 'gis'"

  echo "PostgreSQL - create service file"
  cat > .pg_service.conf <<EOF
  [geopoppy]
  host=localhost
  dbname=gis
  user=gis
  port=5432
  password=gis
EOF

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

case $COMMAND in
  pe)
    liz_storage
    ;;
  up)
    liz_update
    ;;
  in)
     TEST=~/.pg_service.conf
     if [ -f $TEST ]; then
        echo "PostgreSQL - already installed"
        exit
     fi

    liz_update && liz_install_postgresql
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
  *)
    echo "Available commands: pe (permission), up (upgrade), in (install postgresql), pg (service postgresql), ip (get ip), bk (backup PostgreSQL) & re (restore PostgreSQL)"
    exit 2
    ;;
esac
