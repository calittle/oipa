#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2022 Oracle and/or its affiliates. All rights reserved.
# 
# Since: March, 2022
# Author: andy.little@oracle.com
# Description: Installs OIPA database
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
if [ -f "/opt/oracle/oipadb.txt" ]; then
	 echo "INSTALLER: OIPA DB setup skipped. Delete /opt/oracle/oipadb.txt to reprovision."
else
	echo 'INSTALLER: Started up 01-oipadb.sh'
	
	# set up path for oraenv. Perhaps the shell needs to be reconnected so we need not do this.
	export PATH=/usr/local/bin:$PATH
	
	# set up password for oipa/oipaivs
	export ORACLE_PWD=${ORACLE_PWD:-"`openssl rand -base64 8`1"}
	echo "ORACLE PASSWORD FOR $USER_OIPA and $USER_IVS : $ORACLE_PWD";

	# unzip oipa DB installer.
	unzip -qn "/vagrant/${OIPADBZIP}" -d /home/oracle
	chown oracle:oinstall -R /home/oracle

	if [ -f "/opt/oracle/oipadb-step1.txt" ]; then
	 echo "INSTALLER: OIPA user setup skipped; delete /opt/oracle/oipadb-step1.txt to reprovision."
	else    

		# create users and import dir
		su -l oracle -c "sqlplus / as sysdba <<EOF
alter session set container=orclpdb1;
create user $USER_OIPA identified by \"$ORACLE_PWD\";
grant connect, resource to $USER_OIPA;
grant unlimited tablespace to $USER_OIPA;   
create user $USER_IVS identified by \"$ORACLE_PWD\";
grant connect, resource to $USER_IVS;
grant unlimited tablespace to $USER_IVS;
create directory oipa_dir as '/home/oracle';
grant read, write on directory oipa_dir to system;
exit;
EOF"
		su -l oracle -c "echo 'delete this file to recreate oipa users. Note you may need to drop everything that was created to redo this step!'>>/opt/oracle/oipadb-step1.txt"
	fi
	# TODO --> set up TDE 	
	export ORACLE_CDB=$ORACLE_SID
	export ORACLE_SID=$ORACLE_PDB
	export PATH=$ORACLE_HOME/bin:$PATH

	# import the dump files
	if [ -f "/opt/oracle/oipadb-step2.txt" ]; then
		echo "INSTALLER: OIPA DB import skipped; delete /opt/oracle/oipadb-step2.txt to reprovision."
	else    
		# a hack to force the errors to return true so shell provisioner doesn't crap the bed.
		cd /home/oracle
		echo "$ORACLE_PWD" | impdp system@$ORACLE_PDB  directory=oipa_dir dumpfile=oipa_pas.dmp logfile=import_pas.log full=yes remap_schema=oipaqa:$USER_OIPA &> impdp_pas.out | true;
		su -l oracle -c "echo 'delete this file to reimport oipa db. Note you may need to drop everything that was created to redo this step!'>>/opt/oracle/oipadb-step2.txt"
		echo "INSTALLER: oipa_pas.dmp imported. Check impdp_oipa.out for any notable errors as these will not be trapped!";		
	fi
	if [ -f "/opt/oracle/oipadb-step3.txt" ]; then
		echo "INSTALLER: OIPA IVS DB import skipped; delete /opt/oracle/oipadb-step3.txt to reprovision."
	else    		
		# a hack to force the errors to return true so shell provisioner doesn't crap the bed.
		cd /home/oracle
		echo "$ORACLE_PWD" | impdp system@$ORACLE_PDB directory=oipa_dir dumpfile=oipa_ivs.dmp logfile=OIPA_IVS.log full=yes remap_schema=oipa_ivs:$USER_IVS &> impdp_ivs.out | true;
		echo "INSTALLER: oipa_ivs.dmp imported. Check impdp_ivs.out for any notable errors as these will not be trapped!";
		su -l oracle -c "echo 'delete this file to reimport oipa ivs db. Note you may need to drop everything that was created to redo this step!'>>/opt/oracle/oipadb-step3.txt"
	fi
	export ORACLE_SID=$ORACLE_CDB

	chown oracle:oinstall -R /home/oracle
	# TODO --> create read only user

	echo "ORACLE PASSWORD FOR $USER_OIPA and $USER_IVS : $ORACLE_PWD";

	su -l oracle -c "echo 'delete this file to reimport OIPA database. Note you may need to drop everything that was created to redo this step!'>>/opt/oracle/oipadb.txt"
	echo "INSTALLER: 01-oipadb.sh complete.";
fi
