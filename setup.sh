#!/bin/bash
# empty workspace
echo 'cleaing connections and workspace'
rm -rf /etc/NetworkManager/system-connections/*Surfshark* 
rm -rf /etc/NetworkManager/system-connections/*surfshark* 
service NetworkManager restart
# To wait for connect to reset
sleep 20s
rm -rf workspace
# how to get username and password
echo 'naviage to https://my.surfshark.com/vpn/manual-setup/main to get username and password'
# Read Username
echo -n Username: 
read -s username
echo
# Read Password
echo -n Password: 
read -s password
echo
# Run Command
mkdir workspace
# export config files
wget -O workspace/configs.zip https://my.surfshark.com/vpn/api/v1/server/configurations
unzip workspace/configs.zip -d workspace/configs > /dev/null 2>&1
# Rename files
declare -A locationArray
wget -O workspace/servers.json 'https://api.surfshark.com/v3/server/clusters/all'
OLDIFS=$IFS
while IFS="=" read -r key value
do
    locationArray[$key]="$value"
done < <(jq -r '.[]|.connectionName + "=" + .country+ " " +.location' workspace/servers.json)
IFS=$OLDIFS

for i in workspace/configs/*.ovpn
do   
    sequenceNumber=$(echo $locationKey | sed 's/[^0-9]*//g' | sed 's/^0*//')
    locationKey=$(echo $i | cut -d'/' -f 3 | cut -d'_' -f 1);
    if [ ! -v locationArray[$locationKey] ]
    then 
	locationKey=$(echo $locationKey | grep -oP '^[^.]*' | grep -oP '^[a-z]*[-][a-z]*').'prod.surfshark.com'
    fi
    while [ -e "workspace/configs/$(echo $i | cut -d'_' -f 2 | cut -d '.' -f 1 | tr 'a-z' 'A-Z') ${locationArray[$locationKey]} $sequenceNumber.ovpn" ]
    do
    	sequenceNumber=$(($sequenceNumber+1))
    done
    if [ -v locationArray[$locationKey] ]
    then
    	mv -vn $i "workspace/configs/Surfshark $(echo $i | cut -d'_' -f 2 | cut -d '.' -f 1 | tr 'a-z' 'A-Z') ${locationArray[$locationKey]} $sequenceNumber.ovpn"
    else
    	echo "no connection exist for ${locationKey}"
    fi
done
# Apply files
IFS=$'\n'       # make newlines the only separator
for i in $(ls -A workspace/configs/*.ovpn)
do 
    nmcli connection import type openvpn file $i
    nmcli con mod $(echo "$i" | cut -d'/' -f 3 | cut -f 1 -d '.') vpn.persistent true
    nmcli con mod $(echo "$i" | cut -d'/' -f 3 | cut -f 1 -d '.') vpn.user-name "$username"
    nmcli con mod $(echo "$i" | cut -d'/' -f 3 | cut -f 1 -d '.') +vpn.data "password-flags = 0, username = $username"
    nmcli con mod $(echo "$i" | cut -d'/' -f 3 | cut -f 1 -d '.') +vpn.secrets "password=$password"
done
# Remove workspace
rm -rf workspace
echo $password
echo $username

