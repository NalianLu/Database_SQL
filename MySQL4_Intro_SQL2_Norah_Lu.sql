/* MySQL4_Intro_SQL2.sql */
-- **********************************************************************
-- Problems 01 - 05: Order Entry Database
-- **********************************************************************
-- Problem_01: List the average balance (rounded to 2 decimals) and the 
-- number of customers by city. Only include the customers residing in 
-- Washington state (WA). Keep only the cities with at least 2 customers. 
-- (2 rows)
SELECT custcity, 
	ROUND(AVG(custbal), 2) AS avg_balance, 
	COUNT(custno) AS num_customer
FROM customer
WHERE custstate = 'WA'
GROUP BY custcity
HAVING num_customer >= 2

-- Problem_02: List the order number, customer first and last name, and the 
-- total amount for orders placed on January 23, 2030. The total amount of 
-- an order is the sum of the quantity times the product price. Sort the 
-- result descending on the total order amounts. (6 rows)
SELECT ot.ordno, c.custfirstname, c.custlastname, 
	SUM(ol.qty*p.prodprice) AS total_amount
FROM ordertbl ot
	JOIN customer c ON c.custno = ot.custno
	JOIN orderline ol ON ot.ordno = ol.ordno
	JOIN product p ON ol.prodno = p.prodno
WHERE DATE(ot.orddate) = '2030-01-23'
GROUP BY ot.ordno
ORDER BY total_amount DESC

-- Problem_03: For each employee with commission rate greater than 0.03,
-- compute the total commission (rounded to 2 decimals) earned from orders 
-- taken in January 2030. The total commission earned is the total order 
-- amount times the commission rate. The result should include the employee 
-- number, employee first and last name, and the total commission earned, 
-- sorted descending on the total commission. (3 rows)
SELECT e.empno, e.empfirstname, e.emplastname,
	ROUND(e.empcommrate*SUM(ol.qty*p.prodprice), 2) AS total_commission
FROM employee e
	JOIN ordertbl ot ON e.empno = ot.empno
	JOIN orderline ol ON ot.ordno = ol.ordno
	JOIN product p ON ol.prodno = p.prodno
WHERE YEAR(ot.orddate) = 2030 AND MONTH(ot.orddate) = 1
  AND e.empcommrate > 0.03
GROUP BY e.empno
ORDER BY total_commission DESC

-- Problem_04: List the customer number, customer name (first and last),
-- the total quantity of products ordered, and the total order amount for 
-- orders placed in January 2030. Only include products in which the product 
-- name contains Ink Jet or Laser. Only include the customers who have 
-- ordered two or more Ink Jet or Laser products in January 2030. Sort 
-- descending on the total quantity and total amount, both descending. 
-- (5 rows)
SELECT c.custno, c.custfirstname, c.custlastname,
	SUM(ol.qty) AS total_quantity,
	SUM(ol.qty*p.prodprice) AS total_amount
FROM ordertbl ot
	JOIN customer c ON c.custno = ot.custno
	JOIN orderline ol ON ot.ordno = ol.ordno
	JOIN product p ON ol.prodno = p.prodno
WHERE (YEAR(ot.orddate) = 2030 AND MONTH(ot.orddate) = 1)
  AND (p.prodname LIKE '%Ink Jet%' OR p.prodname LIKE '%Laser%')
GROUP BY c.custno
HAVING total_quantity >= 2
ORDER BY total_quantity DESC, total_amount DESC

-- Problem_05: List the product number, product name, the total quantity
-- of products ordered, and the total order amount for orders placed in  
-- January 2030. Only include products whose total amount ordered exceeds 
-- the average of all orders. Sort the result descending on the total 
-- amount. (6 rows)
SELECT p.prodno, p.prodname,
	SUM(ol.qty) AS total_quantity,
	SUM(ol.qty*p.prodprice) AS total_amount
FROM ordertbl ot
	JOIN orderline ol ON ot.ordno = ol.ordno
	JOIN product p ON ol.prodno = p.prodno
