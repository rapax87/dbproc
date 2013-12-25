#!/bin/bash

#title           :dbcommon.sh
#description     :Define common function of DB proc
#author		 :xubingbing
#date            :20131213
#version         :0.1    
#usage		 :hacommon.sh 
#notes           :called by other DB proc shell, import, output etc. 
#==============================================================================
. /opt/UBP/bin/common.sh
LOG_FILE=/opt/UBP/logs/dbproc.log

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
    return 0
}

function sortlist()
{
    if [ $# -lt 1 ];then
        exit 1
    else
        listpath=$1
        if [ ! -f $listpath ];then
            exit 1
        fi
    fi 
    #cd /opt/UBP/conf/cm_service
    #grep -H "FK:" /opt/UBP/conf/cm_service/*.xml|sed -r 's/^(.*)\.xml.*FK:([^"]*)" [^\^].*/\1:\2/'|awk -F: '{print "TBL_"$1"<TBL_"$3}' >depends.list
    grep -H "FK:" /opt/UBP/conf/cm_service/*.xml|sed -r 's/^.*\/([^/]*)\.xml.*FK:([^"]*)" [^\^].*/\1:\2/'|awk -F: '{print "TBL_"$1"<TBL_"$3}' > ./depends.list
    depends=(`cat ./depends.list`)
    tables=(`cat $listpath`)
    for((i=0;i<${#depends[@]};i++));do
        j=9999
        k=9999
        parent=`echo ${depends[i]}|awk -F\< '{print $2'}`
        child=`echo ${depends[i]}|awk -F\< '{print $1'}`
        if [ -z $parent ] || [ -z $child ] || [ "$parent" = "$child" ];then
            continue
        fi
        for((l=0;l<${#tables[@]};l++));do
            if [ $j -ne 9999 ] && [ $k -ne 9999 ];then
                break 1
            fi
            if [ "${tables[l]}" = "$parent" ];then
                j=$l
            elif [ "${tables[l]}" = "$child" ];then
                k=$l
            else
                continue
            fi
        done
        if [ $j -ne 9999 ] && [ $k -ne 9999 ] && [ $j -lt $k ];then
            tmp=${tables[j]}
            tables[j]=${tables[k]}
            tables[k]=$tmp
        fi
    done
    mv ${listpath} ${listpath}.old
    for((m=0;m<${#tables[@]};m++));do
       echo "${tables[m]}">>${listpath} 
    done
    return 0
    rm -rf num_ck.list
    for((n=0;n<${depends[@]};n++));do
       parent=`echo ${depends[n]}|awk -F\< '{print $2'}`
       child=`echo ${depends[n]}|awk -F\< '{print $1'}` 
       p_ln=`grep -n $parent ${listpath}|awk -F: '{print $1}'`
       c_ln=`grep -n $child ${listpath}|awk -F: '{print $1}'`
       echo "$c_ln > $p_ln" >> num_ck.list
    done

    return 0
}
#cp ./all.list.bk ./all.list
#sortlist ./all.list



