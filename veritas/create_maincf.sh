#!/bin/bash
#title           :create_maincf.sh
#description     :This script will make create main.cf file 
#                 from template and ini files.
#author		 :xubingbing
#date            :20130821
#version         :0.1    
#usage		 :create_maincf.sh <secondary_server_ip> <primary_server_ip = optional>
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

CFFILE=/etc/VRTSvcs/conf/config/main.cf
#ORI_CFFILE=/etc/VRTSvcs/conf/config/main.cf
SEC_CFFILE=./main.cf.sec
TMP_PRI_DIR=./primary
TMP_SEC_DIR=./secondary
TMP_PRI_CFFILE=$TMP_PRI_DIR/main.cf
TMP_SEC_CFFILE=$TMP_SEC_DIR/main.cf


#get culster user names from original main.cf file
function get_cluster_UserNames()
{
    #CFFILE=/etc/VRTSvcs/conf/config/main.cf
    if [ ! -f $CFFILE ]
    then
        echo ""
        exit 1
    fi
    LINE=`grep "UserNames" $CFFILE`
    UserNames=`echo $LINE|awk -F"[{}]" '{print $2}'`
    echo "$UserNames"
    exit 0
}

#get culster administrators from original main.cf file
function get_cluster_Administrators()
{
    #CFFILE=/etc/VRTSvcs/conf/config/main.cf
    if [ ! -f $CFFILE ]
    then
        echo ""
        exit 1
    fi
    LINE=`grep "Administrators" $CFFILE`
    Administrators=`echo $LINE|awk -F"[{}]" '{print $2}'`
    echo "$Administrators"
    exit 0
}

function clean()
{
    output "INFO" "Remove temp files: $SEC_CFFILE $TMP_PRI_DIR $TMP_SEC_DIR ..." $LINENO
    rm -rf $SEC_CFFILE $TMP_PRI_DIR $TMP_SEC_DIR
    exit 0
}

#Backup main.cf
cp -rf $ORI_CFFILE $ORI_CFFILE.`date +'%Y%m%d%H%M%S'`
if [ $? -ne 0 ];then
    output "ERROR" "Backup primary $ORI_CFFILE failed." $LINENO
    exit 2
fi
output "INFO" "Backup primary $ORI_CFFILE OK." $LINENO
		
ssh root@$secondary "cp -rf $ORI_CFFILE $ORI_CFFILE.`date +'%Y%m%d%H%M%S'`"
if [ $? -ne 0 ];then
    output "ERROR" "Backup secondary $ORI_CFFILE failed." $LINENO
    exit 3
fi
output "INFO" "Backup secondary $ORI_CFFILE OK." $LINENO
		
mkdir -p $TMP_PRI_DIR
cp -rf $PRI_TEMPLATE $TMP_PRI_CFFILE
if [ $? -ne 0 ];then
    output "ERROR" "copy primary template file $PRI_TEMPLATE to $TMP_PRI_CFFILE failed." $LINENO
    exit 4
fi

output "INFO" "Copy $PRI_TEMPLATE to $TMP_PRI_CFFILE" $LINENO

#for LINE in `cat ./maincf_pri_def.ini|grep -v "^$"|grep -v "^#.*"`  #not good while spaces in line
cat ./conf/vcs.conf|grep -v "^$"|grep -v "^#.*" | while read LINE
do
    from="%`echo $LINE|awk -F= '{print $1}'`%"
    if [ "$from" == "%cluster_UserNames%" ]
    then
        #to=`echo $LINE|awk -F"[{}]" '{print $2}'`
        to="`get_cluster_UserNames`"
        if [ "$to" == "" ]
        then
            #echo "[ERROR]`date +'%Y%m%d %H:%M:%S'` [MSG]Can't get cluster UserNames from original main.cf, check if $ORI_CFFILE exisits"
            output "ERROR" "Can't get cluster UserNames from original main.cf, check if $ORI_CFFILE exisits" $LINENO
            exit 5
        fi
    elif [ "$from" == "%cluster_Administrators%" ]
    then
        to="`get_cluster_Administrators`"
        if [ "$to" == "" ]
        then
            #echo "[ERROR]`date +'%Y%m%d %H:%M:%S'` [MSG]Can't get cluster Administrators from original main.cf, check if $ORI_CFFILE exisits"
            output "ERROR" "Can't get cluster Administrators from original main.cf, check if $ORI_CFFILE exisits" $LINENO
            exit 6
        fi
    else
        to="`echo $LINE|awk -F= '{print $2}'`"
    fi
    sed -i "s/$from/$to/g" $TMP_PRI_CFFILE
