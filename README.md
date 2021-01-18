# termux-postgis-script

Help script to install and manage a PostgreSQL/PostGIS database in Termux

## Installation

You can install the script by manually downloading the `liz.sh` file and put it in your home folder, or use wget inside your termux session

### With wget

Be sure your Android device has a working internet connection. Then start Termux, and follow this guidelines:

```bash
# Update the packages
pkg -y update

# Install wget
pgg install wget

# Get the script
wget https://raw.githubusercontent.com/mdouchin/termux-postgis-script/main/liz.sh -O ~/liz.sh

# Add execute permission
chmod +x ~/liz.sh

# Test it
./liz.sh
# should return the help like
# Available commands: pe (permission), up (upgrade), in (install postgresql), pg (service postgresql), ip (get ip), bk (backup PostgreSQL) & re (restore PostgreSQL)

```

### Manually

* Go to the file URL: https://raw.githubusercontent.com/mdouchin/termux-postgis-script/main/liz.sh
* Save this file `liz.sh` in your computer
* Transfer it to the Android device root folder with USB file transfer: connect your Android device and your computer with a USB wire, and activate the **USB file sharing** service (see: https://support.google.com/android/answer/9064445?hl=en )
* The file must be in the root folder, beside `Android`, `DCIM` and `Videos` folders
* Open Termux session, and follow this guidelines:

```bash
# Copy liz.sh in your home folder
cp /sdcard/liz.sh ~/liz.sh

# Add execute permission
chmod +x liz.sh

# Test
./liz.sh
# should return the help like
Available commands: pe (permission), up (upgrade), in (install postgresql), pg (service postgresql), ip (get ip), bk (backup PostgreSQL) & re (restore PostgreSQL)
```

## Usage

You can use the `./liz.sh` command to run some preconfigured functions:

```bash
# Add symbolic links to access your Android files
# by running termux-setup-storage command line
# This is only required once
# See https://wiki.termux.com/wiki/Termux-setup-storage
./liz.sh pe

# Update packages
# Run it frequently to keep your termux up-to-date
./liz.sh up

# Install PostgreSQL and PostGIS, and create a gis database and a gis user with gis password
# Nothing will be done if PostgreSQL is already installed
./liz.sh in

# Start, stop, restart, get status for PostgreSQL server
./liz.sh pg start
./liz.sh pg stop
./liz.sh pg restart
./liz.sh pg status

# Get IP addresses 
# for WLAN (if WIFI is used) 
# and USB (if your share your Android 3/4/5G connection with your computer)
./liz.sh ip

# Backup gis PostgreSQL database into the root folder /sdcard/
./liz.sh bk

# Restore gis PostgreSQL database
# BEWARE: this will erase your Android PostgresSQL gis database
# and overwrite it with the previosly backuped data
./liz.sh re

```

After installing PostgreSQL/PostGIS with the `./liz.sh in` command, you have a full PostgreSQL server with:

* a `gis` database with PostGIS extension
* a `gis` user with password `gis` who can connect to the database.

You now acces to your PostgreSQL database

* locally in your Termux session

```bash
# With the superuser
psql -d gis

# with the gis user, connect to the database gis
# this is recommanded
psql -h localhost -d gis -U gis
# password is gis

# you can use the geopoppy service
# to connect with the same credentials
psql service=geopoppy
```

* remotely from your computer

  - get your Termux IP address in the local network

```bash
# Get your WIFI or USB IP address from the Termux session
./liz.sh ip
```
  - Connect from your computer (which must be connected to the same network, for example by WIFI (or USB network sharing). For example, if your Termux IP is `192.168.1.130`:

```bash
psql -h 192.168.1.130 -d gis -U gis
```

**BEWARE**: 

* The `$PREFIX/var/lib/postgresql/pg_hba.conf` is configured to allow **all connections from all user from anywhere**. Remove the last line if you want to change this default behaviour.
* The `$PREFIX/var/lib/postgresql/postgresql.conf` is configured to give access to all IPs.  Remove the last line `listen_addresses = '*'` from this file to restrict access if needed.
* The password of the user `gis` can be changed by connecting as the superuser within termux with:

```bash
psql -d gis -c "ALTER ROLE gis WITH PASSWORD 'new_password'"
```

and do not forget to also change the password in the service file in `~/.pg_service.conf`
