#!/bin/bash
#
# Nagios check script for RAIDs that expose their information over SNMP using check_raid

print_usage() {
	echo "Usage: $0 [hostname] [snmp read community]"
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

if [ $# -ne 2 ]; then
	print_usage
fi

DEVICE=$1
COMMUNITY=$2
OID_OUTPUT=".1.3.6.1.3.2.3.1.1.4.114.97.105.100"
OID_STATUS=".1.3.6.1.3.2.3.1.4.4.114.97.105.100"

OUTPUT=`snmpget -v 2c -O qv -c $COMMUNITY $DEVICE $OID_OUTPUT`
STATUS=`snmpget -v 2c -O qv -c $COMMUNITY $DEVICE $OID_STATUS`

# If the return from snmpget wasn't 0 then we should return an UNKNOWN status
if [ ! $? -eq 0 ]; then
	echo "snmpget failed, is SNMP up on the remote host and is it returning check_raid data?"
	exit 3
fi

# snmpget gives us quotations around the output let's strip those
echo ${OUTPUT:1:(${#OUTPUT}-2)}

# Exit with the appropriate exit status
exit $STATUS
