#!/bin/sh

#
# DEBUG
#
# set -x

#
# Defaults
#
IMAGE="danson/connector-bridge-container-"
TYPE="$1"
SUFFIX=""
DOCKER="docker"
BRIDGE_SSH="2222"
NODE_RED_PORT=""
MQTT_PORT=""
API_TOKEN=""
LONG_POLL=""
CLOUD_ARGS=""
LOCAL_NODERED="http://localhost:2880"

#
# Set to a base port number (non-SSL). SSL will be base_port_number+1
#
BASE_PORT_NUMBER=28519

#
# Override base port number 
#
if [ "${OVERRIDE_PORT_NUMBER}X" != "X" ]; then
    BASE_PORT_NUMBER=${OVERRIDE_PORT_NUMBER}
fi

#
# Calculate the non-SSL and SSL numbers
#
NON_SSL_PORT=${BASE_PORT_NUMBER}
SSL_PORT=`expr ${NON_SSL_PORT} + 1`

#
# Enable/Disable previous bridge configuration save/restore
#
# Uncomment (or set in shell environment) to ENABLE. Comment out to DISABLE
#
#SAVE_PREV_CONFIG="YES"

# START: Optional Configuration for Cloud Providers (IBM Watson IoT, MS Azure IoTHub, Amazon IoT)
#
# Simply set these and use one of the specified options in the invocation of this script. For example (IBM Watson):
#
# % ./get_bridge.sh watson <use-long-polling>
#
# Optionally, you can specify the mbed Connector API Token:
#
# % ./get_bridge.sh watson <API Token> <use-long-polling>
#
# If you choose to not edit these, you can still go to your installed instance (i.e. https://<docker host ip address>:8234)
# using username "admin" with default password "admin" and set the values (SAVE after EACH!!!). After set, press "Restart". 
#
# IMPORTANT NOTE: You may need to place  a "\" (i.e. back slash...)  in front of any specific key token values (i.e. & or / etc...) within
#                 the creds for your cloud account. sed() can mis-interpet them otherwise.
#
#                 Example: 
#
#                           AWS_IOT_ACCESS_KEY_TOKEN="dkdkjejuf98e7&dldk"
#
#                 Should be changed to:
#
#                           AWS_IOT_ACCESS_KEY_TOKEN="dkdkjejuf98e7\&dldk"
#
#

#
# mbed Connector API Token
#
MDC_API_TOKEN=""

#
# IBM Watson IoT Credentials
#
IBM_WATSON_API_KEY=""
IBM_WATSON_AUTH_TOKEN=""

#
# MS IoTHub Credentials
#
MS_IOTHUB_HUBNAME=""
MS_IOTHUB_SAS_TOKEN=""

#
# AWS IoT Credentials
#
AWS_IOT_REGION=""
AWS_IOT_ACCESS_KEY_ID=""
AWS_IOT_ACCESS_KEY_SECRET=""

#
# Google Cloud Credentials
#
GOOGLE_APP_NAME=""
GOOGLE_AUTH_JSON=""

#
# Standalone MQTT Broker
#
MQTT_IP_ADDRESS=""
MQTT_USERNAME=""
MQTT_PASSWORD=""
MQTT_CLIENTID=""

#
# END: Optional Configuration for Cloud Providers (IBM Watson IoT, MS Azure IoTHub, Amazon IoT)
#

#
# Environment Selection
#
if [ "$(uname)" = "Darwin" ]; then
    if [ ! -h /usr/local/bin/docker-machine ]; then
        # MacOS (toolkit docker installed (OLD))... default is to pin IP address to 192.168.99.100
        IP="192.168.99.100"
        echo "IP Address:" ${IP}
	BASE_IP=${IP}
        IP=${IP}:
    else
        # MacOS (native docker installed) - dont use an IP address... 
	export IP=""
	BASE_IP=${IP}
        echo "IP Address:" `hostname -s`
    fi
elif [ "$(uname)" = "MINGW64_NT-10.0" ]; then
    # Windows - Must use the Docker Toolkit with the latest VirtualBox installed... pinned to 192.168.99.100 
    IP="192.168.99.100"
    echo "IP Address:" ${IP} 
    BASE_IP=${IP}
    IP=${IP}:
    LOCAL_NODERED="http://192.168.99.100:2880"
