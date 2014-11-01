set -e

# INSTALL CRUDINI
#sudo apt-get install crudini

IRONIC_CONF_FILE="/etc/ironic/ironic.conf"

crudini --set $IRONIC_CONF_FILE DEFAULT enabled_drivers "fake,pxe_lego,pxe_ssh,pxe_ipmitool"

#crudini --set $IRONIC_CONF_FILE lego lego_ev3_classes_jar ""

crudini --set $IRONIC_CONF_FILE lego lego_ev3_classes_jar "/opt/stack/reBot/ev3classes.jar:/opt/stack/reBot/."
crudini --set $IRONIC_CONF_FILE lego lego_press_time_on "500"
crudini --set $IRONIC_CONF_FILE lego lego_press_time_off "5000"
crudini --set $IRONIC_CONF_FILE lego lego_move_degrees "1440"
crudini --set $IRONIC_CONF_FILE lego fake_lego "true"

#./restart-processes-ironic.sh

