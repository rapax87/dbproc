#!/bin/bash
#title           :config_appdir.sh
#description     :This script will config APP directory.
#author         :xubingbing
#date            :20130821
#version         :0.1    
#usage         :config_appdir.sh 
#notes           :Veritas must be installed & configured beforehead, 
#                  an original main.cf should have already existed.
#==============================================================================
configType=$1
#check 
if [ "$configType" != "pri" ] && [ "$configType" != "sec" ];then
    echo "[ERROR]`date +'%Y%m%d %H:%M:%S'` $0($LINENO) [MSG]Usage: $0  pri|sec. at least 1 argument required."
    exit 1
fi

. ./hacommon.sh

#停止eapp服务
pkill -9 -f "ubp_adm"
pkill -9 -f "ubp_sysd"
pkill -9 -f "ubp_svcd"

#. /opt/UBP/svc_profile.sh
#DAEM_EXIST=`/opt/UBP/bin/ubp_adm -cmd status|grep "ubp_daem" |grep "Running"|wc -l`
#if [ $DAEM_EXIST -ne 0 ];then
#    /opt/UBP/bin/ubp_adm -cmd stop
#fi

#停止MySQL
/sbin/service mysql stop
    
if [ $plan -eq 1 ];then
    #方案一、 修改数据目录，仅链接不同步数据
    #修改/etc/my.cnf
    cp -rf /etc/my.cnf /etc/my.cnf.`date +'%Y%m%d%H%M%S'`
    cp -rf ./conf/my.cnf.vrts /etc/my.cnf
    if [ $? -ne 0 ];then
        output "ERROR" "Change /etc/my.cnf failed." $LINENO
        exit 2
    fi

    #主机复制MySQL数据
    if [ "$configType" == "pri" ];then
        rm -Rf $DB_PATH/*
        cp -Rf $ORI_MYSQL_DATA_DIR $DB_PATH/
        if [ $? -ne 0 ];then
            output "ERROR" "Copy from $ORI_MYSQL_DATA_DIR to $DB_PATH/ failed." $LINENO
            exit 1
        fi
        chown -R mysql:mysql $DB_PATH/
        chmod -R 775 $DB_PATH/
        for file in $UBPDB_EXCLUDE_FILES
        do
            rm -rf $DB_PATH/mysql/ubpdb/$file
            ln -s $ORI_MYSQL_DATA_DIR/ubpdb/$file $DB_PATH/mysql/ubpdb/$file
        done
        		
        ssh root@$SEC_IP "rm -Rf ${ORI_MYSQL_DATA_DIR}_bk"
        ssh root@$SEC_IP "mv $ORI_MYSQL_DATA_DIR ${ORI_MYSQL_DATA_DIR}_bk"
        scp -r $ORI_MYSQL_DATA_DIR root@$SEC_IP:$ORI_MYSQL_DATA_DIR
        ssh root@$SEC_IP "chown -R mysql:mysql $ORI_MYSQL_DATA_DIR"
        ssh root@$SEC_IP "chmod -R 775 $ORI_MYSQL_DATA_DIR"
    fi
    #exit 0
else
    #方案二、 不修改数据目录，链接同步数据
    #（MySQL链接调查中）暂时不做
    if [ "$configType" == "pri" ];then
        proc="mv"
    else
        proc="rm -f"
    fi
    #同步UBPDB
    ubpdb_all_files=`ls $ORI_MYSQL_DATA_DIR/ubpdb`
    mkdir -p $DB_PATH/mysql/ubpdb
    mkdir -p $ORI_MYSQL_DATA_DIR/ubpdb/bk
    
    for file in $ubpdb_all_files
    do
        echo $UBPDB_EXCLUDE_FILES|grep -w $file
        if [ $? -ne 0 ];then
            #cp $ORI_MYSQL_DATA_DIR/ubpdb/$file $ORI_MYSQL_DATA_DIR/ubpdb/${file}.bk
            cp $ORI_MYSQL_DATA_DIR/ubpdb/$file $ORI_MYSQL_DATA_DIR/ubpdb/bk/
            $proc $ORI_MYSQL_DATA_DIR/ubpdb/$file $DB_PATH/mysql/ubpdb/$file
            if [ $? -ne 0 ];then
                output "ERROR" "$proc file $file from $ORI_MYSQL_DATA_DIR/ubpdb to $DB_PATH/mysql/ubpdb failed." $LINENO
                exit 3
            fi
            ln -s $DB_PATH/mysql/ubpdb/$file $ORI_MYSQL_DATA_DIR/ubpdb/$file 
        fi
    done
    #同步SDSDB
    sds_all_files=`ls $ORI_MYSQL_DATA_DIR/sds`
    mkdir -p $DB_PATH/mysql/sds
    mkdir -p $ORI_MYSQL_DATA_DIR/sds/bk
    
    for file in $sds_all_files
    do
        echo $SDSDB_EXCLUDE_FILES|grep -w $file
        if [ $? -ne 0 ];
        then
            #cp $ORI_MYSQL_DATA_DIR/sds/$file $ORI_MYSQL_DATA_DIR/sds/${file}.bk
            cp $ORI_MYSQL_DATA_DIR/sds/$file $ORI_MYSQL_DATA_DIR/sds/bk/
            $proc $ORI_MYSQL_DATA_DIR/sds/$file $DB_PATH/mysql/sds/$file
            if [ $? -ne 0 ];then
                output "ERROR" "$proc file $file from $ORI_MYSQL_DATA_DIR/sds to $DB_PATH/mysql/sds failed." $LINENO
                exit 3
            fi
            ln -s $DB_PATH/mysql/sds/$file $ORI_MYSQL_DATA_DIR/sds/$file
        fi
    done
        
        
    chown -R mysql:mysql $DB_PATH/mysql/ubpdb $DB_PATH/mysql/sds
    chown -R mysql:mysql $ORI_MYSQL_DATA_DIR/ubpdb $ORI_MYSQL_DATA_DIR/sds
    chmod -R 770 $ORI_MYSQL_DATA_DIR/ubpdb
    chmod -R 770 $ORI_MYSQL_DATA_DIR/sds
    chmod -R 770 $DB_PATH/mysql/ubpdb
    chmod -R 770 $DB_PATH/mysql/sds
    
fi

#文件同步
#业务数据目录
for dir in $SYN_DIRS
do
    if [ ! -d $dir ];then
        rm -rf $dir
        mkdir -p $dir
    fi
    cp -Rf $dir $SRV_PATH/
    rm -Rf ${dir}_bk
    mv $dir ${dir}_bk
    ln -s $SRV_PATH/`basename $dir` $dir
done

#限定veritas端口
#vrport data 53000 53001 53002
#/etc/init.d/vxnm-vxnetd stop
#/etc/init.d/vxnm-vxnetd start


exit 0

