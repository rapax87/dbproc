#!/bin/bash
#title           :clean.sh
#description     :This script will change eapp IP.
#author		 :xubingbing
#date            :20130821
#version         :0.1    
#usage		 :clean.sh <second ip>
#notes           :Destroy all vxvm, vvr, vxdg
#==============================================================================
secondary=$1
	
. ./hacommon.sh

#/opt/VRTS/bin/hastatus -sum>/dev/null
#if [ $? -eq 0 ];then
#	#资源组ubpApp下线
#	output "INFO" "Offline ubpApp group" $LINENO
#	/opt/VRTS/bin/hagrp -offline -force ubpApp -any -localclus
#	sleep 60
#fi

#停止HA
/opt/VRTS/bin/hastop -local -force

output "INFO" "Kill upb..." $LINENO
pkill -9 -f "ubp_adm"
pkill -9 -f "ubp_sysd"
pkill -9 -f "ubp_svcd"

serveripline=`ifconfig | sed -n '/^\w/{N;s/\([^ ]*\).*addr:\([^ ]*\).*/\1 \2/p}'|grep $SERVERIP`
if [ -n "$serveripline" ];then
	nic=`echo $serveripline|awk '{print $1}'`
	ip=`echo $serveripline|awk '{print $2}'`
	output "INFO" "Delete $ip on $nic..." $LINENO
	ip addr del $ip/24 dev $nic
fi
priclusteripline=`ifconfig | sed -n '/^\w/{N;s/\([^ ]*\).*addr:\([^ ]*\).*/\1 \2/p}'|grep $PRIClusterIP`
if [ -n "$priclusteripline" ];then
	nic=`echo $priclusteripline|awk '{print $1}'`
	ip=`echo $priclusteripline|awk '{print $2}'`
	output "INFO" "Delete $ip on $nic..." $LINENO
	ip addr del $ip/24 dev $nic
fi
secclusteripline=`ifconfig | sed -n '/^\w/{N;s/\([^ ]*\).*addr:\([^ ]*\).*/\1 \2/p}'|grep $SECClusterIP`
if [ -n "$secclusteripline" ];then
	nic=`echo $secclusteripline|awk '{print $1}'`
	ip=`echo $secclusteripline|awk '{print $2}'`
	output "INFO" "Delete $ip on $nic..." $LINENO
	ip addr del $ip/24 dev $nic
fi



#停止MySQL数据库
/sbin/service mysql status>/dev/null
if [ $? -eq 0 ];then
	output "INFO" "Stop MySQL..." $LINENO
	/sbin/service mysql stop
fi

output "INFO" "Recover /etc/my.cnf" $LINENO
if [ -f /opt/UBP/conf/my.cnf ];then
    cp -rf /opt/UBP/conf/my.cnf /etc/my.cnf
    chmod 755 /etc/my.cnf
    #scp -r /opt/UBP/conf/my.cnf root@$secondary:/etc/my.cnf
    #ssh root@$secondary "chmod 755 /etc/my.cnf"
else
    output "WARN" "/opt/UBP/conf/my.cnf not exist, please recover /etc/my.cnf manually" $LINENO
fi

#卸载目录
df -h|awk '{print $6}'|grep "$DB_PATH"
if [ $? -eq 0 ];then
	output "INFO" "umount $DB_PATH..." $LINENO
	umount $DB_PATH
fi
df -h|awk '{print $6}'|grep "$SRV_PATH"
if [ $? -eq 0 ];then
	output "INFO" "umount $SRV_PATH..." $LINENO
	umount $SRV_PATH
fi

#删除volume
/opt/VRTS/bin/vxedit -g $DISK_GROUP -rf rm $RVG_NAME
#删除disk group
/opt/VRTS/bin/vxdg destroy $DISK_GROUP
/opt/VRTS/bin/vxdiskunsetup -C $DISK_NAME

exit 0

if [ ! -z $secondary ];then
    ssh root@$secondary "/opt/VRTS/bin/hagrp -offline ubpApp -any -localclus"
    ssh root@$secondary "/opt/VRTS/bin/hastop -local -force"
    ssh root@$secondary "service mysql stop"
    ssh root@$secondary "umount $DB_PATH"
    ssh root@$secondary "umount $SRV_PATH"
    ssh root@$secondary "vxedit -g $DISK_GROUP -rf rm $RVG_NAME"
    ssh root@$secondary "/opt/VRTS/bin/vxdg destroy $DISK_GROUP"
    ssh root@$secondary "/opt/VRTS/bin/vxdiskunsetup -C $DISK_NAME"
fi


