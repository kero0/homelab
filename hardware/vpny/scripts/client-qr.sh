#!/usr/bin/env bash
# usage: hardware/vpny/scripts/client-qr.sh NAME [--conf]
# prints the client config as a qr code for the wireguard app, or as text with --conf
set -euo pipefail
self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
[ -n "${VPNY_TOOLS:-}" ] || VPNY_TOOLS=1 exec nix shell nixpkgs#qrencode nixpkgs#jq nixpkgs#python3 -c "$self" "$@"
name=${1:?usage: client-qr.sh NAME [--conf]}
vpny=$(cd "$(dirname "$self")/.." && pwd); dir=$vpny/clients
[ -r "$dir/$name.key" ] || { echo "no clients/$name.key, make it with scripts/add-client.sh $name" >&2; exit 1; }

s=$(nix eval --impure --json --expr "let s = import $vpny/settings.nix; in {
  inherit (s.clients) publicKey endpoint;
  inherit (s.clients) dns;
  reachable = s.home.lan ++ [ s.clients.subnet ];
  ip = (import $dir/$name.nix).ip;
  inherit (s.clients) bypass;
  tunnel = s.home.lan ++ [ s.clients.subnet ];
}")
get() { jq -r "$1" <<<"$s"; }
# dns only works if the tunnel carries it
python3 -I -c '
import ipaddress as ip, json, sys
s = json.load(sys.stdin)
ok = [ip.ip_network(n) for n in s["reachable"]]
off = [d for d in s["dns"] if not any(ip.ip_address(d) in n for n in ok)]
if off:
    print("dns", ", ".join(off), "is not inside home.lan or the wg0 subnet (" + ", ".join(s["reachable"]) + "), so devices could not reach it", file=sys.stderr); sys.exit(1)
' <<<"$s"
# everything, minus bypass, plus tunnel (wireguard can't exclude, so spell it out)
allowed=$(python3 -I -c '
import ipaddress as ip, json, sys
s = json.load(sys.stdin)
def minus(n, b):
    if not n.overlaps(b): return [n]
    if n.subnet_of(b): return []
    return list(n.address_exclude(b))
nets = [ip.ip_network("0.0.0.0/0")]
for b in map(ip.ip_network, s["bypass"]):
    nets = [r for n in nets for r in minus(n, b)]
nets += map(ip.ip_network, s["tunnel"])
print(", ".join(map(str, ip.collapse_addresses(nets))) + ", ::/0")
' <<<"$s")
case "$(get .publicKey)$(get .endpoint)" in
  *CHANGE-ME*) echo "set clients.publicKey and clients.endpoint in settings.nix first" >&2; exit 1 ;;
esac

conf="[Interface]
PrivateKey = $(cat "$dir/$name.key")
Address = $(get .ip)
DNS = $(get '.dns | join(", ")')

[Peer]
PublicKey = $(get .publicKey)
Endpoint = $(get .endpoint)
AllowedIPs = $allowed
PersistentKeepalive = 25"

# same checks as the wireguard ios/macos app, so a bad value fails here and not on the phone
python3 -I -c '
import base64, binascii, ipaddress as ip, re, sys
bad = []
sec = None
for line in sys.stdin.read().splitlines():
    line = line.split("#")[0].strip()
    if not line: continue
    if line in ("[Interface]", "[Peer]"): sec = line; continue
    k, _, v = (x.strip() for x in line.partition("="))
    if k in ("PrivateKey", "PublicKey"):
        try:
            if len(base64.b64decode(v, validate=True)) != 32: raise ValueError
        except (binascii.Error, ValueError):
            bad.append(f"{k} is not a wireguard key: {v[:8] if k == "PublicKey" else "(hidden)"}...")
    elif k in ("Address", "AllowedIPs"):
        for n in v.split(","):
            try: ip.ip_network(n.strip(), strict=False)
            except ValueError: bad.append(f"{k} entry {n.strip()!r}")
    elif k == "Endpoint":
        m = re.fullmatch(r"(\[[0-9a-fA-F:]+\]|[^:\[\]\s]+):(\d+)", v)
        if not m or not 0 < int(m.group(2)) < 65536: bad.append(f"Endpoint {v!r} is not host:port")
if bad:
    print("invalid config, fix settings.nix (or the key file):", *bad, sep="\n  ", file=sys.stderr); sys.exit(1)
' <<<"$conf"

if [ "${2:-}" = --conf ]; then echo "$conf"; else qrencode -t ansiutf8 <<<"$conf"; fi
