/* MySQL7_Interm_SQL.sql */
-- **********************************************************************
-- Problems 01 - 05 use Order Entry database
-- **********************************************************************
-- Problem_01: Use regular expressions to list the products whose name 
-- starts with exactly 2 digits and includes "Color" in its name. Include 
-- product number, name, manufacturer and price in the result. (3 rows)
SELECT ProdNo, ProdName, ProdMfg, ProdPrice 
FROM Product 
WHERE ProdName REGEXP '^[0-9]{2}.*\\bColor\\b.*'

-- Problem_02: Use regular expressions to list all the customers who live 
-- on a "street", a "road", an "avenue" or a "way", together with orders  
-- sent to the same address. Include order number, order date, first and 
-- last name of the customer and the street of residence, sorted by the  
-- order date. (10 rows)
SELECT O.OrdNo, O.OrdDate, C.CustFirstName, C.CustLastName, C.CustStreet
FROM Customer C JOIN OrderTbl O USING(CustNo)
WHERE C.CustStreet REGEXP '( \\bSt\\b | \\bRd\\b | \\bAve\\b | \\bway\\b )'
  AND C.CustStreet = O.OrdStreet
ORDER BY O.OrdDate

-- Problem_03: Create a Common Table Expression (CTE) named Sales_by_Prod  
-- to calculate total sales by product. Use the CTE to find the top 
-- selling products for each of the manufacturers, sorted descending on 
-- the total sales. (6 rows)
WITH Sales_by_Prod AS (
  SELECT ProdName, ProdMfg, ProdPrice*SUM(Qty) AS ProdSale
  FROM product INNER JOIN orderline USING (ProdNo)
  GROUP BY ProdName
) SELECT ProdMfg, ProdName AS TopSellProd, MAX(ProdSale) AS TopSell
  FROM Sales_by_Prod
  GROUP BY ProdMfg
  ORDER BY TopSell DESC
  
-- Problem_04: Use three (3) CTEs to find the best and worst customer in 
-- terms of total sales generated. Use CustFull and CustSales as 
-- parameters for the first CTE named Sales_by_Cust. The Best_Cust and 
-- the Worst_Cust CTEs should have the same 2 parameters as well as 
-- CustDsgn parameter that will designate the customer as the "Best" or 
-- the "Worst". Use UNION ALL to get both the best and worst customer 
-- names, sales and designation. (2 rows)
WITH Sales_by_Cust(CustFull, CustSales) AS (
    SELECT CONCAT(c.CustFirstName, ' ', c.custlastname),
		  SUM(ol.qty*p.ProdPrice)
    FROM customer c
		JOIN ordertbl USING (CustNo)
		JOIN orderline ol USING (OrdNo)
		JOIN product p USING (ProdNo)
	GROUP BY c.CustNo
), Best_Cust(CustFull, CustSales, CustDsgn) AS (
   SELECT CustFull, CustSales, 'Best'
   FROM Sales_by_Cust
   WHERE CustSales = (SELECT MAX(CustSales) FROM Sales_by_Cust)
), Worst_Cust(CustFull, CustSales, CustDsgn) AS (
   SELECT CustFull, CustSales, 'Worst'
   FROM Sales_by_Cust
   WHERE CustSales = (SELECT MIN(CustSales) FROM Sales_by_Cust)
) SELECT *
  FROM Best_Cust
  UNION ALL
  SELECT *
  FROM Worst_Cust

-- Problem_05: Use a recursive CTE to reconstruct the employee supervisory
-- hierarchy. Use employee numbers, first and last name, supervisor number 
-- and employee level. The end result must show the employee's full name, 
-- level, as well as supervisor's full name. (7 rows)
-- Note: This is almost exactly the same exercise as the one with Faculty
-- members in the University demo.
WITH RECURSIVE Employee_Supervisor(EmpNo, FName, LName, SupNo, EmpLvl) AS (
	-- Anchor member: retrieves top-level supervisors
    SELECT EmpNo, EmpFirstName, EmpLastName, SupEmpNo, 1
	FROM employee 
	WHERE SupEmpNo IS NULL
	UNION ALL
	-- Recursive member: retrieves next level employees who's 
	-- supervisors (E.SupEmpNo) are the employees (ES.EmpNo) one
	-- level higher, starting with the top-level in the anchor query
	SELECT e.EmpNo, e.EmpFirstName, e.EmpLastName, e.SupEmpNo, EmpLvl+1
	FROM employee e INNER JOIN Employee_Supervisor es
    ON e.SupEmpNo = es.EmpNo
)
SELECT CONCAT(FName, ' ', LName) AS EmpName, EmpLvl, 
  (SELECT CONCAT(EmpFirstName, ' ', EmpLastName) 
	 FROM employee e
	 WHERE e.EmpNo = es.SupNo) AS SupName
