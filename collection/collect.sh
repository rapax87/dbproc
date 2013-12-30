#!/bin/bash
dir=$(dirname $0)
cd $dir

. ../common.sh
#echo $#
if [ $# -lt 2 ]
then
    echo "Invalid args. eg. $0 all <tarFileSavePath>"
    exit 1
fi
FileSavePath=$2

if [ -z $3 ]
then
    before_days=3
else
    before_days=$3
fi

date_str=`date '+%Y%m%d%H%M%S'`_${RANDOM}
if [ ! -d $FileSavePath ];then
    echo "$FileSavePath not exist"
    exit 1
fi
tarFileSavePath=${FileSavePath}/${date_str}
mkdir -p ${tarFileSavePath}
logname="${tarFileSavePath}/ubpinfo_${date_str}.log"

if [ "$1" = "core" ]
then
	./corefileinfo.sh $tarFileSavePath $date_str>> ${logname} 2>&1
elif [ "$1" = "trace" ]
then
	./traceinfo.sh $tarFileSavePath $date_str $before_days>> ${logname} 2>&1
elif [ "$1" = "db" ]
then
	./dbinfo.sh $g_ubpdb $g_odb_user $g_odb_psw $tarFileSavePath $date_str>> ${logname} 2>&1
	./dbinfo.sh sds $g_odb_user $g_odb_psw $tarFileSavePath $date_str>> ${logname} 2>&1
elif [ "$1" = "sys" ]
then
	./sysinfo.sh $tarFileSavePath $date_str>> ${logname} 2>&1
elif [ "$1" = "all" ]
then
	./corefileinfo.sh $tarFileSavePath $date_str>> ${logname} 2>&1
	./traceinfo.sh $tarFileSavePath $date_str $before_days>> ${logname} 2>&1
	./dbinfo.sh $g_ubpdb $g_odb_user $g_odb_psw $tarFileSavePath $date_str>> ${logname} 2>&1
	./dbinfo.sh sds $g_odb_user $g_odb_psw $tarFileSavePath $date_str>> ${logname} 2>&1
	./sysinfo.sh $tarFileSavePath $date_str>> ${logname} 2>&1
	cd $tarFileSavePath
	ls *_info.csv > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		tar czf ubp.report.$date_str.tar.gz *_info.csv
		tar czf ubp.info.$date_str.tar.gz ubp.traceinfo.$date_str.tar.gz ubp.coreinfo.$date_str.tar.gz ubp.dbinfo_sds.$date_str.tar.gz ubp.dbinfo_${g_ubpdb}.$date_str.tar.gz ubp.sysinfo.$date_str.tar.gz ubpinfo_${date_str}.log ubp.report.$date_str.tar.gz
	else
		tar czf ubp.info.$date_str.tar.gz ubp.traceinfo.$date_str.tar.gz ubp.coreinfo.$date_str.tar.gz ubp.dbinfo_sds.$date_str.tar.gz ubp.dbinfo_${g_ubpdb}.$date_str.tar.gz ubp.sysinfo.$date_str.tar.gz ubpinfo_${date_str}.log 
	fi
	
	mv ubp.info.$date_str.tar.gz ${FileSavePath}/
	cd ${FileSavePath}
	rm -rf $tarFileSavePath
	#rm -rf ubp.traceinfo.$date_str.tar.gz ubp.coreinfo.$date_str.tar.gz ubp.dbinfo_sds.$date_str.tar.gz ubp.dbinfo_${g_ubpdb}.$date_str.tar.gz ubp.sysinfo.$date_str.tar.gz ubpinfo_${date_str}.log ubp.report.$date_str.tar.gz
	echo "The ubp information is successfully collected.Please download ubp.traceinfo.$date_str.tar.gz from $FileSavePath in BIN mode."

	cd - > /dev/null 2>&1
else
	echo "do nothing" 
fi
exit 0

