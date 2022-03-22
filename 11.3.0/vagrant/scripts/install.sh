#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: July, 2018
# Author: gerald.venzl@oracle.com
# Description: Installs Oracle database software
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Abort on any error
set -e

echo 'INSTALLER: Started up'

# andy.little@oracle.com 21Mar2022
# Oracle DB requires swap size = memory size if membory > 4GB
# Since we are sizing up to 8GB for running DB+WLS, we need to increase swap space
# Normally we would do this in the OS (OEL7) but since that box is controlled by
# another group we'll manually adjust it here.
if [ -f "/swapfile" ]; then
	echo 'INSTALLER: extra swap file exists.'
else 
	echo 'INSTALLER: adjusting swap'
	fallocate -l 4G /swapfile
	chown root:root /swapfile
	chmod 0600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	swapon -s
	grep -i --color swap /proc/meminfo
	echo "/swapfile none            swap    sw              0       0" >> /etc/fstab
	echo 'INSTALLER: swap adjusted.'
fi

if [ -f "/opt/oracle/sysupdate.txt" ]; then
	echo 'INSTALLER: system update skipped; delete /opt/oracle/sysupdate.txt to provision.'
else
	# get up to date
	yum upgrade -y

	echo 'INSTALLER: System updated'

	# fix locale warning
	yum reinstall -y glibc-common
	echo LANG=en_US.utf-8 >> /etc/environment
	echo LC_ALL=en_US.utf-8 >> /etc/environment

	echo 'INSTALLER: Locale set'

	# set system time zone
	sudo timedatectl set-timezone $SYSTEM_TIMEZONE
	echo "INSTALLER: System time zone set to $SYSTEM_TIMEZONE"

	# Install Oracle Database prereq and openssl packages
	yum install -y oracle-database-preinstall-19c openssl

	echo 'INSTALLER: Oracle preinstall and openssl complete'

	# create directories
	mkdir -p $ORACLE_HOME
	mkdir -p /u01/app
	ln -sf $ORACLE_BASE /u01/app/oracle

	echo 'INSTALLER: Oracle directories created'
	su -l oracle -c "echo 'delete this file to rerun system update. '>>/opt/oracle/sysupdate.txt"
fi

# set environment variables if they don't already exist
if grep -q ORACLE_SID /home/oracle/.bashrc; then
	echo 'INSTALLER: Environment variables previously set; retaining.'
else
	echo "export ORACLE_BASE=$ORACLE_BASE" >> /home/oracle/.bashrc
	echo "export ORACLE_HOME=$ORACLE_HOME" >> /home/oracle/.bashrc
	echo "export ORACLE_SID=$ORACLE_SID" >> /home/oracle/.bashrc
	echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc
	echo 'INSTALLER: Environment variables set'
fi

# Install Oracle
if [ -f "/opt/oracle/dbinstalled.txt" ]; then
	echo "INSTALLER: Database setup skipped."