FROM Employee_Supervisor es
ORDER BY EmpLvl, SupNo

-- **********************************************************************
-- Problems 06 - 10 use the Internet Movie Database (IMDB)
-- **********************************************************************
-- Problem_06: Use an ALTER TABLE statement to add a single index to
-- minimize the number of examined rows. Use SHOW STATUS LIKE 'last_query
-- _cost' to compare the costs before and after adding the index, and then 
-- remove the index. Sequence the query runs, adding and removal of 
-- indices as best as you can and document duration/fetch times and costs 
-- in the worksheet. Copy/pasting the Action Output and combining it 
-- with SHOW STATUS LIKE 'last_query_cost' could be the way to go.
SET profiling = 0;
SET profiling_history_size = 0;
SET profiling_history_size = 100; 
SET profiling = 1;

-- Run the query before adding any indices 
SELECT * FROM movies_sample 
  WHERE release_year BETWEEN 2000 AND 2010 
	  AND moviename LIKE 'T%';
SHOW STATUS LIKE 'last_query_cost';
-- Execution plan review:
-- 1) The cost was about 79,326
-- 2) Shows full table scan of all 783.92K rows
-- 3) 0.125 sec execution duration and 0.266 sec fetch time

-- Add index on release year only and rerun the query 
ALTER TABLE movies_sample 
	ADD INDEX idx_release_year (release_year);
SELECT * FROM movies_sample 
  WHERE release_year BETWEEN 2000 AND 2010 
	  AND moviename LIKE 'T%';
SHOW STATUS LIKE 'last_query_cost';
-- Execution plan review:
-- 1) The cost was still about 79,326
-- 2) Still Shows full table scan of all 783.92K rows
-- 3) The same 0.125 sec execution duration and 0.266 sec fetch time

-- Remove release year index and rerun the query without any indices
ALTER TABLE movies_sample
	DROP INDEX idx_release_year;
SELECT * FROM movies_sample 
  WHERE release_year BETWEEN 2000 AND 2010 
	  AND moviename LIKE 'T%';
SHOW STATUS LIKE 'last_query_cost';

-- Add moviename index and rerun the query 
ALTER TABLE movies_sample
	ADD INDEX idx_moviename (moviename);
SELECT * FROM movies_sample 
  WHERE release_year BETWEEN 2000 AND 2010 
	  AND moviename LIKE 'T%';
SHOW STATUS LIKE 'last_query_cost';
-- Execution plan review:
-- 1) The cost increased to 91,998 
-- 2) Only 164.40K rows examined
-- 3) Improved 0.016 sec execution duration and 0.219 sec fetch time

-- Remove the moviename index and rerun the query without any indices 
-- for the last time.
ALTER TABLE movies_sample
	DROP INDEX idx_moviename;
SELECT * FROM movies_sample 
  WHERE release_year BETWEEN 2000 AND 2010 
	  AND moviename LIKE 'T%';
SHOW STATUS LIKE 'last_query_cost';

-- Reset profiling for future use
SET profiling = 0;
SET profiling_history_size = 0;
SET profiling_history_size = 100; 

-- Problem_07: Optimize the following assuming the database is in its 
-- original state. Use similar approach and documentation ideas from 
-- the previous problem.
SET profiling = 0;
SET profiling_history_size = 0;
SET profiling_history_size = 100; 
SET profiling = 1;

-- Run the query before adding any indices 
SELECT moviename, release_year 
FROM movies_sample 
WHERE movieid = 476084;
SHOW STATUS LIKE 'last_query_cost';
-- Execution plan review:
-- 1) The cost was about 79,326
-- 2) Shows full table scan of all 783.92K rows
-- 3) 0.312 sec execution duration and 0.000 sec fetch time

-- Add movieid index and rerun the query
ALTER TABLE movies_sample
	ADD INDEX idx_movieid (movieid);
SELECT moviename, release_year 
FROM movies_sample 
WHERE movieid = 476084;
SHOW STATUS LIKE 'last_query_cost';
-- Execution plan review:
-- 1) The cost decreased to only 0.46
-- 2) Shows non-unique index key lookup, instead of a full table scan
-- 3) Improved 0.016 sec execution duration and 0.000 sec fetch time

-- Remove movieid index and rerun the query one last time 
ALTER TABLE movies_sample
	DROP INDEX idx_movieid;
SELECT moviename, release_year 
FROM movies_sample 
WHERE movieid = 476084;
SHOW STATUS LIKE 'last_query_cost';

