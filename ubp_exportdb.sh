#! /bin/bash

#title           :ubp_exportdb.sh
#description     :export DB data to XML
#author          :xubingbing
#date            :20131223
#version         :0.1    
#usage           :./ubp_exportdb.sh <outputdir>
#notes           :there should be a output.list file which specifies table names 
#                 in output directory. 
#==============================================================================
dir=$(dirname $0)
cd $dir

#if [ $# -lt 2 ];then
if [ $# -lt 1 ];then
  echo "Usage: $0 <outputdir>"
  exit 1
fi

#tablename=$1
outputdir=$1
datestr=`date +'%Y%m%d%H%M%S'`

. ./ubp_dbcommon.sh

if [ ! -d $outputdir ];then
  output "ERROR" "$outputdir not exist" $LINENO
  exit 2
fi

#. /opt/UBP/bin/common.sh
dbname=$g_ubpdb
userName=$g_odb_user
dbpasswd=$g_odb_psw

if [ ! -f ${outputdir}/output.list ];then
  output "ERROR" "${outputdir}/output.list not exist" $LINENO
  exit 3
fi
outputfile=${outputdir}/output_${dbname}_${datestr}.xml
rm -rf $outputfile
echo "<?xml version=\"1.0\"?>" >>$outputfile
echo "<mysqldump xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">" >>$outputfile
echo "<database name=\"${dbname}\">" >>$outputfile

cat ${outputdir}/output.list|while read tablename;do
  if [ -z "$tablename" ];then
    break
  fi
  mysqldump ${dbname} ${tablename} -X -u${userName} -p${dbpasswd} -t --skip-triggers > ${outputdir}/${tablename}.xml
  sed '1,3d;N;$d;P;D' ${outputdir}/${tablename}.xml>>$outputfile
  rm -rf ${outputdir}/${tablename}.xml
done
echo "</database>" >>$outputfile
echo "</mysqldump>" >>$outputfile

#tar zcvf ${outputdir}/output_${dbname}_${datestr}.tar.gz $outputfile
#rm -rf $outputfile
output "INFO" "Data exported into $outputfile successfully." $LINENO

cd - > /dev/null 2>&1

exit 0
