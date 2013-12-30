#!/bin/bash
. ../common.sh

if [ $# -lt 4 ]
then
    echo "Invalid args."
    exit 1
fi


dbServer=$1
dbUser=$2
dbPasswd=$3
tarFileSavePath=$4

if [ -z $5 ]
then
    date_str=`date '+%Y%m%d%H%M%S'`
else
    date_str=$5
fi

outputDBFileContextPath=dbfile

getUserTable()
{
    FileName="ubp.dbinfo_${dbServer}.${date_str}"
    mkdir -p ${tarFileSavePath}/${outputDBFileContextPath}
    if [ $? -ne 0 ]
    then
        echo "mkdir ${tarFileSavePath}/${outputDBFileContextPath} failed"
        exit 1
    fi
mysql -u$dbUser -p$dbPasswd $dbServer <<EOF >${tarFileSavePath}/${outputDBFileContextPath}/DBInfo_${dbServer}.txt
show variables like '%max_connections%';
show status like 'Threads%';
show processlist;
EOF

mysql -u$dbUser -p$dbPasswd $dbServer <<EOF >${tarFileSavePath}/${outputDBFileContextPath}/tablelist_${dbServer}.txt
show tables;
EOF
    #tableNameList=`grep "TBL_" ${tarFileSavePath}/${outputDBFileContextPath}/tablelist_${dbServer}.txt`
    tableNameList=`grep -v "Tables_in_" ${tarFileSavePath}/${outputDBFileContextPath}/tablelist_${dbServer}.txt`

    for tableName in $tableNameList
    do
mysql -u$dbUser -p$dbPasswd $dbServer <<EOF >${tarFileSavePath}/${outputDBFileContextPath}/${dbServer}_${tableName}.select
select * from ${tableName}
go
EOF
    done
    
    dberrfile="/home/data/mysql/`hostname -s`.err"
    if [ -f $dberrfile ]
    then
        cp $dberrfile ${tarFileSavePath}/${outputDBFileContextPath}
    fi

    cd "$tarFileSavePath"
    tar cfz ${FileName}.tar.gz ${outputDBFileContextPath}
    rm -rf ${outputDBFileContextPath}
    cd - > /dev/null 2>&1
 
    echo "The database table is successfully collected, Please download ${FileName}.tar.gz from ${tarFileSavePath}/.."
}

getUserTable 