WHERE (YEAR(ot.orddate) = 2030 AND MONTH(ot.orddate) = 1)
GROUP BY p.prodno
HAVING total_amount >
	( -- the average of all order lines
	SELECT AVG(ol2.qty*p2.prodprice)
	FROM product p2 
		JOIN orderline ol2 ON ol2.prodno = p2.prodno
	)
ORDER BY total_amount DESC

-- **********************************************************************
-- Problems 06 - 10: Stack Exchange Database
-- **********************************************************************
-- Problem_06: List the user ID, display name, location and Web site URL 
-- (only if both present), as well as creation date for users created in 
-- year 2020 or after, who do not have a badge using Type I subquery. 
-- (18 rows)
SELECT userid,displayname, location, websiteurl, creationdate
FROM users
WHERE YEAR(creationdate) >= 2020
  AND location IS NOT NULL
  AND websiteurl IS NOT NULL
  AND userid NOT IN (
	SELECT userid
	FROM badges
	)

-- Problem_07: List the name of each badge and the number of users who 
-- earned that badge, but only for those users with the number of up-votes 
-- higher than the average of all non-zero user up-votes. Include only the 
-- badges with more than 10 users, sorted descending on the number of users. 
-- (11 rows)
SELECT badgename, count(DISTINCT userid) AS num_user
FROM badges
WHERE userid IN 
	(SELECT userid
	FROM users
	WHERE upvotes > 
		( -- the average of all non-zero user up-votes
		SELECT AVG(upvotes)
		FROM users
		WHERE upvotes > 0)
		)
GROUP BY badgename
HAVING num_user > 10
ORDER BY num_user DESC

-- Problem_08: List the user ID, display name, location, the number of 
-- answers provided by the user, as well as the corresponding total post 
-- "answer score" for that user. Show only those users whose total post 
-- "answer score" is greater than 3 times the average of all post "answer 
-- scores", sorted descending on the number of answers. (23 rows)
SELECT u.userid, u.displayname, u.location, 
	COUNT(p.postid) AS num_answer,
	SUM(p.score) AS total_answer_score
FROM users u
	JOIN posts p ON u.userid = p.owneruserid
WHERE p.posttypeid = 2
GROUP BY u.userid
HAVING total_answer_score > 3*
	( -- the average of all post "answer scores"
	SELECT AVG(score)
	FROM posts
	WHERE posttypeid = 2
	)
ORDER BY num_answer DESC

-- **********************************************************************

-- Note: The only types of posts that are taged are questions with 
-- PostTypeID=1. (244 rows)
SELECT postid
FROM posts
WHERE posttypeid = 1

-- Note: Although there is no associative table to facilitate the 
-- many-to-many relationship between posts and tags, this relationship 
-- can be implemented by "partial-joining" the Tags column from the posts 
-- table with the TagName column from the tags table. To understand this 
-- relationship, you should first list the post ID, Tags and TagName 
-- columns and obtain 496 rows (do not copy/paste this into Excel)
-- Hint: Use LIKE operator and CONCAT function when performing the JOIN
SELECT p.postid, p.tags, t.tagid, t.tagname
FROM posts p
	JOIN tags t ON p.tags LIKE CONCAT('%<', t.tagname ,'>%')

-- Problem_09: This question assumes you successfully established the 
-- relationship between posts and tags tables described above. List the 
-- post ID, title and the number of tags per post. Show only the posts  
-- with more than 3 tags. (22 rows)
SELECT postid, title, COUNT(tagid) AS num_tag
FROM 
	(
	SELECT p.postid, p.tags, p.title, t.tagid, t.tagname
	FROM posts p
	JOIN tags t ON p.tags LIKE CONCAT('%<', t.tagname ,'>%')
	) AS post_tag_table
GROUP BY postid
HAVING num_tag > 3

-- Problem_10: This question assumes you successfully established the 
-- relationship between posts and tags tables described above. Find the 
-- number of posts and total view count by tag name, showing only those 
-- tags with more than 5 posts, sorted descending on the number of posts. 
-- (14 rows)
SELECT tagname, 
	COUNT(postid) AS num_post, 
	SUM(viewcount) AS total_view_count
FROM
	(
	SELECT p.postid, p.tags, p.viewcount, t.tagid, t.tagname
	FROM posts p
	JOIN tags t ON p.tags LIKE CONCAT('%<', t.tagname ,'>%')
	) AS post_tag_table
