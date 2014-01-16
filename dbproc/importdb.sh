#! /bin/bash

#title           :importdb.sh
#description     :import XML data to DB
#author          :xubingbing
#date            :20131223
#version         :0.1    
#usage           :./importdb.sh <xml file path> <delete before import option>
#notes           : 
#==============================================================================
dir=$(dirname $0)
cd $dir

if [ $# -lt 1 ];then
  echo "Usage: $0 <XML file path> <delete before import option>"
  exit 1
fi

#tablename=$1
xmlfile=$1
#xmldir=$2
delete_before_import=$2

#if [ ! -d $xmldir ];then
#  echo "$xmldir not exist"
#  exit 2
#fi

. ./dbcommon.sh

if [ ! -f $xmlfile ];then
  output "ERROR" "$xmlfile not exist" $LINENO
  exit 2
fi
xmldir=`dirname $xmlfile`
output "INFO" "Process XML file: $xmlfile..." $LINENO

#检查同步信息
syncid=`get_sync_info syncno $xmlfile`
mtime=`get_sync_info latestupdate $xmlfile`


#col1=`grep -E -n "<sync" $xmlfile|awk '{print $2}'`
#col1_name=`echo $col1|awk -F"=" '{print $1}'`
#if [ "$col1_name" = "syncno" ];then
#    syncid=`echo $col1|awk -F\" '{print $2}'`
#elif [ "$col1_name" = "latestupdate" ];then
#    mtime=`echo $col1|awk -F\" '{print $2}'`
#elif [ "$col1_name" = "version" ];then
#    version=`echo $col1|awk -F\" '{print $2}'`
#else
#    output "ERROR" "Invalid tag $col1_name in $xmlfile" $LINENO
#    exit 1
#fi

#col2=`grep -E -n "<sync" $xmlfile|awk '{print $3}'`
#col2_name=`echo $col2|awk -F"=" '{print $1}'`
#if [ "$col2_name" = "syncno" ];then
#    syncid=`echo $col2|awk -F\" '{print $2}'`
#elif [ "$col2_name" = "latestupdate" ];then
#    mtime=`echo $col2|awk -F\" '{print $2}'`
#elif [ "$col2_name" = "version" ];then
#    version=`echo $col2|awk -F\" '{print $2}'`
#else
#    output "ERROR" "Invalid tag $col2_name in $xmlfile" $LINENO
#    exit 1
#fi

#col3=`grep -E -n "<sync" $xmlfile|awk '{print $4}'`
#col3_name=`echo $col3|awk -F"=" '{print $1}'`
#if [ "$col3_name" = "syncno" ];then
#    syncid=`echo $col3|awk -F\" '{print $2}'`
#elif [ "$col2_name" = "latestupdate" ];then
#    mtime=`echo $col3|awk -F\" '{print $2}'`
#elif [ "$col2_name" = "version" ];then
#    version=`echo $col3|awk -F\" '{print $2}'`
#else
#    output "ERROR" "Invalid tag $col2_name in $xmlfile" $LINENO
#    exit 1
#fi

if [ -z $syncid ] || [ -z $mtime ];then
  output "ERROR" "Sync info not OK or XML format error" $LINENO
  exit 1
fi
 
#从XML文件中取出需要导入的表名
grep -E -n "<table_data.*[ \"]>$" $xmlfile|awk -F\" '{print $2}'>./import.list
grep -E -n "<table_data.*/>$" $xmlfile|awk -F\" '{print $2}'>>./import.list
#根据外键依赖关系对表名进行排序
sortlist ./import.list

#删除时的顺序与导入的顺序是相反的
del_tables=(`cat ./import.list.delete.seq`)
ins_tables=(`cat ./import.list.insert.seq`)
bak_tables=(`cat ./import.list.bak.seq`)

#这是未进行排序的表名列表
tables=(`grep -E -n "<table_data.*[ \"]>$" $xmlfile|awk -F\" '{print $2}'`)
empty_tables=(`grep -E -n "<table_data.*/>$" $xmlfile|awk -F\" '{print $2}'`)

#还要考虑一下<table_data ... />这种TAG
begins=(`grep -E -n "<table_data.*[ \"]>$" $xmlfile|awk -F: '{print $1}'`)
ends=(`grep -E -n "</table_data>" $xmlfile|awk -F: '{print $1}'`)

if [ ${#begins[@]} -ne ${#ends[@]} ] || [ ${#tables[@]} -ne ${#ends[@]} ];then
  output "ERROR" "$xmlfile format wrong" $LINENO
  errorhandler
  exit 3
fi

size=${#tables[@]}
empty_size=${#empty_tables[@]}
bak_size=${#bak_tables[@]}

#设置数据库信息
dbname=$g_ubpdb
userName=$g_odb_user
dbpasswd=$g_odb_psw

#把XML切分成单表XML，目前只找到了MySQL单表导入的接口
for((i=0;i<$size;i++));do
  if [ ${begins[$i]} -ge ${ends[$i]} ];then
    output "ERROR" "$xmlfile format wrong" $LINENO
    errorhandler
    exit 4
  fi
  output "INFO" "Create XML $xmldir/${tables[$i]}.xml ..." $LINENO
  rm -rf $xmldir/${tables[$i]}.xml
  sed -n "${begins[$i]},${ends[$i]}p" $xmlfile >> $xmldir/${tables[$i]}.xml
done

for((i=0;i<$empty_size;i++));do
  output "INFO" "Create XML $xmldir/${empty_tables[$i]}.xml ..." $LINENO
  rm -rf $xmldir/${empty_tables[$i]}.xml
  echo "<table_data name=\"${empty_tables[$i]}\" />" >>$xmldir/${empty_tables[$i]}.xml
done

#并且将需要导入的表事先备份
rm -rf $xmldir/bak
mkdir -p $xmldir/bak
for((i=0;i<$bak_size;i++));do
  output "INFO" "Backup data ${bak_tables[$i]}..." $LINENO
  ./exportdb.sh $xmldir/bak ${bak_tables[$i]}
done

#事先删除表操作
error=0
if [ ! -z $delete_before_import ];then
  for((i=0;i<$size;i++));do
    output "INFO" "Clear table ${del_tables[$i]}..." $LINENO
    mysql -u${userName} -p${dbpasswd} ${dbname} <<EOF
#SET FOREIGN_KEY_CHECKS=0;
delete from ${del_tables[$i]};
#SET FOREIGN_KEY_CHECKS=1;
EOF
  done
fi

if [ $? -ne 0 ];then
    output "INFO" "Recover DB data" $LINENO
    for file in `ls $xmldir/bak/*.xml`
    do
mysql -u${userName} -p${dbpasswd} ${dbname} <<EOF
SET FOREIGN_KEY_CHECKS=0;
delete from ${tables[$i]};
load xml local infile '$file' replace into table ${tables[$i]};
SET FOREIGN_KEY_CHECKS=1;
EOF
    done
    errorhandler
    exit 1
fi

#导入数据操作
error=0
for((i=0;i<$size;i++));do
  output "INFO" "Import table ${ins_tables[$i]}..." $LINENO
mysql -u${userName} -p${dbpasswd} ${dbname} <<EOF
#SET FOREIGN_KEY_CHECKS=0;
load xml local infile '$xmldir/${ins_tables[$i]}.xml' replace into table ${ins_tables[$i]};
#SET FOREIGN_KEY_CHECKS=1;
EOF
  if [ $? -ne 0 ];then
    output "WARN" "import ${ins_tables[$i]} data failed" $LINENO
    error=1
    break
  fi 
  rm -rf $xmldir/${ins_tables[$i]}.xml
done

#导入成功则更新同步配置文件
#导入失败则使用备份文件恢复原状,这里关联删除的数据未恢复，可能还要考虑
if [ $error -eq 0 ];then
    sed -i '/SYNCHRONID=/d' $g_root/conf/sync.ini
    sed -i '/LASTUPDATE=/d' $g_root/conf/sync.ini
    echo "SYNCHRONID=$syncid">>$g_root/conf/sync.ini
    echo "LASTUPDATE=$mtime">>$g_root/conf/sync.ini
else
    output "INFO" "Recover DB data" $LINENO
    for file in `ls $xmldir/bak/*.xml`
    do
mysql -u${userName} -p${dbpasswd} ${dbname} <<EOF
SET FOREIGN_KEY_CHECKS=0;
delete from ${tables[$i]};
load xml local infile '$file' replace into table ${tables[$i]};
SET FOREIGN_KEY_CHECKS=1;
EOF
    done
fi

rm -rf *.list *.seq $xmldir/bak

cd - > /dev/null 2>&1

exit 0