elif [ "$(uname)" = "MINGW64_NT-6.1" ]; then
    # Windows - Must use the Docker Toolkit with the latest VirtualBox installed... pinned to 192.168.99.100
    IP="192.168.99.100"
    echo "IP Address:" ${IP}
    BASE_IP=${IP}
    IP=${IP}:
    LOCAL_NODERED="http://192.168.99.100:2880"
else
    # (assume) Linux - docker running as native host - use the host IP address
    IP="`ip route get 8.8.8.8 | awk '{print $NF; exit}'`"
    echo "IP Address:" ${IP}
    BASE_IP=${IP}
    export IP=${IP}:
fi

if [ "${TYPE}X" = "X" ]; then
    echo "Usage: $0 [watson | iothub | aws | google | generic-mqtt | generic-mqtt-getstarted] {Connector API Token} {use-long-polling}"
    exit 1
fi

if [ "$2" != "" ]; then
    API_TOKEN="$2"
    LONG_POLL="$3"
fi

if [ "$2" = "use-long-polling" ]; then
    API_TOKEN="$3"
    LONG_POLL="$2"
fi

if [ "${API_TOKEN}X" = "X" ]; then
   API_TOKEN="${MDC_API_TOKEN}" 
fi

if [ "${TYPE}" = "watson" ]; then
    SUFFIX="iotf"
    CLOUD_ARGS="${API_TOKEN} ${IBM_WATSON_API_KEY} ${IBM_WATSON_AUTH_TOKEN}"
    API_TOKEN=""
fi

if [ "${TYPE}" = "iothub" ]; then
    SUFFIX="iothub"
    CLOUD_ARGS="${API_TOKEN} ${MS_IOTHUB_HUBNAME} ${MS_IOTHUB_SAS_TOKEN}"
    API_TOKEN=""
fi

if [ "${TYPE}" = "aws" ]; then
    SUFFIX="awsiot"
    CLOUD_ARGS="${API_TOKEN} ${AWS_IOT_REGION} ${AWS_IOT_ACCESS_KEY_ID} ${AWS_IOT_ACCESS_KEY_SECRET}"
    API_TOKEN=""
fi

if [ "${TYPE}" = "google" ]; then
    SUFFIX="google"
    CLOUD_ARGS="${API_TOKEN} ${GOOGLE_APP_NAME} ${GOOGLE_AUTH_JSON}"
    API_TOKEN=""
fi

if [ "${TYPE}" = "generic-mqtt" ]; then
    SUFFIX="mqtt"
    CLOUD_ARGS="${API_TOKEN} ${MQTT_IP_ADDRESS} ${MQTT_USERNAME} ${MQTT_PASSWORD} ${MQTT_CLIENTID} ${MQTT_PORT}"
    API_TOKEN=""
fi

if [ "${TYPE}" = "generic-mqtt-getstarted" ]; then
    SUFFIX="mqtt-getstarted"
    NODE_RED_PORT="-p ${IP}2880:1880"
    MQTT_PORT="-p ${IP}3883:1883"
fi

if [ "${SUFFIX}X" = "X" ]; then
    echo "Usage: $0 [watson | iothub | aws | google | generic-mqtt | generic-mqtt-getstarted] {Connector API Token} {use-long-polling}"
    exit 2
fi


#
# Save a previous Configuration
#
save_config() {
    if [ "${IP}X" = "X" ]; then
	SSH_IP="localhost:"
    else 
	SSH_IP=${IP}
    fi
    echo "Saving previous bridge configuration...(default container pw: arm1234)"
    #echo scp -q -P 2222 arm@${SSH_IP}connector-bridge/conf/service.properties .
    scp -q -P 2222 arm@${SSH_IP}connector-bridge/conf/service.properties .
    if [ $? != 0 ]; then
        echo "Saving of the previous configuration FAILED"
    else
        echo "Save succeeded."
    fi
    if [ -f service.properties ]; then
        export SAVED_CONFIG="YES"
    else
        export SAVED_CONFIG="NO"
    fi
}

