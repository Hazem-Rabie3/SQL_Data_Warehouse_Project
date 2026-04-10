/*
===============================================================================
Script Name: ddl_gold.sql
===============================================================================
Script Purpose:
    This script creates the views for the 'Gold' layer in the data warehouse.
    The Gold layer represents the presentation layer (Star Schema), consisting 
    of dimension and fact tables ready for business intelligence and reporting.

    Actions Performed:
    - Drops existing views if they exist to ensure a fresh deployment.
    - Creates 'dim_products': Integrates CRM product data with ERP categories,
      filtering for currently active products, and generates surrogate keys.
    - Creates 'dim_customers': Consolidates customer demographic data from CRM 
      and ERP systems, resolving conflicts (e.g., prioritizing CRM gender), 
      and generates surrogate keys.
    - Creates 'fact_sales': Joins sales transactional data with the dimension 
      tables to retrieve surrogate keys for efficient querying and reporting.
===============================================================================
*/

-- ============================================================================
-- View: gold.dim_products
-- ============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT 
    ROW_NUMBER() OVER(ORDER BY prd_start_dt, prd_key) AS product_key,
    prd_id AS product_id,
    prd_key AS product_number,
    prd_nm AS product_name,
    cat_id AS category_id,
    CAT AS category,
    SUBCAT AS subcategory,
    MAINTENANCE AS maintenance,
    prd_cost AS cost,
    prd_line AS product_line,
    prd_start_dt AS start_date
FROM silver.crm_prd_info 
LEFT JOIN silver.erp_PX_CAT_G1V2 
    ON cat_id = ID
WHERE prd_end_dt IS NULL;
GO

-- ============================================================================
-- View: gold.dim_customers
-- ============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER(ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    el.CNTRY AS country,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr  -- CRM is the master for the gender info
        ELSE COALESCE(ec.GEN, 'n/a')
    END AS gender,
    ci.cst_marital_status AS marital_status,
    ec.BDATE AS birthdate,
    ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_CUST_AZ12 ec
    ON ci.cst_key = ec.CID
LEFT JOIN silver.erp_LOC_A101 el
    ON ci.cst_key = el.CID;
GO

-- ============================================================================
-- View: gold.fact_sales
-- ============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT 
    sd.sls_ord_num AS order_number,
    dp.product_key,
    dc.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS ship_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_customers dc
    ON sd.sls_cust_id = dc.customer_id
LEFT JOIN gold.dim_products dp
    ON sd.sls_prd_key = dp.product_number;
GO
