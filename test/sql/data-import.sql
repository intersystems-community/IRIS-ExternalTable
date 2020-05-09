 -- Data migration from external to internal table
 -- create external table 
create table external_table (
    firstname varchar(50), 
    personid int
)
 -- convert table to external storage 
call EXT.ConvertToExternal(
    'external_table',
    '{ 
        "adapter":"EXT.LocalFile", 
        "location":"test/sql/firstname.csv", 
        "delimiter": ",", 
        "skipHeaders": 1
    }' 
)
 -- select from external table
select * from external_table 
 -- internal table with the same structure as external
create table internal_table (
    firstname varchar(50), 
    personid int
)
 -- data migration - basic - columns need to match
INSERT INTO internal_table SELECT * FROM external_table
 -- query internal table
select * from internal_table
 -- advanced syntax
INSERT INTO internal_table (firstname, personid) SELECT firstname, personid*10 FROM external_table
 -- query internal table
select * from internal_table
 -- cleanup external_table 
drop table external_table %NODELDATA
 -- cleanup internal_table 
drop table internal_table 
 -- Done