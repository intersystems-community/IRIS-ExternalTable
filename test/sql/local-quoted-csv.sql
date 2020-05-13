  -- create external table cars
 create table cars ( --Year,Make,Model,Description,Price
    year INT,
    make char(10),
    model varchar(50),
    description varchar(50),
    price float
)
 -- convert table to external storage 
call EXT.ConvertToExternal(
    'cars',
    '{ 
        "adapter":"EXT.LocalFile", 
        "location":"test/sql/quoted.csv",
        "type": "quoted_csv", 
        "delimiter": ",", 
        "skipHeaders": 1
    }' 
)
 -- select from cars
 select * from cars
 -- cleanup cars 
 drop table cars %NODELDATA
 -- Done