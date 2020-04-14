#!/bin/vbash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
declare -a MyStaticTunnelEndpoints=("YOUR-REMOTE-IP-HERE")
MyIP=$(curl -s https://ifconfig.me)
WR="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper"
for ip in "${MyStaticTunnelEndpoints[@]}"; do
    CurrentIPConfig=$($WR show vpn ipsec site-to-site peer $ip local-address | cut -d' ' -f2)
    if [[ "$MyIP" != "$CurrentIPConfig" ]]; then
        $WR begin
        $WR set vpn ipsec site-to-site peer $ip local-address $MyIP
        logger "updated peer $ip with $MyIP"
        $WR save
        $WR commit
        $WR end
        sleep 10
        logger "commited and saved peer $ip with $MyIP"
    else
        logger "No local IP address change detected for peer $ip"
    fi
done
