-- This first section is doing some dat aexploration to get a grasp of some of 
-- the data that I will be dealing with this in this project. 

-- This ensures that I am working with the cirrect database.
use  maven_toys;

-- Looking at the number of sales that maven toys has made. 
select count(distinct sale_id) as num_of_orders from sales;


-- These next two queries show the Minimun, Maximum, ad average of the price and costs of the products. 
select 
  MIN(Product_Price) as lowest_sale_price, 
  AVG(Product_Price) as average_sale_price, 
  MAX(Product_Price) as largest_sale_price 
from 
  products;


select 
  MIN(Product_Cost) as lowest_sale_cost, 
  AVG(Product_Cost) as average_sale_cost, 
  MAX(Product_Cost) as largest_sale_cost 
from 
  products;


-- Looking at the distinct store locations

select 
  distinct Store_Location, 
  sales.Store_ID, 
  sales.Product_ID, 
  sales.Date, 
  sales.Sale_ID 
from 
  stores 
  join sales on sales.Store_ID = stores.Store_ID;


-- Now I will do some analysis centered around some of the statistics that were queried above

--This first query will look at how many units were sold by product

select 
  sales.Product_ID as product_id, 
  products.Product_Name as product_name, 
  SUM(sales.Units) as units_sold 
from 
  sales 
  left join products on products.Product_ID = sales.Product_ID 
group by 
  sales.Product_ID, 
  products.Product_Name 
order by 
  units_sold DESC;


-- Now I will look at the revenue and the unsits sold of each product

select 
  products.Product_ID as product_id, 
  products.Product_Name as product_name, 
  products.Product_Price as product_price, 
  SUM(sales.Units) as units_sold, 
  products.Product_Price * SUM(sales.Units) as product_revenue 
from 
  products 
  left join sales on sales.Product_ID = products.Product_ID 
group by 
  products.Product_ID, 
  products.Product_Name, 
  products.Product_Price 
order by 
  product_revenue DESC;

-- even though colorbuds sold more units, lego bricks produced more revenue.


-- Next we will find the cost of each product

select 
  products.Product_ID as product_id, 
  products.Product_Name as product_name, 
  products.Product_Cost as product_cost, 
  SUM(sales.Units) as units_sold, 
  products.Product_Cost * SUM(sales.Units) as cost_per_product 
from 
  products 
  left join sales on sales.Product_ID = products.Product_ID 
group by 
  products.Product_ID, 
  products.Product_Name, 
  products.Product_Cost 
order by 
  product_cost DESC;


--Now that we have the revenue and the cost per product we will find the profit for each product
select 
  products.Product_ID as product_id, 
  products.Product_Name as product_name, 
  products.Product_Cost as product_cost, 
  products.Product_Price as product_price, 
  SUM(sales.Units) as units_sold, 
  products.Product_Cost * SUM(sales.Units) as cost_per_product, 
  products.Product_Price * SUM(sales.Units) as revenue_per_product, 
  products.Product_Price * SUM(sales.Units) - products.Product_Cost * SUM(sales.Units) as profit, 
  round(
	 (
      (products.Product_Price * SUM(sales.Units) - products.Product_Cost * SUM(sales.Units))
	/ (products.Product_Price * SUM(sales.Units))) * 100, 2
	 ) as profit_margin

from products
	left join sales 
	on sales.Product_ID = products.Product_ID
group by 
	products.Product_ID,
	products.Product_Name, 
	products.Product_Cost, 
	products.Product_Price
order by profit DESC;

-- We can see that colorbuds brings in the most profit, but jenga has the highest profit margin.

 

-- This query creates a temp table for revenue per product that I will use in later on to join two temp tables together. 
select 
  products.Product_ID as product_id, 
  products.Product_Name as product_name, 
  products.Product_Price as product_revenue, 
  SUM(sales.Units) as units_sold, 
  products.Product_Price * SUM(sales.Units) as revenue_per_product into #product_revenue
from 
  products 
  left join sales on sales.Product_ID = products.Product_ID 
group by 
  products.Product_ID, 
  products.Product_Name, 
  products.Product_Price;


-- This query creates a temp table for the cost per product
select 
  products.Product_ID as product_id, 
  products.Product_Name as product_name, 
  products.Product_Cost as product_cost, 
  SUM(sales.Units) as units_sold, 
  products.Product_Cost * SUM(sales.Units) as cost_per_product INTO #product_cost
from 
  products 
  left join sales on sales.Product_ID = products.Product_ID 
group by 
  products.Product_ID, 
  products.Product_Name, 
  products.Product_Cost;