done
echo "[INFO]`date +'%Y%m%d %H:%M:%S'` [MSG]$TMP_PRI_CFFILE created"

#scp root@30.30.30.86:/etc/VRTSvcs/conf/config/main.cf ./main.cf.sec
scp root@$secondary:$ORI_CFFILE $SEC_CFFILE
if [ $? -ne 0 ]
then
    #echo "[ERROR]`date +'%Y%m%d %H:%M:%S'` [MSG]Can't get main.cf from secondary server, check if $ORI_CFFILE exisits and if ssh is set OK"
    output "ERROR" "Can't get main.cf from secondary server, check if $ORI_CFFILE exisits and if ssh is set OK" $LINENO
    exit 7
fi
output "INFO" "Get main.cf from secondary server OK, save as $SEC_CFFILE" $LINENO
CFFILE=$SEC_CFFILE

mkdir -p $TMP_SEC_DIR
cp -rf $SEC_TEMPLATE $TMP_SEC_CFFILE
if [ $? -ne 0 ];then
    output "ERROR" "copy secondary template file $SEC_TEMPLATE to $TMP_PRI_CFFILE failed." $LINENO
    exit 8
fi
output "INFO" "Copy $SEC_TEMPLATE to $TMP_SEC_CFFILE" $LINENO

#for LINE in `cat ./maincf_sec_def.ini|grep -v "^$"|grep -v "^#.*"`  #not good while spaces in line
cat ./conf/vcs.conf|grep -v "^$"|grep -v "^#.*" | while read LINE
do
    from="%`echo $LINE|awk -F= '{print $1}'`%"
    if [ "$from" == "%secondary_cluster_UserNames%" ]
    then
        #to=`echo $LINE|awk -F"[{}]" '{print $2}'`
        to="`get_cluster_UserNames`"
        if [ "$to" == "" ]
        then
            #echo "[ERROR]`date +'%Y%m%d %H:%M:%S'` [MSG]Can't get cluster UserNames from original main.cf, check if $SEC_CFFILE exisits"
            output "ERROR" "Can't get cluster UserNames from original main.cf, check if $ORI_CFFILE exisits" $LINENO
            exit 9
        fi
    elif [ "$from" == "%cluster_Administrators%" ]
    then
        to="`get_cluster_Administrators`"
        if [ "$to" == "" ]
        then
            #echo "[ERROR]`date +'%Y%m%d %H:%M:%S'` [MSG]Can't get cluster Administrators from original main.cf, check if $SEC_CFFILE exisits"
            output "ERROR" "Can't get cluster Administrators from original main.cf, check if $ORI_CFFILE exisits" $LINENO
            exit 10
        fi
    else
        to="`echo $LINE|awk -F= '{print $2}'`"
    fi
    sed -i "s/$from/$to/g" $TMP_SEC_CFFILE
done
#echo "[INFO]`date +'%Y%m%d %H:%M:%S'` [INFO]$TMP_SEC_CFFILE created"
output "INFO" "$TMP_SEC_CFFILE created" $LINENO

#Replace main.cf
cp -rf $TMP_PRI_CFFILE $ORI_CFFILE
if [ $? -ne 0 ];then
    output "ERROR" "Replace primary $ORI_CFFILE with $TMP_PRI_CFFILE failed." $LINENO
    exit 11
fi
output "INFO" "Replace primary $ORI_CFFILE with $TMP_PRI_CFFILE OK." $LINENO

#ssh root@$secondary "cp $TMP_SEC_CFFILE $ORI_CFFILE"
scp $TMP_SEC_CFFILE root@$secondary:$ORI_CFFILE
if [ $? -ne 0 ];then
    output "ERROR" "Replace secondary $secondary:$ORI_CFFILE with $TMP_SEC_CFFILE failed." $LINENO
    exit 12
fi
output "INFO" "Replace secondary $secondary:$ORI_CFFILE with $TMP_SEC_CFFILE OK." $LINENO


clean


#return SUCCESS
exit 0


