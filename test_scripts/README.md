These are some sample scripts that can be used to exercise the generic MQTT bridge. 

To use these scripts:
- You must have Paho MQTT support enabled in your python environment (pip install paho-mqtt)

Then edit each script:
- update the IP value to reflect your MQTT Broker
- if your broker requires authentication, update the scripts to provide it
- update the script replacing all accurances of the endpoint ID with your endpoint ID (MBED_ENDPOINT_NAME in security.h)
- Optionally: update the resources your endpoint is emitting vs. my samples..

The sample K64F endpoint code I use is located here: https://github.com/ARMmbed/mbed-ethernet-sample-withdm

NOTE: for the test scripts, I've had issues with paho-mqtt v1.2. Try v1.1... seems to work better.

Enjoy!
