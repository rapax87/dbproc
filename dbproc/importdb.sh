#! /bin/bash

#title           :importdb.sh
#description     :import XML data to DB
#author          :xubingbing
#date            :20131223
#version         :0.1    
#usage           :./importdb.sh <xml file path>
#notes           : 
#==============================================================================
dir=$(dirname $0)
cd $dir

if [ $# -lt 1 ];then
  echo "Usage: $0 <XML file path>"
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

tables=(`grep -E -n "<table_data" $xmlfile|awk -F\" '{print $2}'`)
begins=(`grep -E -n "<table_data" $xmlfile|awk -F: '{print $1}'`)
ends=(`grep -E -n "</table_data>" $xmlfile|awk -F: '{print $1}'`)

if [ ${#begins[@]} -ne ${#ends[@]} ] || [ ${#tables[@]} -ne ${#ends[@]} ];then
  output "ERROR" "$xmlfile format wrong" $LINENO
  exit 3
fi

size=${#tables[@]}

#. /opt/UBP/bin/common.sh
dbname=$g_ubpdb
userName=$g_odb_user
dbpasswd=$g_odb_psw

for((i=0;i<$size;i++));do
  if [ ${begins[$i]} -ge ${ends[$i]} ];then
    output "ERROR" "$xmlfile format wrong" $LINENO
    exit 4
  fi
  if [ ! -z $delete_before_import ];then
    output "INFO" "Clear table ${tables[$i]}..." $LINENO
mysql -u${userName} -p${dbpasswd} ${dbname} <<EOF
SET FOREIGN_KEY_CHECKS=0;
delete from ${tables[$i]};
SET FOREIGN_KEY_CHECKS=1;
EOF
  fi
  output "INFO" "Import table ${tables[$i]}..." $LINENO
  rm -rf $xmldir/${tables[$i]}.xml
  #echo "<?xml version=\"1.0\"?>" >> $xmldir/${tables[$i]}.xml
  #echo "<mysqldump xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">" >> $xmldir/${tables[$i]}.xml
  #echo "<database name=\"${dbname}\">" >> $xmldir/${tables[$i]}.xml
  sed -n "${begins[$i]},${ends[$i]}p" $xmlfile >> $xmldir/${tables[$i]}.xml
  #echo "</database>" >>$xmldir/${tables[$i]}.xml
  #echo "</mysqldump>" >>$xmldir/${tables[$i]}.xml
mysql -u${userName} -p${dbpasswd} ${dbname} <<EOF
SET FOREIGN_KEY_CHECKS=0;
load xml local infile '$xmldir/${tables[$i]}.xml' replace into table ${tables[$i]};
SET FOREIGN_KEY_CHECKS=1;
EOF
  if [ $? -ne 0 ];then
    output "WARN" "import ${tables[$i]} data failed" $LINENO
  else
    output "INFO" "Import table ${tables[$i]}...successfully" $LINENO
  fi 
  rm -rf $xmldir/${tables[$i]}.xml
done

cd - > /dev/null 2>&1

exit 0
