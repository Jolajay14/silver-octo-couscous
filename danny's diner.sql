--CREATE DATABASE DannysDiner

--USE DannysDiner

--CREATE SCHEMA dannys_diner;


--CREATE TABLE dannys_diner.sales (
--  customer_id VARCHAR(1),
--  order_date DATE,
--  product_id INTEGER
--);

--INSERT INTO dannys_diner.sales
--  ("customer_id", "order_date", "product_id")
--VALUES
--  ('A', '2021-01-01', '1'),
--  ('A', '2021-01-01', '2'),
--  ('A', '2021-01-07', '2'),
--  ('A', '2021-01-10', '3'),
--  ('A', '2021-01-11', '3'),
--  ('A', '2021-01-11', '3'),
--  ('B', '2021-01-01', '2'),
--  ('B', '2021-01-02', '2'),
--  ('B', '2021-01-04', '1'),
--  ('B', '2021-01-11', '1'),
--  ('B', '2021-01-16', '3'),
--  ('B', '2021-02-01', '3'),
--  ('C', '2021-01-01', '3'),
--  ('C', '2021-01-01', '3'),
--  ('C', '2021-01-07', '3');
 

--CREATE TABLE dannys_diner.menu (
--  "product_id" INTEGER,
--  "product_name" VARCHAR(5),
--  "price" INTEGER
--);

--INSERT INTO dannys_diner.menu
--  ("product_id", "product_name", "price")
--VALUES
--  ('1', 'sushi', '10'),
--  ('2', 'curry', '15'),
--  ('3', 'ramen', '12');
  

--CREATE TABLE dannys_diner.members (
--  "customer_id" VARCHAR(1),
--  "join_date" DATE
--);

--INSERT INTO dannys_diner.members
--  ("customer_id", "join_date")
--VALUES
--  ('A', '2021-01-07'),
--  ('B', '2021-01-09');

--Question1:  What is the total amount each customer spent at the restaurant?

SELECT
    s.customer_id,
    SUM(m.price) AS total_amount_spent
FROM
    dannys_diner.sales s
JOIN
    dannys_diner.menu m
ON
    s.product_id = m.product_id
GROUP BY
    s.customer_id;

	--Question2:  What is the total amount each customer spent at the restaurant?
	SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS Numberofdaysvisited
FROM
    dannys_diner.sales
GROUP BY
    customer_id;

--question 3: what was the first item from the menu purchased by each customer?
SELECT
    customer_id,
    MIN(order_date) AS first_purchase_date,
    FIRST_VALUE(product_name) OVER (PARTITION BY customer_id ORDER BY MIN(order_date)) AS first_item_purchased
FROM
    dannys_diner.sales s
JOIN
    dannys_diner.menu m
ON
    s.product_id = m.product_id
GROUP BY
    customer_id, product_name;

---Question 4:What is the most purchased item on the menu and how many times was it purchased by all customers?

 SELECT TOP 1
    m.product_name,
    COUNT(*) AS item_count
FROM
    dannys_diner.sales s
JOIN
    dannys_diner.menu m
ON
    s.product_id = m.product_id
GROUP BY
    m.product_name
ORDER BY
    item_count DESC;
  
 ---Question 5: Which item was the most popular for each customer?
 WITH MostPopular AS (
    SELECT
        s.customer_id,
        m.product_name,
        COUNT(product_name) AS item_count,
        RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(product_name) DESC) AS i_rank
		FROM
        dannys_diner.sales s
    JOIN
        dannys_diner.menu m
    ON
        s.product_id = m.product_id
    GROUP BY
        s.customer_id, m.product_name
)
SELECT
    customer_id,
    product_name,
	item_count
FROM
    MostPopular
WHERE
    i_rank = 1;

--Question 6:Which item was purchased first by the customer after they became a member?
	WITH MemberFirstPurchases AS (
    SELECT
        s.customer_id,
        m.product_name,
       DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS i_rank
    FROM
        dannys_diner.menu m
    JOIN
        dannys_diner.sales s
    ON
        s.product_id = m.product_id
    JOIN
        dannys_diner.members mem
    ON
        mem.customer_id = s.customer_id
  WHERE s.order_date>= mem.join_date)
 select
    MFP.customer_id,
    MFP.product_name
from
    MemberFirstPurchases MFP
	WHERE MFP.i_rank=1;

--Question 7: Which item was purchased just before the customer became a member?
	WITH MemberLastPurchases AS (
    SELECT
        s.customer_id,
        product_name,
        s.order_date,
        DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS i_rank
    FROM
        dannys_diner.menu m
    JOIN
        dannys_diner.sales s
    ON
        s.product_id = m.product_id
    JOIN
        dannys_diner.members mem
    ON
        mem.customer_id = s.customer_id
    WHERE
        s.order_date < mem.join_date
)
SELECT
    customer_id,
    product_name,
    order_date AS last_purchase_date
FROM
    MemberLastPurchases
WHERE
    i_rank = 1;

--Question 8: What is the total items and amount spent for each member before they became a member?
WITH MemberPreJoinSummary AS (
    SELECT
        s.customer_id,
        COUNT(*) AS total_items,
        SUM(m.price) AS total_amount_spent
    FROM
        dannys_diner.sales s
    JOIN
        dannys_diner.menu m
    ON
        s.product_id = m.product_id
    WHERE
        s.order_date < (
            SELECT
                MIN(join_date)
            FROM
                dannys_diner.members
            WHERE
                customer_id = s.customer_id
        )
    GROUP BY
        s.customer_id
)
SELECT
    mem.customer_id,
    COALESCE(total_items, 0) AS total_items_before_join,
    COALESCE(total_amount_spent, 0) AS total_amount_spent_before_join
FROM
    dannys_diner.members mem
LEFT JOIN
    MemberPreJoinSummary mjs
ON
    mem.customer_id = mjs.customer_id;

	--Question 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
	SELECT
    s.customer_id,
    SUM(
        CASE
            WHEN m.product_name = 'sushi' THEN 2 * m.price
            ELSE m.price
        END
    ) * 10 AS total_points
FROM
    dannys_diner.sales s
JOIN
    dannys_diner.menu m
ON
    s.product_id = m.product_id
GROUP BY
    s.customer_id;

	--Question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH PointsEarned AS (
    SELECT *,
         CASE
                WHEN m.product_id = 1 THEN m.price  * 20
                ELSE m.price * 10
            END AS points
    FROM
        dannys_diner.menu AS m
)
SELECT
    s.customer_id, SUM (p.points) AS total_points
FROM
    PointsEarned as p
	JOIN dannys_diner.sales AS s
	ON p.product_id = s.product_id
	GROUP BY s.customer_id
	ORDER BY s.customer_id;
