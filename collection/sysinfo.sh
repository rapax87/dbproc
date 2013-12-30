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
cur_path=`pwd`

if [ ! -d $tarFileSavePath ]
then
    mkdir -p $tarFileSavePath
    if [ $? -ne 0 ]
    then
        echo "mkdir $tarFileSavePath failed"
        exit 1
    fi
fi
outputSysFileContextPath=sysfile
sysinfofile=${tarFileSavePath}/${outputSysFileContextPath}/SysInfo.log
meminfofile=${tarFileSavePath}/${outputSysFileContextPath}/MemInfo.log
processinfofile=${tarFileSavePath}/${outputSysFileContextPath}/ProecessInfo.log

getSysInfo()
{ 
    FileName="ubp.sysinfo.${date_str}"
    mkdir -p ${tarFileSavePath}/${outputSysFileContextPath}
    
    date '+%Y-%m-%d %H:%M:%S' >> $sysinfofile

    echo "===uname -a info start=============================================="  >> $sysinfofile
    uname -a >> $sysinfofile    
    echo "===uname -a info end================================================"  >> $sysinfofile    
    echo >> $sysinfofile
    
    echo "===df -h info start=============================================="  >> $sysinfofile
    df -h >> $sysinfofile    
    echo "===df -h info end================================================"  >> $sysinfofile    
    echo >> $sysinfofile

    echo "===cat /proc/cpuinfo start=============================================="  >> $sysinfofile
    cat /proc/cpuinfo >> $sysinfofile    
    echo "===cat /proc/cpuinfo end================================================"  >> $sysinfofile    
    echo >> $sysinfofile

    echo "===cat /proc/meminfo start=============================================="  >> $sysinfofile
    cat /proc/meminfo >> $sysinfofile    
    echo "===cat /proc/meminfo end================================================"  >> $sysinfofile    
    echo >> $sysinfofile

    echo "===cat /proc/vmstat start=============================================="  >> $sysinfofile
    cat /proc/vmstat >> $sysinfofile    
    echo "===cat /proc/vmstat end================================================"  >> $sysinfofile    
    echo >> $sysinfofile

    echo "===chkconfig --list start=============================================="  >> $sysinfofile
    chkconfig --list >> $sysinfofile    
    echo "===chkconfig --list end================================================"  >> $sysinfofile    
    echo >> $sysinfofile
    
    echo "===IP info start================================================="  >> $sysinfofile
    ifconfig -a >> $sysinfofile    
    #svc_deploy -cmd queryhost >> med_getSysInfo/med_getSysInfo.txt 2>&1
    echo "===IP info end==================================================="  >> $sysinfofile
    echo >> $sysinfofile

    echo "===netstat -antp info start================================================="  >> $sysinfofile
    netstat -antp >> $sysinfofile    
    #svc_deploy -cmd queryhost >> med_getSysInfo/med_getSysInfo.txt 2>&1
    echo "===netstat -antp info end==================================================="  >> $sysinfofile
    echo >> $sysinfofile

    echo "===cat /etc/hosts start================================================="  >> $sysinfofile
    cat /etc/hosts >> $sysinfofile    
    echo "===cat /etc/hosts end==================================================="  >> $sysinfofile
    echo >> $sysinfofile

    echo "===check service pid start================================================="  >> $processinfofile
    echo "===ps -ef|grep svcd|grep -v grep|grep root|awk '{print \$2,\$10}'================================================="  >> $processinfofile
    ps -ef|grep svcd|grep -v grep|grep root|awk '{print $2,$10}' >> $processinfofile    
    echo "===check service pid end==================================================="  >> $processinfofile
    echo >> $processinfofile

    echo "===check process handler count start================================================="  >> $processinfofile
    echo "===lsof -n|grep -w $pid|awk '{print \$2}'|sort|uniq -c|sort -nr================================================="  >> $processinfofile
    list=`ps -ef|grep svcd|grep -v grep|grep root|awk '{print $2}'`
    namelist=( `ps -ef|grep svcd|grep -v grep|grep root|awk '{print $10}'` )
    j=0
    for pid in $list
    do
        lsof -n|grep -w $pid|awk '{print $2, "'${namelist[j]}'"}'|sort|uniq -c|sort -nr >> $processinfofile
        let j=j+1
    done
    echo "===check process handler count end==================================================="  >> $processinfofile
    echo >> $processinfofile

    echo "===check process thread count start=============================================="  >> $processinfofile
    echo "===ps h -Lf $pid|awk '{print \$2}'|uniq -c=============================================="  >> $processinfofile
    k=0
    for pid in $list
    do
        ps h -Lf $pid|awk '{print $2, "'${namelist[k]}'"}'|uniq -c >> $processinfofile
        let k=k+1
    done    
    echo "===check process thread count end================================================"  >> $processinfofile    
    echo >> $processinfofile

    echo "===check process gstack start=============================================="  >> $processinfofile
    echo "===gstack pid=============================================="  >> $processinfofile
    for pid in $list
    do
        echo "gstack $pid"  >> $processinfofile
        gstack $pid >> $processinfofile
    done    
    echo "===check process gstack end================================================"  >> $processinfofile    
    echo >> $processinfofile

	#vsz=VirtualMem(K)' -o rss='RealMem(K)
	echo "===check process memory count start================================================="  >> $meminfofile
    echo "===ps -eo vsz(VirtualMem(K)),rss(RealMem(K)),pid,args info start=============================================="  >> $meminfofile
    ps -eo vsz,rss,pid,args |sort +5 -k1n |grep svcd |grep -v grep |awk '{print $1","$2","$3","$6}' >> $meminfofile    
    echo "===check process memory count end================================================="  >> $meminfofile
    echo >> $meminfofile
    
   cd "$tarFileSavePath"
    tar cfz ${FileName}.tar.gz ${outputSysFileContextPath}
    rm -rf ${outputSysFileContextPath}
    cd - > /dev/null 2>&1
 
    echo "The sys info is successfully collected, Please download ${FileName}.tar.gz from ${tarFileSavePath}/.."   
}
getSysInfo
exit 0
