-------------------
--Case Study #1 Danny's Diner
----------------------------

--Written by Khairah Haleman
--Date: 09/11/2022
--Tool: MS SQL Server

CREATE SCHEMA dannys_diner;
GO


CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

--  -----------------------
----What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(price) as total_amount
FROM dbo.sales s
JOIN dbo.menu m
	ON s.product_id = m.product_id
GROUP BY customer_id;

--How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date)) as visit_count
FROM dbo.sales
GROUP BY customer_id;

----What was the first item from the menu purchased by each customer?

WITH ordered_sales_CTE AS 
(SELECT s.customer_id, m.product_name, s.order_date, DENSE_RANK () OVER (PARTITION BY s.customer_id
ORDER BY s.order_date) AS rank
FROM dbo.sales s
JOIN dbo.menu m
	ON s.product_id = m.product_id
)

SELECT customer_id, product_name
FROM ordered_sales_CTE
WHERE rank = 1
GROUP BY customer_id, product_name;

--What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 (COUNT(s.product_id)) as most_purchased_item, m.product_name
FROM dbo.sales s
JOIN dbo.menu m
	On s.product_id = m.product_id
GROUP BY  product_name
ORDER BY most_purchased_item DESC;

--Which item was the most popular for each customer?

WITH popular_item_cte AS 
(
SELECT 
	s.customer_id, 
	m.product_name, 
	COUNT(m.product_id) AS product_count,
		DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS RANK
FROM dbo.sales AS s
JOIN dbo.menu AS m
	ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
)

SELECT 
	customer_id,
	product_name,
	product_count
FROM popular_item_cte
WHERE RANK = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH members_sales_cte AS (
	SELECT 
	s.customer_id, 
	d.join_date, 
	s.order_date, 
	s.product_id,
		DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
	FROM dbo.sales AS s
	JOIN dbo.members AS d
	ON s.customer_id = d.customer_id
	WHERE s.order_date >= d.join_date
	)
		
SELECT f.customer_id,f.order_date, m.product_name
FROM members_sales_cte AS f
JOIN dbo.menu AS m
	ON f.product_id = m.product_id
WHERE RANK = 1;

-- 7 Which item was purchased just before the customer became a member?
WITH before_members_sales_cte AS (
	SELECT 
	s.customer_id, 
	d.join_date, 
	s.order_date, 
	s.product_id,
		DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rank
	FROM dbo.sales AS s
	JOIN dbo.members AS d
	ON s.customer_id = d.customer_id
	WHERE s.order_date < d.join_date
	)
		
SELECT f.customer_id,f.order_date, m.product_name
FROM before_members_sales_cte AS f
JOIN dbo.menu AS m
	ON f.product_id = m.product_id
WHERE RANK = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(DISTINCT(s.product_id)) AS unique_product_count, SUM(m.price) AS total_amount
FROM dbo.sales AS s
JOIN dbo.menu AS m
	ON s.product_id = m.product_id
JOIN dbo.members AS d
	ON s.customer_id = d.customer_id
WHERE s.order_date < d.join_date
GROUP BY s.customer_id
ORDER BY total_amount DESC, unique_product_count DESC;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points_cte AS (
SELECT *,
	CASE WHEN product_id = 1 THEN price * 20
	ELSE price * 10
	END AS points
FROM dbo.menu
)
SELECT s.customer_id, SUM(p.points) as total_points
FROM points_cte AS p
JOIN dbo.sales AS s
	ON p.product_id = s.product_id
GROUP BY customer_id;

--10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
--January

WITH first_week_cte AS (
SELECT  *, 
DATEADD(DAY, 6, join_date) AS first_week,
EOMONTH('2021-01-31') AS last_date
FROM dbo.members 
)

SELECT fw.customer_id,
SUM(CASE
	WHEN s.order_date BETWEEN fw.join_date AND fw.first_week THEN m.price * 20
	WHEN m.product_name = 'Sushi' THEN m.price * 20
	ELSE m.price * 10
	END) AS total_points
FROM first_week_cte AS fw
JOIN dbo.sales AS s
	ON fw.customer_id = s.customer_id
JOIN dbo.menu AS m
	ON s.product_id = m.product_id
WHERE s.order_date < fw.last_date
GROUP BY fw.customer_id ;


--BONUS QUESTIONS

--a) JOIN ALL THE THINGS

SELECT
s.customer_id,
s.order_date,
m.product_name,
m.price,
	CASE WHEN d.join_date > s.order_date THEN 'N'
	WHEN d.join_date <= s.order_date THEN 'Y'
	ELSE 'N' END AS member
FROM dbo.sales AS s
LEFT JOIN dbo.menu AS m
	ON s.product_id = m.product_id
LEFT JOIN dbo.members AS d
	ON s.customer_id = d.customer_id;

--RANK ALL THE THINGS

WITH members AS (
SELECT
s.customer_id,
s.order_date,
m.product_name,
m.price, (CASE WHEN d.join_date > s.order_date THEN 'N'
	WHEN d.join_date <= s.order_date THEN 'Y'
	ELSE 'N' END)AS member 
FROM dbo.sales AS s
LEFT JOIN dbo.menu AS m
	ON s.product_id = m.product_id
LEFT JOIN dbo.members AS d
	ON s.customer_id = d.customer_id

)
SELECT *, 
	CASE WHEN member = 'N' THEN NULL
	ELSE RANK () OVER (PARTITION BY customer_id, member
	ORDER BY order_date) END AS ranking
FROM members;
