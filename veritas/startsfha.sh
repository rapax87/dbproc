#!/bin/sh
#启动SFHA
#SCRIPT:startsfha.sh

type=$1

. ./hacommon.sh

if [ "$type" == "pri" ];then
	hostName=${HOST_PRI}
elif [ "$type" == "sec" ];then
	hostName=${HOST_SEC}
else
	output "ERROR" "The Argument is pri | sec." $LINENO
	exit 1
fi

templateFile=./conf/startsfha.response
fileName=./conf/startsfha.response.${type}
cp $templateFile $fileName

if [ "$hostName" != "`hostname`" ];then
	output "ERROR" "./conf/vcs.conf may not set properly." $LINENO
	exit 1
fi

sed -i "s/%hostName%/$hostName/g" $fileName

/opt/VRTS/install/installsfha602 -responsefile $fileName
if [ $? -ne 0 ];then
    output "ERROR" "SFHA not start properly." $LINENO
    exit 1
fi

exit 0
