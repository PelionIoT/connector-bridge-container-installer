This is the installation script that can pull down and start the mbed Connector/mbed Cloud bridge.

Usage:

   get_bridge.sh [watson | iothub | aws | google | generic-mqtt | generic-mqtt-getstarted] {Connector API Token} {use-long-polling}

Arguments:

   watson - instantiate a bridge for Watson IoT

   iotub - instantiate a bridge for Microsoft IoTHub

   aws - instantiate a bridge for AWS IoT

   google - instantiate a bridge for Google Cloud

   generic-mqtt - instantiate a bridge for a generic MQTT broker such as Mosquitto
 
   generic-mqtt-getstarted - Like "generic-mqtt" but also has embedded Mosquitto and NodeRED built in by default

Additional Options:
    
   {Connector API Token} - if a Connector API Token is supplied, it will be set in the configuration initially. Otherwise, go to https://<docker host IP address>:8234 and supply it there ("save" first, then "restart")

   {use-long-polling} - provide this switch if the bridge is to be operated behind a NAT were TCP port 28520 is not passed through to the docker host running the bridge image.

   {watson|iothub|aws} - if a cloud provider is specified, users can edit get_bridge.sh and enter their appropriately created cloud credentials near the top of the script. See script for details.

Requirements:

    - either macOS or Ubuntu environment with a docker runtime installed and operational by the user account
    
    - a DockerHub account created

    - for "watson | aws | iothub | google" options, 3rd Party cloud accounts must be created. For more information see:

	watson: https://github.com/ARMmbed/connector-bridge-container-iotf
	
	iothub: https://github.com/ARMmbed/connector-bridge-container-iothub
	
	aws: https://github.com/ARMmbed/connector-bridge-container-awsiot

        google: https://github.com/ARMmbed/connector-bridge-container-google


If you have chosen to enter your API token after the "pull" or if you have choosen "watson | aws | iothub", additional configuration is required to bind to the respective 3rd party cloud accounts:

1). Open a Browser

2). Navigate to: https://<docker host IP address>:8234

3). Accept the self-signed certificate

4). Default username: admin, pw: admin

5). Complete the configuration of the bridge. After entering a given value, press "Save" before editing the next value... When all values are entered and "Saved", press "Restart"


Additional Notes:

     - Each bridge runtime also has "ssh" (default port: 2222) installed so that you can ssh into the runtime and tinker with it. The default username is "arm" and password "arm1234"

     - For the test scripts, I've had issues with paho-mqtt v1.2. Try v1.1... seems to work better.

     - FYI, ./remove_bridge.sh removes the bridge if desired... it also removes the downloaded docker image

     - DockerToolkit uses Oracle VirtualBox which pins the default IP address to 192.168.99.100. If you happen to change this in your installation of Docker on MacOS, you will need to edit get_bridge.sh and adjust accordingly.

     - Bridge source is Apache licensed and located here: https://github.com/ARMmbed/connector-bridge

Enjoy!
