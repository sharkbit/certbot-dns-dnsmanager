#!/bin/bash

_dir="$(dirname "$0")"
source "$_dir/config.sh"

DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')

## get_dns_domains record
CREATE_DOMAIN="_acme-challenge.$DOMAIN"
echo Removing: $CREATE_DOMAIN
dns_id=$(curl -s -X POST $HostWindsAPI \
     -H     "Content-Type: application/json" \
     --data '{"action":"get_dns_domains","search":"'"$DOMAIN"'","API":"'"$API_KEY"'"}' \
			| jq .success[].id )
echo DNS ID: $dns_id


## get_dns_records
dns_rec_id=$(curl -s -X POST $HostWindsAPI \
     -H     "Content-Type: application/json" \
     --data '{"action":"get_dns_records","id":"'"$dns_id"'","API":"'"$API_KEY"'"}' \
             | jq '.success[] | select(.name=="_acme-challenge.'$DOMAIN'")' | jq .id )
echo DNS Rec IDs: $dns_rec_id


## get_locations
get_locations=$(curl -s -X POST $HostWindsAPI \
     -H     "Content-Type: application/json" \
     --data '{"action":"get_locations","API":"'"$API_KEY"'"}' \
             | jq .success | jq 'keys[0]' )
echo Locatiion IDs: $get_locations


curl_data=$(jq -n \
			--arg action "delete_dns_record" \
			--arg dns_rid "$dns_rec_id" \
			--arg api "$API_KEY" \
			--argjson gloc "$get_locations" \
			'{action:$action, id:$dns_rid, API:$api, location_id:$gloc}')

## delete_dns_record
edit_rec=$(curl -s -X POST $HostWindsAPI \
     -H     "Content-Type: application/json" \
     --data "$curl_data" \
             | jq . )
echo Results:  ${edit_rec[*]}
