-- Data validation & Cleaning
-- Null check 
select
sum(case when state is null then 1 else 0 end) as null_state,
sum(case when city is null then 1 else 0 end) as null_city,
sum(case when order_date is null then 1 else 0 end) as null_order_date,
sum(case when restaurant_name is null then 1 else 0 end) as null_restaurant_name,
sum(case when location is null then 1 else 0 end) as null_location,
sum(case when category is null then 1 else 0 end) as null_category,
sum(case when dish_name is null then 1 else 0 end) as null_dish_name,
sum(case when price_inr is null then 1 else 0 end) as null_price_inr,
sum(case when rating is null then 1 else 0 end) as null_rating,
sum(case when rating_count is null then 1 else 0 end) as null_rating_count
from swiggy_data;

-- Blank or Empty Strings
select * from swiggy_data 
where state ='' or restaurant_name ='' or location='' or category='' or dish_name='' ;

-- Duplicate Detection
select state,city,order_date,restaurant_name,location,category,dish_name,price_inr,rating,rating_count, count(*)as cnt from swiggy_data 
group by state,city,order_date,restaurant_name,location,category,dish_name,price_inr,rating,rating_count having count(*)>1;


-- Delete Duplication (pk nahi thi)
alter table swiggy_data add column id int auto_increment primary key; 
delete from swiggy_data where id in(select id from (select id, row_number() 
over(partition by state,city,order_date,restaurant_name,location,category,dish_name,price_inr,rating,rating_count 
order by id ) as rn from swiggy_data)t where rn>1 );


-- create Schema
-- Date table
create table dim_date(
date_id int auto_increment primary key,
full_date date,
year int,
month int,
month_name varchar(20),
quarter int,
day int,
week int
);

-- dim_location
create table dim_location(
location_id int auto_increment primary key,
state varchar (100),
city varchar(100),
location varchar(200)
);

-- dim_restaurant
create table dim_restaurant(
restaurant_id int auto_increment primary key,
restaurant_name varchar(200)
);

-- dim_category
create table dim_category(
category_id int auto_increment primary key,
category varchar(200)
);

-- dim_dish
create table dim_dish(
dish_id int auto_increment primary key,
dish_name varchar(200)
);

-- fact table
create table fact_swiggy_orders(
order_id int auto_increment primary key,
date_id int,
price_inr float,
rating float,
rating_count int,
location_id int,
restaurant_id int,
category_id int,
dish_id int,
foreign key (date_id) references dim_date(date_id),
foreign key (location_id) references dim_location(location_id),
foreign key (restaurant_id) references dim_restaurant(restaurant_id),
foreign key (category_id) references dim_category(category_id),
foreign key (dish_id) references dim_dish (dish_id)
);

-- Insert Data In Table
-- dim_date
insert into dim_date (full_date, year, month, month_name, quarter,day , week)
select distinct
order_date,
year(order_date),
month(order_date),
monthname(order_date),
quarter(order_date),
day(order_date),
week(order_date)
from swiggy_data
where order_date is not null
;

-- dim_location
insert into dim_location (state, city, location)
select distinct
state,
city, location
from swiggy_data;

-- dim_ restaurant
insert into dim_restaurant(restaurant_name)
select distinct
restaurant_name
from swiggy_data;

-- dim_category
insert into dim_category (category)
select
distinct
category
from swiggy_data;

-- dim_dish
insert into dim_dish(dish_name)
select distinct
dish_name
from swiggy_data;

-- fact_table
insert into fact_swiggy_orders(
date_id,
price_inr,
rating,
rating_count,
location_id,
restaurant_id,
category_id,
dish_id
)
select
dim_date.date_id,
swiggy_data.price_inr,
swiggy_data.rating,
swiggy_data.rating_count,
dim_location.location_id,
dim_restaurant.restaurant_id,
dim_category.category_id,
dim_dish.dish_id
from  swiggy_data
join dim_date 
on dim_date.full_date=swiggy_data.order_date
join dim_location
on dim_location.state=swiggy_data.state
and dim_location.city=swiggy_data.city
and dim_location.location=swiggy_data.location
join dim_restaurant
on dim_restaurant.restaurant_name=swiggy_data.restaurant_name
join dim_category
on dim_category.category=swiggy_data.category
join dim_dish
on dim_dish.dish_name=swiggy_data.dish_name;

-- schema  

