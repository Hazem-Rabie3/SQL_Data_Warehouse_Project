/*
========================================================================================
Quality Checks - Gold Layer
========================================================================================
Script Purpose:
    This script performs extensive data quality checks on the Gold Layer views.
    It ensures that the final Star Schema is structurally sound, logically correct,
    and ready for business intelligence consumption.

Expectation:
    All queries below should return ZERO rows. 
    Any results indicate a potential issue in the underlying data or transformations.
========================================================================================
*/

-- =====================================================================================
-- 1. Checking 'gold.dim_customers'
-- =====================================================================================

-- Uniqueness of Surrogate Key
-- The customer_key must be absolutely unique.
SELECT customer_key, COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1 OR customer_key IS NULL;

-- Uniqueness of Business Key (Integration Check)
-- Ensures the joins with ERP tables didn't cause duplication (Cartesian Product).
SELECT customer_id, COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- =====================================================================================
-- 2. Checking 'gold.dim_products'
-- =====================================================================================

-- Uniqueness of Surrogate Key
SELECT product_key, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1 OR product_key IS NULL;

-- Uniqueness of Business Key
-- Since we filtered for active products (prd_end_dt IS NULL), product_number must be unique.
SELECT product_number, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;

-- Ensure the LEFT JOIN to the ERP Category table successfully matched records.
-- If this returns rows, it means there are category IDs in CRM not present in ERP.
-- We have category in the crm not present in ERP (category_id: CO_PE)
SELECT product_number, category_id, category, subcategory
FROM gold.dim_products
WHERE category IS NULL 
   OR subcategory IS NULL;

   SELECT * FROM gold.dim_products
   SELECT * FROM gold.fact_sales
-- =====================================================================================
-- 3. Checking 'gold.fact_sales'
-- =====================================================================================

-- Integrity - Products (Foreign Key Check)
-- Ensures every product_key in fact_sales exists in dim_products.
SELECT f.order_number, f.product_key
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key -- Note: joined on business key to check mapping
WHERE p.product_key IS NULL;

-- Integrity - Customers (Foreign Key Check)
-- Ensures every customer_key in fact_sales exists in dim_customers.
SELECT f.order_number, f.customer_key
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key -- Note: joined on business key to check mapping
WHERE c.customer_key IS NULL;


-- Measure Validation
-- Final check to ensure calculated metrics aggregated to the Gold layer correctly.
SELECT order_number, sales_amount, quantity, price
FROM gold.fact_sales
WHERE sales_amount != (quantity * price)
   OR sales_amount <= 0;
