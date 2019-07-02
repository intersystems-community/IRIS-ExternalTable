# IRIS ExternalTable

Allows IRIS to expose arbitrary delimited file as SQL table. Table can be local file or AWS S3 file based. 
"External" table is a full-featured SQL table. Can be joined, subselect with "Native" tables. 
The only strategy available for the external table is a FullTableScan.


```
do $system.SQL.Shell()


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
call DL.ConvertToExternal('tst.lineitem','s3://bigdataantonum/emrdata/lineitem/lineitem.tbl','|')

create table glob.orders 
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
call DL.ConvertToExternal('glob.orders','s3://bigdataantonum/emrdata/orders/orders.tbl','|')

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
  extglob.orders o join extglob.lineitem l 
  on 
    o.o_orderkey = l.l_orderkey 
where 
  l.l_shipmode = 'MAIL' or l.l_shipmode = 'SHIP'
group by l_shipmode
order by l_shipmode

select top 10 * from extglob.lineitem


```

## loadtest

`loadtest(classname)` routine measures data read time, isolated from SQL engine, 
by calling ReadNextLine() for the class, until entire dataset is read.

### Test July 1st 2019. Instance m5a.2xlarge, 24GB GloBuf
```
USER>do ^loadtest("extglob.orders")
Reading data from class: extglob.orders
..#FileName : s3://bigdataantonum/emrdata/orders/orders.tbl
Time to first line: 29.270293
Time to last line: 104.584113
Total records read: 15000000
Total bytes read: 1734195031

USER>do ^loadtest("extglob.lineitem")
Reading data from class: extglob.lineitem
..#FileName : s3://bigdataantonum/emrdata/lineitem/lineitem.tbl
Time to first line: 128.004969
Time to last line: 431.200915
Total records read: 59986052
Total bytes read: 7715741636
```