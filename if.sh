#!/bin/bash
#
# by Haraguroicha

tmpNumber=`date +%Y%m%d%H%M%S`

function uptimed() {
	t=$(uptime | sed -e 's/,//g' | awk '{print $2" "$3" "$4", "$5}')
	tup=$(echo $t | grep user)
	ttup=$(echo $t | grep mins)
	if [ "$tup" = "" ]
	then
		if [ "$ttup" = "" ]
		then
			tt=$t
		else
			tt=$(echo $t | sed -e 's/,//g' | awk '{print $1" "$2" "$3}')
		fi
	else
		tt=$(echo $t | awk '{print $1" "$2}')
	fi
	echo -e "Uptime:\t\t$tt"
}

function getWIFIStatus() {
	echo Wifi Status:
	/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | sed -e 's/ //g' | awk '{s=$1;printf("%20s %s\n", s, $2)}' | sed -e 's// /g' | sed -e 's/: 0:/: 00:/g' | sed -e 's/:0:/:00:/g' | sed -e 's/:0:/:00:/g' | sed -e 's/:0/:00/g' | sed -e 's/000/00/g'
}

function deviceInfo() {
	echo Devices address:
	devs=$(ifconfig -lu)
	for dev in $devs
	do
		devsh=$(echo -e '' | awk '{print "ifconfig \$dev | grep -v tunnel | grep -v ::1 | grep -v 127.0.0.1 | grep inet | grep -v fe80: | sed -e \x27s/inet6/IPv6/g\x27 | sed -e \x27s/inet/IPv4/g\x27 | sed -e \x27s/temporary/temporary temporary/g\x27 | awk \x27{print \"echo ${dev} \"$1\":\x9\"$2\" \"$7}\x27\\n"}')
		
		echo dev=$dev > /tmp/tmp${tmpNumber}.if.sh
		echo -e $devsh >> /tmp/tmp${tmpNumber}.if.sh
		
		echo dev=$dev >> /tmp/tmp${tmpNumber}.if.result.sh
		
		chmod +x /tmp/tmp${tmpNumber}.if.sh
		chmod +x /tmp/tmp${tmpNumber}.if.result.sh
		
		/tmp/tmp${tmpNumber}.if.sh $dev >> /tmp/tmp${tmpNumber}.if.result.sh
		/tmp/tmp${tmpNumber}.if.result.sh | awk '{s=$3;printf("%5s %s       %s\n", $1, $2, s)}'
		
		rm /tmp/tmp${tmpNumber}.if.sh
		rm /tmp/tmp${tmpNumber}.if.result.sh
	done
	tundev=`ifconfig -l | sed -e 's/[ ]/\\\\n/g'`
	tundev=(`echo -e $tundev | grep -E '^tun0|^gif0'`)
	for((i=0; i<${#tundev[@]}; i++)); do
		_tunipv6=$(ifconfig ${tundev[$i]} | grep inet6 | grep '>' | awk '{print $2}')
			if [ "$_tunipv6" != "" ]
			then
				if [ "$tunipv6" = "" ]
				then
					tunipv6=$_tunipv6
					ipv6dev=$(echo ${tundev[$i]} | sed -e 's/0//g')
				fi
			fi
	done
	if [ "$tunipv6" = "" ]; then
		tunipv6="not available"
	fi
	echo -e "IPv6 $ipv6dev address: ${tunipv6}"
	gw6c=`pgrep gw6c`
	if [ "${gw6c}" = "" ]; then
		gw6c="gw6c is not running"
	fi
	echo -e "  gw6c PID:       ${gw6c}"
}

function getIP() {
	addr=$( echo -e `curl --connect-timeout 1 --compressed gzip --url http://$1/ip/ 2>/dev/null|sed -e 's/[,]/\\\\t/g'|sed -e 's/callback//g'|sed -e 's/[(){}]//g'`|awk '{print $1}'|sed -e 's/"//g'|sed -e 's/ip://g')
	addrIP4=`echo "$addr"|grep "\\."`
	addrIP6=`echo "$addr"|grep ":"`
	addr="${addrIP4}${addrIP6}"
	if [ "${addrIP}" = "" ]; then
		echo -e "${addr}"
	else
		echo ""
	fi
}

function getIPv4v6() {
	dsColor="\033[0m"
	ds=""
	dsIP=""
	v4IP=""
	v6IP=""
	v6=""
	ipv4=$(getIP "ipv4.test-ipv6.com")
	ipv6=$(getIP "ipv6.test-ipv6.com")
	ipds=$(getIP "ds.test-ipv6.com")
	if [ "$ipv4" != "" ]; then
		v4IP="\n      IPv4:       ${ipv4}"
	fi
	if [ "$ipv6" != "$ipds" ] && [ "$ipv6" != "" ]; then
		ds="\n\t\033[31mYou have IPv6, but your system is avoiding to use.\033[0m"
		dsColor="\033[31m"
	fi
	if [ "$ipv4" = "" ] && [ "$ipv6" != "" ] && [ "$ipds" = "$ipv6" ]; then
		ds="\n\t\033[33mYou have IPv6 only.\033[0m"
		dsColor="\033[33m"
	fi
	if [ "$ipv6" != "" ]; then
		v6IP="\n      IPv6:       ${ipv6}"
		dsIP="\n      DSIP:       ${dsColor}${ipds}\033[0m"
	fi
	cip="${v4IP}${v6IP}${dsIP}${ds}"
	if [ "$cip" = "" ]; then
		cip="\n\t\033[33mCurrently, you don't have any connection.\033[0m"
	fi
	echo -e "Current External IP:${cip}"
}

function dnsInfo() {
	dnsip=$(echo `cat /etc/resolv.conf|grep nameserver|awk '{print $2}'`)
	if [ "$dnsip" != "" ]; then
		dns=`echo $dnsip|sed -e 's/ /,\\\\n                  /g'`
		echo -e "DNS Server:       ${dns}"
		for dip in $dnsip; do
			dnsName=`nslookup $dip -timeout=1 | grep 'name = ' | awk '{print $4}'`
			if [ "$dnsName" != "" ]; then
				dig -t A $dnsName +noall +answer|grep A|grep -v ';'|grep -v '^$'|awk '{print "\t"$1"["$5"]"}'|sed -e 's/\.\[/ [/' > /tmp/dns${tmpNumber}.tmp
				dig -t AAAA $dnsName +noall +answer|grep AAAA|grep -v ';'|grep -v '^$'|awk '{print "\t"$1"["$5"]"}'|sed -e 's/\.\[/ [/' >> /tmp/dns${tmpNumber}.tmp
				sort /tmp/dns${tmpNumber}.tmp
				rm /tmp/dns${tmpNumber}.tmp
			else
				echo -e "\033[31mWarning: Your dns server of '${dip}' doesn't have reverse record\033[0m"
			fi
		done
	else
		echo -e "DNS Server:       not available"
	fi
}

uptimed;
getWIFIStatus;
deviceInfo;
getIPv4v6;
dnsInfo;
