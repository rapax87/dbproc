#! /bin/bash

#title           :exportdb.sh
#description     :export DB data to XML
#author          :xubingbing
#date            :20131223
#version         :0.1    
#usage           :./exportdb.sh <outputdir> [singletable]
#notes           :there should be a output.list file which specifies table names 
#                 in output directory. 
#==============================================================================
dir=$(dirname $0)
cd $dir

#if [ $# -lt 2 ];then
if [ $# -lt 1 ];then
  echo "Usage: $0 <outputdir>i [singletable]"
  exit 1
fi

#tablename=$1
outputdir=$1
singletable=$2
datestr=`date +'%Y%m%d%H%M%S'`

. ./dbcommon.sh

if [ ! -d $outputdir ];then
  output "ERROR" "$outputdir not exist" $LINENO
  exit 2
fi

#. /opt/UBP/bin/common.sh
dbname=$g_ubpdb
userName=$g_odb_user
dbpasswd=$g_odb_psw

syncid=`getSyncInfo SYNCHRONID`
mtime=`getSyncInfo LASTUPDATE`
version=`getVersionInfo VerID`

if [ ! -z "$singletable" ];then
  outputfile=${outputdir}/${singletable}.xml
  echo $singletable > ${outputdir}/outputing.list
elif [ -f ${outputdir}/output.list ];then
  outputfile=${outputdir}/output_${dbname}_${datestr}.xml
  cp -rf ${outputdir}/output.list ${outputdir}/outputing.list
else
  output "ERROR" "${outputdir}/output.list not exist" $LINENO
  exit 3
fi
rm -rf $outputfile
echo "<?xml version=\"1.0\"?>" >>$outputfile
echo "<mysqldump xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">" >>$outputfile
echo "<sync syncno=\"$syncid\" latestupdate=\"$mtime\" version=\"$version\" />" >>$outputfile
echo "<database name=\"${dbname}\">" >>$outputfile

cat ${outputdir}/outputing.list|while read tablename;do
  if [ -z "$tablename" ];then
    break
  fi
  mysqldump ${dbname} ${tablename} -X -u${userName} -p${dbpasswd} -t --skip-triggers > ${outputdir}/${tablename}_tmp.xml
  sed '1,3d;N;$d;P;D' ${outputdir}/${tablename}_tmp.xml>>$outputfile
  rm -rf ${outputdir}/${tablename}_tmp.xml
done
echo "</database>" >>$outputfile
echo "</mysqldump>" >>$outputfile

#tar zcvf ${outputdir}/output_${dbname}_${datestr}.tar.gz $outputfile
#rm -rf $outputfile
output "INFO" "Data exported into $outputfile successfully." $LINENO

cd - > /dev/null 2>&1

exit 0