-- Now I will join the two temp tables I just created to find the total revenue and costs for the company.

select 
 
  SUM(pr.revenue_per_product) as total_revenue, 
  SUM(pc.cost_per_product) as total_cost, 
  SUM(pr.revenue_per_product) - SUM(pc.cost_per_product) as total_profit 
from 
  #product_revenue pr
  left join #product_cost pc
  on pr.product_id = pc.product_id 

  -- Maven Toys makes about $ 14 Million in revenue, and about $4 Million in total profit. 



-- This query uses a sub query to pull several columns from three different tables, and this pulls the revenue, cost, and profit based on the city. 
select 
  Store_City, 
  product_id, 
  units_sold, 
  SUM(revenue_per_product) AS revenue, 
  SUM(cost_per_product) AS costs, 
  SUM(revenue_per_product) - SUM(cost_per_product) AS profit 
FROM 
  (
    SELECT 
      st.Store_City, 
      s.Product_ID AS product_ID, 
      d.Product_Name AS product_name, 
      d.Product_Price, 
      d.Product_Cost, 
      SUM(s.units) AS Units_sold, 
      d.Product_Price * SUM(s.units) AS revenue_per_product, 
      SUM(s.units) * d.Product_Cost AS cost_per_product 
    FROM 
      sales s 
      INNER JOIN products d ON s.product_ID = d.product_ID 
      INNER JOIN stores st ON st.Store_ID = s.Store_ID 
    GROUP BY 
      st.Store_City, 
      s.Product_ID, 
      d.Product_Name, 
      d.Product_Price, 
      d.Product_Cost
  ) as revenue_and_cost 
group by 
  Store_City, 
  units_sold, 
  product_id 
order by 
  profit DESC;

-- the results seem to show that thecities with more revenue have the higher profits.

-- This query uses a sub query to pull several columns from three different tables, and this pulls the revenue, cost, and profit based on the store location.
select 
  Store_Location, 
  Store_ID, 
  product_category, 
  SUM(revenue_per_product) AS revenue, 
  SUM(cost_per_product) AS costs, 
  SUM(revenue_per_product) - SUM(cost_per_product) AS profit 
FROM 
  (
    SELECT 
      st.Store_Location, 
      st.store_id, 
      s.Product_ID AS product_ID, 
      d.Product_Name AS product_name, 
      d.Product_Category as product_category, 
      d.Product_Price, 
      d.Product_Cost, 
      SUM(s.units) AS Units_sold, 
      d.Product_Price * SUM(s.units) AS revenue_per_product, 
      SUM(s.units) * d.Product_Cost AS cost_per_product 
    FROM 
      sales s 
      INNER JOIN products d ON s.product_ID = d.product_ID 
      INNER JOIN stores st ON st.Store_ID = s.Store_ID 
    GROUP BY 
      st.Store_Location, 
      st.store_id, 
      s.Product_ID, 
      d.Product_Name, 
      d.Product_Category, 
      d.Product_Price, 
      d.Product_Cost
  ) as revenue_and_cost 
group by 
  Store_Location, 
  store_id, 
  product_category 
order by 
  profit DESC;
	
	-----
	
SELECT 
  Store_Location, 
  SUM(revenue_per_product) AS revenue, 
  SUM(cost_per_product) AS costs, 
  SUM(revenue_per_product) - SUM(cost_per_product) AS profit, 
  (
    SUM(revenue_per_product) - SUM(cost_per_product)
  ) / SUM(revenue_per_product) AS profit_percentage 
FROM 
  (
    SELECT 
      st.Store_Location, 
      s.Product_ID AS product_ID, 
      d.Product_Name AS name, 
      d.Product_Price, 
      d.Product_Cost, 
      SUM(s.units) AS Units_sold, 
      d.Product_Price * SUM(s.units) AS revenue_per_product, 
      SUM(s.units) * d.Product_Cost AS cost_per_product 
    FROM 
      sales s 
      INNER JOIN products d ON s.product_ID = d.product_ID 
      INNER JOIN stores st ON st.Store_ID = s.Store_ID 
    GROUP BY 
      st.Store_Location, 
      s.Product_ID, 
      d.Product_Name, 
      d.Product_Price, 
      d.Product_Cost
  ) AS revenue_and_costs 
GROUP BY 
  Store_Location 
ORDER BY 
  profit_percentage DESC


-- this next query looks at the revenue based on the categories of the products. 

select distinct products.Product_Category from products;

