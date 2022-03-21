#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2022 Oracle and/or its affiliates. All rights reserved.
# 
# Since: March, 2022
# Author: andy.little@oracle.com
# Description: Installs JDK 1.8, WebLogic, others.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Abort on any error
set -e

echo 'INSTALLER: Started up 02-weblogic.sh'
#echo LANG=en_US.utf-8 >> /etc/environment

# Setup password if not already provided.
export WLS_PWD=${WLS_PWD:-"`openssl rand -base64 8`1"}

export OIPA_HOME=$ORACLE_HOME/applications/oipa
export PC_HOME=$ORACLE_HOME/applications/paletteconfig

# create directories
mkdir -p $MW_HOME
mkdir -p $ORACLE_HOME/domains
mkdir -p $OIPA_HOME
mkdir -p $PC_HOME
echo 'INSTALLER: OIPA directories created'

# set environment variables
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc
echo "export MW_HOME=$MW_HOME" >> /home/oracle/.bashrc
echo "export WLS_HOME=$MW_HOME/wlserver" >> /home/oracle/.bashrc
echo "export WL_HOME=$WLS_HOME" >> /home/oracle/.bashrc
echo "export JAVA_HOME=$JAVA_PATH" >> /home/oracle/.bashrc
echo "export PATH=$JAVA_HOME/bin:\$PATH" >> /home/oracle/.bashrc
echo "export OIPA_HOME=\$OIPA_HOME" >> /home/oracle/.bashrc
echo "export PC_HOME=\$PC_HOME" >> /home/oracle/.bashrc
echo 'INSTALLER: Environment variables set'

# Install JDK 1.8
rpm -ivh /vagrant/jdk-$JAVA_VERSION-linux-x64.rpm
echo 'INSTALLER: JDK installed'

# Install WLS
unzip -n /vagrant/fmw_$WLS_VERSION_wls_lite_Disk1_1of1.zip -d /home/oracle
chown oracle:oinstall -R /home/oracle
cp /vagrant/ora-response/wls.rsp.tmpl /vagrant/ora-response/wls.rsp
sed -i -e "s|###MW_HOME###|$MW_HOME|g" /vagrant/ora-response/wls.rsp
su -l oracle -c "java -jar fmw_$WLS_VERSION_wls_lite_generic.jar -silent -responseFile /vagrant/ora-response/wls.rsp -invPtrLoc $ORACLE_HOME/oraInventory/oraInst.loc"
echo 'INSTALLER: WebLogic installed.'

# Prepare OIPA by unzipping to target directory, and downloading external files to lib.
unzip -n /vagrant/V997071.zip -d $OIPA_HOME
mkdir -p /vagrant/tmp
wget -O /vagrant/tmp/aspectj-1.8.10.jar $ASPECTJ_URL
unzip /vagrant/tmp/aspectj-1.8.10.jar -d /vagrant/tmp
mv /vagrant/tmp/lib/aspectjweaver.jar $OIPA_HOME/lib
mv /vagrant/tmp/lib/aspectjrt.jar $OIPA_HOME/lib
wget -O $OIPA_HOME/lib/log4j-1.2.17.jar $LOG4J_URL

cp $MW_HOME/oracle_common/modules/oracle.osdt/osdt_core.jar $OIPA_HOME/lib
cp $MW_HOME/oracle_common/modules/oracle.osdt/osdt_cert.jar $OIPA_HOME/lib
cp $MW_HOME/oracle_common/modules/oracle.pki/oraclepki.jar $OIPA_HOME/lib
cp $MW_HOME/coherence/lib/coherence.jar $OIPA_HOME/lib

# edit some conf files.
sed -i -e "s|D:/logs/oipa%u.log|$OIPA_HOME/oipa%u.log|g" $OIPA_HOME/conf/logging.properties

# Prepare PaletteConfig 
unzip -n /vagrant/V997078-01.zip -d /vagrant/tmp
mkdir -p $PC_HOME/conf
mkdir -p $PC_HOME/lib
mkdir -p $PC_HOME/uploads
mv /vagrant/tmp/PaletteConfig/PaletteConfig-weblogic.war $PC_HOME/PaletteConfig.war 
mv /vagrant/tmp/PaletteConfig/PaletteWebApplication.properties $PC_HOME/conf
echo "download.dir=$PC_HOME/uploads" >> $PC_HOME/conf/PaletteWebApplication.properties

# clean up
rm -rf /vagrant/tmp
chown oracle:oinstall -R $ORACLE_HOME/applications

# Create WLS domain
cp /vagrant/ora-response/wls.properties.tmpl /vagrant/userscripts/wls.properties
sed -i -e "s|###ADMINPORT###|$WLS_ADMINPORT|g" /vagrant/userscripts/wls.properties
sed -i -e "s|###OIPAPORT###|$WLS_OIPAPORT|g" /vagrant/userscripts/wls.properties
sed -i -e "s|###PCPORT###|$WLS_PALETTECONFIGPORT|g" /vagrant/userscripts/wls.properties
sed -i -e "s|###OIPASSLPORT###|$WLS_SSLOIPAPORT|g" /vagrant/userscripts/wls.properties
sed -i -e "s|###PCPSSLORT###|$WLS_SSLPALETTECONFIGPORT|g" /vagrant/userscripts/wls.properties
sed -i -e "s|###MW_DOMAIN###|$MW_DOMAIN|g" /vagrant/userscripts/wls.properties
sed -i -e "s|###WLS_PWD###|$WLS_PWD|g" /vagrant/userscripts/wls.properties
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" /vagrant/userscripts/wls.properties
sed -i -e "s|###LISTENER_PORT###|$LISTENER_PORT|g" /vagrant/userscripts/wls.properties

sed -i -e "s|###OIPA_HOME###|$OIPA_HOME|g" /vagrant/userscripts/wls.properties
sed -i -e "s|###PC_HOME###|$PC_HOME|g" /vagrant/userscripts/wls.properties

sed -i -e "s|###DB_OIPA_USER###|$USER_OIPA|g" /vagrant/userscripts/wls.properties
sed -i -e "s|###DB_OIPA_PWD###|$ORACLE_PWD|g" /vagrant/userscripts/wls.properties
sed -i -e "s|###DB_IVS_USER###|$USER_IVS|g" /vagrant/userscripts/wls.properties
sed -i -e "s|###DB_IVS_PWD###|$ORACLE_PWD|g" /vagrant/userscripts/wls.properties     

export PATH=$MW_HOME/wlserver/common/bin:$PATH

wlst.sh wls.py

echo 'INSTALLER: WebLogic domain created.'

# Install WLS Services
cp /vagrant/ora-response/wls_nm.service.tmpl /etc/systemd/system/wls_nm.service
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /etc/systemd/system/wls_nm.service
sed -i -e "s|###MW_DOMAIN###|$MW_DOMAIN|g" /etc/systemd/system/wls_nm.service

cp /vagrant/ora-response/wls_admin.service.tmpl /etc/systemd/system/wls_admin.service
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /etc/systemd/system/wls_admin.service
sed -i -e "s|###MW_DOMAIN###|$MW_DOMAIN|g" /etc/systemd/system/wls_admin.service

sudo systemctl daemon-reload
sudo systemctl enable wls_nm
sudo systemctl enable wls_admin
sudo systemctl start wls_nm
sudo systemctl start wls_admin

rm /vagrant/ora-response/wls.rsp
rm /vagrant/userscripts/wls.properties

echo 'INSTALLER: WebLogic services started.'
echo "PASSWORD FOR WEBLOGIC: $WLS_PWD";
echo "INSTALLER: Installation complete.";
