/* Customer Report
Purpose: Consolidate by customer metrics and behaviours

Highlights:
	1. Gather name,age,transaction details
	2. Segment customers into categories and age groups
	3. Aggregate:
		- total orders
		- total sales
		- total quantity purchased 
		- total products
		- lifespan
	4. Calcualte valuable KPIs:
		- recency 
		- average order value
		- average monthly spend 
*/
with base_query as (
-- Retrieve the columns from tables
	select
		s.order_number,
		s.product_key,
		s.order_date, 
		s.sales_amount, 
		s.quantity,
		c.customer_key, 
		c.customer_number,
		concat(c.first_name,'',c.last_name) as customer_name, 
		datediff(year,c.birth_date,getdate()) as age
	from gold.fact_sales s
	left join gold.dim_customers c
	on s.customer_key=c.customer_key 
	where order_date is not null)

, customer_aggregation as (
-- Summarize metrics at customer level
	select 
		customer_key, 
		customer_number, 
		customer_name, 
		age,
		count(distinct order_number) as total_orders, 
		sum(sales_amount) as total_sales,
		sum(quantity) as total_quantity,
		count(distinct product_key) as total_products,
		max(order_date) as last_order_date,
		datediff(month,min(order_date),max(order_date)) as lifespan
	from base_query
	group by 
		customer_key,
		customer_number,
		customer_name, 
		age
)
--Final output query
select
	customer_key, 
	customer_number, 
	customer_name, 
	age,
	case 
		when age < 20 then 'Under 20'
		when age between 20 and 29 then '20-29'
		when age between 30 and 39 then '30-39'
		when age between 40 and 49 then '40-49'
		else 'Above 50'
	end as age_group,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	case 
		when lifespan >= 12 and total_sales > 5000 then 'VIP'
		when lifespan >= 12 and total_sales <= 5000 then 'Regular'
		else 'New'
	end as customer_segment,
	last_order_date,
	datediff(month,last_order_date,getdate()) as recency,
	lifespan,
	case 
		when total_orders = 0 then 0
		else total_sales/total_orders
	end as average_order_value,
	case 
		when lifespan = 0 then total_sales 
		else total_sales/lifespan 
	end as average_monthly_spent 
from customer_aggregation 