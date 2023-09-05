/* MySQL3_Intro_SQL1.sql */
-- **********************************************************************
-- Problems 01 - 10: Order Entry Database
-- **********************************************************************
-- Problem_01: List all columns of the Product table for products costing 
-- more than $50. Order the result by product manufacturer (ProdMfg) and 
-- product names. (6 rows)
SELECT *
FROM Product
WHERE ProdPrice > 50
ORDER BY ProdMfg, ProdName

-- Problem_02: List the customer number, the name (first and last), the 
-- city, and the balance of customers who reside in Denver with a balance 
-- greater than $150 or who reside in Seattle with balance greater than 
-- $300. (4 rows)
SELECT CustNo, CustFirstName, CustLastName, CustCity, CustBal
FROM Customer
WHERE (CustCity = 'Denver' AND CustBal > 150)
   OR (CustCity = 'Seattle' AND CustBal > 300)

-- Problem_03: List the columns of the OrderTbl table for phone orders 
-- placed in January 2030. A phone order has an associated employee. 
-- (13 rows)
SELECT *
FROM OrderTbl
WHERE (YEAR(OrdDate) = 2030 AND MONTH(OrdDate) = 1)
  AND EmpNo IS NOT NULL
  
-- Problem_04: List all columns of Product table that contain the words 
-- Ink Jet in the product name. (3 rows)
SELECT *
FROM Product
WHERE ProdName LIKE '%Ink Jet%'

-- Problem_05: List the order number, order date, and customer number of 
-- orders placed after January 23, 2030, shipped to Washington recipients. 
-- (4 rows)
SELECT OrdNo, OrdDate, CustNo
FROM OrderTbl
WHERE OrdDate > '2030-01-23'
  AND OrdState = 'WA'
  
-- Problem_06: List the order number, the order date, the customer number, 
-- the customer name (first and last), for February 2030 orders in which 
-- the customer state is the same as the state to which the order is going 
-- to. Use INNER JOIN style. (4 rows)
SELECT ot.OrdNo, ot.OrdDate, ot.CustNo, c.CustFirstName, c.CustLastName
FROM Customer c INNER JOIN OrderTbl ot ON c.CustNo = ot.CustNo
WHERE (YEAR(ot.OrdDate) = 2030 AND MONTH(ot.OrdDate) = 2)
  AND ot.OrdState = c.CustState

-- Problem_07: List the order number, order date, customer number, and name 
-- (first and last) of orders placed in January 2030 by Colorado customers 
-- (CustState) but sent to Washington recipients (OrdState). Use INNER JOIN 
-- style. (3 rows)
SELECT ot.OrdNo, ot.OrdDate, ot.CustNo, c.CustFirstName, c.CustLastName
FROM Customer c INNER JOIN OrderTbl ot ON c.CustNo = ot.CustNo
WHERE (YEAR(ot.OrdDate) = 2030 AND MONTH(ot.OrdDate) = 1)
  AND (c.CustState = 'CO' AND ot.OrdState = 'WA')
 
-- Problem_08: List the order number, order date, customer number, 
-- customer name (first and last), employee number, and employee name 
-- (first and last) of January 2030 orders placed by Colorado customers. 
-- Use INNER JOIN style. (5 rows)
SELECT ot.OrdNo, ot.OrdDate, ot.CustNo, c.CustFirstName, c.CustLastName,
	e.EmpNo, e.EmpFirstName, e.EmpLastName
FROM Customer c 
	INNER JOIN OrderTbl ot ON c.CustNo = ot.CustNo
	INNER JOIN employee e ON ot.EmpNo = e.EmpNo
WHERE (YEAR(ot.OrdDate) = 2030 AND MONTH(ot.OrdDate) = 1)
  AND c.CustState = 'CO'
   
-- Problem_09: List the employee number, name (first and last), and 
-- phone of employees who have taken orders in January 2030 from 
-- customers with balances greater than $300.Use INNER JOIN style. 
-- (4 rows)
SELECT e.EmpNo, e.EmpFirstName, e.EmpLastName, e.EmpPhone
FROM Customer c 
	INNER JOIN OrderTbl ot ON c.CustNo = ot.CustNo
	INNER JOIN employee e ON ot.EmpNo = e.EmpNo
