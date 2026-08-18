use master;
go
if exists(select 1 from sys.databases where name='DataAnalytics')
begin
	drop database DataAnalytics;
end;
go
create database DataAnalytics;
go
use DataAnalytics;
go
create schema gold;
go

--create table dim_customers
create table gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number varchar(50),
	first_name varchar(50), 
	last_name varchar(50),
	marital_status varchar(50),
	gender varchar(50),
	country varchar(50),
	birth_date date,
	create_date date
);
go

--create table dim_products
create table gold.dim_products(
	product_key int, 
	product_id int,
	product_number varchar(50),
	product_name varchar(50),
	category_id varchar(50),
	category varchar(50),
	subcategory varchar(50),
	maintenance varchar(50),
	product_cost int,
	product_line varchar(50),
	start_date date
);
go

--create table fact_sales
create table gold.fact_sales(
	order_number varchar(50),
	product_key int,
	customer_key int,
	price int,
	quantity int,
	sales_amount int,
	order_date date,
	shipment_date date,
	due_date date
);
go

--inserting values
if object_id('gold.dim_customers','U') is not null
	drop table gold.dim_customers;
go

select * into gold.dim_customers
from datawarehouse.gold.dim_customers;
go

if object_id('gold.dim_products','U') is not null
	drop table gold.dim_products;
go

select * into gold.dim_products
from datawarehouse.gold.dim_products;
go

if object_id('gold.fact_sales','U') is not null
	drop table gold.fact_sales;
go

select * into gold.fact_sales
from datawarehouse.gold.fact_sales;
go




