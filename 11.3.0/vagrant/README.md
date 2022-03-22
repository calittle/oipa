# oipa-11.3.0-vagrant

This Vagrant project provisions:
- Oracle Linux 7
- Oracle Database 19c
- Oracle WebLogic Server
- Oracle Insurance Policy Administration for Life and Annuity

Instructions assume a POSIX-based terminal is used for installation, however, these instructions
can be easily adapted to Windows-based systems.

## Prerequisites

1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://vagrantup.com/)

## Getting started

1. Clone this repository `git clone https://github.com/calittle/oipa.git` into a folder of your choice, e.g. `vagrant-projects`
2. Change into the `vagrant-projects/oipa/11.3.0` directory. This is the *project root* directory.
3. Download the installation zip files into the *project root* directory.
  1. From [OTN](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html) download Oracle 19c (`LINUX.X64_193000_db_home.zip`) for Linux x64.
  2. From [eDelivery](http://edelivery.oracle.com) download the following `DLP: Oracle Insurance Policy Administration for Life and Annuity 11.3.0.0.0` zip files for Linux/WebLogic:
      - `V997064-01.zip`, OIPA_11.3.0.0_AdminConsole_WebLogic, 57.0 MB
      - `V997069-01.zip`, OIPA_11.3.0.0_Database_Oracle, 49.2 MB
      - `V997071-01.zip`, OIPA_11.3.0.0_PASJava_WebLogic, 217.8 MB
      - `V997074-01.zip`, OIPA_11.3.0.0_ServiceLayer_WebLogic, 65.2 MB
  3. From [OTN](https://www.oracle.com/java/technologies/javase/javase8u211-later-archive-downloads.html) Download JDK 1.8 Linux x64 RPM Package `jdk-8u311-linux-x64.rpm`.
  4. From [OTN](https://www.oracle.com/middleware/technologies/weblogic-server-downloads.html) download WebLogic Server 12.2.1.4 `fmw_12.2.1.4.0_wls_lite_Disk1_1of1.zip`. 
  
4. Run `vagrant up`
   1. The first time you run this it will provision everything and may take a while. Ensure you have a good internet connection as the scripts will update the VM to the latest via `yum`.
   2. The installation can be customized, if desired (see [Configuration](#configuration)).
5. Connect to the database (see [Connecting to Oracle](#connecting-to-oracle))
6. You can shut down the VM via the usual `vagrant halt` and then start it up again via `vagrant up`. You can also [reprovision[(#reprovision)]].


## Connecting to Oracle

The default database connection parameters are:

* Hostname: `localhost`
* Port: `1521`
* SID: `ORCLCDB`
* PDB: `ORCLPDB1`
* EM Express port: `5500`
* Database passwords are auto-generated and printed on install

These parameters can be customized, if desired (see [Configuration](#configuration)).

## Resetting password

You can reset the password of the Oracle database accounts (SYS, SYSTEM and PDBADMIN only) by switching to the oracle user (`sudo su - oracle`), then executing `/home/oracle/setPassword.sh <Your new password>`.

## Running scripts after setup

You can have the installer run scripts after setup by putting them in the `userscripts` directory below the directory where you have this file checked out. Any shell (`.sh`) or SQL (`.sql`) scripts you put in the `userscripts` directory will be executed by the installer after the database is set up and started. Only shell and SQL scripts will be executed; all other files will be ignored. These scripts are completely optional.

Shell scripts will be executed as root. SQL scripts will be executed as SYS. SQL scripts will run against the CDB, not the PDB, unless you include an `ALTER SESSION SET CONTAINER = <pdbname>` statement in the script.

To run scripts in a specific order, prefix the file names with a number, e.g., `01_shellscript.sh`, `02_tablespaces.sql`, `03_shellscript2.sh`, etc.

## Reprovision

Sometimes it may be necessary to reprovision the VM if something did not deploy correctly, or simply just to start over. To reprovision, make sure your VM is in a halted stated (e.g. `vagrant halt`) and then run `vagrant up --provision`). Before you do that, make sure you have corrected the elements of the deployment that failed. In order to provide more granular control over what steps are rerun, the deployment scripts create some simple txt files at various points of the deployment process. Delete these files to rerun that step. Note that there isn't a rollback, so sometimes you might need to undo what the deployment step did. This isn't foolproof, so use your best judgment (e.g. if you're not sure, just `vagrant destroy oipa-vagrant` and then `vagrant up` to redo the whole thing.) 

- `/opt/oracle/dbinstalled.txt` - delete this file to redo the entire unpacking and installation of the database software, and listener configuration, CDB/PDB deployment, and database services.
- `/opt/oracle/db-step1.txt` - delete this file to redo the database sfotware unpack and install.
- `/opt/oracle/db-step2.txt` - delete this file to redo the listener configuration.
- `/opt/oracle/db-step3.txt` - delete this file to redo the CDB/PDB creation.
- `/opt/oracle/db-step4.txt` - delete this file to redo the database service registration with the OS.

- `/opt/oracle/oipadb.txt` - delete this file to redo the the OIPA database import and oipa/ivs user creation.
- `/opt/oracle/oipadb-step1.txt` - delete this file to redo oipa/ivs user creation. You may need to drop the users before reprovision.
- `/opt/oracle/oipadb-step2.txt` - delete this file to redo oipa db import. You must adjust impdp settings in `userscripts/01-oipadb.sh` for this to work correctly. Advise dropping user schemas with cascade and start over.
- `/opt/oracle/oipadb-step3.txt` - delete this file to redo ivs db import. You must adjust impdp settings in `userscripts/01-oipadb.sh` for this to work correctly. Advise dropping user schemas with cascade and start over.

- `/opt/oracle/weblogic.txt` - delete this file to redo WebLogic install and domain creation.
- `/opt/oracle/weblogic-step1.txt` - delete this file to reinstall WebLogic server.
- `/opt/oracle/weblogic-step2.txt` - delete this file to redo the prerequisite download and preparation for domain deployment.
- `/opt/oracle/weblogic-step3.txt` - delete this file to recreate the WebLogic domain and application deployment. You may need to delete a directory to do this correctly.
- `/opt/oracle/weblogic-step4.txt` - delete to reprovision WebLogic services.

## Configuration

The `Vagrantfile` can be used _as-is_, without any additional configuration. However, there are several parameters you can set to tailor the installation to your needs.

### How to configure

There are three ways to set parameters:

1. Update the `Vagrantfile`. This is straightforward; the downside is that you will lose changes when you update this repository.
2. Use environment variables. It might be difficult to remember the parameters used when the VM was instantiated.
3. Use the `.env`/`.env.local` files (requires
[vagrant-env](https://github.com/gosuri/vagrant-env) plugin). You can configure your installation by editing the `.env` file, but `.env` will be overwritten on updates, so it's better to make a copy of `.env` called `.env.local`, then make changes in `.env.local`. The `.env.local` file won't be overwritten when you update this repository and it won't mark your Git tree as changed (you won't accidentally commit your local configuration!).

Parameters are considered in the following order (first one wins):

1. Environment variables
2. `.env.local` (if it exists and the  [vagrant-env](https://github.com/gosuri/vagrant-env) plugin is installed)
3. `.env` (if the [vagrant-env](https://github.com/gosuri/vagrant-env) plugin is installed)
4. `Vagrantfile` definitions

### VM parameters

* `VM_NAME` (default: `oipa-vagrant`): VM name.
* `VM_MEMORY` (default: `8192`): memory for the VM (in MB).
* `VM_SYSTEM_TIMEZONE` (default: host time zone (if possible)): VM time zone.
  * The system time zone is used by the database for SYSDATE/SYSTIMESTAMP.
  * The guest time zone will be set to the host time zone when the host time zone is a full hour offset from GMT.
  * When the host time zone isn't a full hour offset from GMT (e.g., in India and parts of Australia), the guest time zone will be set to UTC.
  * You can specify a different time zone using a time zone name (e.g., "America/Los_Angeles") or an offset from GMT (e.g., "Etc/GMT-2"). For more information on specifying time zones, see [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

### Oracle Database parameters

* `VM_ORACLE_BASE` (default: `/opt/oracle/`): Oracle base directory.
* `VM_ORACLE_HOME` (default: `/opt/oracle/product/19c/dbhome_1`): Oracle home directory.
* `VM_ORACLE_SID` (default: `ORCLCDB`): Oracle SID.
* `VM_ORACLE_PDB` (default: `ORCLPDB1`): PDB name.
* `VM_ORACLE_CHARACTERSET` (default: `AL32UTF8`): database character set.
* `VM_ORACLE_EDITION` (default: `EE`): Oracle Database edition. Either `EE` for Enterprise Edition or `SE2` for Standard Edition 2.
* `VM_LISTENER_PORT` (default: `1521`): Listener port.
* `VM_EM_EXPRESS_PORT` (default: `5500`): EM Express port.
* `VM_ORACLE_PWD` (default: automatically generated): Oracle Database password for the SYS, SYSTEM and PDBADMIN accounts.

### Oracle WebLogic Server parameters

* `VM_VM_MW_HOME` (default: `/opt/oracle/middleware`): base directory for WebLogic.
* `VM_MW_DOMAIN` (default: `oipa`): WebLogic domain name
* `VM_WLS_PORT_ADMIN` (default: `7001`): WebLogic administrative port
* `VM_WLS_OIPA_PORT` (default: `10001`): OIPA PASJava server port
* `VM_WLS_OIPA_SSLPORT` (default: `10002`): OIPA PASJava server SSL port
* `VM_WLS_PALETTECONFIG_PORT` (default: `11001`): OIPA Palette Config server port
* `VM_WLS_PALETTECONFIG_SSLPORT` (default: `11002`): OIPA Palette Config serfver SSL port
* `VM_JDK` (default: `8u311`): Java version used (must align with download package obtained from [Getting Started](#Getting-Started))
* `VM_JAVA_PATH` (default: `/usr/java/jdk1.8.0_311-amd64`): Java installation path on VM
* `VM_WLS` (default: `12.2.1.4.0`): WebLogic server version used (must align with download package obtained from [Getting Started](#Getting-Started))

### OIPA parameters
* `VM_ZIP_OIPA_DB` (default: `V997069-01.zip`): The zip package containing the OIPA DB installation files.
* `VM_ZIP_OIPAWLS` (default: `V997071-01.zip`): The zip package containing the OIPA WebLogic installation files.
* `VM_ZIP_ORACLEDB` (default: `LINUX.X64_193000_db_home.zip`): The zip package containing the Oracle datbase installer.
* `VM_ZIP_PCWLS` (default: `V997078-01.zip`): The zip package containing the OIPA Palette Config installation files.
* `VM_DB_USER_OIPA` (default: `oipa`): The db user that owns OIPA tables. Password is set to `VM_ORACLE_PWD`.
* `VM_DB_USER_IVS` (default: `oipaivs`): The db user that owns IVS tables. Password is set to `VM_ORACLE_PWD`.
* `VM_OIPA_URL_ASPECTJ` (default: `https://eclipse.mirror.rafal.ca/tools/aspectj/aspectj-1.8.10.jar`): The *direct download URL* to download AspectJ (OIPA prerequisite component). Download is automated. To find a different mirror and upload the link, search here: https://www.eclipse.org/downloads/download.php?file=/tools/aspectj/aspectj-1.8.10.jar
* `VM_OIPA_URL_LOG4J` (default: `https://archive.apache.org/dist/logging/log4j/1.2.17/log4j-1.2.17.jar`): The URL to download Log4J (OIPA prerequisite component). Download is automated.

## Optional plugins

When installed, this Vagrant project will make use of the following third party Vagrant plugins:

* [vagrant-env](https://github.com/gosuri/vagrant-env): loads environment
variables from .env files;
* [vagrant-proxyconf](https://github.com/tmatilai/vagrant-proxyconf): set
proxies in the guest VM if you need to access the Internet through a proxy. See
the plugin documentation for configuration.

To install Vagrant plugins run:

```shell
vagrant plugin install <name>...
```

## Other info

* If you need to, you can connect to the virtual machine via `vagrant ssh`.
* You can `sudo su - oracle` to switch to the oracle user.
* On the guest OS, the directory `/vagrant` is a shared folder and maps to wherever you have this file checked out.
