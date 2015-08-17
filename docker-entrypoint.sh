#!/bin/sh

#
# Docker wrapper for starting EXIM4
#

PROGNAME=$(basename $0)

if test -z ${SMTP_USERNAME} || test -z ${SMTP_PASSWORD}; then
    echo "${PROGNAME}: both SMTP_USERNAME and SMTP_PASSWORD are required" >&2
    exit 1
fi

if test -z ${AWS_REGION}; then
    AWS_REGION=$(curl --max-time 3 -s http://169.254.169.254/latest/dynamic/instance-identity/document | python -c 'import sys, json; print json.load(sys.stdin)["region"]')
fi

if test -z ${AWS_REGION}; then
    echo "${PROGNAME}: could not determine AWS_REGION" >&2
    exit 1
fi

# Thanks, SO http://stackoverflow.com/q/20762575/115478
mask2cidr() {
   # Assumes there's no "255." after a non-255 byte in the mask
   local x=${1##*255.}
   set -- 0^^^128^192^224^240^248^252^254^ $(( (${#1} - ${#x})*2 )) ${x%%.*}
   x=${1%%$3*}
   echo $(( $2 + (${#x}/4) ))
}

getnet() {
    local IFC=$1

    local INET4=$(/sbin/ifconfig ${IFC} | sed -n 's/^ *inet addr:\([0-9.]*\) .*$/\1/ p')
    local NETMASK4=$(/sbin/ifconfig ${IFC} | sed -n 's/^ *inet addr:[0-9.]*.*Mask:\([0-9.]*\).*$/\1/ p')

    echo ${INET4}/$(mask2cidr ${NETMASK4})
}

if test -z ${DC_RELAY_NETS}; then
    # Assume that eth0 is the docker network
    DC_RELAY_NETS=$(getnet eth0)
fi

if test -z ${DC_RELAY_NETS}; then
    echo "${PROGNAME}: could not determine DC_RELAY_NETS" >&2
    exit 1
fi

set -ex

find /etc/exim4 -name '*.j2' | while read template; do
    j2 ${template} > $(dirname ${template})/$(basename ${template} .j2)
done

/usr/sbin/update-exim4.conf

# initialize the spool dir, if needed
if ! test -e /data/ses-relay; then
    mkdir -p /data/ses-relay
fi

if test -d /data/ses-relay && test -e /data/ses-relay; then
    cp -a /var/spool/exim4 /data/ses-relay/spool
fi

exec "$@"
