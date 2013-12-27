#!/bin/bash
#title           :stopha.sh
#description     :This script will stop HA.
#author         :xubingbing
#date            :20130821
#version         :0.1    
#usage         :stopha.sh <secondary_server_ip> 
#notes           :Veritas must be installed & configured beforehead, 
#                  an original main.cf should have already existed.
#==============================================================================
#参数取得
secondary=$1


. ./hacommon.sh

#Check Primary HA status
ret=`$HASTATUS`
if [ $? -ne 0 ];then
    output "WARN" "Primary HA already stopped" $LINENO
else
    #Stop Primary HA
    ret=`$HASTOP`
    if [ $? -ne 0 ];then
        echo $ret|grep "Cannot connect to VCS engine" 
        if [ $? -ne 0 ];then
            output "ERROR" "Primary HA stop failed" $LINENO
            exit 2
        fi
    fi
    output "INFO" "Primary HA stopped" $LINENO
fi

if [ ! -z $secondary ];then
    #Check Secondary HA status
    ret=`ssh root@$secondary "$HASTATUS"`
    if [ $? -ne 0 ];then
        output "WARN" "Secondary HA already stopped" $LINENO
    else
        #Stop Secondary HA
        ret=`ssh root@$secondary "$HASTOP"`
        if [ $? -ne 0 ];then
            echo $ret|grep "Cannot connect to VCS engine" 
            if [ $? -ne 0 ];then
                output "ERROR" "Secondary HA stop failed" $LINENO
                exit 3
            fi
        fi
        output "INFO" "Secondary HA stopped" $LINENO
    fi
fi

exit 0

