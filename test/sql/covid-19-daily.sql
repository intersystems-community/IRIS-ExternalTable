 -- create external table person.firstname
 -- Row example {"date":"2020-05-11","state":"Wyoming","fips":"56","cases":"669","deaths":"7"}
create table covid_by_state (
    "date" CHAR(10), 
    "state" VARCHAR(20),
    fips INT,
    cases INT,
    deaths INT
)
 -- convert table to external storage
call EXT.ConvertToExternal(
    'covid_by_state',
    '{
    "adapter":"EXT.AWSS3",
    "location":"s3://covid19-lake/rearc-covid-19-nyt-data-in-usa/json/us-states/",
    "type": "jsonlines"
    }' 
)
 -- select from external table. Try to manually change test.csv file and rerun
select  top 10 * from "covid_by_state"
order by "date" desc
 -- cleanup
drop table covid_by_state %NODELDATA
 -- Done