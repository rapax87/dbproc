#!/bin/bash
if [ $# -lt 1 ];then
    echo "Please specify web ip"
    exit 1
fi
webip=$1
cd /home/VER
rm -Rf ./ubp
rm -Rf ./sds
rm -Rf ./web_setup

rm -rf ./ubp.tar.gz
rm -rf ./SDS.tar.gz
rm -rf ./web_setup.tar.gz

tar zxf eApp.tar.gz
tar zxf ubp.tar.gz


cd ubp
service mysql start
./uninstall.sh
./setup_ch.sh -i $webip
service mysql stop

exit 0
