#!/bin/bash
dir=$(dirname $0)
cd $dir

. ../common.sh
if [ $# -lt 1 ]
then
    echo "Invalid args. eg. $0 <tarFileSavePath>"
    exit 1
fi
tarFileSavePath=$1

date_str=`date '+%Y%m%d%H%M%S'`
#csvname="${tarFileSavePath}/report_${date_str}.csv"
#csvname="./info.csv"
tmpname="./info.txt"
rm -rf ${tmpname}
rm -rf ${csvname}

ps -eo user,vsz,rss,pid,args|grep svcd|grep -v grep|grep root>${tmpname}
agentlist=( `awk '{print $7}' ${tmpname}` )
vszlist=( `awk '{print $2}' ${tmpname}` )
rsslist=( `awk '{print $3}' ${tmpname}` )
pids=`awk '{print $4}' ${tmpname}`
pidlist=( $pids )


j=0
for pid in $pids
do
    #echo "pid=${pid}"
    hdrlist[j]=`lsof -n|grep -w $pid|awk '{print $2}'|uniq -c|awk '{print $1}'`
    threadlist[j]=`ps h -Lf $pid|awk '{print $2}'|uniq -c|awk '{print $1}'`
    let j=j+1
done

#echo "pid,agent,rsz,rss,handle,thread">>${csvname}
k=0
for pid2 in $pids
do
    #echo "pid2=${pid2}"
    csvname=${tarFileSavePath}/${agentlist[k]}_info.csv
    if [ ! -f ${csvname} ]
    then
        echo "datetime,pid,agent,vsz,rss,handle,thread">>${csvname}
    fi
    echo "${date_str},${pidlist[k]},${agentlist[k]},${vszlist[k]},${rsslist[k]},${hdrlist[k]},${threadlist[k]}">>${csvname}
    let k=k+1
done

rm -rf ${tmpname}
exit



