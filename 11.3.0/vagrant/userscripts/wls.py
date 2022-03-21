#
# LICENSE UPL 1.0
#
# Copyright (c) 2018, 2020 Oracle and/or its affiliates.
#
# Since: March, 2022
# Author: andy.little@oracle.com, steven.saunders@oracle.com
# Description: Create WebLogic domain and resources for OIPA 11.3.0
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#


def createJDBCDatasource(  jdbcName, jdbcJNDIName, dbUser, dbPassword, dbHost, dbPort, dbName, dbNameType, targetName ) :
	readDomain( dirDomain ); 
	print( '  ' + jdbcName );	
	cd( '/' );	
	create( jdbcName , 'JDBCSystemResource' );	
	cd( '/JDBCSystemResources/' +  jdbcName +'/JdbcResource/' + jdbcName );
	
	create( 'myJdbcDriverParams', 'JDBCDriverParams' );
	cd( 'JDBCDriverParams/NO_NAME_0' );
	
	if dbNameType == "ServiceName" :
		dbJdbcURL= 'jdbc:oracle:thin:@//' + dbHost + ':' + dbPort + '/' + dbName;
	else:
		dbJdbcURL= 'jdbc:oracle:thin:@' + dbHost + ':' + dbPort + ':' + dbName;
	
	set( 'DriverName', 'oracle.jdbc.OracleDriver' );
	set( 'URL', dbJdbcURL );
	set( 'PasswordEncrypted', dbPassword );
	
	create( 'myProps', 'Properties' );
	cd( 'Properties/NO_NAME_0' );
	create( 'user',  'Property' );
	cd( 'Property/user' );
	cmo.setValue( dbUser );
	
	cd( '/JDBCSystemResources/' +  jdbcName +'/JdbcResource/' + jdbcName );
	
	create( 'myJdbcDataSourceParams', 'JDBCDataSourceParams' );
	cd( 'JDBCDataSourceParams/NO_NAME_0');
	set( 'JNDIName', jdbcJNDIName );
	set( 'GlobalTransactionsProtocol', 'None' );
	
	cd( '/JDBCSystemResources/' +  jdbcName +'/JdbcResource/' + jdbcName );
	
	create( 'myJdbcConnectionPoolParams', 'JDBCConnectionPoolParams' );
	cd( 'JDBCConnectionPoolParams/NO_NAME_0' );
	set( 'TestTableName', 'SQL SELECT 1 FROM DUAL' );
	set( 'MaxCapacity', 300 );
	
	cd( '/JDBCSystemResources/' +  jdbcName +'/JdbcResource/' + jdbcName );
	
	cd( '/JDBCSystemResources/' +  jdbcName  );
	set( 'Target', targetName );
	
	updateDomain();

