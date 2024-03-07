#!/bin/bash

sudo docker network ls 

# Überprüfen, ob alle erforderlichen Argumente übergeben wurden
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <ZONE_NAME> <INTERFACE>"
    exit 1
fi

ZONE_NAME="$1"
INTERFACE="$2"


# Überprüfen, ob die Zone korrekt ist
if  firewall-cmd --get-zones | grep -q "\<$ZONE_NAME\>"; then
        sudo firewall-cmd --permanent --delete-zone="$ZONE_NAME"
        sudo firewall-cmd --reload
fi

sudo firewall-cmd --permanent --new-zone="$ZONE_NAME"
sudo firewall-cmd --reload

# Überprüfen, ob die Zone korrekt ist
if ! firewall-cmd --get-zones | grep -q "\<$ZONE_NAME\>"; then
    echo "Error: The zone $ZONE_NAME does not exist."
    exit 1
fi

sudo firewall-cmd --zone="$ZONE_NAME" --add-interface="$INTERFACE" --permanent
sudo  firewall-cmd --reload

echo "set zone accept"
sudo firewall-cmd --permanent --zone="$ZONE_NAME" --add-masquerade  
sudo firewall-cmd --permanent --zone="$ZONE_NAME" --set-target=ACCEPT 

echo "set masquerade"
sudo firewall-cmd --permanent  --direct --add-rule ipv4 nat POSTROUTING 0 -o eno1 -j MASQUERADE
echo "set direct 1"
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i eno1 -o "$INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT 
echo "set direct 2"
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i "$INTERFACE" -o eno1  -j ACCEPT 
sudo  firewall-cmd --reload

echo "Interface $INTERFACE successfully assigned to zone $ZONE_NAME."

sudo firewall-cmd --zone="$ZONE_NAME"  --add-rich-rule='rule family="ipv4" destination  address="141.22.27.238" drop' --permanent 








