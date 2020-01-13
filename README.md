# iNode HT software

Application based on E.Wojtach project: https://github.com/ewojtach/RPiScripts

You can run this project on Raspberry Pi to receive BLE frames from iNode HT devices and send them to Mosquitto MQTT messages Broker. 

Files:

- iNode.sh

- run_iNode.conf

- iNode.conf

  should be placed in /opt/iNode directory. 

You can use MQTTs or just MQTT connection between RPI and Broker (changes have to be done in iNode.sh and iNode.conf files).

iNode.sh generates log file. To serve it you can use logrotate (logrotate.conf file included). 

RPI has a problem with long-running using hcidump. To server this issue I made workaround using crontab. It restarts RPI 3 times a day and runs iNode.sh (see crontab directory in this project). 

To run script use: *$ /opt/iNode/run_iNode.sh*

