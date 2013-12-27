#!/bin/bash
#title           :changeip.sh
#description     :This script will change eapp IP.
#author		 :xubingbing
#date            :20130821
#version         :0.1    
#usage		 :changeip.sh 
#notes           :Veritas must be installed & configured beforehead, 
#                  an original main.cf should have already existed.
#==============================================================================
configType=$1
#check 
if [ "$configType" != "pri" ] && [ "$configType" != "sec" ];then
    echo "[ERROR]`date +'%Y%m%d %H:%M:%S'` $0($LINENO) [MSG]Usage: $0  pri|sec. at least 1 argument required."
    exit 1
fi

. ./hacommon.sh

oldip=`getLocalByEtherNum 1`

files_need_change="
$g_ubp_root/conf/mrs_rec_sinker_agent.xml
$g_ubp_root/conf/deploy_policy.xml
$g_ubp_root/conf/mrs_node_mgr_agent.xml
$g_ubp_root/conf/mrs_rec_man_agent.xml
$g_ubp_root/conf/ubp_db_cfgdata.xml
$g_websvc_dir/tomcat6/webapps/ROOT/WEB-INF/classes/ubp_services.properties
$g_websvc_dir/tomcat6/webapps/ROOT/WEB-INF/classes/database.properties
"

for file in $files_need_change
do
	sed -i "s/$oldip/$SERVERIP/g" $file
done

service mysql start

mysql -u$g_odb_user -p$g_odb_psw $g_ubpdb <<EOF
update TBL_UBPService set AddrIPV4='$SERVERIP';
update TBL_UBPNode set AddrIPV4='$SERVERIP';
update TBL_web_host_info set host_name='`hostname -s`', medip='$SERVERIP', omip='$SERVERIP';
EOF

exit 0

