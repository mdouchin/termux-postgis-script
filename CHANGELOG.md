# CHANGELOG

### 1.0.6 - 16/11/2021

* PostGIS - use version 3.1.4 && install needed new packages binutils & zstd

### 1.0.5 - 15/06/2021

* PostGIS - use version 3.1.2 to fix a bug when installing previous 3.1.0 with new Proj 8

### 1.0.4 - 18/05/2021

* PostgreSQL - Log errors and warning in pg.log file instead of in command prompt
* Synchronisation - add an option in the INI files to configure the frequency in minutes
* Synchronsation - PostgreSQL: check LizSync has been installed before running sync

### 1.0.3 - 22/04/2021

* PostgreSQL sync - remove useless check before running lizsync synchronize command

### 1.0.2 - 24/02/2021

* Add command `./liz.sh zz` to reset all Termux installed softwares, configuration files and PostgreSQL data

### 1.0.1 - 21/02/2021

* Instalation - Add missing file `run_daemon.sh`
* Doc - Add a chapter on FTP synchronisation

### 1.0.0 - 19/02/2021

* First release. See [the README.md file](README.md) for more information
