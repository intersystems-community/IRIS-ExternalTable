 -- create table
create table tst.multifile 
(field1 varchar(50), 
int1 INT, 
float1 DOUBLE, 
field2 varchar(50))
 -- convert table to file-based external
call EXT.ConvertToExternal('tst.multifile','test/multifile.json')
 -- select all
select *,%PATH from tst.multifile 
 -- select TOP
select top 6 *,%PATH from tst.multifile 
 -- select all ALL RECORDS must be returned!!!
select *,%PATH from tst.multifile 
 -- cleanup
drop table tst.multifile %NODELDATA
 -- Done