

/*==================== Question 1 ================================================= */
-- Write a sql script to return the distinct number of customers

SELECT COUNT(DISTINCT customer_id) [Total Customers] FROM dim_customer --793



/*==================== Question 2 ================================================= */
-- Write a sql script to give the total profit by each region per week

-- Total profit by each region per week (with week format 1 - 52)
SELECT region, c.week_of_year [Week of Year], SUM(profit) [Profit Per Week]
FROM 
fact_order a JOIN dim_region b ON a.region_id = b.region_id
JOIN dim_date c on c.date_id = a.order_date_id
GROUP BY region, c.week_of_year
ORDER BY region, c.week_of_year


-- Total profit by each region per week (with week of the month format)
SELECT region [Region], c.month_name [Month Name], 
c.week_of_month [Week of Month], SUM(profit) [Profit Per Week]
FROM 
fact_order a 
JOIN dim_region b ON a.region_id = b.region_id
JOIN dim_date c on c.date_id = a.order_date_id
GROUP BY region, c.month_name,  c.week_of_month
ORDER BY region, c.month_name, c.week_of_month

-- Total profit by each region per week (with week of the month format) excluding returned items
SELECT region [Region], c.month_name [Month Name], 
c.week_of_month [Week of Month], SUM(profit) [Profit Per Week]
FROM fact_order a 
JOIN dim_region b ON a.region_id = b.region_id
JOIN dim_date c on c.date_id = a.order_date_id
WHERE order_id NOT IN (SELECT order_id FROM fact_return)
GROUP BY region, c.month_name,  c.week_of_month
ORDER BY region, c.month_name, c.week_of_month



/*==================== Question 3 ================================================= */
-- Write a sql script to give the 2nd most sold item by quantity in each region, per year

-- 2nd most sold item by quantity in each region, per year (returned items are included)

SELECT Region, [Year], [product_code], [product_name], [Total Quantity]
FROM (
	SELECT 
	[Total Quantity], product_id, region_id, [Year], 
	DENSE_RANK() OVER (PARTITION BY region_id, [Year] Order By [Total Quantity] DESC) [Rank]
	FROM
	(
		SELECT SUM(Quantity) [Total Quantity], product_id, region_id, [year] 
		FROM fact_order a
		JOIN dim_date b on a.order_date_id = b.date_id 
		GROUP BY product_id, region_id, [year]
	) qty_by_region_year
)qty_by_region_year_rank 
JOIN dim_region b on qty_by_region_year_rank.region_id = b.region_id
JOIN dim_product c on qty_by_region_year_rank.product_id = c.product_id
WHERE [Rank] = 2
ORDER BY [Region], [Year] 


-- 2nd most sold item by quantity in each region, per year, excluding returned items
SELECT Region, [Year], [product_code], [product_name], [Total Quantity]
FROM (
	SELECT 
	[Total Quantity], product_id, region_id, [Year], 
	DENSE_RANK() OVER (PARTITION BY region_id, [Year] Order By [Total Quantity] DESC) [Rank]
	FROM
	(
		SELECT SUM(Quantity) [Total Quantity], product_id, region_id, [year] 
		FROM fact_order a
		JOIN dim_date b on a.order_date_id = b.date_id 
		WHERE order_id NOT IN (SELECT order_id FROM fact_return) 
		GROUP BY product_id, region_id, [year]
	) qty_by_region_year
)qty_by_region_year_rank 
JOIN dim_region b on qty_by_region_year_rank.region_id = b.region_id
JOIN dim_product c on qty_by_region_year_rank.product_id = c.product_id
WHERE [Rank] = 2
ORDER BY [Region], [Year] 

/*==================== Question 4 ================================================= */

-- Write a sql script to return, for each customer’s order, the time until their next order

/* Sample result

Customer	Order	        Next order (days)
AA-10315	CA-2016-128055	168
AA-10315	CA-2016-138100	384
AA-10315	CA-2018-103981	150

*/

WITH list_customers AS
(
	SELECT 
	*, 
	LEAD([Order Date], 1) OVER (PARTITION BY customer_no ORDER BY [Order Date]) [Next Order Date]
	FROM 
	(
		SELECT DISTINCT c.customer_no, c.[name] [Customer Name], order_id [Order ID], b.[date] [Order Date] 
		FROM fact_order a
		JOIN dim_date b on b.date_id = a.order_date_id
		JOIN dim_customer c on c.customer_id = a.customer_id

	) DistinctOrders
) 
SELECT customer_no [Customer No], [Customer Name], [Order ID], [Order Date], [Next Order Date], 
DATEDIFF(day, [Order Date], [Next Order Date]) [# o Days Until Next Order]
FROM list_customers
WHERE [Next Order Date] IS NOT NULL