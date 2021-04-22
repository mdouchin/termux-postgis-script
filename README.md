# termux-postgis-script

Help script to install and manage a PostgreSQL/PostGIS database in Termux

## Installation

You can install the script by manually downloading the `liz.sh` file and put it in your home folder, or use wget inside your termux session

### With wget

Be sure your Android device has a working internet connection. Then start Termux, and follow this guidelines:

```bash
# Update the packages
# BEWARE: you will need to answer with Y the questions asked during the upgrade job
pkg update -y
pkg upgrade -y

# Install wget
pkg install -y wget

# Get the script
# you can use the long native URL
cd
wget https://raw.githubusercontent.com/mdouchin/termux-postgis-script/main/liz.sh -O liz.sh
# or the short URL:
# BEWARE: it is an lowercase L, not a 1 (one) after 42
cd
wget https://s.42l.fr/liz -O liz.sh

# Add execute permission
chmod +x liz.sh

# Test it
./liz.sh
# should return the help like
# Available commands: pe (permission), up (upgrade), in (install), pg (service postgresql), ip (get ip), bk (backup PostgreSQL), re (restore PostgreSQL), st (Startup script), ve (version), zz (reset al)

```

![Get and install script](media/download_and_install_script.gif)

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
Available commands: pe (permission), up (upgrade), in (install), pg (service postgresql), ip (get ip), bk (backup PostgreSQL), re (restore PostgreSQL), ve (version), zz (reset all)
```

## Usage

You can use the `./liz.sh` command to run some preconfigured functions:

* `./liz/sh pe`: run termux-setup-storage to allow acces to your documents (Download, DCIM, etc.)
* `./liz/sh up`: update termux packages
* `./liz/sh in`: install PostgreSQL/PostGIS & create gis database and gis user && install sshd and other tools (lftp, crontab, etc.)
* `./liz/sh pg`: start/stop/restart/status PostgreSQL service
* `./liz/sh ip`: get Android device IP address
* `./liz/sh bk`: backup the gis database
* `./liz/sh re`: restore the gis database
* `./liz/sh st`: restart PostgreSQL and the sshd services, to be used at device or session startup. It also shows the SSH username and the devices IP addresses
* `./liz.sh ve`: display the version of the script liz.sh
* `./liz.sh zz`: reset all ! This will completely erase your termux installation, and delete configuration files and PostgreSQL database data. Your Android storage will NOT be deleted.


### Installation

For your first use, we recommend to:

* run the command `pe` to grant access to your Android folders DCIM, Download, etc.
* run the command then `up` to update the packages
* run the command  `in` to install PostgreSQL, sshd and other tools such as lftp and crontab. This can take a couple of minutes, and need you to follow the progress, since it asks for some confirmations: confirm with **Y** You can pass an optionnal argument with the desired password for the SSH and PostgreSQL user.

Of course, the installation process must be done only once.

During the installation, you will be asked for:

* the SSH user password, to connect with SSH from a computer
* the PostgreSQL gis user password to be able to connect to the gis database

only if you have not given the password at the end of the command. See example below.

Example commands:

```bash
# Add symbolic links to access your Android files
# by running termux-setup-storage command line
# This is only required once
# See https://wiki.termux.com/wiki/Termux-setup-storage
./liz.sh pe

# Update packages
# Run it frequently to keep your termux up-to-date
# No need to run it if you just ran "pkg update" before
./liz.sh up

# Install PostgreSQL and PostGIS, and create a gis database and a gis user with gis password
# Nothing will be done if PostgreSQL is already installed
# Install also sshd, shows the user name and asks for a password
# Nothing will be done if sshd is already installed
# Note: if you pass a password as argument, it will be used for the PostgreSQL and SSH user
./liz.sh in
# OR you can use the command
# with a password given as parameter (you could use an environment variable or read from a file, etc
./liz.sh in gis

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
# and overwrite it with the previosly backuped data !!!
./liz.sh re

