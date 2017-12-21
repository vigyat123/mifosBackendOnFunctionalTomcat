#!/bin/bash

set -e

# Apache TOMCAT Installation (Tar file name used is mentioned below)
TOMCAT7_CORE_TAR_FILENAME='apache-tomcat-7.0.72.tar.gz'
# Download URL for Tomcat7 core
TOMCAT7_CORE_DOWNLOAD_URL="https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.72/bin/$TOMCAT7_CORE_TAR_FILENAME"
# The top-level directory after unpacking the tar file
TOMCAT7_CORE_UNPACKED_DIRNAME='apache-tomcat-7.0.72'

# Location where Tomcat would be installed
CATALINA_HOME=/usr/share/tomcat7-codedeploy


# Check whether there exists a valid instance of Tomcat7 installed at the specified directory
[[ -d $CATALINA_HOME ]] && { service tomcat7 status; } && {
    echo "Tomcat7 is already installed at $CATALINA_HOME. Skip reinstalling it."
    exit 0
}

if [[ -f /usr/share/tomcat7-codedeploy/bin/setenv.sh ]]; then
    rm /usr/share/tomcat7-codedeploy/bin/setenv.sh
fi

# Making connection to the RDS instance
cat > /usr/share/tomcat7-codedeploy/bin/setenv.sh <<'EOF'
JAVA_OPTS="$JAVA_OPTS -Xms512m -Xmx1024m -DJDBC_CONNECTION_STRING=jdbc:mysql://mifoslms-mysql.ciflb6pkogmo.ap-south-1.rds.amazonaws.com:3306/mifosplatform-tenants -DJDBC_USER_NAME=root -DJDBC_PASSWORD=mysql"
EOF

# Clear install directory
if [ -d $CATALINA_HOME ]; then
    rm -rf $CATALINA_HOME
fi
mkdir -p $CATALINA_HOME

# Download the specifed Tomcat7 version
cd /tmp
{ which wget; } || { yum install wget; }
wget $TOMCAT7_CORE_DOWNLOAD_URL
if [[ -d /tmp/$TOMCAT7_CORE_UNPACKED_DIRNAME ]]; then
    rm -rf /tmp/$TOMCAT7_CORE_UNPACKED_DIRNAME
fi
tar xzf $TOMCAT7_CORE_TAR_FILENAME

# Copy over to the CATALINA_HOME
cp -r /tmp/$TOMCAT7_CORE_UNPACKED_DIRNAME/* $CATALINA_HOME

# To make Tomcat automatically start when we boot up the server, the below script should be 
# added to make it auto-start and shutdown.

cat > /etc/init.d/tomcat7 <<'EOF'
#!/bin/bash
# description: Tomcat7 Start Stop Restart
# processname: tomcat7
PATH=$JAVA_HOME/bin:$PATH
export PATH
CATALINA_HOME='/usr/share/tomcat7-codedeploy'
case $1 in
start)
sh $CATALINA_HOME/bin/startup.sh
;;
stop)
sh $CATALINA_HOME/bin/shutdown.sh
;;
restart)
sh $CATALINA_HOME/bin/shutdown.sh
sh $CATALINA_HOME/bin/startup.sh
;;
esac
exit 0
EOF

# Change permission mode for the service script
chmod 755 /etc/init.d/tomcat7
