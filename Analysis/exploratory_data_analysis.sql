--Exploratory Data Analysis

--1. Finding the oldest and latest in range of orders
select 
	min(order_date) as oldest_order_date,
	max(order_date) as latest_order_date,
	datediff(year,min(order_date),max(order_date)) as order_range
from gold.fact_sales 

--2. Finding the oldest and youngest customers
select 
	min(birth_date) as oldest_birthdate,
	datediff(year,min(birth_date),getdate()) as oldest_age,
	max(birth_date) as youngest_birthdate,
	datediff(year,max(birth_date),getdate()) as youngest_age
from gold.dim_customers

--3. To check the distinct countries 
select 
	distinct country
from gold.dim_customers 

--4.Finding divisons and subdivisions 
select distinct
	category,
	subcategory,
	product_name
from gold.dim_products
where category is not null
order by 1,2,3

--5. Total number of customers by countries 
select 
	country,
	count(customer_key) as total_customers 
from gold.dim_customers 
group by country 
order by count(customer_key) desc

--6.Total number of customers by gender
select
	gender,
	count(customer_key) as total_customers
from gold.dim_customers 
group by gender 
order by count(customer_key) desc

--7.Total products by Category 
select 
	category,
	count(product_key) as total_products
from gold.dim_products 
where category is not null
group by category
order by count(product_key) desc

--8.Average cost in each category
select 
	category,
	avg(product_cost) as average_cost
from gold.dim_products 
where category is not null 
group by category 
order by avg(product_cost) desc

--9.Total revenue from each category 
select
	p.category,
	format(sum(s.sales_amount),'N2') as total_revenue 
from gold.dim_products p
join gold.fact_sales s
on p.product_key=s.product_key 
where p.category is not null 
group by p.category 
order by sum(s.sales_amount) desc

--10.Total revenue by each customer 
select 
	c.customer_key,
	c.first_name,
	c.last_name,
	sum(f.sales_amount) as total_revenue 
from gold.dim_customers c
join gold.fact_sales f 
on c.customer_key=f.customer_key 
group by 
	c.customer_key,
	c.first_name,
	c.last_name 
order by sum(f.sales_amount) desc

--11.Distribution of sold items by countries 
select 
	c.country,
	sum(s.quantity) as total_quamtity
from gold.dim_customers c
join gold.fact_sales s 
on c.customer_key=s.customer_key 
group by c.country
order by sum(s.quantity) desc

--12.Top 5 products by revenue
select top 5
	p.product_name,
	sum(s.sales_amount) as total_revenue
from gold.dim_products p
join gold.fact_sales s
on p.product_key=s.product_key
group by p.product_name
order by sum(s.sales_amount) desc

--13. Top 10 customers by orders placed
select top 10
	c.customer_key,
	c.first_name,
	c.last_name,
	count(distinct s.order_number) as total_orders 
from gold.dim_customers c 
join gold.fact_sales s 
on c.customer_key=s.customer_key 
group by c.customer_key,c.first_name,c.last_name 
order by count(distinct s.order_number) desc

--14. Worst performing product
select top 10
	p.product_name,
	count(distinct s.order_number) as total_orders
from gold.dim_products p
join gold.fact_sales s 
on p.product_key=s.product_key 
group by p.product_name 
order by count(distinct s.order_number) 

--Exploring measures
--15. Report with all Business metrics
select 
	'Total Sales' as measure_name,
	sum(sales_amount) as measure_value
from gold.fact_sales 
union all
select 
	'Total Quantity' as measure_name,
	sum(quantity) as measure_value
from gold.fact_sales 
union all
select 
	'Average Price' as measure_name,
	avg(price) as measure_value 
from gold.fact_sales 
union all
select 
	'Total Orders' as measure_name, 
	count(distinct order_number) as measure_value
from gold.fact_sales 
union all
select
	'Total Customers' as measure_name, 
	count(customer_key) as  measure_value 
from gold.dim_customers 
union all
select
	'Total Products' as measure_name, 
	count(product_key) as measure_value 
from gold.dim_products
