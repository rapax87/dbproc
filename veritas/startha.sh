#!/bin/bash
#title           :startha.sh
#description     :This script will start HA.
#author         :xubingbing
#date            :20130821
#version         :0.1    
#usage         :startha.sh <secondary_server_ip> 
#notes           :Veritas must be installed & configured beforehead, 
#                  an original main.cf should have already existed.
#==============================================================================
#参数取得
secondary=$1

. ./hacommon.sh

#Check Primary HA status
ret=`$HASTATUS`
if [ $? -eq 0 ];then
    output "WARN" "Primary HA already started" $LINENO
else
    #Start Primary HA
    ret=`$HASTART`
    if [ $? -ne 0 ];then
        output "ERROR" "Primary HA start failed" $LINENO
        exit 2
    fi
    output "INFO" "Primary HA started" $LINENO
fi

if [ ! -z $secondary ];then
    sleep 2
    #Check Secondary HA status
    ret=`ssh root@$secondary "$HASTATUS"`
    if [ $? -eq 0 ];then
        output "WARN" "Primary HA already started" $LINENO
    else
        #Start Secondary HA
        ret=`ssh root@$secondary "$HASTART"`
        if [ $? -ne 0 ];then
            output "ERROR" "Secondary HA start failed" $LINENO
            exit 3
        fi
        output "INFO" "Secondary HA started" $LINENO
    fi
fi

exit 0