-- Reset profiling for future use
SET profiling = 0;
SET profiling_history_size = 0;
SET profiling_history_size = 100;

-- Problem_08: You are a fan of James Bond 007 movies. You wander how
-- many movies out there have a similar title in the sense that they
-- end with a space and three digits. Write a SQL statement that uses
-- a regular expression to search the movies_sample table for all movies
-- that end with the described pattern. Show the movie id, title, and
-- release year, restricting the result to movies released in 2010 
-- or after, sorted by the release year and name. (25 rows)
SELECT * FROM movies_sample
WHERE moviename REGEXP '\\s\\d{3}$'
  AND release_year >= 2010
ORDER BY release_year, moviename

-- Problem_09: In the query for the previous problem, which 3-digit 
-- combination was most the popular in movie titles? Show the 3-digit 
-- combinations (must be exactly 3-digit), the number of movies that 
-- end with this pattern, and show only those 3-digit patterns that 
-- appear at least 5 times, sorted on the count descending. (31 rows)
SELECT RIGHT(moviename, 3) AS 3_digit_comb,
	COUNT(movieid) AS num_movie
FROM movies_sample
WHERE moviename REGEXP '\\s\\d{3}$'
GROUP BY 3_digit_comb
HAVING num_movie >= 5
ORDER BY num_movie DESC

-- Problem_10: We want to find out how many movies are about world wars 
-- (at least in the literal sense). Using regular expression to find all 
-- movies that have words "world" and "war" in the title (in that order). 
-- Notice that both words must appear alone as a stand-alone words, they 
-- cannot be embedded in other words such as "Warsaw". Show the movie id, 
-- title, and release_year, restricting the release year to the last  
-- millennium and sort by release year and the name. (37 rows)
SELECT * FROM movies_sample 
WHERE moviename REGEXP '.*\\bworld\\b.+\\bwar\\b.*'
  AND release_year BETWEEN 1001 AND 1999
ORDER BY release_year, moviename

-- **********************************************************************
-- Problems 11 - 12 use the Sakila database
-- **********************************************************************
-- Problem_11: Create Customer_Rentals CTE that list the customer id, 
-- first and last name, rental date, title, and return_date for all 
-- rentals. Include an additional column named rental_status that 
-- indicates whether the rental was returned 'Late', 'Ontime', or 'Never'. 
-- Use the CTE to list the customers (first, last, phone, city and country) 
-- and the number of times these people did not return movies. Show only 
-- those customers with more than just one "non-return", sorted descending 
-- on the number of "non-returns". (23 rows)
WITH Customer_Rentals AS (
  SELECT c.customer_id, c.first_name, c.last_name,
	r.rental_date, f.title, r.return_date,
	(CASE
	WHEN r.return_date IS NULL THEN 'Never'
	WHEN DATE(r.rental_date) + INTERVAL f.rental_duration DAY < DATE(r.return_date) THEN 'Late'
	ELSE 'Ontime'
	END) AS rental_status
  FROM rental r 
	INNER JOIN customer c ON r.customer_id = c.customer_id
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film f ON i.film_id = f.film_id
) SELECT cr.first_name, cr.last_name, 
	a.phone, ci.city, co.country,
	SUM(CASE
	WHEN cr.rental_status='Never' THEN 1
	ELSE 0
	END) AS num_non_return
  FROM Customer_Rentals cr
	INNER JOIN customer c ON cr.customer_id = c.customer_id
	INNER JOIN address a ON c.address_id = a.address_id
	INNER JOIN city ci ON a.city_id = ci.city_id
	INNER JOIN country co ON ci.country_id = co.country_id
  GROUP BY cr.customer_id
  HAVING num_non_return > 1
  ORDER BY num_non_return DESC