#
# Restore a previous Configuration
#
restore_config() {
   if [ "${SAVED_CONFIG}X" = "YESX" ]; then
 	echo "Waiting for 8 seconds to have the container start up..."
	sleep 8
	if [ "${IP}X" = "X" ]; then
            SSH_IP="localhost"
            START="["
	    STOP="]:"
            SCP_IP="${SSH_IP}:"
        else 
            SSH_IP=${BASE_IP}
	    START=""
	    STOP=""
	    SCP_IP="${SSH_IP}:"
        fi
 	echo "Beginning restoration... Updating known_hosts..."
	# echo ssh-keygen -R ${START}${SSH_IP}${STOP}2222
	ssh-keygen -R ${START}${SSH_IP}${STOP}2222
        echo "Restoring previous configuration... (default container pw: arm1234)"
        # echo scp -q -P 2222 service.properties arm@${SCP_IP}connector-bridge/conf
        scp -q -q -P 2222 service.properties arm@${SCP_IP}connector-bridge/conf
	if [ $? != 0 ]; then
	    echo "Restoration of the previous configuration FAILED"
	else
	    echo "Restoration succeeded... Restarting the bridge runtime..."
	    # echo "ssh -f -p 2222 arm@${SSH_IP} /home/arm/restart.sh"
	    ssh -f -p 2222 arm@${SSH_IP} /home/arm/restart.sh
	    if [ $? != 0 ]; then
                echo "Bridge restart FAILED"
            else
                echo "Bridge restarted."
	    fi
	fi
        rm -f service.properties 2>&1 1>/dev/null
   fi
}

DOCKER_VER="`docker --version`"
if [ "${DOCKER_VER}X" = "X" ]; then
    echo "ERROR: docker does not appear to be installed! Please install docker and retry."
    echo "Usage: $0 [watson | iothub | aws | google | generic-mqtt | generic-mqtt-getstarted] {Connector API Token} {use-long-polling}"
    exit 3
else
    ID=`${DOCKER} ps -a | grep home | grep arm | awk '{print $1}'`
    if [ "${ID}X" != "X" ]; then
        if [ "${SAVE_PREV_CONFIG}X" = "YESX" ]; then
            save_config $*
        fi
        echo "Stopping $ID"
        docker stop ${ID}
    else
        echo "No running bridge container found... OK"
    fi
    
    if [ "${ID}X" != "X" ]; then
        echo "Removing $ID"
        docker rm --force ${ID}
    fi
    
    echo "Looking for existing container image..."

    ID=`${DOCKER} images | grep connector-bridge | awk '{print $3}'`
    if [ "${ID}X" != "X" ]; then
        echo "Removing Image $ID"
        docker rmi --force ${ID}
    else
        echo "No container image found... OK"
    fi

    IMAGE=${IMAGE}${SUFFIX}
    echo ""
    echo "mbed Connector bridge Image:" ${IMAGE}
    echo "Pulling mbed Connector bridge image from DockerHub(tm)..."
    ${DOCKER} pull ${IMAGE}
    if [ "$?" = "0" ]; then
       echo "Starting mbed Connector bridge image..."
       echo ${DOCKER} run -d ${MQTT_PORT} ${NODE_RED_PORT} -p ${IP}${NON_SSL_PORT}:${NON_SSL_PORT} -p ${IP}${SSL_PORT}:${SSL_PORT} -p ${IP}${BRIDGE_SSH}:22 -p ${IP}8234:8234 -t ${IMAGE}  /home/arm/start_instance.sh ${API_TOKEN} ${LONG_POLL} ${CLOUD_ARGS}
       ${DOCKER} run -d ${MQTT_PORT} ${NODE_RED_PORT} -p ${IP}${NON_SSL_PORT}:${NON_SSL_PORT} -p ${IP}${SSL_PORT}:${SSL_PORT} -p ${IP}${BRIDGE_SSH}:22 -p ${IP}8234:8234 -t ${IMAGE}  /home/arm/start_instance.sh ${API_TOKEN} ${LONG_POLL} ${CLOUD_ARGS}
       if [ "$?" = "0" ]; then
           echo "mbed Connector bridge started!  SSH is available to log into the bridge runtime"
	   if [ "${SAVE_PREV_CONFIG}X" = "YESX" ]; then
 	       if [ "${SAVED_CONFIG}X" = "YESX" ]; then
	           echo ""
		   restore_config $*
   	       else 
                   if [ "${NODE_RED_PORT}X" != "X" ]; then
	                echo ""
	                echo "Try this!  In your browser, go to: ${LOCAL_NODERED} to access the included NodeRED dashboard"
                   fi
               fi
           else
	       if [ "${NODE_RED_PORT}X" != "X" ]; then
                   echo ""
                   echo "Try this!  In your browser, go to: ${LOCAL_NODERED} to access the included NodeRED dashboard"
               fi
	   fi
	   exit 0
       else
	   echo "mbed Connector bridge FAILED to start!"
           exit 5
       fi
    else 
	echo "mbed Connector docker \"pull\" FAILED!" 
        exit 6
    fi 
fi