select * from fact_swiggy_orders
 join dim_date
 on fact_swiggy_orders.date_id=dim_date.date_id
 join dim_location
 on fact_swiggy_orders.location_id=dim_location.location_id
 join dim_restaurant
 on fact_swiggy_orders.restaurant_id=dim_restaurant.restaurant_id
 join dim_category
 on fact_swiggy_orders.category_id=dim_category.category_id
 join dim_dish
 on fact_swiggy_orders.dish_id=dim_dish.dish_id;
 
 -- KPI'
 -- Total Orders
select * from  fact_swiggy_orders;
select count(*)as total_order from fact_swiggy_orders;

-- Total Revenue (INR MLLION)
select concat(round(sum(price_inr)/1000000,2),' INR Millon') as Total_revenue from fact_swiggy_orders;

-- Avg Dish Price
select concat(round(avg(price_inr),2),' INR ') as Total_Avg from fact_swiggy_orders;

-- Avg Rating
select avg(rating) as Avg_rating from fact_swiggy_orders;

-- Deep-Drive Bussiness Analysis

-- Monthly Order Trends

 select dim_date.year,dim_date.month,dim_date.month_name, count(*) as Total_orders
from fact_swiggy_orders join dim_date on fact_swiggy_orders.date_id=dim_date.date_id
 group by dim_date.year,dim_date.month,dim_date.month_name
 order by Total_orders desc;
 
 -- Quaterly Trend
 select dim_date.year,dim_date.quarter, count(*) as Total_orders
from fact_swiggy_orders join dim_date on fact_swiggy_orders.date_id=dim_date.date_id
 group by dim_date.year,dim_date.quarter
 order by Total_orders desc; 
 
 -- Yearly Trends
 select dim_date.year, count(*) as Total_orders
from fact_swiggy_orders join dim_date on fact_swiggy_orders.date_id=dim_date.date_id
 group by dim_date.year
 order by Total_orders desc; 
 
 -- Order by Day of Week (Mon-Sun)
select dayname(dim_date.full_date) as Day_Name,
count(fact_swiggy_orders.order_id) as total_order
from fact_swiggy_orders 
join dim_date
on fact_swiggy_orders.date_id=dim_date.date_id
group by dayname(dim_date.full_date), weekday(dim_date.full_date)
order by weekday(dim_date.full_date) ;

-- Top 10 cities by order volume
select dim_location.city, count(fact_swiggy_orders.order_id) as total_order
from dim_location
join fact_swiggy_orders
on dim_location.location_id=fact_swiggy_orders.location_id
group by dim_location.city
order by  total_order desc limit 10;

-- Revenue contribution by state
 select dim_location.state, sum(fact_swiggy_orders.price_inr) as total_revenue
from dim_location
join fact_swiggy_orders
on dim_location.location_id=fact_swiggy_orders.location_id
group by dim_location.state
order by  total_revenue desc;

-- Top 10 restaurants by orders
 
select dim_restaurant.restaurant_name, count(fact_swiggy_orders.order_id) as total_order
from dim_restaurant
join fact_swiggy_orders
on dim_restaurant.restaurant_id=fact_swiggy_orders.location_id
group by dim_restaurant.restaurant_name
order by  total_order desc limit 10;

-- Most ordered Dishes
select dim_dish.dish_name ,count(fact_swiggy_orders.order_id) 
as order_count
from dim_dish
join fact_swiggy_orders
on dim_dish.dish_id=fact_swiggy_orders.dish_id
group by dim_dish.dish_name
order by order_count desc;

-- Cuisine Performance (Orders +Avg Rating)
select dim_category.category, count(fact_swiggy_orders.order_id) as total_order
, round(avg(fact_swiggy_orders.rating),2) as avg_rating
from fact_swiggy_orders
join dim_category
on fact_swiggy_orders.category_id=dim_category.category_id
group by dim_category.category
order by total_order desc;

-- Customer Spending Insights
 -- Buckets of customer spend:
-- 1.under100
-- 100-199
  -- 200-299 etc 
  select
  case
when price_inr <100 then 'Under 100'
when price_inr between 100 and 199 then '100-199'
when price_inr between 200 and 299 then '200-299'
when price_inr between 300 and 499 then '300-499'
 else '500+'
 end as spend_bucket,
 count(order_id)  as total_orders
 from fact_swiggy_orders
 group by spend_bucket
 order by total_orders desc;
 
 
 

 

  
