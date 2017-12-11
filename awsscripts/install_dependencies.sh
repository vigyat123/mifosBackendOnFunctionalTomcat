#!/bin/bash

set -e

CATALINA_HOME=/usr/share/tomcat7-codedeploy

# Tar file name
TOMCAT7_CORE_TAR_FILENAME='apache-tomcat-7.0.72.tar.gz'
# Download URL for Tomcat7 core
TOMCAT7_CORE_DOWNLOAD_URL="https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.72/bin/$TOMCAT7_CORE_TAR_FILENAME"
# The top-level directory after unpacking the tar file
TOMCAT7_CORE_UNPACKED_DIRNAME='apache-tomcat-7.0.72'
# curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash
# . ~/.nvm/nvm.sh
# nvm install 6.11.5

# Check whether there exists a valid instance
# of Tomcat7 installed at the specified directory
[[ -d $CATALINA_HOME ]] && { service tomcat7 status; } && {
    echo "Tomcat7 is already installed at $CATALINA_HOME. Skip reinstalling it."
    exit 0
}

# Clear install directory
if [ -d $CATALINA_HOME ]; then
    rm -rf $CATALINA_HOME
fi
mkdir -p $CATALINA_HOME

# Download the latest Tomcat7 version
cd /tmp
{ which wget; } || { yum install wget; }
wget $TOMCAT7_CORE_DOWNLOAD_URL
if [[ -d /tmp/$TOMCAT7_CORE_UNPACKED_DIRNAME ]]; then
    rm -rf /tmp/$TOMCAT7_CORE_UNPACKED_DIRNAME
fi
tar xzf $TOMCAT7_CORE_TAR_FILENAME

# Copy over to the CATALINA_HOME
cp -r /tmp/$TOMCAT7_CORE_UNPACKED_DIRNAME/* $CATALINA_HOME
sudo keytool -genkey -keyalg RSA -alias tomcat -keystore /usr/share/tomcat.keystore
#sudo nano /usr/share/tomcat7-codedeploy/conf/server.xml 
if [[ -f /usr/share/tomcat7-codedeploy/conf/server.xml ]]; then
    rm /usr/share/tomcat7-codedeploy/conf/server.xml
fi
cat > /usr/share/tomcat7-codedeploy/conf/server.xml <<'EOF'
<?xml version='1.0' encoding='utf-8'?>
<Server port="8005" shutdown="SHUTDOWN">
<Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
<Listener className="org.apache.catalina.core.JasperListener" />
<Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
<Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
<Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />
<GlobalNamingResources>
<Resource name="UserDatabase" auth="Container"
type="org.apache.catalina.UserDatabase"
description="User database that can be updated and saved"
factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
pathname="conf/tomcat-users.xml" />

<Resource type="javax.sql.DataSource"
name="jdbc/mifosplatform-tenants"
factory="org.apache.tomcat.jdbc.pool.DataSourceFactory"
driverClassName="org.drizzle.jdbc.DrizzleDriver"
url="jdbc:mysql://mifoslms-mysql.ciflb6pkogmo.ap-south-1.rds.amazonaws.com:3306/mifostenant-default"
username="root"
password="mysql"
initialSize="3"
maxActive="10"
maxIdle="6"
minIdle="3"
validationQuery="SELECT 1"
testOnBorrow="true"
testOnReturn="true"
testWhileIdle="true"
timeBetweenEvictionRunsMillis="30000"
minEvictableIdleTimeMillis="60000"
logAbandoned="true"
suspectTimeout="60"
/>
</GlobalNamingResources>
<Service name="Catalina"> 
<Connector protocol="org.apache.coyote.http11.Http11Protocol"
port="443" maxThreads="200" scheme="https"
secure="true" SSLEnabled="true"
keystoreFile="/usr/share/tomcat.keystore"
keystorePass="xyz123"
clientAuth="false" sslProtocol="TLS"
URIEncoding="UTF-8"
compression="force"
compressableMimeType="text/html,text/xml,text/plain,text/javascript,text/css"/>
<Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />
<Engine name="Catalina" defaultHost="localhost">
<Realm className="org.apache.catalina.realm.LockOutRealm">
<Realm className="org.apache.catalina.realm.UserDatabaseRealm"
resourceName="UserDatabase"/>
</Realm>
<Host name="localhost" appBase="webapps"
unpackWARs="true" autoDeploy="true">
<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
prefix="localhost_access_log." suffix=".txt"
pattern="%h %l %u %t &quot;%r&quot; %s %b" />
</Host>
</Engine>
</Service>
</Server>
EOF

# Change permission mode for the service script
chmod 755 /etc/init.d/tomcat7
sudo ln -s /etc/init.d/tomcat7 /etc/rc1.d/K99tomcat
sudo ln -s /etc/init.d/tomcat7 /etc/rc2.d/S99tomcat

#export CLASSPATH=/path/mysql-connector-java-ver-bin.jar:$CLASSPATH
