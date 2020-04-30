 -- create GS table
create table tst.multifileGS 
(field1 varchar(50), 
int1 INT, 
float1 DOUBLE, 
field2 varchar(50))
 -- convert table to file-based external Google Cloud
call DL.ConvertToExternal('tst.multifileGS','test/multifile-gs.json')
 --
select %PATH,* from exttst.multifileGS 
 -- create S3 table
create table tst.multifileS3 
(field1 varchar(50), 
int1 INT, 
float1 DOUBLE, 
field2 varchar(50))
 -- convert table to file-based external AWS S3
call DL.ConvertToExternal('tst.multifileS3','test/multifile-s3.json')
 --
select * from exttst.multifileS3
 -- create Azure table
create table tst.multifileAZ 
(field1 varchar(50), 
int1 INT, 
float1 DOUBLE, 
field2 varchar(50))
 -- convert table to file-based external Azure Storage Bucket
call DL.ConvertToExternal('tst.multifileAZ','test/multifile-azure.json')
 --
select * from exttst.multifileAZ
 -- UNION across all three providers
select field1, int1, float1,field2, %PATH  from exttst.multifileGS
union all
select field1, int1, float1,field2,%PATH  from exttst.multifileS3
union all
select field1, int1, float1,field2,%PATH  from exttst.multifileAZ
 -- cleanup  GS
drop table exttst.multifileGS  %NODELDATA
 -- 
drop table tst.multifileGS  
 -- cleanup  S3
drop table exttst.multifileS3  %NODELDATA
 -- 
drop table tst.multifileS3
 -- cleanup  Azure
drop table exttst.multifileAZ  %NODELDATA
 -- 
drop table tst.multifileAZ  
 -- DONE