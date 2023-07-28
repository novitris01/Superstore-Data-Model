/****** Script for SelectTopNRows command from SSMS  

Using the provided data, outline entities of the GSS business model, 
model their relationship to one another (think cardinality) 
and their type (dimension or fact, specifying grain as relevant)). 
Load the data into a RDBMS of your choice, the data model you’ve specified, or otherwise, and answer the following questions:

****/

/*==================== Question 1 ================================================= */
-- Write a sql script to return the distinct number of customers
SELECT COUNT(DISTINCT [Customer ID]) [Total Customers] FROM Orders


/*==================== Question 2 ================================================= */
-- Write a sql script to give the total profit by each region per week

-- Total profit by each region per week (with week format 1 - 52)
SELECT Region, [Week Number], SUM([Profit]) [ProfitPerWeek]
FROM 
(
	SELECT [Profit], DATEPART(WEEK, CAST([Order Date] AS DATE)) [Week Number], Region
	FROM Orders
) profit_by_week_region
GROUP BY Region, [Week Number] 
ORDER BY Region, [Week Number] 

-- Total profit by each region per week (with week of the month format)
SELECT Region, [Month], [Week Number], SUM([Profit]) [ProfitPerWeek]
FROM 
(
	SELECT [Profit], DATEPART(MONTH, [Order Date]) [Month], 
	DATEPART(DAY, DATEDIFF(DAY, 0, [Order Date])/7 * 7)/7 + 1 [Week Number], Region
	from Orders
) profit_by_week_region
GROUP BY Region, [Month], [Week Number] 
ORDER BY Region, [Month], [Week Number] 

-- Total profit by each region per week (with week of the month format) excluding returned items
SELECT Region, [Month], [Week Number], SUM([Profit]) [ProfitPerWeek]
FROM 
(
	SELECT [Profit], DATEPART(MONTH, [Order Date]) [Month], 
	DATEPART(DAY, DATEDIFF(DAY, 0, [Order Date])/7 * 7)/7 + 1 [Week Number], Region
	FROM Orders
	WHERE [Order ID] NOT IN (Select [Order ID] from Returns) 
) profit_by_week_region
GROUP BY Region, [Month], [Week Number] 
ORDER BY Region, [Month], [Week Number] 

/*==================== Question 3 ================================================= */
-- Write a sql script to give the 2nd most sold item by quantity in each region, per year

-- 2nd most sold item by quantity in each region, per year (returned items are included)
SELECT Region, [Year], [Product ID], [Product Name], [Total Quantity]
FROM (
	SELECT 
	[Total Quantity], [Product ID], [Product Name], Region, [Year], 
	DENSE_RANK() OVER (PARTITION BY Region, [Year] Order By [Total Quantity] DESC) [Rank]
	FROM
	(
		SELECT SUM(Quantity) [Total Quantity], [Product ID], [Product Name], Region, YEAR( [Order Date] ) [Year] FROM Orders
		GROUP BY [Product ID], [Product Name], Region, YEAR( [Order Date] ) 
	) qty_by_region_year
)a WHERE [Rank] = 2

-- 2nd most sold item by quantity in each region, per year, excluding returned items
SELECT Region, [Year], [Product ID], [Product Name], [Total Quantity]
FROM (
	SELECT 
	[Total Quantity], [Product ID], [Product Name], Region, [Year], 
	DENSE_RANK() OVER (PARTITION BY Region, [Year] Order By [Total Quantity] DESC) [Rank]
	FROM
	(
		SELECT SUM(Quantity) [Total Quantity], [Product ID], [Product Name], Region, YEAR( [Order Date] ) [Year] FROM Orders
		WHERE [Order ID] NOT IN (Select [Order ID] from Returns) 
		GROUP BY [Product ID], [Product Name], Region, YEAR( [Order Date] ) 
	) qty_by_region_year
)a WHERE [Rank] = 2

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
	LEAD([Order Date], 1) OVER (PARTITION BY [Customer ID] ORDER BY [Order Date]) [Next Order Date]
	FROM 
	(
		SELECT DISTINCT [Customer ID], [Customer Name], [Order ID], [Order Date] 
		FROM Orders
	) DistinctOrders
) 
SELECT [Customer ID], [Customer Name], [Order ID], [Order Date], [Next Order Date], 
DATEDIFF(day, [Order Date], [Next Order Date]) [# of Days Until Next Order]
FROM list_customers
WHERE [Next Order Date] IS NOT NULL