-- Problem_12: List the title and rating of all horror movies on inventory 
-- for rent at store 1. Include an additional column named available that 
-- indicates, with a Yes or No, whether at least 1 copy of that movie was 
-- available for rent in store 1 on Aug 1, 2005. You must use two CTEs:
-- 1) Horror_Inventory listing the title, rating and the total number of   
-- horror copies on inventory at store 1 and 2) Horror_Rentals listing the 
-- title and the number of rented horror movies as of 8/1/2005 in store 1. 
-- The main query must use both CTE's to answer the original question. 
-- You are encouraged to use horror category_id = 11 to reduce the overall  
-- number of joins. (38 rows)
WITH Horror_Inventory AS (
  SELECT title, rating, COUNT(DISTINCT inventory_id) AS num_inventory
  FROM film
	INNER JOIN inventory USING(film_id)
  WHERE film_id IN (
	SELECT film_id
	FROM film_category
	WHERE category_id = (
		SELECT category_id
		FROM category
		WHERE name = 'Horror'))
	AND store_id = 1
  GROUP BY film_id
), Horror_Rentals AS (
  SELECT title, SUM(
	CASE
		WHEN ((DATE(return_date) > '2005-08-01') | (return_date IS NULL)) THEN 1
		ELSE 0
	END) AS num_rented
  FROM rental
	INNER JOIN inventory USING(inventory_id)
	INNER JOIN film USING(film_id)
  WHERE film_id IN (
	SELECT film_id
	FROM film_category
	WHERE category_id = (
		SELECT category_id
		FROM category
		WHERE name = 'Horror'))
	AND store_id = 1
	AND DATE(rental_date) <= '2005-08-01'
  GROUP BY film_id
) SELECT title, rating, (
	CASE
		WHEN num_inventory > num_rented THEN 'Yes'
		ELSE 'No'
	END) AS available
  FROM Horror_Inventory JOIN Horror_Rentals USING(title)

-- ***********************************************************************************
-- Problems 13 - 14 use the Employees database
-- ***********************************************************************************
-- Problem_13: We want to learn about employees that changed departments within the 
-- organization exactly once. Create Emp_Depts CTE (which will also be used in the 
-- next problem) to list employee number, department name, from and to dates for  
-- employees of that department, but restrict the employees to only those that have 
-- changed departments exactly once. Use the CTE to list all such employees (number, 
-- first and last names), department, from and to dates, restricted to those that were 
-- born in 1965 and hired in the mid 1990's (1994 to 1996, both included), sorted by 
-- employee number and the from dates. (36 rows) 
WITH Emp_Depts AS (
  SELECT emp_no, d.dept_name, de.from_date, de.to_date
  FROM dept_emp de
	JOIN departments d USING(dept_no)
  WHERE emp_no IN ( -- employees that have changed departments exactly once
	SELECT DISTINCT emp_no
	FROM dept_emp
	GROUP BY emp_no
	HAVING COUNT(DISTINCT dept_no) = 2)
) SELECT e.emp_no, e.first_name, e.last_name,
	ed.dept_name, ed.from_date, ed.to_date
  FROM Emp_Depts ed 
	JOIN employees e USING(emp_no)
  WHERE YEAR(birth_date) = 1965
    AND YEAR(hire_date) BETWEEN 1994 AND 1996
  ORDER BY e.emp_no, ed.from_date

