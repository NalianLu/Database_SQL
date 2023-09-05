/* MySQL6_More_SQL.sql */
-- **********************************************************************
-- Problems 01 - 08 use OrderEntry database
-- **********************************************************************
-- Problem_01: List all employees that have not taken any orders. Include 
-- the employee number, first and last name, and the number of his or her 
-- supervisor. (1 row)
SELECT EmpNo, EmpFirstName, EmpLastName, SupEmpNo
FROM employee
WHERE NOT EXISTS (
	SELECT *
	FROM ordertbl
	WHERE ordertbl.EmpNo = employee.EmpNo)

-- Problem_02: List all customer orders that were ordered by and are going 
-- to the same person, and were taken by employees with the commission 
-- rate of 4% or greater using Type I subquery on employees. Include 
-- customer number, first and last name, order number, date and the name 
-- of the person the order is going to. (4 rows)
SELECT c.CustNo, c.CustFirstName, c.CustLastName, 
	o.OrdNo, o.OrdDate, o.OrdName
FROM customer c
	JOIN ordertbl o ON c.CustNo = o.CustNo
WHERE CONCAT(c.CustFirstName, ' ', c.CustLastName) = o.OrdName
  AND o.EmpNo IN (
	SELECT EmpNo
	FROM employee
	WHERE EmpCommRate >= 0.04)

-- Problem_03: List all the customers that have only shopped online 
-- using a Type II subquery with NOT EXISTS operator. Include customer 
-- number, first and last name. (3 rows)
SELECT CustNo, CustFirstName, CustLastName
FROM customer
WHERE NOT EXISTS (
	SELECT *
	FROM ordertbl
	WHERE EmpNo IS NOT NULL
	  AND ordertbl.CustNo = customer.CustNo)

-- Problem_04: List all the employees that have taken orders for all 
-- ColorMeg, Inc. products using Type I subquery in the HAVING clause. 
-- List the employee number, first and last name. (1 row)
SELECT e.EmpNo, e.EmpFirstName, e.EmpLastName
FROM employee e
	JOIN ordertbl ot ON e.EmpNo = ot.EmpNo
	JOIN orderline ol ON ot.OrdNo = ol.OrdNo
	JOIN product p ON ol.ProdNo = p.ProdNo
WHERE p.ProdMfg = 'ColorMeg, Inc.'
GROUP BY e.EmpNo
HAVING COUNT(DISTINCT ProdName) = (
	SELECT COUNT(DISTINCT ProdName)
	FROM product p2
	WHERE p2.ProdMfg = 'ColorMeg, Inc.')
	
-- Problem_05: Find the average number of products (rounded to 1 decimal) 
-- and the average sales (rounded to 2 decimals) by customer. Show 
-- customer number, first and last names, and use a grouping subquery 
-- within the FROM clause to first find the number of products and total 
-- sales by order. Sort the result by average sales descending. (16 rows)
SELECT t.CustNo, t.CustFirstName, t.CustLastName,
	ROUND(AVG(t.num_products),1) AS avg_num_products,
	ROUND(AVG(t.total_sales),2) AS avg_sales
FROM (
	SELECT ot.OrdNo,
		ot.CustNo,
		c.CustFirstName,
		c.CustLastName,
		SUM(ol.Qty) AS num_products,
		SUM(ol.Qty*p.ProdPrice) AS total_sales
	FROM customer c
		JOIN ordertbl ot ON c.CustNo = ot.CustNo
		JOIN orderline ol ON ot.OrdNo = ol.OrdNo
		JOIN product p ON ol.ProdNo = p.ProdNo
	GROUP BY ot.OrdNo) t
GROUP BY t.CustNo
ORDER BY avg_sales DESC

-- Problem_06: Create a multiple table view, named Comm_Emp_Cust_Ord,
-- showing customer name (first and last), balance, order dates, and 
-- employee names (first and last) for employees with commission of 
-- 0.04 or higher. (6 rows)
DROP VIEW IF EXISTS Comm_Emp_Cust_Ord;
CREATE VIEW Comm_Emp_Cust_Ord AS
	SELECT c.CustFirstName, c.CustLastName, c.CustBal, 
		o.OrdDate, e.EmpFirstName, e.EmpLastName
	FROM customer c
		JOIN ordertbl o ON c.CustNo = o.CustNo
		JOIN employee e ON o.EmpNo = e.EmpNo
	WHERE e.EmpCommRate >= 0.04;
