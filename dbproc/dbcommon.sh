#!/bin/bash

#title           :dbcommon.sh
#description     :Define common function of DB proc
#author		 :xubingbing
#date            :20131213
#version         :0.1    
#usage		 :hacommon.sh 
#notes           :called by other DB proc shell, import, output etc. 
#==============================================================================
#. /opt/UBP/bin/common.sh
. ../common.sh
LOG_FILE=$g_root/logs/dbproc.log

function errorhandler()
{
  rm -rf *.list *.seq
}

function output()
{
    if [ $# -lt 2 ]
    then
        return 1
    else
        level=$1
        msg=$2
        lineno=$3
        echo "[$level]`date +'%Y%m%d %H:%M:%S'` $0($lineno) [MSG]$msg" | tee -a $LOG_FILE
    fi
    return 0
}

function getSyncInfo()
{
    if [ -z $1 ];then
        return -1
    fi
    grep -w "$1" $g_root/conf/sync.ini | awk -F"=" '{print $2}'
    return 0
}

function getVersionInfo()
{
    if [ -z $1 ];then
        return -1
    fi
    grep -w "$1" $g_root/conf/version.ini | awk -F"=" '{print $2}'
    return 0
}
function sortlist2()
{
    if [ $# -lt 1 ];then
        return 1
    else
        listpath=$1
        if [ ! -f $listpath ];then
            return 1
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

function all_tables()
{
    #mysql -u$g_odb_user -p$g_odb_psw $g_ubpdb <<EOF
#show tables;
#EOF
    mysql -u$g_odb_user -p$g_odb_psw $g_ubpdb --skip-column-names -e "show tables;"
    if [ $? -ne 0 ];then
        return 1
    fi
    return 0
}

function get_sync_info()
{

  if [ $# -lt 2 ];then
        return 1
  fi
  attr=$1
  xmlfile=$2
  rm -rf ./sync.xsl
  echo "<?xml version=\"1.0\"?>" >>./sync.xsl
  echo "<xsl:stylesheet version=\"1.0\"" >>./sync.xsl
  echo "  xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\">" >>./sync.xsl
  echo "" >>./sync.xsl
  echo "<xsl:output method=\"html\" omit-xml-declaration=\"yes\" />" >>./sync.xsl
  echo "" >>./sync.xsl
  echo "<xsl:template match=\"sync\">" >>./sync.xsl
  echo "<xsl:value-of select=\"@$attr\" />" >>./sync.xsl
  echo "</xsl:template>" >>./sync.xsl
  echo "" >>./sync.xsl
  echo "<xsl:template match=\"mysqldump\">" >>./sync.xsl
  echo "<xsl:apply-templates select=\"sync\"/>" >>./sync.xsl
  echo "</xsl:template>" >>./sync.xsl
  echo "" >>./sync.xsl
  echo "</xsl:stylesheet>" >>./sync.xsl
  xsltproc ./sync.xsl $xmlfile 2>/dev/null
  
  return $?
}

function sortlist()
{
    if [ $# -lt 1 ];then
        return 1
    else
        listpath=$1
        if [ ! -f $listpath ];then
            return 1
        fi
    fi
    
    #grep -H "FK:" /opt/UBP/conf/cm_service/*.xml|sed -r 's/^.*\/([^/]*)\.xml.*FK:([^"]*)" [^\^].*/\1:\2/'|awk -F: '{print "TBL_"$1"<TBL_"$3}' > ./depends.list
    #从配置项XML中读出外键依赖信息，输出至depends.list
    grep -H "FK:" $g_root/conf/cm_service/*.xml|sed -r 's/^.*\/([^/]*)\.xml.*FK:([^"]*)" [^\^].*/\1:\2/'|awk -F: '{print "TBL_"$1"<TBL_"$3}' > ./depends.list
    #左侧为外键依赖表，右侧为被依赖表，如A<B，A外键依赖B,将左右侧表名分别取出
    awk -F"<" '{print $1}' ./depends.list|sort|uniq >./lefts.list
    awk -F"<" '{print $2}' ./depends.list|sort|uniq >./rights.list

    #左侧集合 union 右侧集合 表示左右集合的合集
    cat lefts.list rights.list |sort|uniq >./all_depends_tables.list #low=lefts union rights

    #左侧集合-右侧集合表示仅出现在左侧的表名，仅依赖其它表而不被其它表依赖
    cat lefts.list rights.list rights.list|sort|uniq -u >./low.list #low=lefts-rights

    #右侧集合-左侧集合表示仅出现在右侧的表名，仅被其它表依赖而不依赖其它表
    cat rights.list lefts.list lefts.list|sort|uniq -u >./high.list #high=rights-lefts

    #左侧集合 intersect 右侧集合 表示左右集合的交集，表示既出现在右侧又出现在左侧的表名
    #目前表依赖只有三层，如果以后有四层以上的情况可能要做递归处理
    cat rights.list lefts.list |sort|uniq -d >./middle.list #middle=rights intersect lefts
    
    #取得数据库中所有表名
    mysql -u$g_odb_user -p$g_odb_psw $g_ubpdb --skip-column-names -e "show tables;">./all_tables.list

    #取得没有外键依赖被依赖关系的表名
    cat all_tables.list all_depends_tables.list all_depends_tables.list|sort|uniq -u >./no_depends_tables.list

    #删除时的顺序列表
    cat low.list middle.list high.list no_depends_tables.list >./delete.seq.list

    #导入时的顺序列表
    cat high.list middle.list low.list no_depends_tables.list >./insert.seq.list
 
    #根据全局顺序列表生成当前的顺序列表
    #全局顺序列表相对固定，作为配置文件也是可以的
    rm -rf $listpath.delete.seq $listpath.insert.seq $listpath.bak.list $listpath.bak.seq
    cat ./delete.seq.list|while read tablename;do
       if [ -z "$tablename" ];then
           continue
       fi
       grep $tablename $listpath >/dev/null 2>&1
       if [ $? -eq 0 ];then
           echo $tablename>>$listpath.delete.seq
       fi
    done 

    cat ./insert.seq.list|while read tablename;do
       if [ -z "$tablename" ];then
          continue 
       fi
       grep $tablename $listpath >/dev/null 2>&1
       if [ $? -eq 0 ];then
           echo $tablename>>$listpath.insert.seq
       fi
    done
    
    #取得外键依赖导入表的所有表作为备份对象  
    cat $listpath|while read tablename;do
       if [ -z "$tablename" ];then
          continue
       fi
       echo $tablename>>$listpath.bak.list
       grep "<$tablename" ./depends.list|awk -F"<" '{print $1}'>>$listpath.bak.list
    done 
    cat $listpath.bak.list|sort|uniq>$listpath.bak.seq

    return 0
}

#cp ./test.list.bk ./test.list
#sortlist ./test.list



