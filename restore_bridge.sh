#!/bin/sh

USERNAME=arm
DOCKERIP=localhost
PORT=2222

if [ -f backup.properties ]; then 
    echo "Restoring configuration file..."
    scp -P ${PORT} backup.properties ${USERNAME}@${DOCKERIP}:service/conf/service.properties
    echo "Restarting bridge..."
    ssh -l ${USERNAME} -p ${PORT} ${DOCKERIP} "sh -c 'cd /home/arm; nohup ./restart.sh > /dev/null 2>&1'"
    echo "Restarting properties editor..."
    ssh -l ${USERNAME} -p ${PORT} ${DOCKERIP} "sh -c 'cd /home/arm/properties-editor; nohup ./restartPropertiesEditor.sh > /dev/null 2>&1'"
    echo "Bridge container restored - OK"
    exit 0
else
    echo "No backup service.properties (backup.properties) file found... Exiting."
    exit 1
fi