SELECT * FROM Comm_Emp_Cust_Ord

-- Problem_06 (cont.): Create a query using this view to show customer 
-- names, balance and order dates for orders taken by Johnson. (2 rows)
-- Copy/paste the results right next to all view records from above.
SELECT CustFirstName, CustLastName, CustBal, OrdDate
FROM Comm_Emp_Cust_Ord
WHERE EmpLastName = 'Johnson'

-- Problem_07: Create a grouping view, named Product_Summary, summarizing 
-- total sales by product. Make sure to include the product manufacturer  
-- and use the following names for the resulting three columns: 
-- ProductName, ManufName, and TotalSales. (10 rows)
DROP VIEW IF EXISTS Product_Summary;
CREATE VIEW Product_Summary (ProductName, ManufName, TotalSales) AS
	SELECT p.ProdName, ProdMfg, SUM(ol.Qty*p.ProdPrice)
	FROM product p JOIN orderline ol ON p.ProdNo = ol.ProdNo
	GROUP BY p.ProdName;
SELECT * FROM Product_Summary
   
-- Problem_07 (cont.): Create a grouping query on this view to summarize 
-- the number of products and total sales by manufacturer, sorted  
-- descending on total sales. (6 rows)
-- Copy/paste the results right next to all view records from above.
SELECT ManufName,
	COUNT(ProductName) AS NumProducts,
	SUM(TotalSales) AS TotalManuSales
FROM Product_Summary
GROUP BY ManufName
ORDER BY TotalManuSales DESC

-- Problem_08: Create a stored function named get_cust_name that accepts 
-- customer ID as its input and returns customer’s full name, in the 
-- first-space-last name format.
DROP FUNCTION IF EXISTS get_cust_name;
DELIMITER $$
CREATE FUNCTION get_cust_name(cNo CHAR(8))
  RETURNS VARCHAR(100)
  DETERMINISTIC
  READS SQL DATA
  BEGIN
  DECLARE cust_first, cust_last VARCHAR(50);
	DECLARE cust_full_name VARCHAR(100);
	-- SELECT INTO statement
	SELECT CustFirstName, CustLastName
	INTO cust_first, cust_last
	FROM customer
	WHERE CustNo = cNo;
  -- Use CONCAT to create the full name
  SET cust_full_name = CONCAT(cust_first, ' ', cust_last);
  -- RETURN statement	
	RETURN cust_full_name;
  END$$

-- Problem_08 (cont.) Create a stored procedure display_customer_info 
-- that accepts customer number as the only input variable and returns, 
-- using a single SELECT statement, the customer’s full name, obtained 
-- with the get_cust_name function, as well as the city, balance and 
-- estimated delivery time based on the state the customer resides in. 
-- For Washington state customer, the delivery is 'Within 3 business 
-- days', Colorado customers can expect their orders to come 'Between 
-- 3 and 5 business days'. You must use CASE-WHEN statement to define 
-- the delivery time, and this statement must have a case for customers 
-- from other states (or missing state info) where the delivery time is 
-- not defined/applicable.
DROP PROCEDURE IF EXISTS display_customer_info;
DELIMITER $$
CREATE PROCEDURE display_customer_info(IN cNo CHAR(8))
  BEGIN
  DECLARE cust_full_name VARCHAR(100);
	DECLARE cust_city VARCHAR(30);
	DECLARE cust_state CHAR(2);
	DECLARE cust_balance DOUBLE;
	DECLARE cust_delivery VARCHAR(50);
	
	-- SELECT INTO statement (uses get_cust_name function)
	SELECT get_cust_name(CustNo), CustCity, CustBal, CustState
	INTO cust_full_name, cust_city, cust_balance, cust_state
	FROM customer
	WHERE CustNo = cNo;
	
	-- CASE statement defines the delivery message
	SET cust_delivery = 
		CASE
			WHEN cust_state = 'WA' THEN 'Within 3 business days'
			WHEN cust_state = 'CO' THEN 'Between 3 and 5 business days'
			WHEN cust_state IS NULL THEN 'Missing state info'
		END;
	
	-- SELECT statement returns the results
	SELECT cust_full_name, cust_city, cust_balance, cust_delivery;
  END$$

