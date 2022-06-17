#!/bin/bash
export ORACLE_BASE=/u01/oracle
export ORACLE_HOME=/u01/oracle/product/11.2
export ORACLE_SID=yyw
export
PATH=/u01/oracle/product/11.2/bin:/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bi
n:/usr/local/sbin:/usr/sbin:/sbin:/home/oracle/bin
rman target / << EOF
run{
crosscheck backup;
allocate channel c1 device type disk;
allocate channel c2 device type disk;
backup incremental level 0 database format '/u01/backup/rman/db_%U.bak'
plus archivelog format '/u01/backup/rman/ar_%U.bak';
backup current controlfile format '/u01/backup/rman/ctl_%U.bak';
report obsolete device type disk;
delete noprompt obsolete device type disk;
delete noprompt expired backup device type disk;
release channel c1;
release channel c2;
}
EOF
exit
