./stop-process.sh ironic-conductor
./stop-process.sh ironic-api

/usr/bin/python /usr/local/bin/ironic-conductor --config-file=/etc/ironic/ironic.conf &
/usr/bin/python /usr/local/bin/ironic-api --config-file=/etc/ironic/ironic.conf 1>/dev/null 2>/dev/null &


