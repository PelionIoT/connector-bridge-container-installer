#!/bin/sh

USERNAME=arm
DOCKERIP=localhost
PORT=2222

if [ -f backup.properties ]; then
   echo "WARNING: backup properties file already exist!  Please move backup.properties, then retry..."
   exit 1
else
   echo "Backing up bridge configuration..."
   scp -P ${PORT} ${USERNAME}@DOCKERIP:service/conf/service.properties ./backup.properties
   if [ -f backup.properties ]; then
       echo "Bridge configuration backed up OK - backup.properties"
       exit 0
   else
       echo "Unable to backup bridge configuration! - please check USERNAME and DOCKERIP in this script for proper settings..."
       exit -1
   fi
fi
