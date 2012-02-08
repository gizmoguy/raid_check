#!/bin/bash
#
# Nagios check script for SMART status of disks over SNMP

print_usage() {
	echo "Usage: $0 [hostname] [snmp read community] [temp warn level] [temp critical level] [realloc'd sector warn level] [realloc'd sector critical level]"
	exit 3
}

case "$1" in
	--help)
		print_usage
	;;
	-h)
		print_usage
	;;
esac

if [ $# -ne 6 ]; then
	print_usage
fi

DEVICE=$1
COMMUNITY=$2
TEMP_WARN=$3
TEMP_CRIT=$4
REALLOC_WARN=$5
REALLOC_CRIT=$6
OID_DEVICES="NET-SNMP-EXTEND-MIB::nsExtendOutLine.\"smartdevices\""
OID_TEMP="NET-SNMP-EXTEND-MIB::nsExtendOutLine.\"smarttemp\""
OID_REALLOC="NET-SNMP-EXTEND-MIB::nsExtendOutLine.\"smartrawrealloc\""

DEVICES=`snmpwalk -v 2c -O qv -c $COMMUNITY $DEVICE $OID_DEVICES`

if [[ $DEVICES =~ "No Such Instance" ]]; then
	echo "No SMART data available over SNMP"
	exit 0
fi

TEMPS=`snmpwalk -v 2c -O qv -c $COMMUNITY $DEVICE $OID_TEMP`
REALLOCS=`snmpwalk -v 2c -O qv -c $COMMUNITY $DEVICE $OID_REALLOC`

DEV=()
for d in $DEVICES; do
	DEV+=($d)
done

# If the return from snmpget wasn't 0 then we should return an UNKNOWN status
if [ ! $? -eq 0 ]; then
	echo "snmpget failed, is SNMP up on the remote host and is it returning check_disks data?"
	exit 3
fi

STATUS=0

# Check temperatures
c=0
for t in $TEMPS; do
	if [ $t -ge $4 ]; then
		echo -n "CRITICAL: ${DEV[$c]} - temperature is $t deg C "
		STATUS=2
	elif [ $t -ge $3 ]; then
		echo -n "WARNING: ${DEV[$c]} - temperature is $t deg C "
		if [ $STATUS -lt 1 ]; then
			STATUS=1
		fi
	fi
	let c=$c+1
done

# Check reallocated sectors
c=0
for t in $REALLOCS; do
	if [ $t -ge $6 ]; then
		echo -n "CRITICAL: ${DEV[$c]} - $t reallocated sectors "
		STATUS=2
	elif [ $t -ge $5 ]; then
		echo -n "WARNING: ${DEV[$c]} - $t reallocated sectors "
		if [ $STATUS -lt 1 ]; then
			STATUS=1
		fi
	fi
	let c=$c+1
done

echo

# Exit with the appropriate exit status
exit $STATUS
