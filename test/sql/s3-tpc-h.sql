 -- S3 TPC-H test
 -- Create LINEITEM
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
 -- convert LINEITEM to external
call DL.ConvertToExternal('tst.lineitem','test/lineitem-s3.json')
 -- Count # of rows by shipmode
select l_shipmode,count(*) from exttst.lineitem group by l_shipmode
 -- create ORDERS
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
 -- convert ORDERS to external
call DL.ConvertToExternal('tst.orders','test/orders-s3.json')
 -- count # of records
select count(*) from exttst.orders
 -- TPC-H query # ?
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
  exttst.orders o join exttst.lineitem l 
  on 
    o.o_orderkey = l.l_orderkey 
where 
  l.l_shipmode = 'MAIL' or l.l_shipmode = 'SHIP'
group by l_shipmode
order by l_shipmode
 -- cleanup tst.lineitem
drop table tst.lineitem
 -- cleanup tst.orders
drop table tst.orders
 -- cleanup exttst.lineitem
drop table exttst.lineitem %NODELDATA
 -- cleanup exttst.orders
drop table exttst.orders %NODELDATA