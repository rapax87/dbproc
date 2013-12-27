#!/bin/bash
#title           :config_vxvm.sh
#description     :This script will config VxVM.
#author         :xubingbing
#date            :20130821
#version         :0.1    
#usage         :config_vxvm.sh 
#notes           :Veritas must be installed & configured beforehead, 
#                  an original main.cf should have already existed.
#==============================================================================

####################################################################
#双机执行
####################################################################
configType=$1
#check 
if [ "$configType" != "pri" ] && [ "$configType" != "sec" ];then
    echo "[ERROR]`date +'%Y%m%d %H:%M:%S'` $0($LINENO) [MSG]Usage: $0  pri|sec. at least 1 argument required."
    exit 1
fi
    
. ./hacommon.sh
    
DISK_STATE=`vxdisk list | grep ^$DISK_NAME | awk '{print $5}'`
DISK_STATUS=`vxdisk list | grep ^$DISK_NAME | awk '{print $6}'`
#初始化 disk
output "INFO" "Begin init vxdisk." $LINENO
if [ "$DISK_STATE" == "offline" ] || [ "$DISK_STATUS" == "invalid" ];then
    $VCS_BIN/vxdisksetup -i $DISK_NAME >> $LOG_FILE 2>&1
    if [ $? -ne 0 ]
    then
        output "ERROR" "Init disk failed, please check command: $VCS_BIN/vxdisksetup -i $DISK_NAME." $LINENO
        exit 1
    fi
fi
output "INFO" "End init vxdisk." $LINENO

#创建vx diskgroup
output "INFO" "Begin create the disk group." $LINENO
DG_EXIST=`vxdg list | grep $DISK_GROUP | grep -v grep | wc -l`
if [ $DG_EXIST -eq 0 ] 
then
    vxdg init $DISK_GROUP $DISK_NAME
    if [ $? -ne 0 ];then
        output "ERROR" "Create disk group failed, please check command: vxdg init $DISK_GROUP $DISK_NAME." $LINENO
        exit 1
    fi
else
    #存在
    output "WARN" "Disk group $DISK_GROUP exists." $LINENO
fi
output "INFO" "End create the disk group." $LINENO

#创建卷srv
output "INFO" "Begin create the volume for srv." $LINENO
VOL_EXIST=`ls $VOLUME_PATH/$DISK_GROUP/ | grep $VOL_SRV_NAME | grep -v grep | wc -l`
if [ $VOL_EXIST -eq 0 ] 
then
    #创建卷srv volume
    vxassist -b -g $DISK_GROUP make $VOL_SRV_NAME $VOL_SRV_SIZE $DISK_NAME
    if [ $? -ne 0 ]
    then
        output "ERROR" "create volume failed, please check command: vxassist -b -g $DISK_GROUP make $VOL_SRV_NAME $VOL_SRV_SIZE $DISK_NAME." $LINENO
        exit 1
    fi
else
    output "WARN" "Volume $VOL_SRV_NAME exists." $LINENO
fi
output "INFO" "End create the volume for srv." $LINENO
        
#创建卷MySQL
output "INFO" "Begin create the volume for mysql." $LINENO
VOL_EXIST=`ls $VOLUME_PATH/$DISK_GROUP/ | grep $VOL_MYSQL_NAME | grep -v grep | wc -l`
if [ $VOL_EXIST -eq 0 ] 
then
    #创建卷mysql volume
    vxassist -b -g $DISK_GROUP make $VOL_MYSQL_NAME $VOL_MYSQL_SIZE $DISK_NAME
    if [ $? -ne 0 ]
    then
        output "ERROR" "create volume failed, please check command: vxassist -b -g $DISK_GROUP make $VOL_MYSQL_NAME $VOL_MYSQL_SIZE $DISK_NAME." $LINENO
        exit 1
    fi
else
    output "WARN" "Volume $VOL_MYSQL_NAME exist." $LINENO
fi
output "INFO" "End create the volume for mysql." $LINENO
        
#创建卷srl
output "INFO" "Begin create the volume for srl." $LINENO
VOL_EXIST=`ls $VOLUME_PATH/$DISK_GROUP/ | grep $VOL_SRL_NAME | grep -v grep | wc -l`
if [ $VOL_EXIST -eq 0 ] 
then
    #创建卷srl volume
    vxassist -b -g $DISK_GROUP make $VOL_SRL_NAME $VOL_SRL_SIZE $DISK_NAME
    if [ $? -ne 0 ]
    then
        output "ERROR" "create volume failed, please check command: vxassist -b -g $DISK_GROUP make $VOL_SRL_NAME $VOL_SRL_SIZE $DISK_NAME." $LINENO
        exit 1
    fi
else
    output "WARN" "Volume $VOL_SRL_NAME exists." $LINENO
fi
output "INFO" "End create the volume for srl." $LINENO

#创建vx filesystem
output "INFO" "Begin create the vx filesystem." $LINENO
mkfs -t vxfs $VOLUME_PATH/$DISK_GROUP/$VOL_SRV_NAME
mkfs -t vxfs $VOLUME_PATH/$DISK_GROUP/$VOL_MYSQL_NAME
output "INFO" "End create the vx filesystem." $LINENO

#检测创建结果
ls -l /dev/vx/dsk/$DISK_GROUP/
if [ $? -ne 0 ];then
    output "ERROR" "Creat VX Filesystem failed." $LINENO
    exit 4
fi
output "INFO" "VX Filesystem created successfully." $LINENO

#创建mysql、srv目录
if [ ! -d $DB_PATH ];then
    output "INFO" "$DB_PATH create..." $LINENO
    mkdir -p $DB_PATH
else
    output "WARN" "$DB_PATH already exists" $LINENO
fi

if [ ! -d $SRV_PATH ];then
    output "INFO" "$SRV_PATH create..." $LINENO
    mkdir -p $SRV_PATH
else
    output "WARN" "$SRV_PATH already exists" $LINENO
fi

#挂载磁盘
output "INFO" "mount $DB_PATH..." $LINENO
mount -t vxfs /dev/vx/dsk/$DISK_GROUP/$VOL_MYSQL_NAME $DB_PATH >> $LOG_FILE 2>&1
if [ $? -ne 0 ]
then
    output "ERROR" "Mount failed, please check command: mount -t vxfs /dev/vx/dsk/$DISK_GROUP/$VOL_MYSQL_NAME $DB_PATH." $LINENO
    exit 1
fi

output "INFO" "mount $SRV_PATH..." $LINENO
mount -t vxfs /dev/vx/dsk/$DISK_GROUP/$VOL_SRV_NAME $SRV_PATH >> $LOG_FILE 2>&1
if [ $? -ne 0 ]
then
    output "ERROR" "Mount failed, please check command: mount -t vxfs /dev/vx/dsk/$DISK_GROUP/$VOL_SRV_NAME $SRV_PATH." $LINENO
    exit 1
fi

#备机umount目录
if [ "$configType" == "sec" ];then
    umount $DB_PATH
    umount $SRV_PATH
fi

#设置VVR日志
output "INFO" "Begin set the log for vvr." $LINENO
vxassist -g $DISK_GROUP addlog $VOL_SRV_NAME nlog=1 logtype=dcm
vxassist -g $DISK_GROUP addlog $VOL_MYSQL_NAME nlog=1 logtype=dcm
output "INFO" "End set the log for vvr." $LINENO


#判断是否设置成功
#vxprint -l $VOL_SRV_NAME |grep DCM #检查
#vxprint -l $VOL_MYSQL_NAME |grep DCM #检查



exit 0

