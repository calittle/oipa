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

echo 'INSTALLER: Started up 01-oipadb.sh'

# set up password for oipa/oipaivs
export ORACLE_PWD=${ORACLE_PWD:-"`openssl rand -base64 8`1"}

# unzip oipa DB installer.
unzip -n /vagrant/V997069-01.zip -d /home/oracle
chown oracle:oinstall -R /home/oracle

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
echo "INSTALLER: $USER_OIPA created with password $ORACLE_PWD";
echo "INSTALLER: $USER_IVS created with password $ORACLE_PWD";

# TODO --> set up TDE 

# import the dump files
su -l oracle -c "echo $ORACLE_PWD | impdp system@orclpdb1 directory=oipa_dir dumpfile=oipa_pas.dmp logfile=OIPA_PAS.log full=yes remap_schema=oipaqa:$USER_OIPA"
 
echo "INSTALLER: oipa_pas.dmp imported.";

su -l oracle -c "echo $ORACLE_PWD | impdp system@orclpdb1 directory=oipa_dir dumpfile=oipa_ivs.dmp logfile=OIPA_IVS.log full=yes remap_schema=oipa_ivs:$USER_IVS"

echo "INSTALLER: oipa_ivs.dmp imported.";

# TODO --> create read only user

echo "INSTALLER: 01-oipadb.sh complete.";