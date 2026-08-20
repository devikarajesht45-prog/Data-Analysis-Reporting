/* 
Product Report 

Purpose: Consolidate key product metrics and boundaries

Highlights:
	1. Gather product name,category,subcategory and cost 
	2. Segment products by revenue to identify performmance level 
	3. Aggregate: 
		- total orders 
		- total sales
		- total quantity sold
		- total customers
		- lifespan
	4. Calculate valuable KPIs:
		- recency 
		- average order revenue 
		- average monthly revenue 
*/
create view gold.report_products as 
with base_query as (
	select
		s.order_number, 
		s.customer_key, 
		s.order_date,
		s.sales_amount, 
		s.quantity,
		p.product_key,
		p.product_name,
		p.category,
		p.subcategory,
		p.product_cost 
	from gold.fact_sales s 
	left join gold.dim_products p
	on s.product_key=p.product_key 
	where order_date is not null)

,product_aggregation as (
	select 
		product_key, 
		product_name,
		category,
		subcategory, 
		product_cost,
		datediff(month,min(order_date),max(order_date)) as lifespan,
		max(order_date) as last_order_date,
		count(distinct order_number) as total_orders, 
		count(distinct customer_key) as total_customers, 
		sum(sales_amount) as total_sales, 
		sum(quantity) as total_quantity, 
		round(avg(cast(sales_amount as float)/nullif(quantity,0)),1) as average_selling_price
	from base_query 
	group by 
		product_key, 
		product_name, 
		category, 
		subcategory,
		product_cost
)
--Final Query: Combine all customer results into one output 
select 
	product_key,
	product_name, 
	category,
	subcategory,
	product_cost,
	last_order_date, 
	datediff(month,last_order_date,getdate()) as recency_in_months,
	lifespan,
	case 
		when total_sales > 50000 then 'High Performer'
		when total_sales >=10000 then 'Mid Performer'
		else 'Low Performer'
	end as product_segment,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	average_selling_price, 
	case 
		when total_orders = 0 then 0 
		else total_sales/total_orders 
	end as average_order_revenue, 
	case 
		when lifespan = 0 then total_sales 
		else total_sales/lifespan 
	end as average_monthly_revenue 
from product_aggregation