-- Problem_14: We want to analyze the frequency of moves from one department to another 
-- within the organization, but only for employees that changed the departments exactly
-- once (see previous problem). The final result should include the following two 
-- columns: "from_to_depts" and "num_moves". The format of the first column is "from-dept  
-- -> to-dept", for example "Development -> Production", and num_moves is the count of 
-- employees that moved from Development to Production (again, only those employees who
-- moved exactly once). You must start with Emp_Depts CTE from the previous problem, 
-- and then should add 2 more CTEs: Emp_Fst_Dept and Emp_Sec_Dept, each of which will list 
-- the employee number and department name from the first (original) department and the 
-- second department the employee transferred to using "min/max subqueries" appropriately.
-- Finally, you need to combine the first and second department CTEs to count the number 
-- of employees that moved from one to another, but only if the from -> to departments are 
-- not the same (i.e., we do not want Production -> Production, there is a relatively small 
-- number of such "moves").  The result must be sorted in the descending order on the 
-- number of moves, showing the from -> to departments with the highest number of moves at 
-- the top. (21 rows -> 19 rows based on Vedran's announcement)
-- Note: Emp_Fst/Sec_Dept CTEs are my approach, if you have a better one, by all means ...

-- Version using from_date (21 rows)
WITH Emp_Depts AS (
  SELECT emp_no, d.dept_name, de.from_date, de.to_date
  FROM dept_emp de
	JOIN departments d USING(dept_no)
  WHERE emp_no IN ( -- employees that have changed departments exactly once
	SELECT DISTINCT emp_no
	FROM dept_emp
	GROUP BY emp_no
	HAVING COUNT(DISTINCT dept_no) = 2)
), Emp_Fst_Dept AS (
  SELECT emp_no, dept_name
  FROM Emp_Depts
  WHERE (emp_no, from_date) IN (
	SELECT emp_no, MIN(from_date)
	FROM Emp_Depts
	GROUP BY emp_no)
), Emp_Sec_Dept AS (
  SELECT emp_no, dept_name
  FROM Emp_Depts
  WHERE (emp_no, from_date) IN (
	SELECT emp_no, MAX(from_date)
	FROM Emp_Depts
	GROUP BY emp_no)
) SELECT CONCAT(efd.dept_name, " -> ", esd.dept_name) AS from_to_depts,
	COUNT(emp_no) AS num_moves
  FROM Emp_Fst_Dept efd
	JOIN Emp_Sec_Dept esd USING(emp_no)
  WHERE efd.dept_name != esd.dept_name
  GROUP BY CONCAT(efd.dept_name, " -> ", esd.dept_name)
  ORDER BY num_moves DESC

-- Version using to_date (19 rows)
WITH Emp_Depts AS (
  SELECT emp_no, d.dept_name, de.from_date, de.to_date
  FROM dept_emp de
	JOIN departments d USING(dept_no)
  WHERE emp_no IN ( -- employees that have changed departments exactly once
	SELECT DISTINCT emp_no
	FROM dept_emp
	GROUP BY emp_no
	HAVING COUNT(DISTINCT dept_no) = 2)
), Emp_Fst_Dept AS (
  SELECT emp_no, dept_name
  FROM Emp_Depts
  WHERE (emp_no, to_date) IN (
	SELECT emp_no, MIN(to_date)
	FROM Emp_Depts
	GROUP BY emp_no)
), Emp_Sec_Dept AS (
  SELECT emp_no, dept_name
  FROM Emp_Depts
  WHERE (emp_no, to_date) IN (
	SELECT emp_no, MAX(to_date)
	FROM Emp_Depts
	GROUP BY emp_no)
) SELECT CONCAT(efd.dept_name, " -> ", esd.dept_name) AS from_to_depts,
	COUNT(emp_no) AS num_moves
  FROM Emp_Fst_Dept efd
	JOIN Emp_Sec_Dept esd USING(emp_no)
  WHERE efd.dept_name != esd.dept_name
  GROUP BY CONCAT(efd.dept_name, " -> ", esd.dept_name)
  ORDER BY num_moves DESC

-- ***********************************************************************************
-- Problem 15 uses the Adventure Works database
-- ***********************************************************************************
-- Problem_15: Explore the "product" and "billofmaterials" tables. A bill of materials 
-- (BOM) lists all of the component products needed to make a finished product. For 
-- example, the second query shown below will list the ID's of component products 
-- (ComponentID) needed to build finished ProductID 775 (Mountain-100 Black, 38 - see 
-- the first query). These component products, in turn, have their own BOMs. Finished 
-- products (such as ProductID 775) have a ProductAssemblyID of NULL (see third query). 
-- Note that BOMs have an end date, which you may need to take into consideration! You 
-- must create Product_BOM recursive CTE to list the product ID, name, and color, 
-- component and product assembly IDs, BOM level and the quantity of all components  
-- required to assemble finished ProductID 775. The names of these columns are: 
-- (ProdID, ProdName, ProdColor, ProdCompID, ProdAssembID, BOMLvl, AssembQty) as shown
-- in the header Product_BOM CTE.
-- (90 rows total, including the top row for ProductID 775 in the final result).
-- Note: This one takes a bit of time to digest, I will discussed in class before the 
-- assignment is due.

SELECT * FROM product WHERE ProductID = 775;
SELECT * FROM billofmaterials WHERE ProductAssemblyID = 775;
SELECT * FROM billofmaterials WHERE ProductAssemblyID IS NULL AND ComponentID = 775;

WITH RECURSIVE Product_BOM (ProdID, ProdName, ProdColor, ProdCompID, 
  ProdAssembID, BOMLvl, AssembQty) AS (
	-- Anchor query establishing the top level of the BOM, the finished product 775
	SELECT p.ProductID, p.Name, p.Color, bom.ComponentID, 
		bom.ProductAssemblyID, bom.BOMLevel, bom.PerAssemblyQty
	FROM product p INNER JOIN billofmaterials bom
		ON p.ProductID = bom.ComponentID
	WHERE (ProductAssemblyID IS NULL AND ComponentID = 775)
UNION ALL
	-- Recursive member retrieves next BOM level who's product assembly ID is
	-- the component ID of the product one level up (recursive reference)
	SELECT p.ProductID, p.Name, p.Color, bom.ComponentID, 
		bom.ProductAssemblyID, bom.BOMLevel, bom.PerAssemblyQty
	FROM (product p INNER JOIN billofmaterials bom ON p.ProductID = bom.ComponentID)
		INNER JOIN Product_BOM pb ON bom.ProductAssemblyID = pb.ProdCompID -- Recursive reference
	WHERE bom.EndDate IS NULL
) SELECT *
  FROM Product_BOM



