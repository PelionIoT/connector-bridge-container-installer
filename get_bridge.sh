#!/bin/sh

# set -x


#
# Defaults...
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
        IP=${IP}:
    else
        # MacOS (native docker installed) - dont use an IP address... 
	IP=""
        echo "IP Address:" `hostname -s`
    fi
elif [ "$(uname)" = "MINGW64_NT-10.0" ]; then
    # Windows - Must use the Docker Toolkit with the latest VirtualBox installed... pinned to 192.168.99.100 
    IP="192.168.99.100"
    echo "IP Address:" ${IP} 
    IP=${IP}:
else
    # (assume) Linux - docker running as native host - use the host IP address
    IP="`ip route get 8.8.8.8 | awk '{print $NF; exit}'`"
    echo "IP Address:" ${IP}
    IP=${IP}:
fi

if [ "${TYPE}X" = "X" ]; then
    echo "Usage: $0 [watson | iothub | aws | generic-mqtt | generic-mqtt-getstarted] {Connector API Token} {use-long-polling}"
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
    echo "Usage: $0 [watson | iothub | aws | generic-mqtt | generic-mqtt-getstarted] {Connector API Token} {use-long-polling}"
    exit 2
fi

DOCKER_VER="`docker --version`"
if [ "${DOCKER_VER}X" = "X" ]; then
    echo "ERROR: docker does not appear to be installed! Please install docker and retry."
    echo "Usage: $0 [watson | iothub | aws | generic-mqtt | generic-mqtt-getstarted] {Connector API Token} {use-long-polling}"
    exit 3
else
    ID=`${DOCKER} ps -a | grep home | grep arm | awk '{print $1}'`

    if [ "${ID}X" != "X" ]; then
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
        echo "No container image found... (OK)"
    fi

    IMAGE=${IMAGE}${SUFFIX}
    echo ""
    echo "mbed Connector bridge Image:" ${IMAGE}
    echo "Pulling mbed Connector bridge image from DockerHub(tm)..."
    ${DOCKER} pull ${IMAGE}
    if [ "$?" = "0" ]; then
       echo "Starting mbed Connector bridge image..."
       ${DOCKER} run -d ${MQTT_PORT} ${NODE_RED_PORT} -p ${IP}28519:28519 -p ${IP}28520:28520 -p ${IP}${BRIDGE_SSH}:22 -p ${IP}8234:8234 -t ${IMAGE}  /home/arm/start_instance.sh ${API_TOKEN} ${LONG_POLL} ${CLOUD_ARGS}
       if [ "$?" = "0" ]; then
           echo "mbed Connector bridge started!  SSH is available to log into the bridge runtime"
           if [ "${NODE_RED_PORT}X" != "X" ]; then
	        echo ""
	        echo "Try this!  In your browser, go to: http://localhost:2880 to access the included NodeRED dashboard"
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
