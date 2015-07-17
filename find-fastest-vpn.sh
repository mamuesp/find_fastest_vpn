#!/bin/bash
#
# SCRIPT  :   find-fastest-vpn.sh
# PURPOSE :   out of a bundle of OpenVPN configuration files, determine the fastest
#             connection and link the corresponding .ovpn file as current connection
# COPYRIGHT:  Manfred Mueller-Spaeth, fms1961@gmail.com
# LICENSE:    This script might be used under the MIT License (MIT)
#

######################## function usage ###############################
#
# A little usage hint if the script is called with the wrong parameters
# Might be extended with a little help text in the future.
#
usage () {
    echo    "$*"
    echo -e ""      
    echo -e "Usage: ${0##*/} -p <VPN service provider>\n" 1>&2; exit 1;
}

######################## function doLog ###############################
#
# This function prints a message to stdout and an optional logfile,
# if VERBOSE is set to true. If not, it logs only to the logfile 
# defined with the second paraemter
#
function doLog() {
	if [ $VERBOSE ] || [ ${3} ]; then
		echo ${1} | tee -a ${2}
	else
		echo ${1} >> ${2}
	fi
}

######################## function printSettings ###############################
#
# This function prints all parameters used in this script if DOUBLE_VERBOSE
# is set to "true"
#
function printSettings() {
	if [ $DOUBLE_VERBOSE == true ]; then
		echo "List of settings:"
		HLP_OVPN_PATH="OpenVPN settings path"
		HLP_CONF_PATH="Configurations path" 
		HLP_CONF_CURR="Current active OVPN config" 
		HLP_PROVIDER="VPN Server Provider" 
		HLP_IPERF_SRV="Public IPERF server"
		HLP_CONF_PREPS="Path for prepared configs"
		HLP_CONF_FILES="Path of original configs"
		HLP_CONF_HOSTS="List of hosts to examine"
		HLP_CONF_ADDS="Specific settings"
		HLP_CONF_TEMP_PATH="Path for temp files"
		HLP_BW_FILE="Storing the best bandwidth"
		HLP_CONF_LOGBASE="Logging base for log files" 
		HLP_PERFLOG="Performance logfile" 
		HLP_LOGFILE="Standard openvpn client log" 
		HLP_FASTLOG="Perfomance measurement log" 

		gap=30
	
		printf "${COL_BLUE}$HLP_OVPN_PATH ${COL_NORM}"; tput cuf $(($gap - ${#HLP_OVPN_PATH})); echo ${COL_GREEN}$OVPN_PATH${COL_NORM};
		printf "${COL_BLUE}$HLP_CONF_PATH ${COL_NORM}"; tput cuf $(($gap - ${#HLP_CONF_PATH})); echo ${COL_GREEN}$CONF_PATH${COL_NORM};
		printf "${COL_BLUE}$HLP_CONF_CURR ${COL_NORM}"; tput cuf $(($gap - ${#HLP_CONF_CURR})); echo ${COL_GREEN}$CONF_CURR${COL_NORM};
		printf "${COL_BLUE}$HLP_PROVIDER ${COL_NORM}"; tput cuf $(($gap - ${#HLP_PROVIDER})); echo $PROVIDER${COL_NORM};
		printf "${COL_BLUE}$HLP_IPERF_SRV ${COL_NORM}"; tput cuf $(($gap - ${#HLP_IPERF_SRV})); echo $IPERF_SRV${COL_NORM};
		printf "${COL_BLUE}$HLP_CONF_PREPS ${COL_NORM}"; tput cuf $(($gap - ${#HLP_CONF_PREPS})); echo ${COL_YELLOW}$CONF_PREPS${COL_NORM};
		printf "${COL_BLUE}$HLP_CONF_FILES ${COL_NORM}"; tput cuf $(($gap - ${#HLP_CONF_FILES})); echo ${COL_YELLOW}$CONF_FILES${COL_NORM};
		printf "${COL_BLUE}$HLP_CONF_HOSTS ${COL_NORM}"; tput cuf $(($gap - ${#HLP_CONF_HOSTS})); echo ${COL_YELLOW}$CONF_HOSTS${COL_NORM};
		printf "${COL_BLUE}$HLP_CONF_ADDS ${COL_NORM}"; tput cuf $(($gap - ${#HLP_CONF_ADDS})); echo ${COL_YELLOW}$CONF_ADDS${COL_NORM};
		printf "${COL_BLUE}$HLP_CONF_TEMP_PATH ${COL_NORM}"; tput cuf $(($gap - ${#HLP_CONF_TEMP_PATH})); echo ${COL_YELLOW}$CONF_TEMP_PATH${COL_NORM};
		printf "${COL_BLUE}$HLP_BW_FILE ${COL_NORM}"; tput cuf $(($gap - ${#HLP_BW_FILE})); echo ${COL_YELLOW}$BW_FILE${COL_NORM};
		printf "${COL_BLUE}$HLP_CONF_LOGBASE ${COL_NORM}"; tput cuf $(($gap - ${#HLP_CONF_LOGBASE})); echo ${COL_CYAN}$CONF_LOGBASE${COL_NORM};
		printf "${COL_BLUE}$HLP_PERFLOG ${COL_NORM}"; tput cuf $(($gap - ${#HLP_PERFLOG})); echo ${COL_CYAN}$PERFLOG${COL_NORM};
		printf "${COL_BLUE}$HLP_LOGFILE ${COL_NORM}"; tput cuf $(($gap - ${#HLP_LOGFILE})); echo ${COL_CYAN}$LOGFILE${COL_NORM};
		printf "${COL_BLUE}$HLP_FASTLOG ${COL_NORM}"; tput cuf $(($gap - ${#HLP_FASTLOG})); echo ${COL_CYAN}$FASTLOG${COL_NORM};
	fi
}

######################## function setDefaults ###############################
#
# This function sets the default parameters used in this script
#
function setDefaults() {
	# OpenVPN settings path
	OVPN_PATH="/etc/openvpn/"
	# Configurations path
	CONF_PATH="${OVPN_PATH}providers/"
	# Current active OVPN config
	CONF_CURR="${OVPN_PATH}current.conf"
	# VPN Server Provider
	CONF_PROVIDER="freevpns"
	# Public server which offers the server part for iperf bw measurements
	IPERF_SRV="ping.online.net"
	# Path for prepared configs
	CONF_PREPS="${CONF_PATH}${PROVIDER}preps/"
	# Path of original configs
	CONF_FILES="${CONF_PATH}${PROVIDER}configs/"
	# Full path and filename of list of hosts to examine
	CONF_HOSTS="${CONF_PATH}${PROVIDER}vpnhosts"
	# Full path and filename of specific (providers and users) settings
	CONF_ADDS="${CONF_PATH}${PROVIDER}additional.txt"
	# Path for temp files
	CONF_TEMP_PATH="${CONF_PATH}tmp/"
	# path to file for storing the fastest bandwidth measured
	BW_FILE="${CONF_TEMP_PATH}currBW" 
	# Logging base for open vpn log files
	CONF_LOGBASE="/var/log/openvpn/"
	# Performance logfile
	PERFLOG="${CONF_LOGBASE}iperf.log"
	# Standard openvpn client logfile
	LOGFILE="${CONF_LOGBASE}client.log"
	# Perfomance measurement results logfile
	FASTLOG="${CONF_LOGBASE}fastvpn.log"
	# color settings
	COL_BLACK="$(tput setaf 0)"
	COL_RED="$(tput setaf 1)"
	COL_GREEN="$(tput setaf 2)"
	COL_YELLOW="$(tput setaf 3)"
	COL_BLUE="$(tput setaf 4)"
	COL_MAGENTA="$(tput setaf 5)"
	COL_CYAN="$(tput setaf 6)"
	COL_WHITE="$(tput setaf 7)"
	COL_NORM="$(tput setaf 9)"
	COL_NORM=$COL_BLACK
	# Text attributes variables
	TXT_UNDERL=$(tput sgr 0 1) # Underline
	TXT_BOLD=$(tput bold)      # Bold
	TXT_RES=$(tput sgr0)       # Reset
}

######################## function timestamp ###############################
#
# This function returns a formatted timestamp
#
function timestamp() {
	date +"%Y-%m-%d_%H-%M-%S"
}

######################## function firstWord ###############################
#
# This function returns the first word of a textline
#
function firstWord() {
	echo $1 | awk '{split($0,a,/ /); print a[1]}'
}

######################## function prepareConfig ###############################
#
# This function sets the value of a parameter as defined in "additional.txt"
# or appends a new parameter in a new line, if it does exist in the 
# configuration file (
#
function prepareConfig() {
	sWord="$(firstWord $1)"
	echo "${1} - ${2}"
	if [ ${#sWord} -gt 0 ]; then
		clear="sed -i '/$sWord/d' $2"
		test="$( eval $clear )"
	fi
}

###################### function connectionActive ###############################
#
# This function checks whether there is an OpenVPN connection active
#
function connectionActive() {
	test="$( ifconfig tun0 2> /dev/null | grep -c '00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00' )"
	return test
}

######################## function checkHosts ###############################
#
# This function tries to open an openvpn tunnel with the settings of the 
# actually read configuration from "vpnhosts". If successful, the possible
# bandwidth will be determined via "iperf", the value will be compared with
# the other results laster on.
#
function checkHosts() {
	lineLen=${#2}
	
	if [[ ${2:0:1} != '#' ]] && [[ $lineLen -gt 0 ]]; then
		currConf="${2}"
		doLog "$( timestamp ) - current conf: ${currConf}" ${FASTLOG}
		# set the source for the preparation
		srcConf="${CONF_PREPS}${currConf}"
		if [ "${FORCE_PREPS}" = true ] || ! [ -f "${srcConf}" ]; then
			doLog "$( timestamp ) - customize current conf" ${FASTLOG}
			# copy the ovpn file to the preps folder
			test="$( cp -a ${CONF_FILES}${currConf} ${srcConf} )"
			for line in "${addLines[@]}"; do
				cmd="prepareConfig '${line}' '${srcConf}'"
				test="$( eval ${cmd} )"
			done
			test="$( cat ${CONF_ADDS} >> ${srcConf} )"
			sed -i -e '/^\s*$/d' ${srcConf}
		fi

		if [ -f "${srcConf}" ]; then
			stop="$( service openvpn stop > /dev/null )"
			link="$( ln -sf ${srcConf} ${CONF_CURR} )"
			start="$( service openvpn start )"
			sleep 3
			bandWidth=$bwNone
			echo ${bandWidth} > "${BW_FILE}"
			doEndTail=false
			tail -f "${LOGFILE}" | while read -t 10 LOGLINE; do
				if [[ -z "${LOGLINE}" && $? -ne 0 ]] ; then
					# Variable is empty and read timed out
					doEndTail=true
				else
					#echo -e "${LOGLINE}"
					if [[ "${LOGLINE}" == *"Cannot resolve host address"* ]]; then
						doEndTail=true
						bandWidth=$bwNone
					fi
					if [[ "${LOGLINE}" == *"Initialization Sequence Completed"* ]]; then
						doEndTail=true
						iperf -c ${IPERF_SRV} -f m -n 1M -p 5001 >> $perfLog
						#iperf -c ping.online.net -i 2 -t 20 -r
						bandWidth="$( echo -e $(awk '/Bandwidth/ {getline}; END{print $8}' $perfLog) )"
						if [[ $bandWidth =~ ^[0-9\.]+$ ]]; then
							doLog "$( timestamp )"" - Bandwidth: ${bandWidth} Mbits/sec" ${FASTLOG}
							echo ${bandWidth} > "${BW_FILE}"
						fi
					fi
				fi
				if [[ $doEndTail = true ]]; then
					# Nothing else is using the log file     
					pkill -f "tail -f ${LOGFILE}"  # Specific, so we don't kill tails of other files
					break
				fi
			done
		fi

		bandWidth=$(<"${BW_FILE}")
		doLog "$( timestamp )"" - Check Bandwidth ${bandWidth} against fastest: ${fastestBw} ..." ${FASTLOG}
		if (( $(bc <<< "${bandWidth} > ${bwNone}") == 1 )); then
			currBw=$bandWidth
			if (( $(bc <<< "${currBw} > ${fastestBw}") == 1 )); then
				shortConf=$currConf
				fastestConf=$srcConf
				fastestBw=$currBw
			fi
		fi
	fi
}

######################## function startFinding ###############################
#
# This function handles the performance measurement of the configurations
# which are found in the list "vpnhosts" and are not commented (deactivated)
#
function startFinding() {

    if ! [[ -d "${CONF_PATH}${PROVIDER}" ]]; then
    	echo "Provider ${PROVIDER} does not exists!"
    	exit 1;
    fi
    if ! [[ -f "${CONF_ADDS}" ]]; then
    	echo "Settings file 'additional.txt' does not exists!"
    	exit 1;
    fi
    if ! [[ -f "${CONF_HOSTS}" ]]; then
    	echo "Selection list of VPN hosts 'vpnhosts' does not exists!"
    	exit 1;
    fi

    # add ip / hostname separated by white space
    bwNone=-1.0
    bandWidth=${bwNone}
    fastestBw=${bwNone}
    currBw=${bwNone}
    fastestConf="<none>"
    srcConf="<none>"
    perfLog="${PERFLOG}"

    if [ -f $perfLog ]; then
        rm $perfLog
    fi

    if [ -f "${BW_FILE}" ]; then
        echo "-1.0" > "${BW_FILE}"
    fi
    if ! [[ -d "${CONF_TEMP_PATH}" ]]; then
        mkdir -p ${CONF_TEMP_PATH}
    fi
    if ! [[ -d "${CONF_PREPS}" ]]; then
        mkdir -p ${CONF_PREPS}
    fi
    mapfile -t addLines < "$CONF_ADDS"
    fastestConf="$( realpath ${CONF_CURR} )"

    doLog "$( timestamp )"" - Service stopped ... " ${FASTLOG} true
	doLog "$( timestamp ) - read host list: ${CONF_HOSTS}" ${FASTLOG}

    if [[ -f "${CONF_HOSTS}" ]]; then
        mapfile -t -c 1 -C 'checkHosts' < "${CONF_HOSTS}"
    fi

    if [[ -f "${fastestConf}" ]]; then
        link="$( ln -sf ${fastestConf} ${CONF_CURR} )"
        echo "$( timestamp )"" - New conf: ${shortConf} - ${fastestBw} Mbit/sec" | tee -a ${FASTLOG}
    fi

    dL="$( service openvpn restart )"
    echo "$( timestamp )"" - Service restarted ... " | tee -a ${FASTLOG}
}

function getPathName() {
	pushd . > /dev/null
	SCRIPT_PATH="${BASH_SOURCE[0]}";
	if ([ -h "${SCRIPT_PATH}" ]); then
		while([ -h "${SCRIPT_PATH}" ]); do cd `dirname "$SCRIPT_PATH"`; SCRIPT_PATH=`readlink "${SCRIPT_PATH}"`; done
	fi
	cd `dirname ${SCRIPT_PATH}` > /dev/null
	SCRIPT_PATH=`pwd`;
	popd  > /dev/null
	echo $SCRIPT_PATH
}

######################## function delTempFiles ###############################

# This function is called by trap command
# For conformation of deletion use rm -fi *.$$

delTempFiles() {
    rm -f *.$$
    if [ -f "${BW_FILE}" ]; then rm -f "${BW_FILE}"; fi
    if [ -f $perfLog ]; then rm -f $perfLog; fi
}

##############################################################################
#                           THE SCRIPT STARTS HERE                           #
##############################################################################
trap 'delTempFiles'  EXIT     # calls deletetempfiles function on exit

# at first set the parameters to its default values
setDefaults

# ... then get the options from the command line
PROVIDER=""
FORCE_PREPS=false
VERBOSE=false
DOUBLE_VERBOSE=false
DEBUG=false
DEBUGFILE=
SCRIPT_PATH="$( getPathName $0 )"
SCRIPT="$( basename $0 )"
SCRIPT=$SCRIPT_PATH"/"$SCRIPT

while true; do
  case "$1" in
    -f | --force_preps ) FORCE_PREPS=true; shift ;;
    -v | --verbose ) VERBOSE=true; shift ;;
    -vv | --double_verbose ) VERBOSE=true; DOUBLE_VERBOSE=true; shift ;;
    -d | --debug ) DEBUG=true; shift ;;
    -p | --provider ) OPT_PROVIDER="$2/"; shift 2 ;;
    --debugfile ) DEBUGFILE="$2"; shift 2 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# check configuration
confFile="${SCRIPT//.sh/.conf}"
confFile=${confFile##*/}
# look in the folder of the script
confData="./${confFile}"
if [ ! -f "${confData}" ]; then
	# look in the folder /etc
	confData="/etc/${confFile}"
fi
if [ ! -f "${confData}" ]; then
	# look in the folder /etc/openvpn
	confData="/etc/openvpn/${confFile}"
fi

# get the provider name of the configuration file
if [ -f "${confData}" ]; then
	eval "grep 'CONF_PROVIDER' < $confData" > /dev/null 2> /dev/null
fi

# get the providers name
if [ "${#OPT_PROVIDER}" -gt 1 ]; then
	PROVIDER="${OPT_PROVIDER%/}/"
else
	if [ "${PROVIDER}" == "" ] && [ "${#CONF_PROVIDER}" -gt 1 ]; then
		PROVIDER="${CONF_PROVIDER%/}/"
	else
    	usage "($SCRIPT): VPN server provider is missing or empty! (${PROVIDER})"
	fi
fi

# load and evaluate the configuration file
if [ -f "${confData}" ]; then
	source $confData
fi

# optionally print the used settings/parameters
printSettings
# ... and go, do your job!
startFinding