-- Problem_08 (cont.): You must test the code by calling the stored 
-- procedure (and function) with a customer C3340959 from Washington and 
-- then with C9128574 from Colorado, and finally with an non-existing 
-- customer C1234567 (or similar). (3 rows)
CALL display_customer_info('C3340959');
CALL display_customer_info('C9128574');
CALL display_customer_info('C1234567')

-- **********************************************************************
-- Problems 09 - 14 use StackExchange database
-- **********************************************************************
-- Problem_09: List the ID, display name and location of users that have 
-- only posted in 2014 using Type II subquery with NOT EXISTS operator, 
-- sorted by the user ID. (43 rows)
SELECT DISTINCT u.userid, u.displayname, u.location
FROM users u JOIN posts p ON u.userid = p.owneruserid
WHERE YEAR(p.creationdate) = 2014
  AND NOT EXISTS (
	SELECT *
	FROM posts p2
	WHERE YEAR(p2.creationdate) <> 2014
	  AND p2.owneruserid = u.userid)
ORDER BY u.userid

-- Problem_10: List the ID, display name and location of users that only 
-- commented on posts, but did not post themselves using Type II subquery 
-- with NOT EXISTS operator. (38 rows)
SELECT DISTINCT u.userid, u.displayname, u.location
FROM users u JOIN comments c ON u.userid = c.userid
WHERE NOT EXISTS (
	SELECT *
	FROM posts p2
	WHERE p2.owneruserid = u.userid)
ORDER BY u.userid

-- Problem_11: List the users ID, display name, reputation, both up-votes
-- and down-votes for users who neither post nor comment, using two Type II
-- subqueries with NOT EXISTS operators, but have a reputation over 100 and 
-- over 5 up-votes, sorted descending on the number of up-votes. (25 rows)
SELECT userid, displayname, reputation, upvotes, downvotes
FROM users
WHERE NOT EXISTS (
	SELECT *
	FROM comments
	WHERE comments.userid = users.userid)
  AND NOT EXISTS (
	SELECT *
	FROM posts
	WHERE posts.owneruserid = users.userid)
  AND reputation > 100
  AND upvotes > 5
ORDER BY upvotes DESC

-- Problem_12: List the post ID, the original title/question, the number 
-- of answers provided for each question, and the total "answer scores".
-- Keep only the rows where the total number of answers is more than 2,
-- sorted descending on the total answer score. (31 rows)
SELECT p1.postid, p1.title, p1.answercount, SUM(p2.score) as total_answer_scores
FROM posts p1 JOIN posts p2 ON p1.postid = p2.parentid
WHERE p1.answercount > 2
GROUP BY p1.postid
ORDER BY total_answer_scores DESC

-- Problem_13: List the post ID and the original title/question, along 
-- with its accepted answer ID, the body of its accepted answer and the 
-- score of its accepted answer, but only if the accepted "answer score" 
-- is at least 5, sorted descending on the "answer score". (33 rows)
-- Note: Don't bother copy/pasting difficult to parse answer PostBody, 
-- the rest of the columns are sufficient for documenting your answer.
SELECT p1.postid, p1.title, p1.acceptedanswerid, 
	p2.postbody AS answer_body, p2.score AS answer_score
FROM posts p1 JOIN posts p2 ON p1.acceptedanswerid = p2.postid
WHERE p2.score >= 5
ORDER BY p2.score DESC

-- Problem_14 (part 1): Use insight from the previous assignment to find 
-- the maximum view count of posts by tag name, sorted ascending by tag 
-- name. (49 rows)
SELECT tagname, MAX(viewcount) AS MaxViewCount
FROM (
	SELECT p.postid, p.tags, p.viewcount, t.tagid, t.tagname
	FROM posts p
	JOIN tags t ON p.tags LIKE CONCAT('%<', t.tagname ,'>%') ) AS post_tag_table