select 
  year, 

  SUM(distinct case when Product_Category = 'Art & Crafts' then revenue_per_product else null end)	AS arts_crafts_revenue, 
  SUM(distinct case when Product_Category = 'Electronics' then revenue_per_product else null end)	AS electronics_revenue, 
  SUM(distinct case when Product_Category = 'Games' then revenue_per_product else null end)		AS games_revenue, 
  SUM(distinct case when Product_Category = 'Sports & Outdoors' then revenue_per_product else null end)		AS sports_outdoors_revenue, 
  SUM(distinct case when Product_Category = 'Toys' then revenue_per_product else null end)	 AS toys_revenue 
from
  (
    select 
      year(sales.date) as year, 
      products.Product_Category as product_category, 
      products.Product_ID as product_id, 
      products.Product_Name as product_name, 
      products.Product_Price as product_revenue, 
      products.Product_Cost as product_cost, 
      SUM(sales.Units) as units_sold, 
      products.Product_Price * SUM(sales.Units) as revenue_per_product, 
      products.Product_Cost * SUM(sales.Units) as cost_per_product 
    from 
      products 
      left join sales on sales.Product_ID = products.Product_ID 
    group by 
      year(sales.date), 
      products.Product_Category, 
      products.Product_ID, 
      products.Product_Name, 
      products.Product_Price, 
      products.Product_Cost
  ) as revenue_per_product_category 
group by 
  year

 
order by 
  year;

  -- Looking at the results of this query we can see that the only categiry that made more revenue in 2018 than in 2017 was arts and crafts. 
  -- Taking a deeper dive into the products in each category might give some insight as to why all the other categories saw a drop in revenue. 



  select 
  year,  
  SUM(
    distinct case when Product_Category = 'Art & Crafts' then cost_per_product else null end
  ) as arts_crafts_cost, 
  SUM(
    distinct case when Product_Category = 'Electronics' then cost_per_product else null end
  ) as electronics_cost, 
  SUM(
    distinct case when Product_Category = 'Games' then cost_per_product else null end
  ) as games_cost, 
  SUM(
    distinct case when Product_Category = 'Sports & Outdoors' then cost_per_product else null end
  ) as sports_outdoors_cost, 
  SUM(
    distinct case when Product_Category = 'Toys' then cost_per_product else null end
  ) as toys_cost 
from 
  (
    select 
      year(sales.date) as year, 
      products.Product_Category as product_category, 
      products.Product_ID as product_id, 
      products.Product_Name as product_name, 
      products.Product_Price as product_revenue, 
      products.Product_Cost as product_cost, 
      SUM(sales.Units) as units_sold, 
      products.Product_Price * SUM(sales.Units) as revenue_per_product, 
      products.Product_Cost * SUM(sales.Units) as cost_per_product 
    from 
      products 
      left join sales on sales.Product_ID = products.Product_ID 
    group by 
      year(sales.date), 
      products.Product_Category, 
      products.Product_ID, 
      products.Product_Name, 
      products.Product_Price, 
      products.Product_Cost
  ) as cost_per_product_category 
group by 
  year
order by 
  year;

  -- The cost for all categories went down except for arts and crafts. This may have something to do with why the revenue for the arts anbd crafts went up also. 




	-- The last query I will do total inventory cost grouped by product category

select 
  SUM(inventory_cost_per_product) as total_inventory_cost, 
  SUM(
    distinct case when Product_Category = 'Art & Crafts' then inventory_cost_per_product else null end
  ) as arts_crafts_inventory, 
  SUM(
    distinct case when Product_Category = 'Electronics' then inventory_cost_per_product else null end
  ) as electronics_inventory, 
  SUM(
    distinct case when Product_Category = 'Games' then inventory_cost_per_product else null end
  ) as games_inventory, 
  SUM(
    distinct case when Product_Category = 'Sports & Outdoors' then inventory_cost_per_product else null end
  ) as sports_outdoors_inventory, 
  SUM(
    distinct case when Product_Category = 'Toys' then inventory_cost_per_product else null end
  ) as toys_inventory 
from 
  (
    select 
      products.Product_ID as product_id, 
      products.Product_Name as product_name, 
      products.Product_Category as product_category, 
      products.Product_Cost as product_cost, 
      SUM(inventory.Stock_On_Hand) * products.Product_Cost as inventory_cost_per_product 
    from 
      products 
      left join inventory on inventory.Product_ID = products.Product_ID 
    group by 
      products.Product_ID, 
      products.Product_Name, 
      products.Product_Category, 
      products.Product_Cost
  ) as cost_of_inventory;

  -- The total invenroty cost of all product categories is abouy $300,000. Looking at the inventory costs a little deeper may lead to knowing which products are yielding the least amount of profit for the company.


	
	