GROUP BY tagid
HAVING num_post > 5
ORDER BY num_post DESC

-- **********************************************************************
-- Problems 11 - 15: Employees Database
-- **********************************************************************
-- Problem_11: Find the number of employees by department and title as of 
-- 1/1/2000, sorted by department and the number of employees descending. 
-- Show only those department-title combinations with at least 5000 
-- employees. (20 rows)
SELECT d.dept_name, t.title, COUNT(e.emp_no) AS num_employee
FROM employees e
	JOIN titles t ON e.emp_no = t.emp_no
	JOIN dept_emp de ON e.emp_no = de.emp_no
	JOIN departments d ON de.dept_no = d.dept_no
WHERE '2000-01-01' BETWEEN t.from_date and t.to_date
  AND '2000-01-01' BETWEEN de.from_date and de.to_date
GROUP BY d.dept_name, t.title
HAVING num_employee >= 5000
ORDER BY d.dept_name, num_employee DESC

-- Problem_12: List the job title and average salary (rounded to 0 digits) 
-- for all job titles with an average salary of $60,000 or more as of 
-- 1/1/2000. Order the results descending on the average salary. (5 rows)
SELECT t.title, ROUND(AVG(s.salary),0) AS avg_salary
FROM employees e
	JOIN titles t ON e.emp_no = t.emp_no
	JOIN salaries s ON e.emp_no = s.emp_no
WHERE '2000-01-01' BETWEEN t.from_date AND t.to_date
  AND '2000-01-01' BETWEEN s.from_date AND s.to_date
GROUP BY t.title
HAVING avg_salary >= 60000
ORDER BY avg_salary DESC

-- Problem_13: Examine the difference in Senior Staff average salaries 
-- (rounded to 0 digits) between departments having employees with this 
-- title as of 1/1/2000. Sort the result descending on the average  
-- Senior Staff salaries. (8 rows)
SELECT d.dept_name, ROUND(AVG(salary)) AS avg_salary_senior
FROM employees e
	JOIN salaries s ON e.emp_no = s.emp_no
	JOIN dept_emp de ON e.emp_no = de.emp_no
	JOIN departments d ON de.dept_no = d.dept_no
WHERE '2000-01-01' BETWEEN s.from_date AND s.to_date
  AND '2000-01-01' BETWEEN de.from_date and de.to_date
  AND e.emp_no IN 
	( -- senior staff emp_no
	SELECT emp_no
	FROM titles
	WHERE title = 'Senior Staff'
	)
GROUP BY d.dept_name
ORDER BY avg_salary_senior DESC

-- Problem_14: List the employee number, first and last name, gender and 
-- hire date of employees born in 1965 that have changed job titles 
-- exactly 3 times, sorted by the hire date. (14 rows)
SELECT emp_no, first_name, last_name, gender, hire_date
FROM employees
WHERE YEAR(birth_date) = 1965
  AND emp_no IN 
	( -- emp_no for employees that have changed job titles 3 times
	SELECT emp_no
	FROM titles
	GROUP BY emp_no
	HAVING COUNT(DISTINCT title) = 3
	)
ORDER BY hire_date

-- Problem_15: List the title and number of employees who never changed 
-- their job title, sorted descending on number of employees. You must use 
-- previous problem as the basis for a Type I subquery that needs to be 
-- used in the solution. (6 rows)
SELECT title, COUNT(emp_no) AS num_employee_no_title_change
FROM titles
WHERE emp_no IN 
	( -- emp_no for employees that never changed their job title
	SELECT emp_no
	FROM titles
	GROUP BY emp_no
	HAVING COUNT(DISTINCT title) = 1
	)
GROUP BY title
ORDER BY num_employee_no_title_change DESC

-- **********************************************************************
-- Problems 16 - 20: Enron Emails Database
-- **********************************************************************
-- Problem_16: List the number of email messages sent by year and month. 
-- Keep only year-months from July 1999 through June of 2002, sorted on 
-- year-months. (36 rows)
-- Create a quick line chart in Excel to describe the overall trend and
-- identify the peak year-month.
SELECT CONCAT(YEAR(messagedt), '-', LPAD(MONTH(messagedt),2,'0')) AS Yr_Mon,
	COUNT(messageid) AS num_email_message
