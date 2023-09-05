-- ***********************************************************************************
-- Problems 01 - 05 use the AdvWorks database
-- ***********************************************************************************
-- Problem_01: We want to rank our salespeople based on the number of orders they are 
-- associated with and location. Create SP_Orders CTE that will calculate the number of 
-- orders for each sales person, named NumSPOrds. Include salesperson's number, first 
-- and last name, sales territory (as Territory), the country/region (as CountryRegion), 
-- and the number of orders, but only for salespeople with assigned territory. Use the 
-- CTE to rank salespeople based on the number of orders by country in which their 
-- territory resides. Display salespeople's first and last name, territory, country, 
-- number of orders, and the rank named SPRank. (14 rows)
WITH SP_Orders AS (
  SELECT so.salespersonid, p.firstname, p.lastname, 
	st.name AS Territory, cr.name AS CountryRegion,
	COUNT(SalesOrderID) AS NumSPOrds
  FROM SalesOrderHeader so
	JOIN salesperson s ON so.salespersonid = s.businessentityid
	JOIN employee USING (businessentityid)
	JOIN person p USING (businessentityid)
	JOIN salesterritory st ON s.territoryid = st.territoryid
	JOIN countryregion cr ON st.CountryRegionCode = cr.CountryRegionCode
  GROUP BY so.salespersonid
) SELECT firstname, lastname, Territory, CountryRegion, NumSPOrds,
	RANK() OVER(PARTITION BY CountryRegion ORDER BY NumSPOrds DESC) AS SPRank
  FROM SP_Orders

-- Problem_02: We want to rank our retail customers based on their total sales and 
-- location. Create Cust_Sales CTE that will calculate the total sales by customer. 
-- Use TotalDue column from the SalesOrderHeader table, rather than the standard 
-- calculation involving SalesOrderDetail and Product tables. List the state/province 
-- named StateProv, CountryRegion, customer first (CustFirst) and last name (Custlast), 
-- as well as the total sales named TotCustSales rounded to 0 decimals. Include only 
-- those "high value customers" defined as having at least $10,000 in sales. Use the 
-- CTE to rank the "high value customers" based on sales within their state/province, 
-- but only include those states/provinces with more than one "high sales" customer. 
-- Display the StateProv, CountryRegion, CustFirst, Custlast, TotCustSales, and rank, 
-- named CustRank. (42 rows)
-- Hint: I used another CTE named Cust_Rank to calculate the rank and the main query
-- to reduce the result, but this is not required.
WITH Cust_Sales AS (
  SELECT sp.name AS StateProv, cr.name AS CountryRegion,
	p.firstname AS CustFirst, p.lastname AS Custlast,
	ROUND(SUM(soh.TotalDue),0) AS TotCustSales
  FROM salesorderheader soh
	JOIN person p ON soh.customerid =  p.businessentityid
	JOIN businessentityaddress USING (businessentityid)
	JOIN address USING(addressid)
	JOIN StateProvince sp USING(stateprovinceid)
	JOIN CountryRegion cr USING(CountryRegionCode)
  GROUP BY p.businessentityid
  HAVING TotCustSales > 10000
), Cust_Rank AS (
  SELECT *, 
	RANK() OVER(PARTITION BY StateProv ORDER BY TotCustSales DESC) AS CustRank,
	COUNT(*) OVER(PARTITION BY StateProv) AS NumCust
  FROM Cust_Sales
) SELECT StateProv, CountryRegion, CustFirst, Custlast, TotCustSales, CustRank
  FROM Cust_Rank
  WHERE NumCust > 1