def createJMSServer( serverName, defaultPort, sslPort ) :
	print 'INFO: Creating Managed Server=<' + serverName + '>, ports: ' + defaultPort + ', ' + sslPort;
	jvmArgs = None;
	try:
		if jvmArgsJMSServer is not None:
			jvmArgs=str(jvmArgsJMSServer);
	except:
		print ' ERROR: No property jvmArgsJMSServer defined, skipping applying JVM Arguments to managed server=<' + serverName + '>!'

	dirDomain= getDomainDir()
	readDomain( dirDomain ); 

	try:
		cd('/');
		create( serverName, 'Server');
		cd('/Servers/' + serverName );
		set( 'ListenPort', int(defaultPort) );
		create( serverName, 'SSL' );
		cd('/Servers/'+ serverName + '/SSL/' + serverName );
		set( 'ListenPort', int(sslPort) );
		set( 'Enabled', 'True');
		cd( '/Servers/'+serverName );
	except:
		print 'ERROR: Server  ' + serverName + ' might already exist, skipping create server!'

	try:
		if jvmArgs is not None:
			print '  INFO: Setting Managed Server=<' + serverName + '> JVM Arguments to=<' + jvmArgs +  '>';
			create( serverName,'ServerStart');
			cd('/Server/'+serverName+'/ServerStart/NO_NAME_0');
			set('Arguments',jvmArgs );
	except:
		print ' ERROR: Could not apply JVM args=<' + jvmArgs + '> to Managed Server=<' + serverName + '>!'

	try:
		if nameCluster is not None:
			print '  INFO: Setting Managed Server=<' + serverName + '> WebLogic Cluster to <' + nameCluster +  '>';
			wlc = find_weblogic_cluster(dirDomain, nameCluster, false);
			if( len(wlc) > 0 ):
				cd('/Server/'+serverName);
				set('Cluster', nameCluster);
			else:
				print '  ERROR: WebLogic Cluster <' + nameCluster +  '> not found, skipping!  Available WebLogic Clusters are: ' + str(display_weblogic_clusters(dirDomain,false));
	except:
		print ' ERROR: Could not target WebLogic Cluster=<' + nameCluster + '> to Managed Server=<' + serverName + '>!'

	try:
		if nameMachine is not None:
			print '  INFO: Setting Managed Server=<' + serverName + '> Machine to <' + nameMachine +  '>';
			mch = find_machine(dirDomain, nameMachine, false);
			if( len(mch) > 0 ):
				cd('/Server/'+serverName);
				set('Machine', nameMachine);
			else:
				print '  ERROR: Machine <' + nameMachine +  '> not found, skipping!  Available Machines are: ' + str(display_machines(dirDomain,false));
	except:
		print ' ERROR: Could not target Machine=<' + nameMachine + '> to Server=<' + serverName + '>!'

	try:
		if nameCoherenceCluster is not None:
			print '  INFO: Setting Managed Server=<' + serverName + '> Coherence Cluster to <' + nameCoherenceCluster +  '>';
			coh = find_coherence_cluster(dirDomain, nameCoherenceCluster, false);
			if( len(coh) > 0 ):
				cd('/Server/'+serverName);
				set('CoherenceClusterSystemResource', nameCoherenceCluster);
			else:
				print '  ERROR: Coherence Cluster <' + nameCoherenceCluster +  '> not found, skipping!  Available Coherece Clusters are: ' + str(display_coherence_clusters(dirDomain,false));
	except:
		print ' ERROR: Could not target Coherence Cluster=<' + nameCoherenceCluster + '> to Managed Server=<' + serverName + '>.'

	try:
		updateDomain();
	except:
		print ' ERROR: Cound not updateDomain(), for Managed Server=<' + serverName + '>, might already exist! Skipping create server'
	closeDomain();

	print ' INFO: Applying JRF to Managed Server=<' + serverName + '>';
	try:
		readDomain( dirDomain ); 
		applyJRF( serverName, dirDomain );
	except:
		print ' ERROR: Cound not apply JRF to Managed Server=<' + serverName + '>!'
	closeDomain();

	#applying Data Sources 
	try:
		readDomain( dirDomain ); 
		print ' INFO: Adding Data Source targets to Managed Server=<' + serverName + '>';
		changeDocumakerDatasourceTargets( jdbcAdminUsername, serverName );
		updateDomain();
	except:
		print ' ERROR: Cound not target Data Sources to Managed Server=<' + serverName + '>!'
	closeDomain();
	
	print;

#####################################################################################################################
#####################################################################################################################
#####################################################################################################################


#
# Load the wls.properties file, a name/value pairs file.
# names are converted to variables in jython.
#
f = open( "wls.properties", 'r' )
line = f.readline()
while line:
	if len(line) > 3 :
		s = line.find( "=" )
		if( line[0] != '#' and s > -1 ) :
			propVariable = (line.split("=",1))[0];
			propValue = (line.split("=",1))[1];
			propValue = propValue.strip();
			if not propValue:
				newProperty = "global " + propVariable + ";\n" + propVariable + '=None';
			else:
				newProperty = "global " + propVariable + ";\n" + propVariable + '="' + propValue + '"';
			exec( newProperty );			
	line = f.readline()
f.close()	

dirDomain= dirUserProjectsPath + '/' + weblogicDomain;

wlsTemplate = dirWeblogicHome + '/' + dirWeblogicTemplates + '/wls.jar';
jrfTemplate = dirWeblogicHome + '/' + dirCommon + '/common/templates/wls/oracle.jrf_template.jar' ;
emTemplate = dirWeblogicHome + '/' + dirEM + '/common/templates/wls/oracle.em_wls_template.jar' ;
createDomain( wlsTemplate, dirDomain, weblogicUsername, weblogicPassword );
readDomain( dirDomain ); 
addTemplate( jrfTemplate ); 
addTemplate( emTemplate ); 
updateDomain();

