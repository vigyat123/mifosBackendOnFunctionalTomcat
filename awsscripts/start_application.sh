#!/bin/bash

set -e

CATALINA_HOME='/usr/share/tomcat7-codedeploy'
DEPLOY_TO_ROOT='true'

TEMP_STAGING_DIR='/tmp/codedeploy-deployment-staging-area'
WAR_STAGED_LOCATION="$TEMP_STAGING_DIR/fineract-provider.war"

# In Tomcat, ROOT.war maps to the server root
if [[ "$DEPLOY_TO_ROOT" = 'true' ]]; then
    CONTEXT_PATH='fineract-provider'
fi
if [[ -f $CATALINA_HOME/webapps/$CONTEXT_PATH.war ]]; then
    rm $CATALINA_HOME/webapps/$CONTEXT_PATH.war
fi

if [[ -f $CATALINA_HOME/webapps/$CONTEXT_PATH.war ]]; then
    rm $CATALINA_HOME/webapps/$CONTEXT_PATH.war
fi

if [[ -d $CATALINA_HOME/webapps/$CONTEXT_PATH ]]; then
    rm -rfv $CATALINA_HOME/webapps/$CONTEXT_PATH
fi

# Copy the WAR file to the webapps directory
cp $WAR_STAGED_LOCATION $CATALINA_HOME/webapps
chmod 777 $CATALINA_HOME/webapps/$CONTEXT_PATH.war
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
url="jdbc:mysql://mifoslms-mysql.ciflb6pkogmo.ap-south-1.rds.amazonaws.com:3306/', mysqlUser, mysqlPassword, 'com.mysql.jdbc.Driver"
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
port="8443" maxThreads="200" scheme="https"
secure="true" SSLEnabled="true"
SSLCertificateFile="/usr/share/certfile.crt"
SSLCertificateKeyFile="/usr/share/keyfile.key"
clientAuth="false" sslProtocol="TLS"
URIEncoding="UTF-8"
compression="force"
compressableMimeType="text/html,text/xml,text/plain,text/javascript,text/css"/>

<Connector port="8080" connectionTimeout="20000" protocol="HTTP/1.1"/>
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

service tomcat7 start
