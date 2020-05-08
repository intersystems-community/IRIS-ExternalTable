# Testing in IRIS SQL Shell

## Test SQL files

`test/sql/` directory of the repository contains multiple files that can be used for automated testing.

To run a test file use:
```
USER>s sc= ##class(Test.SQLRunner).RunSQLFile("test/sql/localfiles.sql")
```
## GitHub Actions

`.gitgub/workflows/` directory contains GitHub Actions workflow https://github.com/antonum/IRIS-ExternalTable/actions, executed on every github pull and involves some of the SQL tests from the `test/sql/`  above.

## SQL Shell

```sql
set ^ET.Config("LocalDir")="/Users/anton/IRIS-ExternalTable/"
do $system.SQL.Shell()
drop table tst.lineitem

create table tst.lineitem (
L_ORDERKEY INT,
L_PARTKEY INT,
L_SUPPKEY INT,
L_LINENUMBER INT,
L_QUANTITY INT,
L_EXTENDEDPRICE DOUBLE,
L_DISCOUNT DOUBLE,
L_TAX DOUBLE,
L_RETURNFLAG varchar(50),
L_LINESTATUS varchar(50),
L_SHIPDATE varchar(50),
L_COMMITDATE varchar(50),
L_RECEIPTDATE varchar(50),
L_SHIPINSTRUCT varchar(50),
L_SHIPMODE varchar(50), 
L_COMMENT varchar(150))
go
 -- convert table to file-based external
call DL.ConvertToExternal('tst.lineitem','test/lineitem.json')
select l_shipmode,count(*) from tst.lineitem group by l_shipmode
 --
 --
drop table tst.orders 

create table tst.orders 
(O_ORDERKEY INT, 
O_CUSTKEY INT, 
O_ORDERSTATUS varchar(50), 
O_TOTALPRICE DOUBLE, 
O_ORDERDATE varchar(50), 
O_ORDERPRIORITY varchar(50), 
O_CLERK varchar(50), 
O_SHIPPRIORITY INT, 
O_COMMENT varchar(150)) 
go
call DL.ConvertToExternal('tst.orders','test/orders.json')
 --

select 
  l_shipmode,
  sum(case
    when o_orderpriority ='1-URGENT'
         or o_orderpriority ='2-HIGH'
    then 1
    else 0
end
  ) as high_line_count,
  sum(case
    when o_orderpriority <> '1-URGENT'
         and o_orderpriority <> '2-HIGH'
    then 1
    else 0
end
  ) as low_line_count
from
  tst.orders o join tst.lineitem l 
  on 
    o.o_orderkey = l.l_orderkey 
where 
  l.l_shipmode = 'MAIL' or l.l_shipmode = 'SHIP'
group by l_shipmode
order by l_shipmode
go
 --

create table tst.multifile 
(field1 varchar(50), 
int1 INT, 
float1 DOUBLE, 
field2 varchar(50))
go 
```