cd('/');
create( nameOipaServer, 'Server');
cd('/Servers/' + nameOipaServer );
set( 'ListenPort', portOipaServer );
cd('/Server/'+nameOipaServer+'/ServerStart/NO_NAME_0');
set('Arguments',jvmArgsOipaServer );
set('ClassPath',jvmClassPathOipaServer );
create( nameOipaServer, 'SSL');
cd('/Servers/' + nameOipaServer + '/SSL/' + nameOipaServer );
set( 'ListenPort', portSslOipaServer );
set( 'Enabled', 'True');

cd('/');
create( namePCServer, 'Server');
cd('/Servers/' + namePCServer );
set( 'ListenPort', portPCServer );
cd('/Server/'+namePCServer+'/ServerStart/NO_NAME_0');
set('Arguments',jvmArgsPCServer );
set('ClassPath',jvmClassPathPCServer );
create( namePCServer, 'SSL');
cd('/Servers/' + namePCServer + '/SSL/' + namePCServer );
set( 'ListenPort', portSslPCServer );
set( 'Enabled', 'True');

cd('/')
create(nameMachine,'UnixMachine')
assign('Server', 'oipa_server','paletteconfig_server','Machine',nameMachine)
cd('/UnixMachine/' + nameMachine)
create(nameMachine, 'NodeManager')
cd('NodeManager/' + nameMachine)
set('NMType','SSL')
set('ListenAddress', 'localhost')
set('ListenPort', 5556)
set('DebugEnabled','false')

updateDomain()

createJDBCDatasource( 'ADMINSERVERDS_0', 'jdbc/ADMINSERVERDS',  jdbcOipaUser, jdbcOipaPwd, 'localhost', '1521', 'orclpdb1','ServiceName', nameOipaServer );
createJDBCDatasource( 'ADMINSERVERRESOURCEDS_0', 'jdbc/ADMINSERVERRESOURCEDS',  jdbcOipaUser, jdbcOipaPwd, 'localhost', '1521', 'orclpdb1','ServiceName', nameOipaServer );
createJDBCDatasource( 'ADMINSERVERSEARCHDS_0', 'jdbc/ADMINSERVERSEARCHDS',  jdbcOipaUser, jdbcOipaPwd, 'localhost', '1521', 'orclpdb1','ServiceName', nameOipaServer );
createJDBCDatasource( 'ADMINSERVERREADONLYDS_0', 'jdbc/ADMINSERVERREADONLYDS',  jdbcOipaUser, jdbcOipaPwd, 'localhost', '1521', 'orclpdb1','ServiceName', nameOipaServer );
createJDBCDatasource( 'PALETTECONFIGDS_0', 'jdbc/PALETTECONFIGDS',  jdbcOipaUser, jdbcOipaPwd, 'localhost', '1521', 'orclpdb1','ServiceName', namePCServer );
createJDBCDatasource( 'PALETTECONFIGIVSDS_0', 'jdbc/PALETTECONFIGIVSDS',  jdbcIvsUser, jdbcIvsPwd, 'localhost', '1521', 'orclpdb1','ServiceName', namePCServer);
# #create_cluster_offline(getDomainDir(),None, namejmsCluster, None);
# createJMSServer( nameJmsServer, portJmsServer, portJmsSslServer );
# createDocumakerJMSResources( nameJmsServer );
cd( '/' );
create( nameOipaApp, 'AppDeployment' );
cd( '/AppDeployment/' + nameOipaApp );
set( 'Target', nameOipaServer ); 
set( 'ModuleType', 'war' ); 
set( 'DeploymentOrder', 100 ); 
set( 'SourcePath', dirOipaHome +'/PASJava-weblogic.war' ); 
set( 'SecurityDDModel', 'DDOnly' ); 
cd( '/' );
create( namePCApp, 'AppDeployment' );
cd( '/AppDeployment/'+namePCApp );
set( 'Target', namePCServer ); 
set( 'ModuleType', 'war' ); 
set( 'DeploymentOrder', 100 ); 
set( 'SourcePath', dirPCHome +'/PaletteConfig.war' ); 
set( 'SecurityDDModel', 'DDOnly' ); 
cd('/AppDeployments')
# Hiding WSDL getting published
# Login to Console
# Go to OIPA managed server, click Deployments tab
# Click Deployed Application, here in this case PASJava, the application tree expends
# Select first WebService
# Go to its configuration, under General tab Unchecked View Dynamic WSDL Enabled
# Follow step 5 to 7 for remaining web services
updateDomain()
closeDomain()
