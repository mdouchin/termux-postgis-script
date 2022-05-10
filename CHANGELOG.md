# CHANGELOG

### 1.1.0 - 10/05/2022

* PostGIS - Install from package and not from source (reduce installation time).
* IP - Install missing iproute2 package to be able to show the IP address

### 1.0.7 - 17/11/2021

* PostgreSQL - Fix bug while creating the `gis` user.

### 1.0.6 - 16/11/2021

* PostGIS - use version 3.1.4 && install needed new packages `binutils` & `zstd`

### 1.0.5 - 15/06/2021

* PostGIS - use version 3.1.2 to fix a bug when installing previous 3.1.0 with new `Proj` 8

### 1.0.4 - 18/05/2021

* PostgreSQL - Log errors and warning in pg.log file instead of in command prompt
* Synchronization - add an option in the INI files to configure the frequency in minutes
* Synchronization - PostgreSQL: check `LizSync` has been installed before running sync

### 1.0.3 - 22/04/2021

* PostgreSQL sync - remove useless check before running `lizsync` synchronize command

### 1.0.2 - 24/02/2021

* Add command `./liz.sh zz` to reset all Termux installed applications, configuration files and PostgreSQL data

### 1.0.1 - 21/02/2021

* Installation - Add missing file `run_daemon.sh`
* Doc - Add a chapter on FTP synchronization

### 1.0.0 - 19/02/2021

* First release. See [the README.md file](README.md) for more information