WHERE (YEAR(ot.OrdDate) = 2030 AND MONTH(ot.OrdDate) = 1)
  AND c.CustBal > 300

-- Problem_10: List Colorado customer names (first and last) and their
-- order lines, showing only those order lines for orders shipped within 
-- the state. Include order number, date, name of the person the order 
-- is going to, as well as the street, city and state where order is 
-- going to. Also include the product name, price, quantity and line 
-- item total. (8 rows)
SELECT c.CustFirstName, c.CustLastName,
	ot.OrdNo, ot.OrdDate, ot.OrdName, ot.OrdStreet, ot.OrdCity, ot.OrdState,
	p.ProdName, p.ProdPrice, ol.Qty, p.ProdPrice*ol.Qty as LineItemTotal
FROM Customer c 
	INNER JOIN OrderTbl ot ON c.CustNo = ot.CustNo
	INNER JOIN orderline ol ON ot.OrdNo = ol.OrdNo
	INNER JOIN Product p ON ol.ProdNo = p.ProdNo
WHERE c.CustState = 'CO'
  AND ot.OrdState = c.CustState

-- **********************************************************************
-- Problems 11 - 15: StackExchange Database
-- **********************************************************************
-- Problem_11: List the post ID, title, user display name, post view  
-- count and the reputation of the owner of the original posts (i.e. 
-- posts that have a title) viewed at least 200 times. Order the results 
-- so that the posts with the user with the highest reputation appear 
-- first. (34 rows)
SELECT p.PostID, p.Title, u.DisplayName, p.ViewCount, u.Reputation
FROM users u INNER JOIN posts p ON u.UserID = p.OwnerUserID
WHERE p.ViewCount >= 200
ORDER BY u.Reputation DESC

-- Problem_12: List the user ID, display name, location and the date of 
-- the badge for users with Student badge name, created in 2018 or 
-- after, with an existing location sorted by the badge date. (38 rows)
SELECT u.UserID, u.DisplayName, u.location, b.BadgeDate
FROM users u INNER JOIN badges b ON u.UserID = b.UserID
WHERE b.BadgeName = 'Student'
  AND YEAR(b.BadgeDate) >= 2018
  AND u.Location IS NOT NULL
ORDER BY b.BadgeDate

-- Problem_13: List the comment ID, post title and creation date of the 
-- original posts (i.e. posts that have a title) together with the text 
-- and the creation date of each associated comment. Include only those 
-- results where the original post has a score of 15 or over. Order your 
-- results so that both posts and comments appear in chronological order 
-- on dates. (36 rows)
SELECT c.CommentID, p.Title, p.CreationDate, c.CommentText, c.CreationDate
FROM comments c INNER JOIN posts p ON c.PostID = p.PostID
WHERE p.Title IS NOT NULL 
  AND p.Score >= 15
ORDER BY p.CreationDate, c.CreationDate

-- Problem_14: List the vote ID, post title of the original posts (i.e., 
-- posts that have a title), the owner's display name and location for the 
-- posts that were down voted on the same day. (13 rows)
SELECT v.VoteID, p.Title, u.DisplayName, u.Location
FROM votes v
	INNER JOIN posts p ON v.PostID = p.PostID
	INNER JOIN users u ON p.OwnerUserID = u.UserID
WHERE p.Title IS NOT NULL
  AND v.VoteID IN (
	SELECT v.VoteID
	FROM votes v INNER JOIN posts p ON v.PostID = p.PostID
	WHERE DATE(p.CreationDate) = DATE(v.CreationDate)
	  AND v.VoteTypeID = 3)

-- Problem_15: List the post ID, post creation date, display name and 
-- the location of the post owner, as well as the display name and location
-- of the post's last editor with last edit date and view count, for all 
-- posts with a view count and last edit within a week of the creation 
-- date, sorted descending by the post view count. (37 rows)
SELECT p.PostID, p.CreationDate, u1.DisplayName as OwnerName, u1.Location as OwnerLocation,
	u2.DisplayName as EditorName, u2.Location as EditorLocation,
	p.LastEditDate, p.ViewCount
FROM posts p
	INNER JOIN users u1 ON p.OwnerUserID = u1.UserID
	INNER JOIN users u2 ON p.LastEditorUserID = u2.UserID