GROUP BY tagname
ORDER BY tagname

-- Problem_14 (part 2): List the post ID, title, view count and tag name
-- for posts with view counts that are within 10% of the maximum number of 
-- views (see part 1) for any tag with which the post is tagged. However, 
-- do not include the posts with the maximum number of views for any given 
-- tag. Order the results descending on the view count. (7 rows)
-- 1. Create view: post_tag_table
DROP VIEW IF EXISTS post_tag_table;
CREATE VIEW post_tag_table AS
	SELECT p.postid, p.title, p.tags, p.viewcount, t.tagid, t.tagname
	FROM posts p
	JOIN tags t ON p.tags LIKE CONCAT('%<', t.tagname ,'>%')
-- 2. Create view: tag_max_view
DROP VIEW IF EXISTS tag_max_view;
CREATE VIEW tag_max_view AS
	SELECT tagname, MAX(viewcount) AS max_view_num
	FROM post_tag_table
	GROUP BY tagname
-- 3. List post with view counts within 10% of the maximum number
SELECT postid, title, viewcount, tags
FROM (
	SELECT postid, title, viewcount, tags, tagname, max_view_num,
		(CASE 
			WHEN viewcount >= 0.9*max_view_num THEN 1
			ELSE 0
		END) AS within_10p_max,
		(CASE
			WHEN viewcount = max_view_num THEN 1
			ELSE 0
		END) AS equal_max
	FROM post_tag_table
		JOIN tag_max_view USING (tagname)) AS Criteria_table
WHERE within_10p_max = 1 AND equal_max = 0
ORDER BY viewcount DESC

-- **********************************************************************
-- Problems 15 - 18 use Employees database
-- **********************************************************************
-- Problem_15: List the employee number, first and last name of employees 
-- born in 1965, hired in the mid 1990's (1993 to 1997, both included), 
-- who changed departments once, and are still working at the company, 
-- sorted by the employee number. You must use Type I subquery to find 
-- the list of employee numbers for employees that changed departments
-- exactly once. (29 rows)
SELECT emp_no, first_name, last_name
FROM employees
WHERE YEAR(birth_date) = 1965
  AND YEAR(hire_date) BETWEEN 1993 AND 1997
  AND emp_no IN (
	SELECT emp_no
	FROM dept_emp
	GROUP BY emp_no
	HAVING COUNT(DISTINCT dept_no) = 2
	   AND MAX(to_date) = '9999-01-01')
ORDER BY emp_no

-- Problem_16: List the employee number, first and last name, as well as 
-- the last date at the company, for employees born in 1965, hired in  
-- the 1990's who changed departments once, and are no longer working at
-- the company, sorted by the last date at the company. Again, you must use 
-- Type I subquery to find the list of employee numbers for employees that 
-- changed departments exactly once. (14 rows) 
SELECT e.emp_no, e.first_name, e.last_name, de.to_date AS last_date
FROM employees e JOIN dept_emp de ON e.emp_no = de.emp_no
WHERE YEAR(e.birth_date) = 1965
  AND YEAR(e.hire_date) BETWEEN 1990 AND 1999
  AND e.emp_no IN (
	SELECT emp_no
	FROM dept_emp
	GROUP BY emp_no
	HAVING COUNT(DISTINCT dept_no) = 2)
GROUP BY e.emp_no
HAVING MAX(de.to_date) != '9999-01-01'
ORDER BY last_date

-- Problem_17: List the employee number, first and last name, salary, the 
-- department name, the highest salary for the department for all 
-- employees earning within 5% of the highest salary for their department 
-- as of 1/1/2000. (41 rows)
-- 1. Create dept_max_salary view
DROP VIEW IF EXISTS dept_max_salary;
CREATE VIEW dept_max_salary AS
	SELECT d.dept_no, d.dept_name, MAX(s.salary) AS dept_highest_salary
	FROM salaries s
		JOIN employees e  USING(emp_no)
		JOIN dept_emp de USING(emp_no)
		JOIN departments d USING(dept_no)
	WHERE '2000-01-01' BETWEEN s.from_date AND s.to_date
	  AND '2000-01-01' BETWEEN de.from_date AND de.to_date
	GROUP BY d.dept_no
