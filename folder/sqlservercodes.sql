select * from ordersf

ALTER TABLE ordersf
ALTER COLUMN shipping VARCHAR(20);

ALTER TABLE ordersf
ALTER COLUMN sub_category VARCHAR(20);

-- Modify other columns
ALTER TABLE dbo.ordersf
ALTER COLUMN order_date DATE NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN segment VARCHAR(20) NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN country VARCHAR(20) NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN city VARCHAR(20) NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN state VARCHAR(20) NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN postal_code VARCHAR(20) NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN region VARCHAR(20) NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN category VARCHAR(20) NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN product_id VARCHAR(50) NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN quantity INT NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN Actual_Discount DECIMAL(7,2) NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN Sale_Price DECIMAL(7,2) NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN Profit DECIMAL(7,2) NULL;

ALTER TABLE dbo.ordersf
ALTER COLUMN order_id INT NOT NULL;

ALTER TABLE dbo.ordersf
ADD CONSTRAINT PK_order_id PRIMARY KEY (order_id);

-- top 10 highest revenue generating products

select product_id, sum(sale_price)as total_sales
from ordersf
group by product_id
order by total_sales desc

-- five high selling products in each region
with cte as (
select region, product_id, sum(sale_price) as total_sales
from ordersf
group by region, product_id)
select * from (
select *
, ROW_NUMBER() over(partition by region order by total_sales desc ) as rn
from cte) A
where rn<= 5

UPDATE ordersf
SET order_date = DATEADD(MONTH, ABS(CHECKSUM(NEWID())) % 12, 
                          CAST(CONCAT(YEAR(order_date), '-01-', DAY(order_date)) AS DATE))
WHERE order_date IS NOT NULL;

-- month over month growth comparison for 2022 and 2023 sales eg: jan 2022 vs jan 2023
with cte as (
select year(order_date) as order_year, month(order_date) as order_month,
sum(sale_price) as sales
from ordersf
group by year(order_date), month(order_date)
--order by year(order_date), month(order_date)
)
select order_month
, sum(case when order_year = 2022 then sales else 0 end) as sales_2022
, sum(case when order_year = 2023 then sales else 0 end) as sales_2023
from cte
group by order_month
order by order_month


-- for each category which month had highest sales
with cte as (
select category, format(order_date,'yyyyMM') as order_year_month, sum(sale_price) as sales
from ordersf
group by category, format(order_date, 'yyyyMM')
--order by category, format(order_date, 'yyyyMM')
)
select * from (
select *,
ROW_NUMBER() over(partition by category order by sales desc) as rn
from cte
) a
where rn = 1

-- which sub category had highest growth by profit in 2023 compared to 2022
with cte as (
select sub_category, year(order_date) as order_year,
sum(sale_price) as sales
from ordersf
group by sub_category, year(order_date)
--order by year(order_date), month(order_date)
)
, cte2 as (
select sub_category
, sum(case when order_year = 2022 then sales else 0 end) as sales_2022
, sum(case when order_year = 2023 then sales else 0 end) as sales_2023
from cte
group by sub_category
)
select top 1 *
, (sales_2023 -sales_2022)*100/sales_2022
from cte2
order by (sales_2023 -sales_2022)*100/sales_2022 desc