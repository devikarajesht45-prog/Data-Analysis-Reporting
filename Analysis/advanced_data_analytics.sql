--Advanced Data Analysis
--1a. Trend Analysis - Analyzing change over time
select
	year(order_date) as order_year,
	month(order_date) as order_month,
	sum(sales_amount) as total_sales,
	count(distinct customer_key) as total_customers,
	sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null 
group by 
	year(order_date),
	month(order_date)
order by
	year(order_date),
	month(order_date)

--1b. Trend Analysis using Datetrunc
select
	datetrunc(year,order_date) as order_year,
	sum(sales_amount) as total_sales,
	count(distinct customer_key) as total_customers,
	sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null 
group by 
	datetrunc(year,order_date) 
order by
	datetrunc(year,order_date) 

--1c. Trend Analysis using Format
select
	format(order_date,'yyyy-MMM') as order_date,
	sum(sales_amount) as total_sales,
	count(distinct customer_key) as total_customers,
	sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null 
group by 
	format(order_date,'yyyy-MMM') 
order by
	format(order_date,'yyyy-MMM')

--2. Cumulative Analysis - Total Sales/month,Running total sales,Moving avg price
select
	order_date,
    total_sales,
	sum(total_sales) over
		(partition by year(order_date) order by order_date) 
	as running_sales,
	avg(average_price) over
		(partition by year(order_date) order by order_date)
	as moving_average_price
from (
	select 
		datetrunc(month,order_date) as order_date,
		sum(sales_amount) as total_sales,
		avg(price) as average_price
	from gold.fact_sales
	where order_date is not null
	group by datetrunc(month,order_date)
) as t;

--3. Segmenting products into cost range & to find how many products fall in each segment
with product_segment as (
	select 
		product_key,
		product_name,
		product_cost,
		case
			when product_cost < 100 then 'Below 100'
			when product_cost between 100 and 500 then '100-500'
			when product_cost between 500 and 1000 then '500-1000'
			else 'Above 1000'
		end as cost_range
	from gold.dim_products)
select 
	cost_range,
	count(product_key) as total_products
from product_segment 
group by cost_range
order by count(product_key)

/* 4. Group customers into three segments based on their spending behaviour.
	-VIP: Atleast 12 months of history and spent more than 5000
	-Regualar: Atleast 12 months of history but spent less than 5000
	-New: Customers with lifespan less than 12 months 
	Find total customers in each group */

with customer_spending as( 
	select
		customer_key,
		sum(sales_amount) as total_spending,
		min(order_date) as first_order,
		max(order_date) as last_order,
		datediff(month,min(order_date),max(order_date)) as lifespan
	from gold.fact_sales
	group by customer_key)
select
	customer_segment,
	count(customer_key) as total_customers 
from (
	select 
		customer_key,
		case 
			when lifespan >=12 and total_spending >5000 then 'VIP'
			when lifespan >=12 and total_spending <=5000 then 'Regular'
			else 'New'
		end as customer_segment
	from customer_spending) t
group by customer_segment
order by total_customers

--5. Which category contributes to most overall sales
with category_sales as (
	select 
		p.category,
		sum(s.sales_amount) as total_sales
	from gold.dim_products p 
	join gold.fact_sales s 
	on p.product_key=s.product_key 
	group by p.category)
select 
	category,
	total_sales,
	sum(total_sales) over () as overall_sales,
	concat(round((cast(total_sales as float)/sum(total_sales) over ())*100,2),'%') as percentage_of_total
from category_sales 
order by total_sales desc

--Performance Analysis
/* Analyse yearly performance of products by comparing the sales to 
both average sales amd the previous year's sales of the product */
with annual_product_sales as (
	select 
		year(s.order_date) as order_year,
		p.product_name,
		sum(s.sales_amount) as current_sales
	from gold.fact_sales s 
	join gold.dim_products p
	on s.product_key=p.product_key 
	where s.order_date is not null
	group by 
		year(s.order_date),
		p.product_name)
select 
	order_year,
	product_name,
	current_sales,
	--Finding average to current sales difference
	avg(current_sales) over (partition by product_name) as average_sales,
	current_sales - avg(current_sales) over (partition by product_name) as diff_average,
	case 
		when current_sales - avg(current_sales) over (partition by product_name) >0 then 'Above Average'
		when current_sales - avg(current_sales) over (partition by product_name) <0 then 'Below Average'
		else 'Average'
	end as average_change,
	--Finding year over year analysis 
	lag(current_sales) over (partition by product_name order by order_year) as py_sales,
	current_sales - lag(current_sales) over (partition by product_name order by order_year) as diff_py,
	case 
		when current_sales - lag(current_sales) over (partition by product_name order by order_year) >0 then 'Increase in Sales'
		when current_sales - lag(current_sales) over (partition by product_name order by order_year) <0 then 'Decrease in Sales'
		else 'No Change'
	end as py_change
from annual_product_sales 
order by 
	product_name,
	order_year	