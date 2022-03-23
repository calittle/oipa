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
if [ -f "/opt/oracle/weblogic.txt" ]; then
	 echo "INSTALLER: WebLogic skipped. Delete /opt/oracle/weblogic.txt to attempt reprovision steps."

else

	echo 'INSTALLER: Started up 02-weblogic.sh'
	#echo LANG=en_US.utf-8 >> /etc/environment

	# Setup password if not already provided.
	export WLS_PWD=${WLS_PWD:-"`openssl rand -base64 8`1"}
	echo "INSTALLER: PASSWORD FOR WebLogic : $WLS_PWD";

	export OIPA_HOME=$ORACLE_BASE/applications/oipa
	export PC_HOME=$ORACLE_BASE/applications/paletteconfig

	# create directories
	mkdir -p $MW_HOME
	mkdir -p $ORACLE_BASE/domains
	mkdir -p $OIPA_HOME
	mkdir -p $PC_HOME
	chown oracle:oinstall $MW_HOME
	chown oracle:oinstall $ORACLE_BASE/domains
	chown oracle:oinstall $OIPA_HOME
	chown oracle:oinstall $PC_HOME
	echo 'INSTALLER: OIPA directories created'

	# set environment variables
	if grep -q PC_HOME /home/oracle/.bashrc; then
		echo 'INSTALLER: Environment variables previously set; retaining.'
	else
		echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc
		echo "export MW_HOME=$MW_HOME" >> /home/oracle/.bashrc
		echo "export WLS_HOME=$MW_HOME/wlserver" >> /home/oracle/.bashrc
		echo "export WL_HOME=$WLS_HOME" >> /home/oracle/.bashrc
		echo "export JAVA_HOME=$JAVA_PATH" >> /home/oracle/.bashrc
		echo "export JAVA_HOME=$JAVA_PATH" >> /root/.bashrc
		echo "export PATH=$JAVA_HOME/bin:\$PATH" >> /home/oracle/.bashrc
		echo "export OIPA_HOME=$OIPA_HOME" >> /home/oracle/.bashrc
		echo "export PC_HOME=$PC_HOME" >> /home/oracle/.bashrc
		echo 'INSTALLER: Environment variables set'
	fi

	# Install JDK 1.8
	if [ -f "$JAVA_HOME/bin/java" ]; then
		echo 'INSTALLER: JDK is already installed'
	else
		rpm -ivh /vagrant/jdk-$JAVA_VERSION-linux-x64.rpm
		echo 'INSTALLER: JDK installed'
	fi
	if [ -f "/opt/oracle/weblogic-step1.txt" ]; then
		 echo "INSTALLER: WebLogic installation skipped. Delete /opt/oracle/weblogic-step1.txt to reprovision."
	else
		# Install WLS
		echo "INSTALLER: Installing WebLogic version $WLS_VERSION"
		unzip -qn "/vagrant/fmw_${WLS_VERSION}_wls_lite_Disk1_1of1.zip" -d /home/oracle
		chown oracle:oinstall -R /home/oracle
		cp /vagrant/ora-response/wls.rsp.tmpl /vagrant/ora-response/wls.rsp
		sed -i -e "s|###MW_HOME###|$MW_HOME|g" /vagrant/ora-response/wls.rsp
		# fix oraInv permissions, which were weird for some reason.
		chown oracle:oinstall -R "$ORACLE_BASE/oraInventory"
		su -l oracle -c "java -jar fmw_${WLS_VERSION}_wls_lite_generic.jar -silent -responseFile /vagrant/ora-response/wls.rsp -invPtrLoc $ORACLE_BASE/oraInventory/oraInst.loc"
		su -l oracle -c "echo 'delete this file to reinstall WebLogic. Note you may need to manually remove everything that was created to redo this step!'>>/opt/oracle/weblogic-step1.txt"
		rm /vagrant/ora-response/wls.rsp
		echo 'INSTALLER: WebLogic installed.'
	fi
	if [ -f "/opt/oracle/weblogic-step2.txt" ]; then
		 echo "INSTALLER: OIPA web application prep skipped. Delete /opt/oracle/weblogic-step2.txt to reprovision."
	else
		
		# Prepare OIPA by unzipping to target directory, and downloading external files to lib.
		unzip -qn "/vagrant/${OIPAWLSZIP}" -d $OIPA_HOME
		mkdir -p /vagrant/tmp
		wget -q -O /vagrant/tmp/aspectj-1.8.10.jar "$ASPECTJ_URL" 
		unzip -qn /vagrant/tmp/aspectj-1.8.10.jar -d /vagrant/tmp		
		wget -q -O $OIPA_HOME/lib/log4j-1.2.17.jar "$LOG4J_URL"
		mv /vagrant/tmp/lib/aspectjweaver.jar $OIPA_HOME/lib
		mv /vagrant/tmp/lib/aspectjrt.jar $OIPA_HOME/lib		
		cp $MW_HOME/oracle_common/modules/oracle.osdt/osdt_core.jar $OIPA_HOME/lib
		cp $MW_HOME/oracle_common/modules/oracle.osdt/osdt_cert.jar $OIPA_HOME/lib
		cp $MW_HOME/oracle_common/modules/oracle.pki/oraclepki.jar $OIPA_HOME/lib
		cp $MW_HOME/coherence/lib/coherence.jar $OIPA_HOME/lib

		# edit some conf files.
		sed -i -e "s|D:/logs/oipa%u.log|$OIPA_HOME/oipa%u.log|g" $OIPA_HOME/conf/logging.properties

		# Prepare PaletteConfig 
		unzip -qn "/vagrant/${PCZIP}" -d /vagrant/tmp
		mkdir -p $PC_HOME/conf
		mkdir -p $PC_HOME/lib
		mkdir -p $PC_HOME/uploads
		mv /vagrant/tmp/PaletteConfig/PaletteConfig-weblogic.war $PC_HOME/PaletteConfig.war 
		mv /vagrant/tmp/PaletteConfig/PaletteWebApplication.properties $PC_HOME/conf
		echo "download.dir=$PC_HOME/uploads" >> $PC_HOME/conf/PaletteWebApplication.properties

		# clean up
		rm -rf /vagrant/tmp
		chown oracle:oinstall -R $ORACLE_HOME
		su -l oracle -c "echo 'delete this file to rerun OIPA web application preparation.'>>/opt/oracle/weblogic-step2.txt"
	fi
	if [ -f "/opt/oracle/weblogic-step3.txt" ]; then
		 echo "INSTALLER: WebLogic OIPA domain creation skipped. Delete /opt/oracle/weblogic-step3.txt to reprovision."
	else

		# Create WLS domain
		cp /vagrant/ora-response/wls.properties.tmpl /vagrant/userscripts/wls.properties
		sed -i -e "s|###OIPA_HOME###|$OIPA_HOME|g" /vagrant/userscripts/wls.properties
		sed -i -e "s|###PC_HOME###|$PC_HOME|g" /vagrant/userscripts/wls.properties

		sed -i -e "s|###ADMINPORT###|$WLS_ADMINPORT|g" /vagrant/userscripts/wls.properties
		sed -i -e "s|###OIPAPORT###|$WLS_OIPAPORT|g" /vagrant/userscripts/wls.properties
		sed -i -e "s|###PCPORT###|$WLS_PALETTECONFIGPORT|g" /vagrant/userscripts/wls.properties
		
		sed -i -e "s|###OIPASSLPORT###|$WLS_SSLOIPAPORT|g" /vagrant/userscripts/wls.properties
		sed -i -e "s|###PCSSLPORT###|$WLS_SSLPALETTECONFIGPORT|g" /vagrant/userscripts/wls.properties

		sed -i -e "s|###MW_DOMAIN###|$MW_DOMAIN|g" /vagrant/userscripts/wls.properties
		sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /vagrant/userscripts/wls.properties
		sed -i -e "s|###MW_HOME###|$MW_HOME|g" /vagrant/userscripts/wls.properties
		sed -i -e "s|###WLS_PWD###|$WLS_PWD|g" /vagrant/userscripts/wls.properties
		
		sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" /vagrant/userscripts/wls.properties
		sed -i -e "s|###LISTENER_PORT###|$LISTENER_PORT|g" /vagrant/userscripts/wls.properties		
		sed -i -e "s|###DB_OIPA_USER###|$USER_OIPA|g" /vagrant/userscripts/wls.properties
		sed -i -e "s|###DB_OIPA_PWD###|$ORACLE_PWD|g" /vagrant/userscripts/wls.properties
		sed -i -e "s|###DB_IVS_USER###|$USER_IVS|g" /vagrant/userscripts/wls.properties
		sed -i -e "s|###DB_IVS_PWD###|$ORACLE_PWD|g" /vagrant/userscripts/wls.properties     


		if [ -d "$ORACLE_BASE/domains/$MW_DOMAIN" ]; then
			echo "INSTALLER: removing existing WebLogic domain at $ORACLE_BASE/domains/$MW_DOMAIN"
			rm -rf "$ORACLE_BASE/domains/$MW_DOMAIN"
		fi
		su -l oracle -c "cd /vagrant/userscripts && $MW_HOME/oracle_common/common/bin/wlst.sh wls.py"		
		
		echo 'INSTALLER: WebLogic domain created.'
		su -l oracle -c "echo 'delete this file to rerun WebLogic OIPA domain creation. '>>/opt/oracle/weblogic-step3.txt"
	fi
	if [ -f "/opt/oracle/weblogic-step4.txt" ]; then
		 echo "INSTALLER: WebLogic service registration skipped. Delete /opt/oracle/weblogic-step4.txt to reprovision."
	else

		# Install WLS Services
		cp /vagrant/ora-response/wls_nm.service.tmpl /etc/systemd/system/wls_nm.service
		sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /etc/systemd/system/wls_nm.service
		sed -i -e "s|###MW_DOMAIN###|$MW_DOMAIN|g" /etc/systemd/system/wls_nm.service

		cp /vagrant/ora-response/wls_admin.service.tmpl /etc/systemd/system/wls_admin.service
		sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /etc/systemd/system/wls_admin.service
		sed -i -e "s|###MW_DOMAIN###|$MW_DOMAIN|g" /etc/systemd/system/wls_admin.service

		sudo systemctl daemon-reload
		sudo systemctl enable wls_nm
		sudo systemctl enable wls_admin
		sudo systemctl start wls_nm
		sudo systemctl start wls_admin
		
		echo 'INSTALLER: WebLogic services started. '
		echo '	To check status of services :'
		echo '		$ sudo systemctl status wls_nm';
		echo '		$ sudo systemctl status wls_admin';
		echo '	To check stop/start services :'
		echo '		$ sudo systemctl stop wls_nm';
		echo '		$ sudo systemctl start wls_admin';
		echo "	To access the WebLogic adminstration console, browse to http://localhost:7001/console on your host machine and login with weblogic/$WLS_PWD";

		su -l oracle -c "echo 'delete this file to reinstall WebLogic services.'>>/opt/oracle/weblogic-step4.txt"
	fi	
	# if [ -f "/opt/oracle/weblogic-step5.txt" ]; then
	# 	echo "INSTALLER: WebLogic server start skipped. Delete /opt/oracle/weblogic-step5.txt to rerun this step."
	# else		
	# 	su -l oracle -c "cd /vagrant/userscripts && $MW_HOME/oracle_common/common/bin/wlst.sh nm.py"
	# 	echo 'INSTALLER: Managed servers started.'
	# 	echo '!!!!!!!! FOR SECURITY PURPOSES YOU SHOULD REMOVE THE /vagrant/userscripts/wls.properties FILE AS THIS CONTAINS PASSWORDS !!!!!!'
	# 	echo 'Note that you will have to recreate this file to reprovision, or remove weblogic-step3.txt and weblogic.txt to get it recreated.'
	# 	su -l oracle -c "echo 'delete this file to start WebLogic servers; or just use WebLogic console.'>>/opt/oracle/weblogic-step5.txt"
	# fi
	
	[ -f "/vagrant/userscripts/wls.properties" ] && rm /vagrant/userscripts/wls.properties	
	su -l oracle -c "echo 'delete this file to reinstall WebLogic. Note you may need to manually remove everything that was created to redo this step!'>>/opt/oracle/weblogic.txt"
fi 