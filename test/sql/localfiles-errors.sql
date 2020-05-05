 -- file with intentional errors to test SQL Runnier error reporting
 -- create external table person.firstname (error)
create table person.firstname (
    firstname varchar(50), 
    personid int1
)
 -- create external table person.firstname
create table person.firstname (
    firstname varchar(50), 
    personid int
)
 -- convert table to external storage (currently we add "ext" prefix to the table name to keep the original for debugging)
call DL.ConvertToExternal('person.firstname','test/sql/firstname.json')
 -- select from external table. Try to manually change test.csv file and rerun
select * from person.firstname
 -- lastname is a "regular" global - based table
create table person.lastname (
    lastname varchar(50), 
    personid int
)
 -- insert data into "lastname" regular table
insert into person.lastname1  (lastname, personid) values ('umnikov',1)
 -- insert data into "lastname" regular table
insert into person.lastname  (lastname, personid) values ('doe',2)
 -- insert data into "lastname" regular table
insert into person.lastname  (lastname, personid) values ('smith',3)
 -- join between external and regular table
SELECT * FROM person.firstname f JOIN person.lastname l ON l.personid = f.personid
 -- cleanup extperson.firstname 
drop table person.firstname %NODELDATA
 -- cleanup person.lastname 
drop table person.lastname 
 -- Done