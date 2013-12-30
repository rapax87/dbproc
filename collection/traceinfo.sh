#!/bin/bash
. ../common.sh
if [ $# -lt 1 ]
then
    echo "Invalid args."
    exit 1
fi
tarFileSavePath=$1
if [ -z $2 ]
then
    date_str=`date '+%Y%m%d%H%M%S'`
else
    date_str=$2
fi

if [ -z $3 ]
then
    before_days=3
else
    before_days=$3
fi


#dir=$(dirname $0)
#cd $dir
cur_path=${tarFileSavePath}

if [ ! -d $tarFileSavePath ]
then
    mkdir -p $tarFileSavePath
    if [ $? -ne 0 ]
    then
        echo "mkdir $tarFileSavePath failed"
        exit 1
    fi
fi
outputTraceFileContextPath=tracefile
outputSDSTraceFileContextPath=sdstracefile
outputWebTraceFileContextPath=webtracefile
outputSysTraceFileContextPath=systracefile
outputVRTSTraceFileContextPath=vrtstracefile


#获取trace文件，当前trace文件或者历史trace文件
getTrace()
{
	cd $g_root/logs/
	traceFileList=`ls *.log* 2>&1`
	if [ -d ${cur_path}/${outputTraceFileContextPath} ]
        then
        	rm -rf ${cur_path}/${outputTraceFileContextPath}
        	mkdir -p ${cur_path}/${outputTraceFileContextPath}
    	else
        	mkdir -p ${cur_path}/${outputTraceFileContextPath}
    	fi

    ifexist=`echo $traceFileList | grep "No such file or directory"`
    if [ "$ifexist" != "" ];then
    		echo "There is no trace file to get!"
    		exit
    else
    	for traceFile in $traceFileList
    	do
    		if [ -d $traceFile ]
    		then
    			echo "$traceFile is not a file!"
    		else
    			cp $traceFile ${cur_path}/${outputTraceFileContextPath}
    		fi
    	done
    fi

    cd $g_root/logs/backup
    backupFileList=`ls *.tar.gz 2>&1`
    if [ -d ${cur_path}/${outputTraceFileContextPath}/backup ]
    then
        rm -rf ${cur_path}/${outputTraceFileContextPath}/backup
        mkdir -p ${cur_path}/${outputTraceFileContextPath}/backup
    else
        mkdir -p ${cur_path}/${outputTraceFileContextPath}/backup
    fi
    for backupFile in $backupFileList
    	do
    		#if [ -f $backupFile ] && [ `date '+%Y%m%d%H%M%S' -d"-${before_days} day"` -le `echo $backupFile|cut -d_ -f 4|cut -d. -f 1` ]
    		if [ -f $backupFile ] && [ `date '+%Y%m%d%H%M%S' -d"-${before_days} day"` -le `echo $backupFile|rev|cut -d_ -f 1|rev|cut -d. -f 1` ]
    		then
    			cp $backupFile ${cur_path}/${outputTraceFileContextPath}/backup
    		fi
    	done

    #cp -Rf backup ${cur_path}/${outputTraceFileContextPath}

    if [ -d ${cur_path}/${outputVRTSTraceFileContextPath} ]
    then
        rm -rf ${cur_path}/${outputVRTSTraceFileContextPath}
        mkdir -p ${cur_path}/${outputVRTSTraceFileContextPath}
    else
        mkdir -p ${cur_path}/${outputVRTSTraceFileContextPath}
    fi
    if [ -f /etc/vcs/conf/config/main.cf ];then
        cp -Rf /etc/vcs/conf/config/main.cf ${cur_path}/${outputVRTSTraceFileContextPath}/
    else
        echo  "/etc/vcs/conf/config/main.cf not exist"
    fi
    if [ -f /opt/UBP/bin/veritas/conf/vcs.conf ];then
        cp -Rf /opt/UBP/bin/veritas/conf/vcs.conf ${cur_path}/${outputVRTSTraceFileContextPath}/
    else
        echo  "/opt/UBP/bin/veritas/conf/vcs.conf not exist"
    fi
    if [ -d /var/VRTSvcs/log ];then
        cp -Rf /var/VRTSvcs/log ${cur_path}/${outputVRTSTraceFileContextPath}/
    else
        echo  "/var/VRTSvcs/log not exist"
    fi
    
    cd $g_sds_dir/openfire/logs/
	traceFileList=`ls *.log* 2>&1`
	if [ -d ${cur_path}/${outputSDSTraceFileContextPath} ]
        then
        	rm -rf ${cur_path}/${outputSDSTraceFileContextPath}
        	mkdir -p ${cur_path}/${outputSDSTraceFileContextPath}
    	else
        	mkdir -p ${cur_path}/${outputSDSTraceFileContextPath}
    	fi

    ifexist=`echo $traceFileList | grep "No such file or directory"`
    if [ "$ifexist" != "" ];then
    		echo "There is no trace file to get!"
    		exit
    else
    	for traceFile in $traceFileList
    	do
    		if [ -d $traceFile ]
    		then
    			echo "$traceFile is not a file!"
    		else
    			cp $traceFile ${cur_path}/${outputSDSTraceFileContextPath}
    		fi
    	done
    fi

    cd $g_websvc_dir/tomcat6/webapps/ROOT/log
	traceFileList=`ls *.log* 2>&1`
	if [ -d ${cur_path}/${outputWebTraceFileContextPath} ]
        then
        	rm -rf ${cur_path}/${outputWebTraceFileContextPath}
        	mkdir -p ${cur_path}/${outputWebTraceFileContextPath}
    	else
        	mkdir -p ${cur_path}/${outputWebTraceFileContextPath}
    	fi

    ifexist=`echo $traceFileList | grep "No such file or directory"`
    if [ "$ifexist" != "" ];then
    		echo "There is no trace file to get!"
    		exit
    else
    	for traceFile in $traceFileList
    	do
    		if [ -d $traceFile ]
    		then
    			echo "$traceFile is not a file!"
    		else
    			cp $traceFile ${cur_path}/${outputWebTraceFileContextPath}
    		fi
    	done
    fi

    cd $g_websvc_dir/tomcat6/webapps/ROOT/log
	traceFileList=`ls *.log* 2>&1`
	if [ -d ${cur_path}/${outputWebTraceFileContextPath} ]
        then
        	rm -rf ${cur_path}/${outputWebTraceFileContextPath}
        	mkdir -p ${cur_path}/${outputWebTraceFileContextPath}
    	else
        	mkdir -p ${cur_path}/${outputWebTraceFileContextPath}
    	fi

    ifexist=`echo $traceFileList | grep "No such file or directory"`
    if [ "$ifexist" != "" ];then
    		echo "There is no trace file to get!"
    		exit
    else
    	for traceFile in $traceFileList
    	do
    		if [ -d $traceFile ]
    		then
    			echo "$traceFile is not a file!"
    		else
    			cp $traceFile ${cur_path}/${outputWebTraceFileContextPath}
    		fi
    	done
    fi

    cd /var/log
	traceFileList=`ls messages* 2>&1`
	if [ -d ${cur_path}/${outputSysTraceFileContextPath} ]
        then
        	rm -rf ${cur_path}/${outputSysTraceFileContextPath}
        	mkdir -p ${cur_path}/${outputSysTraceFileContextPath}
    	else
        	mkdir -p ${cur_path}/${outputSysTraceFileContextPath}
    	fi

    ifexist=`echo $traceFileList | grep "No such file or directory"`
    if [ "$ifexist" != "" ];then
    		echo "There is no trace file to get!"
    		exit
    else
    	for traceFile in $traceFileList
    	do
    		if [ -d $traceFile ]
    		then
    			echo "$traceFile is not a file!"
    		else
    			cp $traceFile ${cur_path}/${outputSysTraceFileContextPath}
    		fi
    	done
    fi

    tarFileName="ubp.traceinfo.${date_str}.tar.gz"
    cd $cur_path
    if [ -f $g_root/conf/version.ini ]
    then
    	cp $g_root/conf/version.ini $cur_path/
    	tar czf $tarFileName $outputTraceFileContextPath $outputSysTraceFileContextPath $outputWebTraceFileContextPath $outputSDSTraceFileContextPath $outputVRTSTraceFileContextPath version.ini
    else
    	tar czf $tarFileName $outputTraceFileContextPath $outputSysTraceFileContextPath $outputWebTraceFileContextPath $outputSDSTraceFileContextPath $outputVRTSTraceFileContextPath
    fi
    
    #mv $tarFileName $tarFileSavePath
    rm -rf ${outputTraceFileContextPath} ${outputSysTraceFileContextPath} ${outputWebTraceFileContextPath} ${outputSDSTraceFileContextPath} ${outputVRTSTraceFileContextPath} version.ini
    echo "The trace information is successfully collected.Please download $tarFileName from ${tarFileSavePath}/.. in BIN mode."

    
}
getTrace
exit 0

