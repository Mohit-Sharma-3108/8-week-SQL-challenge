
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
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
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  
-- Case Study Questions
-- Each of the following case study questions can be answered using a single SQL statement:

-- 1.What is the total amount each customer spent at the restaurant?

select s.customer_id,sum(m.price) total_amount_spent
from sales s
join menu m
on s.product_id = m.product_id
group by s.customer_id;

-- 2.How many days has each customer visited the restaurant?

select customer_id,count(distinct order_date) days_visited
from sales
group by customer_id;

-- 3.What was the first item from the menu purchased by each customer?

with cte as(select dt1.customer_id cid,m.product_name item,row_number() over(partition by dt1.customer_id) rn
from (select s.customer_id customer_id,min(s.order_date) first_order
	from sales s
	group by s.customer_id) dt1
join sales s
on s.customer_id = dt1.customer_id and s.order_date = dt1.first_order
join menu m
on s.product_id = m.product_id)

select cid,item
from cte
where rn = 1;

-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_id,m.product_name,count(customer_id) cnt
from sales s
join menu m
on s.product_id = m.product_id
group by s.product_id,m.product_name
order by count(customer_id) desc
limit 1;

-- 5.Which item was the most popular for each customer?


with cte as (select customer_id,product_id,count(*) cnt
from sales
group by customer_id,product_id)

select customer_id,product_name
from cte 
join menu m
on cte.product_id = m.product_id
where (customer_id,cnt) in (select customer_id,max(cnt)
			 from cte
             group by customer_id)
order by customer_id; -- B has 3 itmes that they ordered 2 times each, hence their name gets repeated thrice.



-- 6.Which item was purchased first by the customer after they became a member?

select dt1.cid,menu.product_name
from (select s.customer_id cid,s.product_id pid,row_number() over(partition by s.customer_id order by members.join_date) rn
	from sales s
	join members
	on s.customer_id = members.customer_id
	where s.order_date > members.join_date) dt1
join menu
on dt1.pid = menu.product_id
where dt1.rn = 1;

-- 7.Which item was purchased just before the customer became a member?

select dt1.cid,m.product_name
from (select s.customer_id cid,s.product_id pid,s.order_date order_date,last_value(product_id) over(partition by s.customer_id order by s.order_date rows between unbounded preceding and unbounded following) lv
	from sales s
	join members
	on s.customer_id = members.customer_id
	where s.order_date < members.join_date) dt1
join menu m
on dt1.pid = m.product_id
where dt1.pid = dt1.lv;


-- 8.What is the total items and amount spent for each member before they became a member?

select s.customer_id,sum(menu.price),group_concat(menu.product_name) all_items_ordered
from sales s
join menu 
on s.product_id = menu.product_id
join members
on s.customer_id = members.customer_id
where s.order_date < members.join_date
group by s.customer_id;


-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select s.customer_id,sum(case when menu.product_name like '%sushi%' then menu.price*20
							  else menu.price*10
                              end) points
from sales s
join menu
on s.product_id = menu.product_id
group by s.customer_id;

		
-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select cid,sum(points)
from (select s.customer_id cid,sum(case when menu.product_name like '%sushi%' then menu.price*20
							  else menu.price*10
                              end) points
	from sales s
	join menu
	on s.product_id = menu.product_id
	join members
	on s.customer_id = members.customer_id
	where datediff(order_date,join_date) > 6 or order_date < join_date and order_date like '2021-01-%%'
	group by s.customer_id

	union all

	select s.customer_id cid,sum(price) *20 points
	from sales s
	join menu
	on s.product_id = menu.product_id
	join members
	on s.customer_id = members.customer_id
	where order_date like '2021-01-%%' and datediff(order_date,join_date) between 0 and 6 
	group by s.customer_id) dt1
group by cid;