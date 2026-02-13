-- 1.Find each country and number of stores

SELECT 
    count(store_id) AS total_stores,
    country
FROM stores
GROUP BY 2
ORDER BY 1 DESC

--2. What is the total number of units sold by each store?

SELECT 
    sum(quantity) AS total_sales,
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
SELECT DISTINCT s.store_id
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
    SUM(quantity)
FROM sales s
JOIN stores st
    ON st.store_id = s.store_id
WHERE sale_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 1, 2
ORDER BY 3 DESC


--7. Count the number of unique products sold in the last year.
SELECT
    COUNT(DISTINCT product_id)
FROM sales
WHERE sale_date BETWEEN '2023-01-01' AND '2023-12-31'

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

WITH best_selling_day AS 
(
    SELECT
        store_id,
        TO_CHAR(sale_date, 'Day') AS day,
        sum(quantity) AS total_sales,
        dense_rank() OVER(PARTITION BY store_id ORDER BY sum(quantity) DESC) AS rank
    FROM sales
    GROUP BY 
        1, 2
    ORDER BY 
        1 DESC,
        3 DESC
)

SELECT
    store_id,
    day,
    total_sales
FROM best_selling_day
WHERE rank = 1
ORDER BY total_sales DESC

--11. Identify least selling product of each country for each year based on total unit sold
WITH least_selling_pdt AS 
(
    SELECT
        st.country AS country,
        pr.product_name AS product_name,
        Extract (Year FROM sale_date) AS Year,
        sum(quantity) AS total_unit_sold,
        dense_rank() OVER(PARTITION BY country, Extract (Year FROM sale_date) ORDER BY sum(quantity)) AS rank
    FROM sales s
    JOIN stores st
        ON st.store_id = s.store_id
    JOIN products pr
        ON s.product_id = pr.product_id
    GROUP BY 
        product_name, Year, country
    ORDER BY 
        country,
        Year
)
SELECT *
FROM least_selling_pdt
WHERE rank = 1

--12. How many warranty claims were filed within 180 days of a product sale?

SELECT
    count(claim_id) AS number_of_claims
FROM 
    warranty w
JOIN sales s
    ON s.sale_id = w.sale_id
WHERE w.claim_date  - s.sale_date <= 180


--13. How many warranty claims have been filed for products launched in 2023?

SELECT
    count(claim_id) AS number_of_claims
FROM 
    warranty w
JOIN sales s
    ON s.sale_id = w.sale_id
JOIN products pr
    ON pr.product_id = s.product_id
WHERE Extract (Year FROM launch_date) = '2023'


--14. List the months in the last 3 years where sales exceeded 5000 units from usa.
SELECT
        st.country AS country,
        TO_CHAR(sale_date, 'Month') AS Month,
        Extract (Year FROM sale_date) AS Year,
        sum(quantity) AS total_unit_sold
    FROM sales s
    JOIN stores st
        ON st.store_id = s.store_id
    WHERE 
        country = 'USA'
    GROUP BY 
        Year, country, Month
    HAVING 
        sum(quantity) > 5000
    ORDER BY 
        country,
        Month,
        Year


--15. Which product category had the most warranty claims filed in the last 2 years

SELECT
    pr.category_id AS product_category,
    count(claim_id) AS number_of_claims
FROM 
    warranty w
JOIN sales s
    ON s.sale_id = w.sale_id
JOIN products pr
    ON pr.product_id = s.product_id
GROUP BY
    product_category

--16. Determine the percentage chance of receiving claims after each purchase for each country.

SELECT 
    *,
    ROUND(total_claims::numeric / total_sales::numeric * 100, 2) AS chance_of_receiving_claims
FROM
(
SELECT
    st.country,
    count(w.claim_id) AS total_claims,
    count(s.sale_id) AS total_sales
FROM warranty w
RIGHT JOIN sales s 
    ON w.sale_id = s.sale_id
RIGHT JOIN stores st
    ON s.store_id = st.store_id
GROUP BY
    st.country
) AS t1

ORDER BY chance_of_receiving_claims DESC


--17. Analyze each stores year by year growth ratio


WITH revenue AS 
(
    SELECT
        s.store_id,
        Extract (Year FROM s.sale_date) AS Years,
        SUM(s.quantity * pr.price) AS total_revenue
    FROM sales s
    JOIN products pr
        ON pr.product_id = s.product_id
    GROUP BY 
        Years,
        store_id
    ORDER BY 
        store_id,
        Years
),

growth_ratio AS 

(
    SELECT
        store_id,
        Years,
        total_revenue AS current_sales,
        LAG(total_revenue, 1) OVER(PARTITION BY store_id) AS previous_sales
    FROM revenue
)

SELECT
    store_id,
    Years,
    current_sales,
    previous_sales,
    ROUND((current_sales - previous_sales)::numeric / previous_sales::numeric * 100, 2) AS growth_ratio
FROM growth_ratio


/*18. What is the correlation between product price and warranty claims for products sold? (Segment based on diff price)*/


WITH groupings AS 

(
    SELECT  
        claim_id,
        pr.price,
        CASE
            WHEN pr.price < 500 THEN 'Less Expensive'
            WHEN pr.price BETWEEN 500 AND 1000 THEN 'Mid Expensive'
            ELSE 'Highly Expensive'
        END AS price_category
    FROM 
        products pr 
    JOIN sales s
        ON s.product_id = pr.product_id
    JOIN warranty w
        ON w.sale_id = s.sale_id
    GROUP BY 
        pr.price,
        claim_id
) 

SELECT
    price_category,
    count(claim_id) AS count
FROM groupings
GROUP BY 
    price_category
ORDER BY 
    count DESC

/*19. Identify the store with the highest percentage of "Paid Repaired" claims in relation to total
claims filed.*/

WITH t_claims AS 
(
SELECT 
    st.store_name AS store_name,
    count(claim_id) AS total_claims
FROM 
    warranty w
JOIN sales s 
    ON s.sale_id = w.sale_id
JOIN stores st
    ON s.store_id = st.store_id
GROUP BY 
    st.store_name
),

pr_claims AS
(
SELECT 
    st.store_name AS store_name,
    count(claim_id) AS paid_repaired_claims
FROM 
    warranty w
JOIN sales s 
    ON s.sale_id = w.sale_id
JOIN stores st
    ON s.store_id = st.store_id
WHERE repair_status = 'Paid Repaired'
GROUP BY 
    st.store_name
)

SELECT
    prc.store_name,
    total_claims,
    paid_repaired_claims,
    ROUND(paid_repaired_claims::numeric / total_claims::numeric * 100, 2) AS percentage
FROM
    t_claims tc   
JOIN pr_claims prc
    ON tc.store_name = prc.store_name


/*20.Write SQL query to calculate the monthly running total of sales for each store over the past
four years and compare the trends across this period?*/

SELECT 
    st.store_name,
    sum(pr.price * s.quantity) AS total_sales,
    Extract (Year FROM s.sale_date) AS years,
    Extract (Month FROM s.sale_date) AS months
FROM sales s
JOIN stores st
    ON s.store_id = st.store_id
JOIN products pr 
    ON pr.product_id = s.product_id
GROUP BY
    st.store_name,
    months,
    years
ORDER BY 
    st.store_name,
    years,
    months