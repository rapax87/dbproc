#!/bin/bash
#title           :configVcsEnv.sh
#description     :This script will make GCO configuration automatically.
#author		 :xubingbing
#date            :20130821
#version         :0.1    
#usage		 :configVcsEnv.sh <secondary_server_ip> 
#notes           :Veritas must be installed & configured beforehead, 
#                  an original main.cf should have already existed.
#==============================================================================
clean_install=$1
. ./hacommon.sh
secondary=$SEC_IP

if [ -z $clean_install ];then
    #Clean environment
    ./clean.sh
    ssh root@$secondary "cd /opt/UBP/bin/veritas;./clean.sh"
else
    service mysql stop
    ssh root@$secondary "service mysql stop"
fi

#Run vradmind server & vxnetd threads
/etc/init.d/vras-vradmind.sh start 
/etc/init.d/vxnm-vxnetd start
ssh root@$secondary "/etc/init.d/vras-vradmind.sh start" 
ssh root@$secondary "/etc/init.d/vxnm-vxnetd start"

scp ./conf/vcs.conf root@$secondary:/opt/UBP/bin/veritas/conf/vcs.conf
if [ $? -ne 0 ];then
    output "ERROR" "Copy ./conf/vcs.conf to Sec failed." $LINENO
    exit 2
fi

#Config VxVM
./config_vxvm.sh pri
if [ $? -ne 0 ];then
    exit 2
fi

ssh root@$secondary "cd /opt/UBP/bin/veritas;./config_vxvm.sh sec"
if [ $? -ne 0 ];then
    exit 2
fi

#set Disk ID
./setDiskId.sh $secondary
if [ $? -ne 0 ];then
    exit 2
fi

#Start HA
./startha.sh $secondary
if [ $? -ne 0 ];then
    exit 8
fi

#Config VVR
./config_vvr.sh pri
if [ $? -ne 0 ];then
    exit 4
fi

#Config APP directory
./config_appdir.sh pri
if [ $? -ne 0 ];then
    exit 3
fi

ssh root@$secondary "cd /opt/UBP/bin/veritas;./config_appdir.sh sec"
if [ $? -ne 0 ];then
    exit 3
fi

#Stop HA
./stopha.sh $secondary
if [ $? -ne 0 ];then
    exit 5
fi

#Create main.cf
./create_maincf.sh $secondary
if [ $? -ne 0 ];then
    exit 6
fi

#copy agent
./copy_agent.sh $secondary
if [ $? -ne 0 ];then
    exit 7
fi

#Start HA
./startha.sh $secondary
if [ $? -ne 0 ];then
    exit 8
fi

#限定veritas端口
/opt/VRTS/bin/vrport data 53000,53001,53002
/etc/init.d/vxnm-vxnetd stop
/etc/init.d/vxnm-vxnetd start


###vradmin -g $DISK_GROUP -f stoprep $RVG_NAME
#启动复制
output "INFO" "Start replicator" $LINENO
vradmin -g $DISK_GROUP -a startrep $RVG_NAME
if [ $? -ne 0 ];then
    output "ERROR" "VVR failed:vradmin -g $DISK_GROUP -a startrep $RVG_NAME" $LINENO
    exit 1
fi
#检查复制连接
vxprint -thg $DISK_GROUP | grep "^rl" |  grep "CONNECT"

#查看链接属性
vxprint -g $DISK_GROUP -Pl
##vxprint -g $DISK_GROUP -l $RVG_NAME

#清除ubp自启动
rm -rf /etc/rc.d/rc3.d/S99startubp
rm -rf /etc/rc.d/rc5.d/S99startubp
rm -rf /etc/rc.d/start_ubp.sh

ssh root@$secondary "rm -rf /etc/rc.d/rc3.d/S99startubp"
ssh root@$secondary "rm -rf /etc/rc.d/rc5.d/S99startubp"
ssh root@$secondary "rm -rf /etc/rc.d/start_ubp.sh"

#替换/opt/VRTSvcs/bin/RVG/monitor (sfha bug:line 124 $awk)
cp ./conf/monitor /opt/VRTSvcs/bin/RVG/monitor
if [ $? -ne 0 ];then
    output "ERROR" "Copy ./conf/monitor to /opt/VRTSvcs/bin/RVG/monitor failed." $LINENO
    exit 2
fi

scp ./conf/monitor root@$secondary:/opt/VRTSvcs/bin/RVG/monitor
if [ $? -ne 0 ];then
    output "ERROR" "Copy ./conf/monitor to Sec failed." $LINENO
    exit 2
fi

exit 0
