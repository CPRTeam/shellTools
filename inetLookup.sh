#!/bin/bash
sec="0"
inet=""
trace="0"
pattern=""
gates=""
testPrefixText="\tDetecting: "
badgePos="\r\033[50C"
PING="RESULT "
PING_TIME=1000
PING_OK="${badgePos}[  \033[32mO  K\033[m  ]"
PING_FAILED="${badgePos}[ \033[31mFAILED\033[m ]"
PING_TIMEOUT="\033[31mTimeout\033[m"
Web_OK="://google.com${PING_OK}"
Web_FAILED="://google.com${PING_FAILED}"
Sheep_OK="://hhmr.biz${PING_OK}"
Sheep_FAILED="://hhmr.biz${PING_FAILED}"
ping_hosts=""
ping_test_hosts=""
defaultGateway=""
otherGateway=""
origLines=`echo -e "lines"|tput -S`
origCols=`echo -e "cols"|tput -S`
airport="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"

root() {
	echo -ne "Need Administrator Authorize: Passed\033[8D"
	sudo whoami 1>/dev/null 2>/dev/null
	echo -ne ": Passed"
}
help() {
	usage="Usage: ${0##*/}"
	echo "$usage [-t] -i <interface>"
	echo "$usage [-t] -i <interface> -gp <gateway_pattern> -gs <gateway_suffix> [-pt <ping_timeout>]"
	echo -e "Detail Help:
	\033[33m[-t, forceTrace]\033[m	Force Trace
	\033[33m<-i, interface>\033[m		Device name. (Example: \`en0\`)
	\033[33m<-gp, gateway_pattern>\033[m	Gateway prefix mask pattern.
	Example: If your gateway is \`192.168.0.1\` and you want \`192.168\` to be prefix,
		 this field just use \`..\`, and you want \`192.168.0\` to be prefix,
		 please use \`...\`, and so on.
	\033[33m<-gs, gateway_suffix>\033[m	Gateway suffix.
	Example: If your gateway is \`192.168.0.1\` and you using pattern \`...\`,
		 then you want to test \`192.168.0.1\` and \`192.168.0.2\`,
		 please use \`\"1 2\"\` in this field.
		 In the same situation, If your pattern is \`..\`, then \`\"0.1 0.2\"\`.
	\033[33m[-pt, ping_timeout]\033[m	Test timeout of ping. (Default is \`1000\` ms)
"
	exit;
}
trap "exit" SIGHUP SIGINT SIGQUIT SIGKILL SIGTERM SIGSTOP SIGTSTP SIGUSR1 SIGUSR2
root;
echo -ne "\r\n\033[?25l==== \033[34m${0##*/}\033[m is Script by Haraguroicha 2013-01-12 ====\n"
echo -e "     mod 2013-07-21 by Haraguroicha"
prev=""
for arg in $@
do
	case $arg in
		-h)		help; exit; ;;
		--help)	help; exit; ;;
		-t)		trace=1 ;;
		-i)		prevArg=$arg ;;
		-gp)	prevArg=$arg ;;
		-gs)	prevArg=$arg ;;
		-pt)	prevArg=$arg ;;
		*)
			case $prevArg in
				-i)		inet=$arg ;;
				-gp)	pattern=`echo $arg | sed -e 's/\./\\\\d*\\\\./g'` ;;
				-gs)	gates=$arg ;;
				-pt)	PING_TIME=$arg ;;
			esac
	esac
done
echo -ne "\033[8;30;60t"
main() {
	ret=""
	IPv4=""
	IPv6=""
	v4=`route -nv get default -ifscope $inet 2>/dev/null|grep default|grep $inet|awk '{print $5" "$2}'`
	v6=`netstat -rn -f inet6 | grep $inet | grep \`netstat -rn -f inet6 | grep default | awk '{print $2}'\` 2>/dev/null | grep r | awk '{print $2}'`
	#ip=`ifconfig $inet 2>/dev/null | grep inet | sed 's/inet/IPv4/' | sed 's/IPv46/IPv6/' | awk '{print $1"="$2"\\\\n"}'`
	#echo -e $ip>./setIP.$inet.tmp.sh
	#chmod +x ./setIP.$inet.tmp.sh
	#. ./setIP.$inet.tmp.sh;
	#rm ./setIP.$inet.tmp.sh
	ip=$v4
	IPv4=`echo $v4 | awk '{print $1}'`
	IPv6=$v6
	v4c=`echo $IPv4 | sed 's/\./ /g' | awk '{print $1"."$2}'`
	if [ "$IPv4" == "" ] || [ "$IPv6" == "" ] || [ "$v4c" == "169.254" ]; then
		if [ "$IPv4" != "" ] && [ "$v4c" != "169.254" ]; then
			sec=0
			ret=$ip
		else
			if [ "$IPv6" != "" ]; then
				sec=0
				ret=$IPv6
			else
				sec=$(($sec+1))
				v4cs=""
				if [ "$v4c" == "169.254" ]; then
					v4cs="localnetIP: $IPv4, no net."
				fi
				echo -ne "there are no IP, timeout for 1 sec. (sec=${sec})\t${v4cs}\t${IPv4}\t${IPv6}\r"
				sleep 1
			fi
		fi
	else
		sec=0
		ret=$ip
	fi
}
main_handler() {
	while [ "$ret" == "" ] || [ $trace == 1 ]; do
		main;
		if [ "$ret" != "" ]; then
			gateway=`route -n get default -ifscope $inet 2>/dev/null|grep gateway|awk '{print $2}'`
			SSID=`${airport} -I | grep '^[ ]*SSID' | awk '{print $2}'`
			BSSID=`${airport} -I | grep '^[ ]*BSSID' | awk '{print $2}'`
			channel=`${airport} -I | grep '^[ ]*channel' | awk '{print $2}'`
			echo -e "IPv4: \r\033[6C${IPv4}\r\033[22C/\r\033[24C${gateway}\tIPv6: ${IPv6}\n > SSID: ${SSID}(${channel}@${BSSID})"
			if [ "$pattern" != "" ] && [ "$gates" != "" ]; then
				ping_hosts=""
				for pt in $gates
				do
					ptt=`echo \`echo $gateway | grep -o -e "${pattern}" | grep -v '^\.'\` | awk '{print $1}'`
					ping_hosts="${ping_hosts} ${ptt}${pt}"
				done
				ping_test_hosts="${gateway} 168.95.1.1 8.8.8.8 ${ping_hosts}"
			else
				ping_test_hosts=""
			fi
			WAIT_TIME=1
			if [ "$ping_hosts" != "" ]; then
				WAIT_TIME=3
				otherGateway=`echo $ping_hosts | sed -e 's/${gateway}//'`
				otherGateway="${otherGateway} ${gateway}"
				for og in $otherGateway
				do
					echo "Test form gateway: '${og}'"
					sudo route change default -ifscope ${inet} ${og} 1>/dev/null 2>/dev/null
					for pt in $ping_test_hosts
					do
						pingResult=`ping -S ${IPv4} -W ${PING_TIME} -c 1 ${pt} 2>/dev/null && echo "${PING}${PING_OK}" || echo "${PING}${PING_FAILED}"`
						resultText=`echo -e "$pingResult" | grep ttl | grep time | awk '{print $7" "$8}'`
						result=`echo "$pingResult" | grep "${PING}" | sed -e "s/${PING}//"`
						if [ "$resultText" == "" ]  && [ "$result" != "$PING_FAILED" ]; then
							resultText=$PING_TIMEOUT
						fi
						echo -e "${testPrefixText}${pt}\r\033[32C${resultText}${result}"
					done
					echo -e "Web(http/https) Connecting Testing for 3secs..."
					httpsTest=`curl --interface ${inet} --verbose --insecure --ipv4 --head --connect-timeout 3 --url https://google.com 2>/dev/null| grep 'HTTP/1.1' && echo "${Web_OK}" || echo "${Web_FAILED}"`
					httpsTest=`echo "${httpsTest}" | grep -v "HTTP/1.1"`
					echo -e "\thttps${httpsTest}"
					httpTest=`curl --interface ${inet} --verbose --insecure --ipv4 --head --connect-timeout 3 --url http://google.com 2>/dev/null| grep 'HTTP/1.1' && echo "${Web_OK}" || echo "${Web_FAILED}"`
					httpTest=`echo "${httpTest}" | grep -v "HTTP/1.1"`
					echo -e "\t http${httpTest}"
					httpSheepTest=`curl --interface ${inet} --basic --user {$RANDOM}:{$RANDOM} --verbose --insecure --ipv4 --head --connect-timeout 3 --url "http://{$RANDOM}.public.hhmr.biz" 2>/dev/null| grep 'HTTP/1.1' && echo "${Sheep_OK}" || echo "${Sheep_FAILED}"`
					httpSheepTest=`echo "${httpSheepTest}" | grep -v "HTTP/1.1"`
					echo -e "\t http${httpSheepTest}"
				done
			fi
			sleep $WAIT_TIME
		fi
	done
}
exit_handler() {
	echo -ne "\r                                                            "
	if [ $trace == 0 ]; then
		echo -e "\rdone!"
		#\nIPv4: $IPv4\nIPv6: $IPv6"
	else
		echo -e "\rSIGINT exit!"
	fi
	if [ "${otherGateway}" != "" ]; then
		echo -e "rollback to gateway: ${defaultGateway}"
		sudo route change default -ifscope ${inet} ${defaultGateway} 1>/dev/null 2>/dev/null
		echo -e "rollback to original window size ${origLines}:${origCols} \033[8;${origLines};${origCols}t"
		echo -e "done!\r"
	fi
	echo -ne "\r\033[?25h\r"
	exit 2
}
trap exit_handler SIGHUP SIGINT SIGQUIT SIGKILL SIGTERM SIGSTOP SIGTSTP SIGUSR1 SIGUSR2
defaultGateway=`route -n get default -ifscope $inet 2>/dev/null|grep gateway|awk '{print $2}'`
main_handler;
exit_handler;
