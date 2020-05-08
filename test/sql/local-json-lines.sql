 -- file contains multiple json objects. single object per line 
 -- {"id":"12","slug":"https://parking.greenp.com/carpark/12_30-alvin-avenue/","address":"30 Alvin Avenue",
 -- "lat":"43.68919056469554","lng":"-79.39269983525526","rate":"$3.50 / Half Hour",
 -- "carpark_type":"surface","carpark_type_str":"Surface","is_ttc":false,"is_under_construction":false,"changing_rates":false,"rate_half_hour":"3.50","capacity":"188","max_height":"2.67","bike_racks":"available",
 -- "payment_methods":["Bills","Coins","Charge (Visa / Mastercard / American Express Only)","GreenP Express (Fast Track Card)"],
 -- "payment_options":["Pay at Exit Lane Stations","Credit Card at Entry & Exit","Cashier"],
 -- "rate_details":{"periods":[{"title":"Day Maximum until 6 PM - $25.00 (Entering 6 AM - 10 AM).\r\nDay Maximum until 6 PM - $22.00 (Entering 10 AM - 6 PM).","rates":[{"when":"Night Maximum (6pm - 6am)","rate":"$6.00"}],"notes":[]}],"addenda":[]},
 -- "monthly_permit_status":"not_available","monthly_permit_quantity":"","monthly_permit_price":"","map_marker_logo":"greenp_only","alert_box":"",
 -- "enable_streetview":"yes","streetview_lat":"43.68919056469554","streetview_long":"-79.39269983525526","streetview_yaw":"330.84","streetview_pitch":"1.32","streetview_zoom":"0"}
 -- create external table toronto.greenparking
 create table toronto.greenparking (
    address varchar(150),
    enable_streetview char(3),
    lat float,
    lng float,
    payment_options varchar(50),
    rate varchar(50),
    rate_details_periods varchar(150)
)
 -- convert table to external storage 
call DL.ConvertToExternal('toronto.greenparking','test/toronto-green-parking.json')
 -- select from external table. 
select * from toronto.greenparking
 -- select %DOCUMENT, containing the entire JSON line from table. 
select %PATH, LEFT(%DOCUMENT,30)||'...' from toronto.greenparking
 -- cleanup toronto.greenparking 
drop table toronto.greenparking %NODELDATA
 -- Done