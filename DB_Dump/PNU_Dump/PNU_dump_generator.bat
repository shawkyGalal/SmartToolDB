# This Batch File Created By Shawky Foda at 01/01/2004 To Backup DB

d:

cd D:\Google Drive\SmartValue\Sources\app\SmartTool\DB_Dump\PNU_Dump
set mydate=%date:~6,4%%date:~3,2%%date:~0,2%

exp FILE=SmartTool%mydate%.dmp userid="system/redsea11@svdb" OWNER=(SUPPORT,ICDB,JCCS,PNU,MOEP )  statistics=none 