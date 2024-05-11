#!/bin/bash
DEVNAME=$1

################## Custom Code to unlock Copy-protect drive ###########################
################## Requires VLC and CVLC installed ####################################
# Runs vlc for 6 seconds starting 16 seconds into the playback, then exits
/bin/su -l -c "cvlc --run-time 6 --start-time 16 ${DEVNAME} vlc://quit" -s /bin/bash arm
################## End Custom Code ####################################################

/opt/arm/scripts/thickclient/arm_wrapper.sh ${DEVNAME}