else

	if [ -f "/opt/oracle/db-step1.txt" ]; then
		echo "INSTALLER: Database unpack skipped."
	else
		unzip -n "/vagrant/$ORACLEDBZIP" -d $ORACLE_HOME/
		cp /vagrant/ora-response/db_install.rsp.tmpl /vagrant/ora-response/db_install.rsp
		sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /vagrant/ora-response/db_install.rsp
		sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /vagrant/ora-response/db_install.rsp
		sed -i -e "s|###ORACLE_EDITION###|$ORACLE_EDITION|g" /vagrant/ora-response/db_install.rsp
		chown oracle:oinstall -R $ORACLE_BASE

		su -l oracle -c "yes | $ORACLE_HOME/runInstaller -silent -ignorePrereqFailure -waitforcompletion -responseFile /vagrant/ora-response/db_install.rsp"
		$ORACLE_BASE/oraInventory/orainstRoot.sh
		$ORACLE_HOME/root.sh
		rm /vagrant/ora-response/db_install.rsp
		su -l oracle -c "echo 'delete this file to unpack and setup database'>>/opt/oracle/db-step1.txt"
		echo 'INSTALLER: Oracle software installed'
	fi
	if [ -f "/opt/oracle/db-step2.txt" ]; then
		echo "INSTALLER: Listener setup skipped."
	else
	
		# create sqlnet.ora, listener.ora and tnsnames.ora
		su -l oracle -c "mkdir -p $ORACLE_HOME/network/admin"
		su -l oracle -c "echo 'NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)' > $ORACLE_HOME/network/admin/sqlnet.ora"

		# Listener.ora
		su -l oracle -c "echo 'LISTENER = (DESCRIPTION = (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1))(ADDRESS=(PROTOCOL=TCP)(HOST= 0.0.0.0)(PORT = $LISTENER_PORT)))' > $ORACLE_HOME/network/admin/listener.ora"
		su -l oracle -c "echo 'DEDICATED_THROUGH_BROKER_LISTENER=ON' >> $ORACLE_HOME/network/admin/listener.ora"
		su -l oracle -c "echo 'DIAG_ADR_ENABLED = off' >> $ORACLE_HOME/network/admin/listener.ora"
		

		su -l oracle -c "echo '$ORACLE_SID=localhost:$LISTENER_PORT/$ORACLE_SID' > $ORACLE_HOME/network/admin/tnsnames.ora"
		su -l oracle -c "echo '$ORACLE_PDB=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=0.0.0.0)(PORT= $LISTENER_PORT))(CONNECT_DATA=(SERVER = DEDICATED)(SERVICE_NAME=$ORACLE_PDB)))' >> $ORACLE_HOME/network/admin/tnsnames.ora"

		# Start LISTENER
		su -l oracle -c "lsnrctl start"
		su -l oracle -c "echo 'delete this file to setup listener database'>>/opt/oracle/db-step2.txt"
		echo 'INSTALLER: Listener created'
	fi
	# Create database
	if [ -f "/opt/oracle/db-step3.txt" ]; then
		echo "INSTALLER: CDB/PDB setup skipped."
	else    
		# Auto generate ORACLE PWD if not passed on
		export ORACLE_PWD=${ORACLE_PWD:-"`openssl rand -base64 8`1"}
		echo "INSTALLER: ORACLE_PWD set to $ORACLE_PWD"

		cp /vagrant/ora-response/dbca.rsp.tmpl /vagrant/ora-response/dbca.rsp
		sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /vagrant/ora-response/dbca.rsp
		sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" /vagrant/ora-response/dbca.rsp
		sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" /vagrant/ora-response/dbca.rsp
		sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" /vagrant/ora-response/dbca.rsp
		sed -i -e "s|###EM_EXPRESS_PORT###|$EM_EXPRESS_PORT|g" /vagrant/ora-response/dbca.rsp

		# Create DB
		su -l oracle -c "dbca -silent -createDatabase -responseFile /vagrant/ora-response/dbca.rsp"

		# Post DB setup tasks
		su -l oracle -c "sqlplus / as sysdba <<EOF
			ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE;
			EXEC DBMS_XDB_CONFIG.SETGLOBALPORTENABLED (TRUE);
			ALTER SYSTEM SET LOCAL_LISTENER = '(ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT))' SCOPE=BOTH;
			ALTER SYSTEM REGISTER;
			exit;
			EOF"
#    oipa-vagrant: -bash: line 6: warning: here-document at line 0 delimited by end-of-file (wanted `EOF')
		rm /vagrant/ora-response/dbca.rsp
		su -l oracle -c "echo 'delete this file to set CDB/PDB databases'>>/opt/oracle/db-step3.txt"
		echo 'INSTALLER: Database created'
	fi
	if [ -f "/opt/oracle/db-step4.txt" ]; then
		echo "INSTALLER: System registration skipped."
	else   
		sed -i -e "\$s|${ORACLE_SID}:${ORACLE_HOME}:N|${ORACLE_SID}:${ORACLE_HOME}:Y|" /etc/oratab
		echo 'INSTALLER: Oratab configured'

		# configure systemd to start oracle instance on startup
		sudo cp /vagrant/scripts/oracle-rdbms.service /etc/systemd/system/
		sudo sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /etc/systemd/system/oracle-rdbms.service
		sudo systemctl daemon-reload
		sudo systemctl enable oracle-rdbms
		sudo systemctl start oracle-rdbms
		echo "INSTALLER: Created and enabled oracle-rdbms systemd's service"

		sudo cp /vagrant/scripts/setPassword.sh /home/oracle/
		sudo chmod a+rx /home/oracle/setPassword.sh
		echo "INSTALLER: setPassword.sh file setup";
		su -l oracle -c "echo 'delete this file to register system services.'>>/opt/oracle/db-step4.txt"
		echo "ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: $ORACLE_PWD";
	fi
	su -l oracle -c "echo 'delete this file to reinstall'>>/opt/oracle/dbinstalled.txt"
fi 

# run user-defined post-setup scripts
echo 'INSTALLER: Running user-defined post-setup scripts'

for f in /vagrant/userscripts/*
	do
		case "${f,,}" in
			*.sh)
				echo "INSTALLER: Running $f"
				. "$f"
				echo "INSTALLER: Done running $f"
				;;
			*.sql)
				echo "INSTALLER: Running $f"
				su -l oracle -c "echo 'exit' | sqlplus -s / as sysdba @\"$f\""
				echo "INSTALLER: Done running $f"
				;;
			/vagrant/userscripts/put_custom_scripts_here.txt)
				:
				;;
			*)
				echo "INSTALLER: Ignoring $f"
				;;
		esac
	done

echo 'INSTALLER: Done running user-defined post-setup scripts'


echo "INSTALLER: Installation complete, database ready to use!";
