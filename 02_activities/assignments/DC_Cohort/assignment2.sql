/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */
-- note to self, coalesce looks for NULL automatically 
SELECT 
product_name ||
', '|| COALESCE (product_size,'')||  -- I am replacing product_size NULL with blank
' ('||COALESCE(product_qty_type,'unit') || ')' -- I am replacing NULL with "unit" 
FROM product;


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT 
   customer_id,
   market_date,
   ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date ASC) AS visit_number -- I am essentially using partition to tell it when to start labelling rows again and order to tell it to use which column info to order it 
FROM customer_purchases;

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */
SELECT * FROM -- select all from this nested table, but with "where" only pick visit 1
(
SELECT --subquery (like a "nested" table) 
   customer_id,
   market_date,
   ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS visit_number 
FROM customer_purchases
) 
WHERE visit_number = 1;

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */
SELECT DISTINCT --I kept on running into errors with this code, turns out i just needed distinct, or else I get duplicate entries - distinct collapse entries!
   customer_id,
   product_id,
   COUNT(*) OVER (PARTITION BY product_id, customer_id) AS times_purchased
FROM customer_purchases;


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
--SELECT
  -- COALESCE(NULLIF((SUBSTR(product_name, 1, INSTR(product_name,' -')),''),'NULL') AS product_name_shortened --this one broke my head a little bit... too many nests! and errors!
--FROM product 
--here it is correct with TRIM and better formatting!!!
SELECT
   COALESCE(
   NULLIF(TRIM(SUBSTR(product_name, 1, INSTR(product_name,' -') - 1)), ''),'NULL'
   ) AS product_name_shortened
FROM product;


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
SELECT
   product_size,
   COALESCE(
   NULLIF(TRIM(SUBSTR(product_name, 1, INSTR(product_name,' -') - 1)), ''),'NULL'
   ) AS product_name_shortened
FROM product
WHERE REGEXP_LIKE(product_size,'[0-9]'); --Iused REGEXP_LIKE function here, because its the best one I think I could find to look for numerical digits! 

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
--first query to get sale values grouped by dates
CREATE TEMP TABLE sales_by_date AS
SELECT 
   market_date,
   SUM(sales) AS total_sale
FROM vendor_daily_sales
GROUP BY market_date --need group by! so we get sum for each date, not whole table!

--second query with temp to rank and finding best and worst! 
CREATE TEMP TABLE sales_by_date_ranked3 AS
SELECT
   market_date,
   total_sale,
   RANK() OVER (ORDER BY total_sale DESC) AS RANK_DESC
FROM sales_by_date

--now actually create the table with best and worst! 
-- iended up having to use where to filter, because iwanted to include market date! 
SELECT
   market_date,
   total_sale,
   "Best Day" AS status
FROM sales_by_date_ranked3
WHERE total_sale = (SELECT max(total_sale) FROM sales_by_date_ranked3)

UNION

SELECT
    market_date,
    total_sale,
    "Worst Day" AS status
FROM sales_by_date_ranked3
WHERE total_sale = (SELECT min(total_sale) FROM sales_by_date_ranked3)

--not gonna lie, this was hard !!
/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
--Forgive me for taking a more complicated route

--first I built a cartesian product as a temporary table cross joining each customer to possible vendor items and multiplying that by 5
CREATE TEMP TABLE cartesian_product2 AS
SELECT DISTINCT A.vendor_id, A.product_id, A.original_price,B.customer_id,v.vendor_name
FROM vendor_inventory AS A
JOIN vendor AS v
   ON A.vendor_id = v.vendor_id
CROSS JOIN customer AS B

--Second, I selected from that cartesian temp table and GROUP BY specific products. 
SELECT 
   c.vendor_name,
   p.product_name,
   SUM(c.original_price*5) AS sale_per_customer_product
FROM cartesian_product2 AS c
JOIN product AS p
   ON c.product_id = p.product_id
GROUP BY 
   c.product_id



--INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
CREATE TABLE product_units2 (
   product_name VARCHAR(100),
   product_qty_type VARCHAR(100) DEFAULT 'unit',--I am presuming, you guys wnat every product qty type column to be in "units" 
   snapshot_timestamp TIME
);
/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
INSERT INTO product_units2 (product_name, snapshot_timestamp)
   VALUES('Apple Pie',CURRENT_TIME); --I used current_time, because you said updated time stamp! 



 -- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
DELETE FROM product_units2
   WHERE product_name = 'Apple Pie'; --I used where, so I dont give myself a heart attack :)! 
   


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

--adding that extra column to my new table! 
ALTER TABLE product_units2
ADD current_quantity INT;

--creating a temp table with vendor name in it through join! --Actually. scratch this plan,, i would need to use join here...  i shall do subquery
CREATE TEMP TABLE quantity_latest2 AS
SELECT 
   vi.vendor_id,
   p.product_name,
   vi.product_id,
   vi.quantity,
   vi.market_date AS latest_date
FROM vendor_inventory AS vi
JOIN product AS p
    ON vi.product_id = p.product_id
JOIN (
    SELECT vendor_id, product_id, MAX(market_date) AS latest_date
    FROM vendor_inventory
    GROUP BY vendor_id, product_id
) AS latest
    ON vi.vendor_id = latest.vendor_id
    AND vi.product_id = latest.product_id
    AND vi.market_date = latest.latest_date

--New plan and udpate with correlated subquery, no join required!!!
UPDATE product_units2
SET product_name = (  -- this correlates my temp table with the updating table
   SELECT ql.product_name
   FROM quantity_latest2 AS ql
   WHERE ql.product_id = product_units2.product_id
)
WHERE product_id IN (SELECT product_id FROM quantity_latest2); --this sets conditions to pick rows

--actually... im still confused.... im not sure if this works ???



