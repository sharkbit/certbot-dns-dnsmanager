#!/bin/bash

_dir="$(dirname "$0")"
source "$_dir/config.sh"

DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')

## get_dns_domains record
CREATE_DOMAIN="_acme-challenge.$DOMAIN"
echo Creating: $CREATE_DOMAIN
dns_id=$(curl -s -X POST $HostWindsAPI \
     -H     "Content-Type: application/json" \
     --data '{"action":"get_dns_domains","search":"'"$DOMAIN"'","API":"'"$API_KEY"'"}' \
			| jq .success[].id )
##          | python3 -c "import sys,json;print(json.load(sys.stdin)['success'][0]['id'])")
echo DNS ID: $dns_id

# get_locations
get_locations=$(curl -s -X POST $HostWindsAPI \
     -H     "Content-Type: application/json" \
     --data '{"action":"get_locations","API":"'"$API_KEY"'"}' \
             | jq .success | jq 'keys[0]' )
echo Locatiion IDs: $get_locations

echo " - - - "
curl_data=$(jq -n \
			--arg action "edit_dns_record" \
			--arg dns_id "$dns_id" \
			--arg name "$CREATE_DOMAIN" \
			--arg cv "$CERTBOT_VALIDATION" \
			--arg api "$API_KEY" \
			--argjson gloc "$get_locations" \
			'{action:$action, dns_id:$dns_id, name:$name, type:"TXT", value:$cv, ttl:"500", API:$api, location_id:$gloc}')
echo $curl_data

echo " - - - "
## edit_dns_record
edit_rec=$(curl -s -X POST $HostWindsAPI \
     -H     "Content-Type: application/json" \
     --data "$curl_data" \
             | jq . )
echo Results:  ${edit_rec[*]}

sleep 30
