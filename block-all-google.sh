#!/bin/bash
#========================================
# Author: wesaphzt
# Route all Google IP ranges to localhost
# IPv4 only
#========================================

ASN=AS15169
ROUTETYPE=''
HOST=ipinfo.io
HOST_RANGE=https://$HOST/${ASN}\#blocks
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
RANGE_FILE=$SCRIPTDIR/$ASN
HOSTPING=0
PORT=8080
PROXYSITE=https://api.getproxylist.com
PROXYIP=''

#------------------------------------------------->
function cmdStatus {
	"$@"
	local status=$?
	if [ $status -ne 0 ]; then
		echo "error" >&2
	fi
	return $status
}
#------------------------------------------------->
function randomProxy {
	# random proxy
	PROXYIP=$(curl $PROXYSITE/proxy?port[]=$PORT | grep '"ip":' | cut -f 4 -d '"')
}
#------------------------------------------------->
#========================================
# checks
#========================================
#----------------------------------------
# arguments
#----------------------------------------
usage() { echo "Usage: sudo $0 [-b] (block) [-u] (unblock)" 1>&2; exit 1; }

while getopts "bu" option; do
	case "${option}" in
		b)
			ROUTETYPE="add"
			;;
		u)
			ROUTETYPE="del"
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

if [[ "$ROUTETYPE" == "add" ]]; then echo "script set to block"; elif [[ "$ROUTETYPE" == "del" ]]; then echo "script set to unblock"; else echo "error"; exit 1; fi

#----------------------------------------
# check root
#----------------------------------------
if (( $(id -u) != 0 )); then
	echo "not running as root, exit";
	exit 1
else
	echo "running as root";
fi
#----------------------------------------
# test network conection
#----------------------------------------
echo "check network interface connectivity"
for intf in $(ls /sys/class/net/ | grep -v lo);
do
	if [[ $(cat /sys/class/net/$intf/carrier) = 1 ]] &>/dev/null; then online=1; echo "interface $intf online"; fi
done
if ! [ $online ]; then echo "interface $intf offline, exit" >/dev/stderr; exit 1; fi
#----------------------------------------
# test target host connection
#----------------------------------------
echo "pinging $HOST"
if ! ping -c3 $HOST &>/dev/null; then echo "$HOST ping fail, assume google blocked"; HOSTPING=1; else echo "$HOST ping success"; fi
#----------------------------------------
# test google connection
#----------------------------------------
echo "pinging google"
if ! ping -c3 google.com &>/dev/null; then echo "google ping fail, assume google blocked"; HOSTPING=1; else echo "google ping success"; fi

#========================================
# main
#========================================
#----------------------------------------
# download ip ranges
#----------------------------------------
echo "downloading ip ranges to $RANGE_FILE"

# backup if file exists
if [ -f $RANGE_FILE ]; then cp $RANGE_FILE $RANGE_FILE.bak; echo "file exists, backup created at $RANGE_FILE.bak"; fi

# curl ip ranges
if [[ $HOSTPING -eq 0 ]]; then
	cmdStatus curl -SsL $HOST_RANGE | grep "${ASN}/" | cut -f 2 -d '"' | cut -f 3-4 -d '/' | sed '/::/d' > $RANGE_FILE || exit;
elif [[ $HOSTPING -eq 1 ]]; then
	# curl ip ranges through proxy
	echo "google offline, dl using proxy"
	COUNT=0
	until randomProxy && cmdStatus curl -SsLx $PROXYIP:$PORT $HOST_RANGE | grep "${ASN}/" | cut -f 2 -d '"' | cut -f 3-4 -d '/' | sed '/::/d' > $RANGE_FILE; do
		if [ $COUNT -eq 10 ]; then echo "$COUNT proxies failed, exit"; exit 10; fi
		sleep 1; ((COUNT++))
	done
else
	echo "error"; exit 1;
fi
#----------------------------------------
# change routing table
#----------------------------------------
echo "making changes to routing table"
COUNT=0
while read line; do
	cmdStatus route $ROUTETYPE -net $line gw 127.0.0.1 lo &>/dev/null;
	# counter
	if [ $? -eq 0 ]; then ((COUNT++)); fi
done < $RANGE_FILE
echo "$COUNT ip ranges processed"

#========================================
# finish
#========================================
#----------------------------------------
# test google connection
#----------------------------------------
echo "ping test google again"
if ! ping -c3 google.com &>/dev/null; then HOSTPING=1; else HOSTPING=0; fi

if [ "$ROUTETYPE" == "add" ]; then
	if [ $HOSTPING -eq 1 ]; then echo "success (google ping failed)"; fi
	if [ $HOSTPING -eq 0 ]; then echo "fail (google ping successful)"; fi
elif [ "$ROUTETYPE" == "del" ]; then
	if [ $HOSTPING -eq 1 ]; then echo "fail (google ping failed)"; fi
	if [ $HOSTPING -eq 0 ]; then echo "success (google ping successful)"; fi
else
	echo "error"
fi

echo "//done"
