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

# connect to node manager
nmConnect(weblogicUsername, weblogicPassword, hostAdminServer, '5556',weblogicDomain , dirUserProjectsPath + '/' + weblogicDomain,'SSL')
nmStart(nameOipaServer,'Server') 
nmStart(namePCServer,'Server')
exit()