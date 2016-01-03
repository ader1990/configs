#ps1

# How to set up:
# http://lifehacker.com/turn-your-windows-10-computer-into-a-wi-fi-hotspot-1724762931
 
# How to debug:
# http://stackoverflow.com/questions/18182084/cant-start-hostednetwork

$password = "myverystr@ngp@ssw0rd"
$SSID = "MyAwesomeHotspot"

netsh wlan set hostednetwork mode=allow ssid=$SSID key=$password
netsh wlan start hostednetwork

# if the start does not work, check in Device Manager, under Network Adapters,
# the "Microsoft Hosted Network Virtual Adapter" to be enabled.
# To make sure this adapter is shown, in Device Manager/View, click on
# "Show hidden devices"

# In order to have Internet connection, make sure you share the connection
# which has Internet access with the local area connection of the type
# "Microsoft Hosted Network Virtual Adapter", which has the name the SSID
# you previously set.
