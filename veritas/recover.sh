#!/bin/bash
#title           :clean.sh
#description     :This script will change eapp IP.
#author         :xubingbing
#date            :20130821
#version         :0.1    
#usage         :clean.sh <second ip>
#notes           :Destroy all vxvm, vvr, vxdg, vxdisk, back to pre-configured
#==============================================================================
secondary=$1

. ./hacommon.sh
output "INFO" "Offline ubpApp..." $LINENO
/opt/VRTS/bin/hagrp -offline -force ubpApp -any -localclus
sleep 60
	
output "INFO" "Recover /etc/my.cnf" $LINENO
if [ $plan -eq 1 ];then
    cp -rf /opt/UBP/conf/my.cnf /etc/my.cnf
    chmod 755 /etc/my.cnf
    scp -r /opt/UBP/conf/my.cnf root@$secondary:/etc/my.cnf
    ssh root@$secondary "chmod 755 /etc/my.cnf"
fi

if [ $plan -eq 2 ];then
mount -t vxfs /dev/vx/dsk/$DISK_GROUP/$VOL_MYSQL_NAME $DB_PATH
cd $DB_PATH/mysql/ubpdb
ubpdb_all_files=`ls $DB_PATH/mysql/ubpdb`
for file in $ubpdb_all_files
do
    rm -rf $ORI_MYSQL_DATA_DIR/ubpdb/$file
    cp $DB_PATH/mysql/ubpdb/$file $ORI_MYSQL_DATA_DIR/ubpdb/$file
    if [ $? -ne 0 ];then
            output "ERROR" "cp file $file from $DB_PATH/mysql/ubpdb to $ORI_MYSQL_DATA_DIR/ubpdb failed." $LINENO
            exit 3
    fi
    chown -R mysql:mysql $ORI_MYSQL_DATA_DIR/ubpdb/$file
    chmod -R 660 $ORI_MYSQL_DATA_DIR/ubpdb/$file
    if [ ! -z $secondary ];then
        ssh root@$secondary "rm -rf $ORI_MYSQL_DATA_DIR/ubpdb/$file"
        scp $ORI_MYSQL_DATA_DIR/ubpdb/$file root@$secondary:$ORI_MYSQL_DATA_DIR/ubpdb/$file
        if [ $? -ne 0 ];then
           output "ERROR" "copy file to secondary $ORI_MYSQL_DATA_DIR/ubpdb/$file failed." $LINENO
           exit 3
        fi
        ssh root@$secondary "chown -R mysql:mysql $ORI_MYSQL_DATA_DIR/ubpdb/$file"
        ssh root@$secondary "chmod -R 660 $ORI_MYSQL_DATA_DIR/ubpdb/$file"
    fi
done
cd -


cd $DB_PATH/mysql/sds
sds_all_files=`ls $DB_PATH/mysql/sds`
for file in $sds_all_files
do
    rm -rf $ORI_MYSQL_DATA_DIR/sds/$file
    cp $DB_PATH/mysql/sds/$file $ORI_MYSQL_DATA_DIR/sds/$file
    if [ $? -ne 0 ];then
       output "ERROR" "cp file $file from $DB_PATH/mysql/sds to $ORI_MYSQL_DATA_DIR/sds failed." $LINENO
       exit 3
    fi
    chown -R mysql:mysql $ORI_MYSQL_DATA_DIR/sds/$file
    chmod -R 770 $ORI_MYSQL_DATA_DIR/sds/$file
    if [ ! -z $secondary ];then
        ssh root@$secondary "rm -rf $ORI_MYSQL_DATA_DIR/sds/$file"
        scp $ORI_MYSQL_DATA_DIR/sds/$file root@$secondary:$ORI_MYSQL_DATA_DIR/sds/$file
        if [ $? -ne 0 ];then
           output "ERROR" "copy file to secondary $ORI_MYSQL_DATA_DIR/sds/$file failed." $LINENO
           exit 3
        fi
        ssh root@$secondary "chown -R mysql:mysql $ORI_MYSQL_DATA_DIR/sds/$file"
        ssh root@$secondary "chmod -R 770 $ORI_MYSQL_DATA_DIR/sds/$file"
    fi
done
cd -

output "INFO" "umount $DB_PATH" $LINENO
umount $DB_PATH

rm -rf $ORI_MYSQL_DATA_DIR/sds/bk
rm -rf $ORI_MYSQL_DATA_DIR/ubpdb/bk

fi

./stopha.sh $secondary



#删除volume
/opt/VRTS/bin/vxedit -g eappdg -rf rm eapprvg
#删除disk group
/opt/VRTS/bin/vxdg destroy eappdg
#反初始化磁盘
output "INFO" "Unsetup Disk $DISK_NAME" $LINENO
/opt/VRTS/bin/vxdiskunsetup -C $DISK_NAME

if [ ! -z $secondary ];then
    ssh root@$secondary "rm -rf $ORI_MYSQL_DATA_DIR/sds/bk"
    ssh root@$secondary "rm -rf $ORI_MYSQL_DATA_DIR/ubpdb/bk"
    ssh root@$secondary "/opt/VRTS/bin/vxedit -g eappdg -rf rm eapprvg"
    ssh root@$secondary "/opt/VRTS/bin/vxdg destroy eappdg"
    ssh root@$secondary "/opt/VRTS/bin/vxdiskunsetup -C $DISK_NAME"
fi
exit 0

