#!/bin/bash
#title           :copy_agent.sh
#description     :This script will make create main.cf file 
#                 from template and ini files.
#author		 :xubingbing
#date            :20130821
#version         :0.1    
#usage		 :copy_agent.sh <secondary_server_ip> <primary_server_ip = optional>
#notes           :Veritas must be installed & configured beforehead, 
#                  an original main.cf should have already existed.
#==============================================================================
#参数检查
if [ $# -lt 1 ]
then
    echo echo "[ERROR]`date +'%Y%m%d %H:%M:%S'` $0($LINENO) [MSG]at least 1 argument required."
    echo "Usage: $0 <secondary_server_ip> <primary_server_ip = optional>"
    exit 1
fi
secondary=$1
primary=$2

. ./hacommon.sh

TMP_AGENT_CFFILE=./conf/eAPPTypes.cf
TMP_AGENT_BINDIR=./eAPPApplication

#Backup Agent CF file
if [ -f $ORI_AGENT_CFFILE ];then
    cp -rf $ORI_AGENT_CFFILE $ORI_AGENT_CFFILE.`date +'%Y%m%d%H%M%S'`
    if [ $? -ne 0 ];then
        output "ERROR" "Backup primary $ORI_AGENT_CFFILE failed." $LINENO
        exit 2
    fi
fi
output "INFO" "Backup primary $ORI_AGENT_CFFILE OK." $LINENO

ssh root@$secondary "ls $ORI_AGENT_CFFILE"
if [ $? -eq 0 ];then
    ssh root@$secondary "cp -rf $ORI_AGENT_CFFILE $ORI_AGENT_CFFILE.`date +'%Y%m%d%H%M%S'`"
    if [ $? -ne 0 ];then
        output "ERROR" "Backup secondary $ORI_AGENT_CFFILE failed." $LINENO
        exit 3
    fi
fi
output "INFO" "Backup secondary $ORI_AGENT_CFFILE OK." $LINENO

#Backup Agent BIN directory
if [ -d $ORI_AGENT_BINDIR ];then
    cp -rf $ORI_AGENT_BINDIR $ORI_AGENT_BINDIR.`date +'%Y%m%d%H%M%S'`
    if [ $? -ne 0 ];then
        output "ERROR" "Backup primary $ORI_AGENT_BINDIR failed." $LINENO
        exit 4
    fi
fi
output "INFO" "Backup primary $ORI_AGENT_BINDIR OK." $LINENO
			
ssh root@$secondary "ls $ORI_AGENT_BINDIR"
if [ $? -eq 0 ];then
    ssh root@$secondary "cp -rf $ORI_AGENT_BINDIR $ORI_AGENT_BINDIR.`date +'%Y%m%d%H%M%S'`"
    if [ $? -ne 0 ];then
        output "ERROR" "Backup secondary $ORI_AGENT_BINDIR failed." $LINENO
        exit 5
    fi
fi
output "INFO" "Backup secondary $ORI_AGENT_BINDIR OK." $LINENO

#Replace Agent CF
cp -rf $TMP_AGENT_CFFILE $ORI_AGENT_CFFILE
if [ $? -ne 0 ];then
    output "ERROR" "Replace primary $ORI_AGENT_CFFILE with $TMP_AGENT_CFFILE failed." $LINENO
    exit 6
fi
output "INFO" "Replace primary $ORI_AGENT_CFFILE with $TMP_AGENT_CFFILE OK." $LINENO

scp $TMP_AGENT_CFFILE root@$secondary:$ORI_AGENT_CFFILE
if [ $? -ne 0 ];then
    output "ERROR" "Replace secondary $secondary:$ORI_AGENT_CFFILE with $TMP_AGENT_CFFILE failed." $LINENO
    exit 7
fi
output "INFO" "Replace secondary $secondary:$ORI_AGENT_CFFILE with $TMP_AGENT_CFFILE OK." $LINENO

#Replace Agent BINDIR
cp -rf $TMP_AGENT_BINDIR $ORI_BINDIR/
if [ $? -ne 0 ];then
    output "ERROR" "Replace primary $ORI_AGENT_BINDIR with $TMP_AGENT_BINDIR failed." $LINENO
    exit 10
fi
#sed -i "s/%SERVERIP%/$SERVERIP/g" $ORI_AGENT_BINDIR/online
output "INFO" "Replace primary $ORI_AGENT_BINDIR with $TMP_AGENT_BINDIR OK." $LINENO

scp -r $TMP_AGENT_BINDIR root@$secondary:$ORI_BINDIR/
if [ $? -ne 0 ];then
    output "ERROR" "Replace secondary $secondary:$ORI_AGENT_BINDIR with $TMP_AGENT_BINDIR failed." $LINENO
    exit 11
fi
#ssh root@$secondary "sed -i \"s/%SERVERIP%/$SERVERIP/g\" $ORI_AGENT_BINDIR/online"
output "INFO" "Replace secondary $secondary:$ORI_AGENT_BINDIR with $TMP_AGENT_BINDIR OK." $LINENO


#Replace ORI_AGENT_BINFILE
cp -rf $ORI_AGENT_BINFILE_TEMPLATE $ORI_AGENT_BINFILE
if [ $? -ne 0 ];then
    output "ERROR" "Replace primary $ORI_AGENT_BINFILE with $ORI_AGENT_BINFILE_TEMPLATE failed." $LINENO
    exit 12
fi
output "INFO" "Replace primary $ORI_AGENT_BINFILE with $ORI_AGENT_BINFILE_TEMPLATE OK." $LINENO

ssh root@$secondary "cp -rf $ORI_AGENT_BINFILE_TEMPLATE $ORI_AGENT_BINFILE"
if [ $? -ne 0 ];then
    output "ERROR" "Replace secondary $secondary:$ORI_AGENT_BINFILE_TEMPLATE with $ORI_AGENT_BINFILE failed." $LINENO
    exit 13
fi
output "INFO" "Replace secondary $secondary:$ORI_AGENT_BINFILE_TEMPLATE with $ORI_AGENT_BINFILE OK." $LINENO
		
exit 0

