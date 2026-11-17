#!/usr/bin/env bash
# usage: NORD_TOKEN=... scripts/nordlynx-info.sh [country code]
# token: nord account -> nordvpn -> manual setup -> generate new token
set -euo pipefail
: "${NORD_TOKEN:?set NORD_TOKEN}"
api=https://api.nordvpn.com/v1

priv=$(curl -gfsS -u "token:${NORD_TOKEN}" "$api/users/services/credentials" | jq -r .nordlynx_private_key)

filter='filters[servers_technologies][identifier]=wireguard_udp'
if [ -n "${1:-}" ]; then
  cid=$(curl -gfsS "$api/servers/countries" | jq -r --arg c "${1^^}" '.[] | select(.code==$c) | .id')
  filter="$filter&filters[country_id]=$cid"
fi
srv=$(curl -gfsS "$api/servers/recommendations?$filter&limit=1")

echo "nord.endpoint  = \"$(jq -r '.[0].hostname' <<<"$srv"):51820\";"
echo "nord.publicKey = \"$(jq -r '.[0].technologies[] | select(.identifier=="wireguard_udp") | .metadata[] | select(.name=="public_key") | .value' <<<"$srv")\";"
echo
echo "private key (goes into nord.age, keep it secret):"
echo "$priv"
