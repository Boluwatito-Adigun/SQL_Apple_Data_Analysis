-- 1.Find each country and number of stores

SELECT 
    count(store_id) AS total_stores,
    country
FROM stores
GROUP BY 2
ORDER BY 1 DESC

--2. What is the total number of units sold by each store?

SELECT 
    count(sale_id) AS total_sales,
    store_id
FROM sales
GROUP BY 2
ORDER BY 1 DESC

--3. How many sales occurred in December 2023?

SELECT 
    count(sale_id) as total_sales
FROM sales
WHERE sale_date BETWEEN '2023-12-1' AND '2023-12-31'

--4. How many stores have never had a warranty claim filed against any of their products?
SELECT 
    COUNT(s.store_id)
FROM warranty w
RIGHT JOIN sales s
    ON s.sale_id = w.sale_id
WHERE w.claim_id IS NULL

--5. What percentage of warranty claims are marked as "Warranty Void"?

SELECT
    repair_status,
    count(repair_status),
    ROUND(count(repair_status)::numeric / (SELECT COUNT(repair_status) FROM warranty)::numeric, 2) * 100 AS percentage
FROM warranty
    GROUP BY 1
ORDER BY 2 DESC

--6. Which store had the highest total units sold in the last year?
SELECT
    st.store_id,
    st.store_name,
    count(s.sale_id)
FROM sales s
JOIN stores st
    ON st.store_id = s.store_id
WHERE sale_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 1, 2
ORDER BY 3 DESC


--7. Count the number of unique products sold in the last year.
SELECT
    product_id,
    count(product_id) AS product_count 
FROM sales
GROUP BY 1
ORDER BY 2 DESC

--8. What is the average price of products in each category?

WITH average_table AS
(
    SELECT 
        category_id,
        sum(price) AS total_price,
        COUNT(category_id) AS product_count 
    FROM products
    GROUP BY 1
    ORDER BY 2 DESC
)

SELECT 
    category_id,
    total_price,
    total_price / product_count AS average_price
FROM average_table


--9. How many warranty claims were filed in 2020?

SELECT 
    count(claim_id)
FROM warranty
WHERE claim_date BETWEEN '2020-01-01' AND '2020-12-31'

--10. Identify each store and best selling day based on highest qty sold