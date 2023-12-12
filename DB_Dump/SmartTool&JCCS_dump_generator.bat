# This Batch File Created By Shawky Foda at 01/01/2004 To Backup DB

d:
cd d:\Oracle\DB\product\11.1.0\db_2\BIN

exp FILE=SmartToolJCCS%date%.dmp userid="system/redsea11@xe" OWNER=(SUPPORT,JCCS)