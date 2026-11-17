#!/usr/bin/env bash
# usage: hardware/vpny/scripts/add-client.sh NAME
set -euo pipefail
self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
[ -n "${VPNY_TOOLS:-}" ] || VPNY_TOOLS=1 exec nix shell nixpkgs#wireguard-tools nixpkgs#jq -c "$self" "$@"
name=${1:?usage: add-client.sh NAME}
[[ $name =~ ^[a-z0-9-]+$ ]] || { echo "name: lowercase letters, digits and -" >&2; exit 2; }
vpny=$(cd "$(dirname "$self")/.." && pwd); dir=$vpny/clients
[ ! -e "$dir/$name.nix" ] || { echo "$name already exists" >&2; exit 1; }

subnet=$(nix eval --impure --raw --expr "(import $vpny/settings.nix).clients.subnet")
prefix=${subnet%.*}   # 10.100.0.0/24 -> 10.100.0
# next free host address, .1 is vpny
used=$(nix eval --impure --json --expr "map (p: p.ip) (import $vpny/settings.nix).clients.peers" | jq -r '.[]' | sed 's|.*\.||; s|/.*||')
n=2; while grep -qx "$n" <<<"$used"; do n=$((n + 1)); done
[ "$n" -le 254 ] || { echo "no free addresses in $subnet" >&2; exit 1; }

(umask 077; wg genkey > "$dir/$name.key")
cat > "$dir/$name.nix" <<NIX
{
  name = "$name";
  publicKey = "$(wg pubkey < "$dir/$name.key")";
  ip = "$prefix.$n/32";
}
NIX
git -C "$dir" add "$name.nix"
echo "added $name as $prefix.$n, key in clients/$name.key (not committed)"
echo "next: deploy .#vpny, then scripts/client-qr.sh $name"
