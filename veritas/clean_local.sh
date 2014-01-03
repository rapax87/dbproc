#!/bin/bash
#title           :clean.sh
#description     :This script will clean veritas config.
#author		 :xubingbing
#date            :20130821
#version         :0.1    
#usage		 :clean.sh 
#notes           :Destroy all vxvm, vvr, vxdg
#==============================================================================
	
. ./hacommon.sh

#/opt/VRTS/bin/hastatus -sum>/dev/null
#if [ $? -eq 0 ];then
#	#资源组ubpApp下线
#	output "INFO" "Offline ubpApp group" $LINENO
#	/opt/VRTS/bin/hagrp -offline -force ubpApp -any -localclus
#	sleep 60
#fi

local_ip=`hostname -i`
if [ "$local_ip" = "$PRI_IP" ];then
    secondary=$SEC_IP
elif [ "$local_ip" = "$SEC_IP" ];then
    secondary=$PRI_IP
else
    output "ERROR" "Local IP $local_ip is neither PRI($PRI_IP) nor SEC($SEC_IP), please check vcs.conf." $LINENO
    exit 1
fi

#判断本机ubpApp是否ONLINE
hagrp -state ubpApp -localclus|grep ONLINE
now_master=$?


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

pkill -9 -f "mysql"

#如MySQL数据库目录存在则备份数据至单机数据库目录
df -h|awk '{print $6}'|grep "$DB_PATH"
if [ $? -eq 0 ];then
    rm -Rf ${ORI_MYSQL_DATA_DIR}_bk
    mv $ORI_MYSQL_DATA_DIR ${ORI_MYSQL_DATA_DIR}_bk
    cp -Rf $DB_PATH/mysql $ORI_MYSQL_DATA_DIR
    if [ $? -ne 0 ];then
        output "ERROR" "Copy from $DB_PATH to $ORI_MYSQL_DATA_DIR/ failed." $LINENO
        exit 1
    fi
    
    for file in $UBPDB_EXCLUDE_FILES
    do
        rm -rf $ORI_MYSQL_DATA_DIR/ubpdb/$file
        cp -rf ${ORI_MYSQL_DATA_DIR}_bk/ubpdb/$file $ORI_MYSQL_DATA_DIR/ubpdb/$file
    done

    chown -R mysql:mysql $ORI_MYSQL_DATA_DIR
    chmod -R 775 $ORI_MYSQL_DATA_DIR
		
    ssh root@$secondary "rm -Rf ${ORI_MYSQL_DATA_DIR}_bk"
    ssh root@$secondary "mv $ORI_MYSQL_DATA_DIR ${ORI_MYSQL_DATA_DIR}_bk"
    scp -r $ORI_MYSQL_DATA_DIR root@$secondary:$ORI_MYSQL_DATA_DIR
    ssh root@$secondary "chown -R mysql:mysql $ORI_MYSQL_DATA_DIR"
    ssh root@$secondary "chmod -R 775 $ORI_MYSQL_DATA_DIR"
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