WHERE p.ViewCount IS NOT NULL
  AND DATEDIFF(p.LastEditDate, p.CreationDate)<=7 -- DIFF: DATEDIFF(A,B) & DATE(A)-DATE(B)
ORDER BY p.ViewCount DESC

-- **********************************************************************
-- Problems 16 - 20: Employees Database
-- **********************************************************************
-- Problem_16: List the first name, last name, birth date, and hire date
-- for female employees born in 1965 hired in the last quarter (October - 
-- December) of 1990, sorted by the hire date. (22 rows)
SELECT first_name, last_name, birth_date, hire_date
FROM employees
WHERE gender = 'F'
  AND YEAR(birth_date) = 1965
  AND (QUARTER(hire_date) = 4 AND YEAR(hire_date) = 1990)
ORDER BY hire_date

-- Problem_17: List the first name, last name, birth and hire dates, from 
-- and to dates, and salary as of 1/1/2000 for all employees born in 1965, 
-- hired in 1990's, earning at least $100,000 as of that date, sorted 
-- descending on salary. (26 rows) 
SELECT e.first_name, e.last_name, e.birth_date, e.hire_date,
	s.from_date, s.to_date, s.salary
FROM employees e
	INNER JOIN salaries s ON e.emp_no = s.emp_no
WHERE '2000-01-01' BETWEEN s.from_date and s.to_date
  AND YEAR(birth_date) = 1965
  AND YEAR(hire_date) BETWEEN 1990 AND 1999
  AND s.salary >= 100000
ORDER BY s.salary DESC

-- Problem_18: List the first name, last name, birth and hire dates, from 
-- and to dates, as well as salary for employees born in 1965 working at  
-- the Research department as of 1/1/2010, making at least $70,000 as of  
-- that date, sorted descending on salary. (38 rows) 
SELECT e.first_name, e.last_name, e.birth_date, e.hire_date,
	s.from_date, s.to_date, s.salary
FROM employees e
	INNER JOIN salaries s ON e.emp_no = s.emp_no
	INNER JOIN dept_emp de ON e.emp_no = de.emp_no
WHERE YEAR(birth_date) = 1965
  AND de.dept_no = (SELECT dept_no FROM departments WHERE dept_name = 'Research')
  AND '2010-01-01' BETWEEN de.from_date and de.to_date
  AND s.salary >= 70000
  AND '2010-01-01' BETWEEN s.from_date and s.to_date
ORDER BY s.salary DESC

-- Problem_19: List the employee number, first name, last name, birth and 
-- hiredates, and job titles for employees born in 1965 hired in the summer 
-- (June, July, August) of 1985. Keep only those employees still working at 
-- the company. Sort the result by employee last name. (42 rows) 
SELECT e.emp_no, e.first_name, e.last_name, e.birth_date, e.hire_date,
	t.title
FROM employees e INNER JOIN titles t ON e.emp_no = t.emp_no
WHERE YEAR(birth_date) = 1965
  AND MONTH(e.hire_date) IN (6,7,8) AND YEAR(e.hire_date) = 1985
  AND DATE(t.to_date) = '9999-01-01'
ORDER BY e.last_name
 
-- Problem_20: Confirm that Oscar is the only department manager born in 
-- 1963 and hired during the week of 2/3/1992 - 2/7/1992.
SELECT e.first_name, e.last_name
FROM employees e
	INNER JOIN dept_manager dm ON e.emp_no = dm.emp_no
WHERE YEAR(birth_date) = 1963
  AND e.hire_date BETWEEN '1992-02-03' and '1992-02-07'

-- List employee first and last name, birth date and hire date for all 
-- employees who are not deparment managers that were born in 1963 and were 
-- hired during the week of 2/3/1992 - 2/7/1992, sorted by first name, 
-- confirming that Oscar is not one of them. (18 rows)
SELECT first_name, last_name, birth_date, hire_date
FROM employees
WHERE emp_no NOT IN (SELECT emp_no FROM dept_manager)
  AND YEAR(birth_date) = 1963
  AND hire_date BETWEEN '1992-02-03' and '1992-02-07'
ORDER BY first_name