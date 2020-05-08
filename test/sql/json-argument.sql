 -- Single Local file + regular table join
 -- create external table person.firstname
create table person.firstname (
    firstname varchar(50), 
    personid int
)
 -- convert table to external storage using json string as a parameter
 -- call EXT.ConvertToExternal('person.firstname','{ "adapter":"EXT.LocalFile", "location":"test/sql/firstname.csv", "delimiter": "," }')
call EXT.ConvertToExternal(
    'person.firstname',
    '{ 
        "adapter":"EXT.LocalFile", 
        "location":"test/sql/firstname.csv", 
        "delimiter": ",", 
        "skipHeaders": 1
    }' 
)
 -- select from external table. Try to manually change test.csv file and rerun
select * from person.firstname
 -- lastname is a "regular" global - based table
drop table person.firstname %NODELDATA
 -- Done