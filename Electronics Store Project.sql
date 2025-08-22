select * from customers;
select * from sales;
select * from products;
select * from stores;

--1.Range of sales data
select min(order_date), max(order_date)
from sales;

--2.Total unique orders
select count(distinct(ordernumber))
from sales;

--3.Number of unique customers
select count(distinct(customerkey))
from sales;

--4.Total number of unique products
select count(distinct(productkey))
from products;

--5.Total Revenue, Costs and Profits
create view profit_table as
select 
	s.*, 
	p.unitpriceUSD*s.quantity as revenue, 
	p.unitcostUSD*s.quantity as cost, 
	(p.unitpriceUSD - p.unitcostUSD)*s.quantity as profit
from sales as s
left join products as p
	on s.productkey = p.productkey
;

select
	sum(revenue) as Revenue,
	sum(cost) as Cost,
	sum(profit) as Profit
from profit_table;

--6.Total Profit each month
select 
	*,
	total_profit - lag(total_profit) over(partition by 1,2) as profit_increase,
	round(avg(total_profit) over(order by year,month),2) as moving_avg
from(
select
	extract(year from order_date) as year,
	extract(month from order_date) as month,
	sum(profit) as total_profit
from profit_table
group by 1,2
order by 1,2)
;

--7.Average Profit from each store each month
select
	s.storekey,
	s.country,
	s.state,
	round(avg(p.monthly_store_profit),2) as avg_monthly_profit
from (
	select
		storekey,
		extract(year from order_date) as year,
		extract(month from order_date) as month,
		sum(profit) as monthly_store_profit
	from profit_table
	group by 1,2,3
)as p
join stores as s
	on p.storekey = s.storekey
group by 1,2,3
order by 4 desc;

--8.Which brands generate the most profit?
select
	p.brand,
	sum(s.profit)
from profit_table as s
join products as p
	on s.productkey = p.productkey
group by 1
order by 2 desc;

--9.Top 10 most sold products
select
	p.productname,
	sum(s.quantity)
from sales as s
join products as p
	on s.productkey = p.productkey
group by 1
order by 2 desc
limit 10;

--10.Top 10 Products by profit
select
	p.productname,
	sum(s.profit)
from profit_table as s
join products as p
	on s.productkey = p.productkey
group by 1
order by 2 desc
limit 10;

--11.Which categories have the most products?
select
	category,
	count(distinct(productkey))
from products
group by 1
order by 2 desc;

--12.Total Profit and Products sold by each category
select
	p.category,
	sum(s.profit),
	sum(s.quantity)
from profit_table as s
join products as p
	on s.productkey = p.productkey
group by 1
;

--13.Top 3 most popular subcategories for each gender
select *
from(
	select
		c.gender, p.subcategory, sum(s.quantity),rank() over(partition by c.gender order by sum(quantity) desc)
	from sales as s
	left join products as p
		on p.productkey = s.productkey
	left join customers as c
		on c.customerkey = s.customerkey
	group by 1,2
)
where rank < 4
order by 1,4

--14.Number of purchases by each gender in each category
select
	p.category,
	sum(case when c.gender='Male' then 1 else 0 end) as Male,
	sum(case when c.gender='Female' then 1 else 0 end) as Female
from sales as s
left join products as p
	on p.productkey = s.productkey
left join customers as c
	on c.customerkey = s.customerkey
group by 1;

--15.Average order price for each age group
create view age_table as
select *, 
	   case when age<20 then '<20'
	   		when age between 20 and 30 then '20-30'
			when age between 30 and 40 then '31-40'
			when age between 40 and 50 then '41-50'
			when age between 50 and 60 then '51-60'
			else '61+'
		end as age_group
from (
select
	s.*,
	floor((s.order_date - c.birthday)/365) as age
from sales as s
join customers as c
	on s.customerkey = c.customerkey
);

select
	a.age_group,
	round(sum(a.quantity*p.unitpriceusd)/count(distinct(a.ordernumber)),2)
from age_table as a
left join products as p
	on a.productkey = p.productkey
group by 1;

--16.Top 3 Most Popular subcategory for each age group
select *
from(
	select
		a.age_group, p.subcategory, sum(a.quantity),rank() over(partition by a.age_group order by sum(a.quantity) desc)
	from age_table as a
	left join products as p
		on p.productkey = a.productkey
	group by 1,2
)
where rank < 4
order by 1;

--17.Percentage of customers that make more than 1 purchase
select sum(case when count>1 then 1 else 0 end)*100/count(*)
from(
select
	customerkey,
	count(distinct(ordernumber))
from sales
group by 1)
;

--18.Comparing online vs in_store sales
select
	online_or_store,
	sum(revenue),
	sum(profit),
	count(distinct(ordernumber))
from (
select *, case when storekey=0 then 'online' else 'store' end as online_or_store  
from profit_table
)
group by 1;

--19.Which store was the fastest to reach $100,000 in sales
select
	p.storekey,
	s.country,
	s.state,
	min(order_date)-s.open_date days_to_$100k
from(
select *,
	sum(revenue) over(partition by storekey order by order_date) as running_total
from profit_table
) as p
join stores as s
	on p.storekey = s.storekey
where running_total >= 100000
group by 1,2,3, s.open_date
order by 4;