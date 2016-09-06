#!/usr/bin/python

ip = "127.0.0.1"
port = 3883

import paho.mqtt.client as paho
mqttc = paho.Client()

# Callbacks
def on_connect(mosq, obj, rc):
    print("connect rc: "+str(rc))

def on_message(mosq, obj, msg):
    print( "Received on topic: " + msg.topic + " Message: "+str(msg.payload) + "\n");
 
def on_subscribe(mosq, obj, mid, granted_qos):
    print("Subscribed OK")

# Set callbacks
mqttc.on_message = on_message
mqttc.on_connect = on_connect
mqttc.on_subscribe = on_subscribe

# Connect and subscribe
mqttc.connect(ip, port, 60)
mqttc.subscribe("mbed/response/#", 0)

# Wait forever, receiving messages
rc = 0
while rc == 0:
    rc = mqttc.loop()
print("rc: "+str(rc))
