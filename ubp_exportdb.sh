#! /bin/bash

#title           :ubp_exportdb.sh
#description     :enable or disable an regular export task
#author          :xubingbing
#date            :20131223
#version         :0.1    
#usage           :./ubp_exportdb.sh <option> <outputdir> <day> <month> <day of week>
#notes           :there should be a output.list file which specifies table names 
#                 in output directory. 
#==============================================================================
dir=$(dirname $0)
cd $dir

#if [ $# -lt 2 ];then
if [ $# -lt 5 ];then
  echo "Usage: $0 <option> <outputdir> <day> <month> <day of week>"
  exit 1
fi

option=$1
outputdir=$2
day=$3
week=$5
month=$4
datestr=`date +'%Y%m%d%H%M%S'`

if [ $option -eq 0 ];then
  sed -i '/ubp_exportdb.sh/d' /var/spool/cron/tabs/root
else
  echo "0 0 $day $month $week /opt/UBP/bin/ubp_exportdb.sh $outputdir >/dev/null 2>&1 &" >> /var/spool/cron/tabs/root
fi
/etc/init.d/cron reload
/etc/init.d/cron restart

cd - > /dev/null 2>&1

exit 0
