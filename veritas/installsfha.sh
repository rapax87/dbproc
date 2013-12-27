#!/bin/sh

#SCRIPT:installsfha.sh
#AUTHOR: luhuanwen
#DATE: 2013-8-20
#PLATFORM: for linux
#PURPOSE:install SFHA
#参数列表:
#:clusterID 集群ID
#:clusterName 集群名字
#########################################
######  DEFINE FILES AND VARIABLES  #####
type=$1

. ./hacommon.sh
#source ./conf/vcs.conf

if [ "$type" == "pri" ];then
	clusterName=${CLUSTER_PRI}
	clusterID=${PRIClusterID}
	hostName=${HOST_PRI}
elif [ "$type" == "sec" ];then
	clusterName=${CLUSTER_SEC}
	clusterID=${SECClusterID}
	hostName=${HOST_SEC}
else
	output "ERROR" "The Argument is pri | sec." $LINENO
	exit 1
fi


if [ -z $clusterID ]
then
    output "ERROR" "The clusterID not set." $LINENO
    exit 1
fi

if [ -z $clusterName ]
then
    output "ERROR" "The clusterName not set." $LINENO
   exit 1
fi
#hostName=`hostname`
templateFile=./conf/installer.response
fileName=./conf/installer.response.${type}
cp $templateFile $fileName

if [ "$hostName" != "`hostname`" ] || [ -z $clusterID ] || [ -z $clusterName ] || [ -z $PRIClusterNIC ] || [ -z $PRIClusterIP ] || [ -z $lltlink1 ];then
	output "ERROR" "./conf/vcs.conf may not set properly." $LINENO
	exit 1
fi

sed -i 's/%clusterID%/'"$clusterID"'/g' $fileName
sed -i 's/%clusterName%/'"$clusterName"'/g' $fileName 
sed -i "s/%hostName%/$hostName/g" $fileName

if [ $type == "pri" ];then
	sed -i "s/%csgnic%/$PRIClusterNIC/g" $fileName
	sed -i "s/%csgvip%/$PRIClusterIP/g" $fileName
	sed -i "s/%lltlink1%/$lltlink1/g" $fileName
	sed -i "s/%lltlinklowpri1%/$lltlinklowpri1/g" $fileName
fi
if [ $type == "sec" ];then
	sed -i "s/%csgnic%/$SECClusterNIC/g" $fileName
	sed -i "s/%csgvip%/$SECClusterIP/g" $fileName
	sed -i "s/%lltlink1%/$secondary_lltlink1/g" $fileName
	sed -i "s/%lltlinklowpri1%/$secondary_lltlinklowpri1/g" $fileName
fi

#/root/veritas/dvd2-suselinux/sles11_x86_64/installer -responsefile $fileName
$SFHA_INSTALL_DIR/dvd2-suselinux/sles11_x86_64/installer -responsefile $fileName

cp -rf /etc/sysconfig/llt /etc/sysconfig/llt.bk
sed -i 's/LLT_START=1/LLT_START=0/g' /etc/sysconfig/llt

cp -rf /etc/sysconfig/gab /etc/sysconfig/gab.bk
sed -i 's/GAB_START=1/GAB_START=0/g' /etc/sysconfig/gab

cp -rf /etc/sysconfig/vcs /etc/sysconfig/vcs.bk
sed -i 's/ONENODE=no/ONENODE=yes/g' /etc/sysconfig/vcs

#使用标准版license
vxkeyless set NONE <<EOF
y
EOF

vxkeyless set SFHASTD_VR,VCS_GCO <<EOF
y
EOF

exit 0