-- Problem_03: Calculate the monthly running/cummulative sales and associated 3-month 
-- moving average. Use TotalDue column from the SalesOrderHeader table, rather than the 
-- standard calculation involving SalesOrderDetail and Product tables. You must first 
-- create YrMth_Sales CTE that will calculate total sales for each year-month. The 
-- final result must show the year-mth, monthly sales, running/cumulative sales, and 
-- the 3-month moving average of monthly sales (current + the 2 previous months), all 
-- sales rounded to 0 decimals, in chornological order. (38 rows)
-- Hint: Research UNBOUNDED PRECEDING and use with the cumulative monthly sales
WITH YrMth_Sales AS (
  SELECT CONCAT(YEAR(orderdate),'-',LPAD(MONTH(orderdate),2,'0')) AS YearMth,
	ROUND(SUM(TotalDue),0) AS monthly_sales
  FROM SalesOrderHeader
  GROUP BY YearMth
) SELECT *,
	ROUND(SUM(monthly_sales) OVER (ORDER BY YearMth 
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS CumSales,
	ROUND(AVG(monthly_sales) OVER (ORDER BY YearMth
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) AS MA3MonthSales
  FROM YrMth_Sales

-- Problem_04: Examine percentage changes in total daily sales to identify the end of 
-- month or beginning of the month spikes in total daily sales. Use TotalDue column 
-- from the SalesOrderHeader table, rather than the standard calculation involving 
-- SalesOrderDetail and Product tables. You must first create Daily_Sales CTE that 
-- will calculate total sales for each day. There appear to be either beginning or 
-- end of month spikes in total daily sales, where the values are mostly in millions 
-- vs. 10K's during the remaining days of the month. We will call those "spike days". 
-- The final result must show the date, formatted without the time component, total 
-- daily sales rounded to 0 decimals, and the percentage daily sales rounded to 2 
-- decimals, but only for those "spike days" where the daily percentage change was 
-- over 1000%. (36 rows)
-- Hint: I used another CTE named Daily_Sales_Growth to calculate the percentage 
-- increase in total daily sales and main query to reduce the result, but this is 
-- not required.
WITH Daily_Sales AS (
  SELECT orderdate, SUM(TotalDue) AS DailySale
  FROM SalesOrderHeader
  GROUP BY orderdate
), Daily_Sales_Growth AS (
  SELECT DATE_FORMAT(orderdate, '%Y-%m-%d') AS OrderDate,
	ROUND(DailySale,0) AS DailySale,
	ROUND(100*(DailySale / (LAG(DailySale,1) OVER (ORDER BY orderdate)) - 1), 2) AS DailyGrowth
  FROM Daily_Sales
) SELECT *
  FROM Daily_Sales_Growth
  WHERE DailyGrowth > 1000

-- Problem_05: Use Daily_Sales CTE from the previous problem to create another CTE 
-- named Daily_Sales_Smooth by simply dividing those "spike days" "high daily sales" 
-- by 100. Use Daily_Sales_Smooth CTE to list the dates, total sales for that date and 
-- the highest sales over the last 30 days preceeding the current date, starting on 
-- 1/1/2014 and ending on 5/30/2014. Both sales columns must be rounded to 0 decimals. 
-- Create a quick line chart in Excel to compare the total daily sales with the 
-- benchmark. (150 rows)
-- Separately, list only those rows where the total daily sales exceeded the benchmark, 
-- which should be only on a handful of days. (8 rows)
-- Hint: This is similar to one of the last demo example
WITH Daily_Sales AS (
  SELECT orderdate, SUM(TotalDue) AS DailySale
  FROM SalesOrderHeader
  GROUP BY orderdate
), Daily_Sales_Growth AS (
  SELECT DATE_FORMAT(orderdate, '%Y-%m-%d') AS OrderDate,
	ROUND(DailySale,0) AS DailySale,
	ROUND(100*(DailySale / (LAG(DailySale,1) OVER (ORDER BY orderdate)) - 1), 2) AS DailyGrowth
  FROM Daily_Sales
), Daily_Sales_Smooth AS (
  SELECT OrderDate,
	(CASE
		WHEN DailyGrowth < 1000 THEN DailySale
		ELSE DailySale/100
	END) AS DailySaleSmooth
  FROM Daily_Sales_Growth
), Daily_Sales_Smooth_Max30 AS (
  SELECT OrderDate, ROUND(DailySaleSmooth,0) AS DailySaleSmooth,
	ROUND(MAX(DailySaleSmooth) OVER(ORDER BY OrderDate ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING),0) AS MaxSales30Days
  FROM Daily_Sales_Smooth
) SELECT *
  FROM Daily_Sales_Smooth_Max30
  WHERE OrderDate BETWEEN '2014-01-01' and '2014-05-30'
    AND DailySaleSmooth > MaxSales30Days

-- ***********************************************************************************
-- Problems 06 - 07 use the Employees database
-- ***********************************************************************************
-- We want to analyze employees career progress by examining the job title changes 
-- over time, but only for the employees that changed job title exactly once. You must 
-- setup Employee_Progress CTE using the LEAD (or LAG) window function to create a 
-- record of employment for each employee that changed titles exactly once. The record 
-- must start with all the information in the employees table (6 columns), followed by
-- the first title, first from and to dates, second title and second from and to dates,
-- so also 6 columns for a total of 12 columns. You must define EmpTitleWin WINDOW to 
-- use withthe LEAD function when getting the second title, from and to dates (or the 
-- LAG function when getting the first title, from and to dates). (137,256 rows)
-- Note: Include the CTE code here, you don't have to repeat it in problems 6 & 7.
WITH Employee_Progress AS (
  SELECT el.emp_no, el.birth_date, el.first_name, el.last_name, el.gender, el.hire_date,
	tl.title AS first_title, tl.from_date AS first_from, tl.to_date AS first_to,
	LEAD(tl.title, 1) OVER EmpTitleWin AS second_title,
	LEAD(tl.from_date, 1) OVER EmpTitleWin AS second_from,
	LEAD(tl.to_date, 1) OVER EmpTitleWin AS second_to
  FROM titles tl
	JOIN employees el USING (emp_no)
  WHERE tl.emp_no IN 
	(SELECT emp_no
	FROM employees
		JOIN titles USING (emp_no)
	GROUP BY emp_no
	HAVING COUNT(*) = 2)
  WINDOW EmpTitleWin AS (PARTITION BY el.emp_no ORDER BY tl.from_date ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING)
) SELECT *
  FROM Employee_Progress
  WHERE second_title IS NOT NULL

-- Problem_06: You must use Employee_Progress CTE to analyze the career paths of 
-- employees born in 1965, hired in 1990's who are no longer working for the company. 
-- You must list the employee first and last names, hire date, first title, number of 
-- years in the first title (first_title_dur), second title, and the number of years 
-- in the second title (second_title_dur), sorted ascending on the hire date. You 
-- must use the DATEDIFF function and divide by 365.25 days to get the two durations,  
-- both rounded to 2 decimals. (19 rows)
-- Note: You don't have to repeat the CTE code here, only the query based on the CTE.
-- Of course, you will need the CTE to get the result.
WITH Employee_Progress AS (
  SELECT el.emp_no, el.birth_date, el.first_name, el.last_name, el.gender, el.hire_date,
	tl.title AS first_title, tl.from_date AS first_from, tl.to_date AS first_to,
	LEAD(tl.title, 1) OVER EmpTitleWin AS second_title,
	LEAD(tl.from_date, 1) OVER EmpTitleWin AS second_from,
	LEAD(tl.to_date, 1) OVER EmpTitleWin AS second_to
  FROM titles tl
	JOIN employees el USING (emp_no)
  WHERE tl.emp_no IN 
	(SELECT emp_no
	FROM employees
		JOIN titles USING (emp_no)
	GROUP BY emp_no
	HAVING COUNT(*) = 2)
  WINDOW EmpTitleWin AS (PARTITION BY el.emp_no ORDER BY tl.from_date ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING)
) SELECT first_name, last_name, hire_date, first_title, 
	ROUND(DATEDIFF(first_to, first_from)/365.25, 2) AS first_title_dur,
	second_title,
	ROUND(DATEDIFF(second_to, second_from)/365.25, 2) AS second_title_dur
  FROM Employee_Progress
  WHERE second_title IS NOT NULL
    AND YEAR(birth_date) = 1965
	AND YEAR(hire_date) BETWEEN 1990 AND 1999
	AND YEAR(second_to) != 9999
  ORDER BY hire_date

-- Problem_07: We want to analyze the frequency of title changes for employees that 
-- changed title exactly once, as well as how long, on average, were they working 
-- under their first title before getting promoted. You must use the Employee_Progress 
-- CTE to create a title_chg column, for example 'Staff -> Senior Staff', followed by 
-- freq_title_chg showing the number of times 'Staff' got promoted to 'Senior Staff', 
-- as well as avg_title_dur showing the average number of years spent in the first 
-- title, like 'Staff' before getting promoted to the second title, such as 'Senior 
-- Staff', sorted descending on the frequency count. (10 rows)
-- Note: You don't have to repeat the CTE code here, only the query based on the CTE.
-- Of course, you will need the CTE to get the result. For example, I got 66,261 
-- Staff -> Senior Staff title changes with approximately 6.80 years spent as Staff 
-- on average. Engineer -> Senior Engineer was similar with 64,692 / 6.77, but then 
-- Assistant Engineer -> Engineer dropped to only 6,285 / 7.22. The remaining 7 title 
-- changes were extremely infrequent (as in < 10) because of the limited number of 
-- management roles (see dept_manager table).
WITH Employee_Progress AS (
  SELECT el.emp_no, el.birth_date, el.first_name, el.last_name, el.gender, el.hire_date,
	tl.title AS first_title, tl.from_date AS first_from, tl.to_date AS first_to,
	LEAD(tl.title, 1) OVER EmpTitleWin AS second_title,
	LEAD(tl.from_date, 1) OVER EmpTitleWin AS second_from,
	LEAD(tl.to_date, 1) OVER EmpTitleWin AS second_to
  FROM titles tl
	JOIN employees el USING (emp_no)
  WHERE tl.emp_no IN 
	(SELECT emp_no
	FROM employees
		JOIN titles USING (emp_no)
	GROUP BY emp_no
	HAVING COUNT(*) = 2)
  WINDOW EmpTitleWin AS (PARTITION BY el.emp_no ORDER BY tl.from_date ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING)
) SELECT CONCAT(first_title, ' -> ', second_title) AS title_chg,
	COUNT(emp_no) AS freq_title_chg,
	ROUND(AVG(DATEDIFF(first_to, first_from)/365.25), 2) AS avg_title_dur
  FROM Employee_Progress
  WHERE second_title IS NOT NULL
  GROUP BY first_title, second_title

-- ***********************************************************************************
-- Problems 08 - 10 use the Sakila database
-- ***********************************************************************************
-- Problem_08: We are looking for our best customers. We want to break this problem 
-- into 2 steps: 1) Create Customer_Rentals CTE that will count the number of rentals 
-- by each store and customer and 2) Use the CTE to rank customers renting at a 
-- particular store such that the customer with the most rentals at store 1 earns rank 
-- 1 and the customer with the most rentals at store 2 earns rank 1, etc.. Include only   
-- customers with 20 rentals or more. The Customer_Rentals CTE must return the number  
-- of rentals, named NumRentals by store_id, named StoreID, followed by customer_id, 
-- named CustID, as well as first and last name, named CustFirst and CustLast. You must 
-- use RANK() window function with appropriate partition to create CustRank column of 
-- customer ranks. Then add another column with sequential ranks using DENSE_RANK() 
-- window function named CustDenseRank. (62 rows) 
WITH Customer_Rentals AS (
  SELECT i.store_id AS StoreID, c.customer_id AS CustID,
	c.first_name AS CustFirst, c.last_name AS CustLast,
	COUNT(*) AS NumRentals
  FROM customer c
	JOIN rental r USING(customer_id)
	JOIN inventory i USING(inventory_id)
  GROUP BY StoreID, CustID
  HAVING NumRentals >= 20
  ORDER BY StoreID, NumRentals DESC
) SELECT StoreID, CustID, CustFirst, CustLast, NumRentals,
	RANK() OVER(PARTITION BY StoreID ORDER BY NumRentals DESC) AS CustRank,
	DENSE_RANK() OVER (PARTITION BY StoreID ORDER BY NumRentals DESC) AS CustDenseRank
  FROM Customer_Rentals

-- Problem_09: List the title, store_id, a copy number (starting at 1 for each film and 
-- store), and email address of the customer who had possession of that copy on Aug 1, 
-- 2005 for all copies of films in the Music category. If no customers had possession 
-- of a copy on that particular date, display 'Not rented' for the email address. You 
-- must use ROW_NUMBER() window function for copy numbers. We want to break this problem 
-- into 3 steps: 1) Create a Music_Inventory CTE that will display all music titles on 
-- inventory. List the inventory_id named MusicID, film title named MusicTitle, and the 
-- store_id where it is, named MusicStore. 2) Create Music_Rentals that will join the 
-- Music_Inventory CTE with rental and customer tables to include customer email, named 
-- CustEmail, and implement the 8/1/2005 restriction. 3) Main query that uses both CTE's 
-- to list the music title, store, title's copy number by store using ROW_NUMBER()  
-- window function and named MusicCopyNo, and finally customer email or 'Not rented' if   
-- a particular copy was not out at the time. (232 rows)
WITH Music_Inventory AS (
  SELECT i.inventory_id AS MusicID, f.title AS MusicTitle, i.store_id AS MusicStore
  FROM category c
	JOIN film_category fc USING(category_id)
	JOIN film f USING(film_id)
	JOIN inventory i USING(film_id)
  WHERE c.name = 'Music'
), 
Music_Rentals AS (
  SELECT MI.MusicID, MI.MusicTitle, MI.MusicStore,
	c.email AS CustEmail
  FROM Music_Inventory MI
	JOIN rental r ON MI.MusicID = r.inventory_id
	JOIN customer c USING(customer_id)
  WHERE r.rental_date <= '2005-08-01'
    AND r.return_date >= '2005-08-01'
) SELECT MI.MusicTitle, MI.MusicStore,
	ROW_NUMBER() OVER(PARTITION BY MI.MusicStore, MI.MusicTitle) AS MusicCopyNo,
	IFNULL(MR.CustEmail, 'Not rented') AS CustEmail
  FROM Music_Inventory MI 
	LEFT JOIN Music_Rentals MR USING(MusicID)