-- 2. List the employees earning within 5% of the highest salary for their department
SELECT e.emp_no, e.first_name, e.last_name,
	s.salary, dms.dept_name, dms.dept_highest_salary
FROM employees e 
	JOIN salaries s USING(emp_no)
	JOIN dept_emp de USING(emp_no)
	JOIN dept_max_salary dms USING(dept_no)
WHERE '2000-01-01' BETWEEN s.from_date AND s.to_date
  AND '2000-01-01' BETWEEN de.from_date AND de.to_date
  AND s.salary >= 0.95*dms.dept_highest_salary
ORDER BY dms.dept_highest_salary DESC, emp_no

-- Problem_18: We are interested in employees with significant salary
-- increases. List the employee number, first and last name, and salary
-- of all employees making at least $130,000 as of 1/1/2000, who made 
-- less than $100,000 at any time during 1980's. (36 rows)
SELECT e.emp_no, e.first_name, e.last_name, s.salary
FROM employees e 
	JOIN salaries s USING(emp_no)
WHERE '2000-01-01' BETWEEN s.from_date AND s.to_date
  AND s.salary >= 130000
  AND e.emp_no IN (
		SELECT e1.emp_no
		FROM employees e1 
			JOIN salaries s1 USING(emp_no)
		WHERE ((YEAR(s1.from_date) > 1980 AND (YEAR(s1.from_date) < 1990))
		   OR ((YEAR(s1.to_date) > 1980 AND (YEAR(s1.to_date) < 1990))))
		  AND s1.salary < 100000)

-- **********************************************************************
-- Problems 19 - 20 use Enron database
-- **********************************************************************
-- Problem_19: Who is sending a lot of messages just to themselves? List 
-- the person's ID, email, name, and the number of messages sent only to 
-- the originating user for each person. Users should appear in the 
-- result if they have sent at least 30 messages exclusively to 
-- themselves, sorted descending on the number of messages. (26 rows)
SELECT p.personid, p.email, p.name, COUNT(m.messageid) AS num_self_messages
FROM people p JOIN messages m ON p.personid = m.senderid
WHERE (m.messageid, p.personid) IN (
	SELECT m2.messageid, r.personid
	FROM messages m2 JOIN recipients r ON m2.messageid = r.messageid
	GROUP BY m2.messageid
	HAVING COUNT(r.recipientid) = 1)
GROUP BY p.personid
HAVING num_self_messages >= 30
ORDER BY num_self_messages DESC

-- Problem_20: Who was the most active user in any given year for the 
-- four year period from 1999 through 2002? List the year, senderid, 
-- email, name, and message sent count (for that year) for all senders 
-- whose number of messages sent was within 25% of the most active 
-- sender witin a year. (9 rows)
-- 1. Create year_most_active_sender_num view
DROP VIEW IF EXISTS year_most_active_sender_num;
CREATE VIEW year_most_active_sender_num AS
	SELECT msg_year, MAX(msg_num) AS max_msg_num
	FROM (
		SELECT YEAR(messagedt) AS msg_year, senderid, COUNT(messageid) AS msg_num
		FROM messages
		WHERE YEAR(messagedt) BETWEEN 1999 AND 2002
		GROUP BY msg_year, senderid) AS yr_msg_tb
	GROUP BY msg_year
-- 2. List most active user
SELECT YEAR(m.messagedt) AS yr, m.senderid, 
	p.email, p.name, 
	COUNT(messageid) AS yr_mesg_num
FROM messages m
	JOIN people p ON m.senderid = p.personid
	JOIN year_most_active_sender_num ymas ON YEAR(m.messagedt) = ymas.msg_year
WHERE YEAR(m.messagedt) BETWEEN 1999 AND 2002
GROUP BY yr, m.senderid
HAVING yr_mesg_num >= 0.75*MAX(ymas.max_msg_num)
ORDER BY yr_mesg_num DESC