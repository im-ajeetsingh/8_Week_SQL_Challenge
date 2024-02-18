create table sales(
	"customer_id" VARCHAR(1),
	"order_date" DATE,
	"product_id" INTEGER
);
insert into sales
  ("customer_id","order_date","product_id")
values
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

create table menu(
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

select *from sales;
select *from menu;
select *from members;

--1.What is the total amount each customer spent at the restaurant? 
select sales.customer_id,sum(menu.price) as sum_spent
from sales
INNER JOIN menu
on sales.product_id = menu.product_id
group by sales.customer_id
order by sum_spent desc;

--2.How many days has each customer visited the restaurant?
select customer_id,count(distinct(order_date)) as no_visited
from sales
group by customer_id
order by no_visited desc;

--3.What was the first item from the menu purchased by each customer?
select s.customer_id, m.product_name
from sales s
inner join menu m on s.product_id=m.product_id

WITH RankedSales AS (
  SELECT
    s.customer_id,
    m.product_name,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS purchase_rank
  FROM
    sales s
    INNER JOIN menu m ON s.product_id = m.product_id
)

SELECT
  customer_id,
  product_name AS first_purchased_item
FROM
  RankedSales
WHERE
  purchase_rank = 1;

--4.What is the most purchased item on the menu and how many times 
--was it purchased by all customers?
select s.customer_id ,m.product_name, count(m.product_name) as no_of_times
from sales s
inner join menu m on s.product_id = m.product_id
group by s.customer_id,m.product_name
order by count(s.product_id) desc;

--5.Which item was the most popular for each customer?

With rank as
(
Select S.customer_ID ,
       M.product_name, 
	   Count(S.product_id) as Count,
       Dense_rank()  Over (Partition by S.Customer_ID order by Count(S.product_id) DESC ) as Rank
From Menu m
Join Sales s
On m.product_id = s.product_id
Group by S.customer_id,S.product_id,M.product_name
)
Select Customer_id,Product_name,Count
From rank
Where rank = 1;

--6. Which item was purchased first by the customer after they became a member?
With Rank as (
select 
	s.customer_id,
	m.product_name,
	s.order_date,
	Dense_rank()OVER (Partition by s.customer_id order by s.order_date) as Rank
from sales s
join menu m
on s.product_id = m.product_id
join members me
on s.customer_id = me.customer_id
where s.order_date >= me.join_date	
)
select customer_id, product_name, order_date
from Rank
where Rank = 1;

--7. Which item was purchased just before the customer became a member?
With Rank as (
select 
	s.customer_id,
	m.product_name,
	s.order_date,
	Dense_rank()OVER (Partition by s.customer_id order by s.order_date) as Rank
from sales s
join menu m
on s.product_id = m.product_id
join members me
on s.customer_id = me.customer_id
where s.order_date < me.join_date	
)
select customer_id, product_name, order_date
from Rank
where Rank = 1;

--8. What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(s.product_id) as Items, sum(m.price) as total_sales
from sales s
join menu m
on s.product_id = m.product_id
join members ME
on s.customer_id = ME.customer_id
where s.order_date < ME.join_date
group by s.customer_id;



--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

With Points as
(
Select *, Case When product_id = 1 THEN price*20
               Else price*10
			   End as Points
From Menu
)
Select S.customer_id, Sum(P.points) as Points
From Sales S
Join Points p
On p.product_id = S.product_id
Group by S.customer_id;

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
--how many points do customer A and B have at the end of January?


WITH dates AS 
(
   SELECT *, 
   DATEADD(DAY, 6, join_date) AS valid_date, 
   EOMONTH('2021-01-31') AS last_date
   FROM members 
)
Select S.Customer_id, 
       SUM(
	         Case 
		       When m.product_ID = 1 THEN m.price*20
			     When S.order_date between D.join_date and D.valid_date Then m.price*20
			     Else m.price*10
			     END 
		       ) as Points
From Dates D
join Sales S
On D.customer_id = S.customer_id
Join Menu M
On M.product_id = S.product_id
Where S.order_date < d.last_date
Group by S.customer_id;






















































































