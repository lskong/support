#SQL> conn /as sysdba
#SQL> create or replace directory dumpdir as '/oradata/dumpdir';
DATE=`date +%y-%m-%d`
datename=${DATE}
expdp system/kingdee dumpfile=kingdee${datename}.dmp directory=dumpdir schemas=scott logfile=kingdee${datename}.log compression=ALL
find /oradata/dumpdir -mtime +60 -name "*${DATE}.dmp" -print |xargs rm -f -r