-- Problem_10: We are looking for our best customers and their favorite movies. List the
-- customer email, film title, and number of times that customer has rented that title, 
-- named NumTitleRented. Include only films ranked #1 or #2 for that customer (by number 
-- of times rented). In addition, only include in the list those customers that have 
-- rented 2 or more films multiple times each. For example, customer Thelma Murray should 
-- appear in the list 4 times: she rented one movie 3 times and 3 other movies 2 times 
-- each. Customer Yolanda Weaver, on the other hand, should not appear in the list: she 
-- only rented 1 move twice and 25 different titles once. (60 rows)
WITH Cust_Titles AS (
 SELECT c.email, f.title, 
	COUNT(*) AS NumTitleRented,
	RANK() OVER(PARTITION BY email ORDER BY COUNT(*) DESC) AS TitleRank
  FROM customer c 
	JOIN rental r USING(customer_id)
	JOIN inventory i USING(inventory_id)
	JOIN film f USING(film_id)
  GROUP BY c.email, f.title
) SELECT *
  FROM Cust_Titles CT1
  WHERE TitleRank <= 2
    AND (SELECT COUNT(*)
		FROM Cust_Titles CT2
		WHERE NumTitleRented > 1
		  AND CT1.email = CT2.email
		GROUP BY CT2.email) > 1
  ORDER BY email, title