# Restart PostgreSQL
# And display the SSH user and the IP addresses
# This must not be necessary since this command is automatically run at startup
# But you can call it anytime needed
./liz/sh st
```

### Startup

The installation has added a script `~/.bash_profile` which will be **run automatically at startup**. This wil let you have a working PostgreSQL and sshd server after starting a new Termux session. No need to manually run the command `./liz.sh st`

### Use PostgreSQL

After installing PostgreSQL/PostGIS with the `./liz.sh in` command, you have a full PostgreSQL server with:

* a `gis` database with PostGIS extension
* a `gis` user with password `gis` who can connect to the database.

You now acces to your PostgreSQL database

* locally in your Termux session

```bash
# With the superuser
psql -d gis

# with the gis user, connect to the database gis
# this is recommended
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
* You can change the password of the user `gis` by connecting as the superuser within termux and run:

```bash
psql -d gis -c "ALTER ROLE gis WITH PASSWORD 'new_password'"
```

and do not forget to also change the password in the service file in `~/.pg_service.conf`

### Use the SSH remote access

You need to know you SSH user name, and the Termux IP address. To do so, run the commands `./liz.sh ip` from the Termux console, which will show your WIFI or USB IP address and your SSH user name

Now you can connect from your computer, if it is connected in the same network, for example by WIFI. Let say that the SSH user name is `u0_a171` and your Termyx IP address is `192.168.1.29`, you can connect from your computer with:

```bash
ssh u0_a171@192.168.1.29 -p 8022
```
 and the password you setup during the first installation with `./liz.sh in`

### Crontab: run actions periodically

The installation process has installed and configured **crontab**. This tool is in charge of running some actions at regular intervals.

To check which actions are configured, you can execute

```bash
crontab -l
```

The result of this command will be like:

```
~ $ crontab -l
* * * * * echo "$(date)" > /data/data/com.termux/files/home/test_cron
*/5 * * * * /data/data/com.termux/files/home/cron_postgresql.sh start
*/5 * * * * /data/data/com.termux/files/home/cron_lftp.sh start
```

The first line is a test action executed every minute which writes the current date into the file `~/test_cron`. You can check it works by running

```bash
ls -lh ~/test_cron
```

Two other scripts will be run every 5 minutes. They can be used to run some FTP and PostgreSQL database synchronisation processes if the needed INI configuration files are found.

If no file `~/test_cron` exists, you can test to reactivate the cron service with 

```bash
sv-enable crond
```

NB: This command should be done on every start, since it is now included in the startup script.

#### FTP synchronisation with lftp

The script `/data/data/com.termux/files/home/cron_lftp.sh` is in charge of running the **synchronisation of files** between a file directory of your Android device and a FTP server directory. The library **lftp** is used in mirror mode for this purpose. The cron checks every 5 minutes if the content of a chosen folder has changed, and runs the synchronisation. Only new of modified files are uploaded. Not deletion is made on the server side.

To enable it, you need to  edit the INI file `lftp.ini` and change the properties:

```ìni
[lftp]
active=false
protocol=ftp
host=some-fake-ftp-domain.com
port=21
user=your_ftp_username
local_dir=storage/downloads/qgis/media
remote_dir=qgis/directory/media

```

* **active** If set to `true`, the synchronisation is activated. Use `false` to deactivate file synchronisation
* **protocol** Use `ftp` or `sftp`, depending on your FTP server
* **host** The domain name or IP address of the FTP server
* **port** The port. Usually `21` for FTP and `22` for SFTP
* **user** The FTP user which will logs in
* **local_dir** The local directory of your Termux setup to synchronise. In the example above, all files and folders under your Android folder `Downloads/qgis/media` will be synchronized. The `storage/` root corresponds to your Android user folder, which usually contains DCIM, Downloads, Pictures, Videos
* **remote_dir** The remote directory in your FTP server. Choose with care, as the synchronisation will modify its content

The **password** needed to log in is not stored in this file, but needs to be written in the file `.netrc` of your Termux home folder. See the [netrc file documentation](https://www.gnu.org/software/inetutils/manual/html_node/The-_002enetrc-file.html) for more information on the syntax.

#### PostgreSQL synchronisation with LizSync

TODO

