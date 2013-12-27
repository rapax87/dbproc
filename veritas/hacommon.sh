#!/bin/bash

#title           :hacommon.sh
#description     :This script will make create main.cf file 
#                 from template and ini files.
#author		 :xubingbing
#date            :20130821
#version         :0.1    
#usage		 :hacommon.sh 
#notes           :Veritas must be installed & configured beforehead, 
#                  an original main.cf should have already existed.
#==============================================================================
. /opt/UBP/bin/common.sh
. ./conf/vcs.conf
#新mysql数据目录，与my.cnf.vrts中定义相同
DB_PATH=/opt/mysql/data
SRV_PATH=/srv
#original mysql data path, same as my.cnf
ORI_MYSQL_DATA_DIR=/home/data/mysql
#volume path
VOLUME_PATH=/dev/vx/rdsk

#VCS Bin
###############################
VCS_BIN=/opt/VRTS/bin
VCS_MAN=/opt/VRTS/man
AGENT_FILE=/opt/VRTSvcs/bin
VCS_CONF=/etc/VRTSvcs/conf/config
#LOG_FILE=/tmp/vcsConfig.log
LOG_FILE=/opt/UBP/logs/ubp_vcsConfig.log

function output()
{
    if [ $# -lt 2 ]
    then
        exit 1
    else
        level=$1
        msg=$2
        lineno=$3
        echo "[$level]`date +'%Y%m%d %H:%M:%S'` $0($lineno) [MSG]$msg" | tee -a $LOG_FILE
    fi
}

ORI_CFDIR=/etc/VRTSvcs/conf/config
ORI_CFFILE=$ORI_CFDIR/main.cf
ORI_BINDIR=/opt/VRTSvcs/bin
ORI_AGENT_BINDIR=$ORI_BINDIR/eAPPApplication
ORI_AGENT_BINFILE_TEMPLATE=$ORI_BINDIR/Script51Agent
ORI_AGENT_BINFILE=$ORI_AGENT_BINDIR/eAPPApplicationAgent
ORI_AGENT_CFFILE=$ORI_CFDIR/eAPPTypes.cf
#不同步的数据库文件
UBPDB_EXCLUDE_FILES="TBL_UBPNode.ibd
TBL_UBPService.ibd
TBL_MRSNode.ibd
TBL_web_host_info.ibd
TBL_CallRecTaskInfo.ibd
TBL_RecPttInfo.ibd
TBL_RecPremptedInfo.ibd
TBL_IpcRecTaskInfo.ibd
TBL_BCCInfo.ibd
TBL_RecSipInfo.ibd
TBL_MRSBackupMode.ibd
TBL_MRSStorageResource.ibd"

SDSDB_EXCLUDE_FILES=""
#需同步的目录
SYN_DIRS="/opt/UBP/data/fm /opt/SDS/openfire/plugins/admin/webapp/upload /opt/UBP/ftp/license"

HASTART="/etc/init.d/vcs start"
HASTOP="/opt/VRTS/bin/hastop -local -force"
HASTATUS="/opt/VRTS/bin/hastatus -sum"

#plan=1: 方案一、 修改数据目录，仅链接不同步数据
#plan=2: 方案二、 不修改数据目录，链接同步数据
plan=1

#Set PATH
#VCS_PATH=`env | grep ^PATH | grep ${VCS_BIN} | wc -l`
#if [ $VCS_PATH -eq 0 ]
#then
#	export PATH=$PATH:$VCS_BIN
#	export MANPATH=$MANPATH:$VCS_MAN
#fi