FROM messages
WHERE messagedt BETWEEN '1999-07-01' AND '2002-06-30'
GROUP BY YEAR(messagedt), MONTH(messagedt)
ORDER BY YEAR(messagedt), MONTH(messagedt)

-- Problem_17: List the number of emails sent by hour of a day for July 
-- 1999 through June 2002 time period, sorted by the hour of the day. 
-- (24 rows)
-- Create a quick line chart in Excel to describe the overall trend and
-- identify the peak hour.
SELECT HOUR(messagedt) AS message_hour, COUNT(messageid) AS num_email
FROM messages
WHERE messagedt BETWEEN '1999-07-01' AND '2002-06-30'
GROUP BY message_hour
ORDER BY message_hour
-- The peak hour is 10am

-- Problem_18: What were the words at the beginning of emails? Assume, 
-- for now, that the characters before the first blank represent the 
-- first "word". Use the same July 1999 through June 2002 time period, 
-- showing only those "words" with frequency of at least 1000 sorted 
-- descending on the frequency. (30 rows)
-- Copy/paste to Excel with quotes around so you can see the 
-- empty string '', special characters such as '\n', etc..
SELECT LEFT(b.body, LOCATE(" ", b.body)) AS begin_words,
	COUNT(*) AS word_frequency
FROM bodies b
	JOIN messages m ON b.messageid = m.messageid
WHERE m.messagedt BETWEEN '1999-07-01' AND '2002-06-30'
GROUP BY begin_words
HAVING word_frequency >= 1000
ORDER BY word_frequency DESC

-- Problem_19: We are interested in the messages sent to a large number 
-- of recipients. List sender's email and name, message subject, and the 
-- number of recipients, showing only the messages with 500 or more 
-- recipients, sorted descending on number or recipients. (34 rows)
SELECT p.email, p.name, m.subject, COUNT(r.recipientid) AS num_recipients
FROM messages m 
	JOIN recipients r ON m.messageid = r.messageid
	JOIN people p ON m.senderid = p.personid
GROUP BY m.messageid
HAVING num_recipients >= 500
ORDER BY num_recipients DESC

-- Problem_20: We are interested in people that BCC a lot, as well as those
-- people that are being BCC'd by them. Create 2 queries to analyze this 
-- issue, the first one listing people's ID's, emails, names and the number 
-- of times they BCC'd, showing only those senders that BCC'd over 1000 
-- recepients, sorted descending on the number of BCC's. (16 rows)
SELECT p.personid, p.email, p.name, SUM(mg.bccs) AS Num_BCC
FROM mailgraph mg
	JOIN people p ON mg.senderid = p.personid
GROUP BY mg.senderid
HAVING Num_BCC > 1000
ORDER BY Num_BCC DESC
-- The personid of the top BCC-er is 256

-- Problem 20 (cont.): One person should clearly stand out as the top BCC-er, 
-- with the total number of BCC'd recepients an order of magnitude higher than 
-- the second highest BCC-er. Use this person's ID to formulate the second 
-- query that will return the BCC'd receipent's IDs, emails, names and the 
-- number of times they were BCC'd by the top BCC-er, sorted descending on the 
-- number of times BCC'd. (27 rows)
-- Copy/paste the results to the right of the first result in the same sheet

-- Version 1: use mailgraph and people tables
SELECT p.personid, p.email, p.name, m.bccs AS Num_BCCd
FROM mailgraph m
	JOIN people p ON m.recipientid = p.personid
WHERE m.senderid = 256
  AND Num_BCCd > 0
ORDER BY Num_BCCd DESC

-- Version 2: use recipients, messages, and people tables
SELECT r.personid, p.email, p.name, COUNT(*) AS Num_Bccd
FROM messages m
	JOIN recipients r ON m.messageid = r.messageid
	JOIN people p ON r.personid = p.personid
WHERE senderid = 256
  AND r.reciptype = 'BCC'
GROUP BY r.personid
ORDER BY Num_Bccd DESC