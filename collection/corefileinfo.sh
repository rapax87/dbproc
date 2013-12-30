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

dir=$(dirname $0)
cd $dir
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
outputCoreFileContextPath=corefile

DBType=$1
DBType="ORACLE"

getRelevantTrace()
{
		tmp_pwd=`pwd`
		cd $g_root/logs/
		coretime=`cat $cur_path/$outputCoreFileContextPath/time_list.txt | grep "$coreFile" | awk '{print $6,$7}' | sed 's/-//g' | cut -d. -f1 | awk '{print $1$2}'|sed 's/://g'`
 		
 		ls -lrt $g_root/logs/$trace_name_tmp*.log* > $cur_path/$outputCoreFileContextPath/tmp.txt 2>&1
 		
		trace_name=`ls | grep $trace_name_tmp`
		
		cd $cur_path/$outputCoreFileContextPath/
		isExist=`cat tmp.txt | grep "No such file or directory"`
 		if [ "$isExist" != "" ];then
 				cd $g_root/logs/
 				if [ "$trace_name" != "" ];then
						cp $trace_name $tmp_pwd/$outputCoreFileContextPath
				fi
				cd -> /dev/null
				rm tmp.txt
				return 0
    fi
    
    cat tmp.txt | cut -d'/' -f7 > $cur_path/$outputCoreFileContextPath/fileList.txt
    rm tmp.txt
    tailTime=`tail -1 fileList.txt|cut -d'.' -f4 | sed 's/DST$//g'`
    headTime=`head -1 fileList.txt|cut -d'.' -f4 | sed 's/DST$//g'`
    if [ $coretime -gt $tailTime ];then
				cd $IMAP_ROOT/var/logs/
				if [ "$trace_name" != "" ];then
						cp $trace_name $tmp_pwd/$outputCoreFileContextPath
				fi
				cd -> /dev/null
        rm -f fileList.txt
        return 0
    fi
    
		while read fileName
    do 
        fileTime=`echo $fileName|cut -d'.' -f4  | sed 's/DST$//g'`
        if [ $coretime -le $fileTime ];then
						cp $g_root/logs/$fileName $tmp_pwd/$outputCoreFileContextPath
						rm -f fileList.txt
						return 0
        fi 
    done < fileList.txt
    
}


getCoreFile()
{
	#进入core文件所在目录
    #cd $g_root/var/tmp/
    #cd $g_root
    corefiledir=/home/corefile
    cd $corefiledir
	coreFileList=`ls core* 2>&1`
    
    if [ -d ${cur_path}/corefile ]
    then
        rm -rf ${cur_path}/corefile
        mkdir -p ${cur_path}/corefile
    else
        mkdir -p ${cur_path}/corefile
    fi
    
    ifexist=`echo $coreFileList | grep "No such file or directory"`
    if [ "$ifexist" != "" ];then
    		echo "There is no core file to get!"
    		exit
    else
    	type=`uname`
    	if [ "$type" = "SunOS" ];then
    		$cur_path/bin/ls -lh --time-style=full-iso core.*[0-9] > $cur_path/$outputCoreFileContextPath/time_list.txt
    	else
    		ls -lh --time-style=full-iso core.*[0-9] > $cur_path/$outputCoreFileContextPath/time_list.txt
    	fi
    fi
    cd ->/dev/null
    
    for coreFile in $coreFileList
    do
        if [ -d $coreFile ]
        then
            echo "$coreFile is not a file!"
        else
        	cd $cur_path
        	#sun系统取trace
        	if [ "$DBType" = "SYBASE" ]
        	then	            
	            #获取内存堆栈
	            echo Start to obtain information from the stack..................
	            echo "coreFile=$coreFile"
	            pstack $IMAP_ROOT/var/logs/$coreFile >/tmp/${coreFile}stack.txt 2>&1
	            isvalid=`cat /tmp/${coreFile}stack.txt | grep "pstack: cannot"`
	            if [ "$isvalid" != "" ];then
	            		echo "$coreFile is not a core file"
	            else
	                pstack $IMAP_ROOT/var/logs/$coreFile | c++filt > $outputCoreFileContextPath/${coreFile}stack.txt
	            		pflags $IMAP_ROOT/var/logs/$coreFile > $outputCoreFileContextPath/${coreFile}flag.txt
	            		#获取相应的trace文件
	            		trace_name_tmp=`cat $outputCoreFileContextPath/${coreFile}stack.txt|sed -n '1p'|awk '{print $7}'`
	            		if [ "$trace_name_tmp" != "" ];then
	            				getRelevantTrace $coreFile
									fi
	      					echo Obtaining information from the stack finished....................
	            fi
	            
	        #suse系统取trace
	        elif [ "$DBType" = "ORACLE" ]
	        then
	        #获取内存堆栈
	        echo gdb start..................
	        echo "coreFile=$coreFile"
	        #binfile=`file $g_root/$coreFile|awk -F\' '{print $2}'|awk '{print $1}'|awk -F/ '{print $NF}'`
		binfile=`file $corefiledir/$coreFile|awk -F\' '{print $2}'|awk '{print $1}'|awk -F/ '{print $NF}'`
		
#gdb $g_root/bin/svcd $g_root/$coreFile<< EOF > $outputCoreFileContextPath/${coreFile}.txt 2>&1
#gdb $g_root/bin/$binfile $g_root/$coreFile<< EOF > $outputCoreFileContextPath/${coreFile}.txt 2>&1
gdb $g_root/bin/$binfile $corefiledir/$coreFile<< EOF > $outputCoreFileContextPath/${coreFile}.txt 2>&1
bt
quit
EOF
			#获取相应的trace文件
			trace_name_tmp=`cat $outputCoreFileContextPath/${coreFile}.txt|grep "Core was generated"|awk '{print$7}'`
			if [ "$trace_name_tmp" = "" ];then
					echo "$coreFile cannot be examined"
			else
					#getRelevantTrace $coreFile
					echo "getRelevantTrace $coreFile... not yet"
			fi
			echo gdb end....................
	    	fi
      fi
    done    
    
    tarFileName="ubp.coreinfo.${date_str}.tar.gz"
    cd $cur_path
    tar czf $tarFileName $outputCoreFileContextPath
    
    #mv $tarFileName $tarFileSavePath
    rm -rf ${cur_path}/${outputCoreFileContextPath}
    echo "The core information is successfully collected.Please download $tarFileName from ${tarFileSavePath}/.. in BIN mode."
}
getCoreFile
exit 0
