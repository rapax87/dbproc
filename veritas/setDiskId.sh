#!/bin/bash
#title           :setDiskId.sh
#description     :This script will set disk ID.
#author		 :xubingbing
#date            :20130821
#version         :0.1    
#usage		 :setDiskId.sh <secondary_server_ip> 
#notes           :Veritas must be installed & configured beforehead, 
#                  an original main.cf should have already existed.
#==============================================================================


if [ $# -lt 1 ];then
    echo "[ERROR]`date +'%Y%m%d %H:%M:%S'` $0($LINENO) [MSG]1 argument required."
    echo "Usage: $0 <secondary_server_ip>" 
    exit 1
fi
secondary=$1
	
. ./hacommon.sh
	
####################################################################
#主备互相设置磁盘ID
####################################################################
vxdg list | grep $DISK_GROUP | awk '{print $3}' > /tmp/.rdg 
ssh root@$secondary "cp /etc/vx/vras/.rdg /etc/vx/vras/.rdg.`date +'%Y%m%d%H%M%S'`"
scp /tmp/.rdg root@${secondary}:/etc/vx/vras/.rdg

ssh root@$secondary "vxdg list | grep $DISK_GROUP | awk '{print \$3}'> /tmp/.rdg"
cp /etc/vx/vras/.rdg /etc/vx/vras/.rdg.`date +'%Y%m%d%H%M%S'`
scp  root@${secondary}:/tmp/.rdg /etc/vx/vras/.rdg

exit 0

