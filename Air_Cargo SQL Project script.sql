

use air_cargo; 
create table customer (
	customer_id		tinyint	not null primary key,
	first_name 		varchar(30)	not null,
	last_name 		varchar(30) not null,
	date_of_birth 	date not null,
	gender 			char(1) not null
);
describe customer;
select * from customer;

create table routes (
	Route_id 		tinyint not null unique primary key,
	Flight_num 		smallint constraint check_1 check (Flight_num is not null),
	Origin_airport 	char(3) 	not null,
	Destination_airport 	char(3)	not null,
	Aircraft_id 	varchar(15)	not null,
	Distance_miles 	smallint not null constraint check_2 check (distance_miles > 0)
);
describe routes;

select * from routes;

create table passengers_on_flights (
	customer_id		tinyint not null references customer(customer_id),
    aircraft_id 	varchar(20)	not null,	
	route_id 		tinyint not null references route(route_id),
	depart			char(3)	not null,
	arrival 		char(3)	not null,
	seat_num 		varchar(10)	not null,
	class_id 		varchar(20)	not null,
	travel_date 	date not null,
	flight_num 		smallint not null);
describe passengers_on_flights;
select * from passengers_on_flights;

create table ticket_details (
	p_date 			date not null,
	customer_id 	tinyint not null references customer(customer_id),
	aircraft_id 	varchar(20) not null,
	class_id 		varchar(20) not null,
	no_of_tickets 	tinyint not null,
	a_code 			char(3)	not null,
	price_per_ticket decimal(5,2) not null,
	brand 			varchar(30) not null
);
describe ticket_details;

select * from ticket_details;

select * from passengers_on_flights where route_id between 1 and 25 order by route_id, customer_id;

select count(*) as 'Number of Passengers', sum(no_of_tickets*price_per_ticket) as 'Total Revenue' from ticket_details where class_id = 'Bussiness';

select concat(first_name, ' ',last_name) as "Full Name" from customer;


select * from customer c where exists (select 1 from ticket_details t where t.customer_id = c.customer_id) order by customer_id;  
select count(*) from customer c where c.customer_id in  (select distinct customer_id from ticket_details);

select c.customer_id, c.first_name, c.last_name from customer c
 where exists (select 1 from ticket_details t 
 where t.customer_id = c.customer_id and brand = 'Emirates') order by customer_id;


select customer_id, count(customer_id) as "Number of Travels" from passengers_on_flights
where class_id = 'Economy Plus' group by customer_id having count(customer_id) >= 1;

select if(sum(no_of_tickets * price_per_ticket) > 10000,  'YES, Revenue crossed 10000','NO, Revenue has not crossed 10000') 
as Result from ticket_details;   


create user if not exists 'air_cargouser'@'127.0.0.1' identified by 'password123';
grant all privileges on air_cargo to 'air_cargouser'@'127.0.0.1';

select class_id, max(price_per_ticket) group by class_id;
select distinct class_id, max(price_per_ticket) over(partition by class_id) as Maximum_price from ticket_details order by Maximum_price;

select customer_id, route_id from passengers_on_flights where route_id = 4;

create index route_idx on passengers_on_flights (route_id);
select * from passengers_on_flights where route_id = '4';


select customer_id, aircraft_id, sum(no_of_tickets * price_per_ticket) as Total_Price 
from ticket_details group by customer_id, aircraft_id with rollup;

create view Business_classes as 
select c. first_name, c. last_name , t. brand from customer c 
inner join ticket_details t on c. customer_id = t. customer_id where class_id = "Bussiness"  order by customer_id ;
SELECT * FROM Business_classes;


delimiter $$
create procedure check_routes(in rid VARCHAR (255))
begin
  declare TableNotFound condition for 1146;
declare exit handler for TableNotFound
select 'Please check if table customer / route_id are created - one/both are are missing' Message;
set @query = concat('select * from customer where customer_id in (select distinct customer_id from passengers_on_flights 
where route_id in (', rid,'));');
prepare sql_query from @query;
execute sql_query; 
end$$
delimiter ;
call check_routes("1,5");

DELIMITER // 
create procedure travelled_more_than_2000_miles()
begin 
Select * from routes where distance_miles > 2000;
end //
call travelled_more_than_2000_miles();


DELIMITER //
create function travelled_distance(distance_miles INT)
returns VARCHAR(100) deterministic
begin 
declare travelled_distance VARCHAR (100); 
IF distance_miles BETWEEN 0 AND 2000 THEN SET travelled_distance = 'Short Distance Travel (SDT)';
ELSEIF distance_miles BETWEEN 2000 AND 6500 THEN SET travelled_distance = 'Intermediate Distance Travel (IDT)';
ELSEIF distance_miles > 6500 THEN SET travelled_distance = 'Long-Distance Travel (LDT)';
END IF; 
RETURN (travelled_distance);
END //
DELIMITER //
select route_id, flight_num, origin_airport, destination_airport, distance_miles, travelled_distance(distance_miles) AS distance_miles 
from routes order by distance_miles;


select p_date, customer_id, class_id,
case when class_id in ('Business', 'Economy Plus') then 'Yes'
else "No"
end as complimentary_service from ticket_details;

delimiter $$
create function chk_comp_ser(cls varchar(20)) 
returns char(3)
deterministic
begin
declare comp_ser CHAR(3);
    if cls in('Bussiness', 'Economy Plus') THEN set comp_ser = 'Yes';
    else set comp_ser = 'No';
    end if;
	return (comp_ser);
end $$
create procedure chk_comp_ser_pro()
begin
select p_date, customer_id, class_id, chk_comp_ser(class_id) as complimentary_service from ticket_details;
 end $$
 call chk_comp_ser_pro();


DELIMITER //
create Procedure my_cursor ()
begin
declare a VARCHAR (100);
declare b VARCHAR (100);
declare my_cursor cursor for select last_name, first_name from customer 
where last_name = 'Scott'; 
open my_cursor; 
repeat fetch my_cursor into a,b;
until b = 0 end repeat; 
select a as last_name, b as first_name; 
close my_cursor; 
end;
// DELIMITER ;
CALL my_cursor();

