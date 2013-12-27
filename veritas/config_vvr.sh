#!/bin/bash
#title           :config_vvr.sh
#description     :This script will config VVR.
#author         :xubingbing
#date            :20130821
#version         :0.1    
#usage         :config_vvr.sh <secondary_server_ip> <primary_server_ip = optional>
#notes           :Veritas must be installed & configured beforehead, 
#                  之前需启动SFHA
#==============================================================================
configType=$1
#check 
if [ "$configType" != "pri" ] && [ "$configType" != "sec" ];then
    echo "[ERROR]`date +'%Y%m%d %H:%M:%S'` $0($LINENO) [MSG]Usage: $0  pri|sec. at least 1 argument required."
    exit 1
fi
        
if [ "$configType" == "sec" ];then
    echo "[INFO]`date +'%Y%m%d %H:%M:%S'` $0($LINENO) [MSG]Do nothing on secondary."
    exit 0
fi

. ./hacommon.sh
#需加入异常检查
#设置VVR，进行全同步
output "INFO" "Create Primary RVG $RVG_NAME $VOL_MYSQL_NAME,$VOL_SRV_NAME $VOL_SRL_NAME" $LINENO
vradmin -g $DISK_GROUP createpri $RVG_NAME $VOL_MYSQL_NAME,$VOL_SRV_NAME $VOL_SRL_NAME
if [ $? -ne 0 ];then
    output "ERROR" "VVR failed:vradmin -g $DISK_GROUP createpri $RVG_NAME $VOL_MYSQL_NAME,$VOL_SRV_NAME $VOL_SRL_NAME" $LINENO
    exit 1
fi

output "INFO" "Add Secondary RVG $RVG_NAME $PRI_IP $SEC_IP" $LINENO
vradmin -g $DISK_GROUP addsec $RVG_NAME $PRI_IP $SEC_IP prlink=to_secondary_eapp srlink=to_primary_eapp
if [ $? -ne 0 ];then
    output "ERROR" "VVR failed:vradmin -g $DISK_GROUP addsec $RVG_NAME $PRI_IP $SEC_IP prlink=to_secondary_eapp srlink=to_primary_eapp" $LINENO
    exit 1
fi



exit 0

