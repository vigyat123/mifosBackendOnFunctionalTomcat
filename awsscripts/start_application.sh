#!/bin/bash

set -e

CATALINA_HOME='/usr/share/tomcat7-codedeploy'
DEPLOY_TO_ROOT='true'
#CONTEXT_PATH='##CONTEXT_PATH##'
SERVER_HTTP_PORT='8080'

TEMP_STAGING_DIR='/tmp/codedeploy-deployment-staging-area'
WAR_STAGED_LOCATION="$TEMP_STAGING_DIR/fineract-provider.war"

# In Tomcat, ROOT.war maps to the server root
if [[ "$DEPLOY_TO_ROOT" = 'true' ]]; then
    CONTEXT_PATH='ROOT'
fi

# Remove unpacked application artifacts
if [[ -f $CATALINA_HOME/webapps/fineract-provider.war ]]; then
    rm $CATALINA_HOME/webapps/fineract-provider.war
fi
#if [[ -d $CATALINA_HOME/webapps/$CONTEXT_PATH ]]; then
#   rm -rfv $CATALINA_HOME/webapps/$CONTEXT_PATH
#fi

# Copy the WAR file to the webapps directory
cp $WAR_STAGED_LOCATION $CATALINA_HOME/webapps
service tomcat7 start
