/*
========================================================================================
Data Quality Assurance - Silver Layer
========================================================================================
Script Purpose:
    This script executes a series of validation rules against the Silver layer tables.
    The primary goal is to ensure the ETL transformations (cleansing, standardizing, 
    and deduplication) were applied successfully.

Validation Categories:
    1. Entity Integrity: Checking for NULL or duplicate Primary Keys.
    2. Format Consistency: Identifying leading/trailing spaces in text columns.
    3. Mathematical Accuracy: Validating derived or calculated metrics (e.g., Sales).
    4. Business Logic: Ensuring chronological date validity and allowed values.
========================================================================================
*/

-- =====================================================================================
-- 1. Table: silver.crm_cust_info
-- =====================================================================================
-- Rule: Primary Key must be unique and NOT NULL
SELECT cst_id, COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Rule: Text columns should not contain leading or trailing spaces
SELECT cst_key, cst_firstname, cst_lastname
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key)
   OR cst_firstname != TRIM(cst_firstname)
   OR cst_lastname != TRIM(cst_lastname);

-- Rule: Categorical values must be standardized
-- Action: Manually review the output to ensure only 'Married', 'Single', 'n/a' and 'Male', 'Female', 'n/a' exist
SELECT DISTINCT cst_marital_status, cst_gndr
FROM silver.crm_cust_info;


-- =====================================================================================
-- 2. Table: silver.crm_prd_info
-- =====================================================================================

-- Rule: Primary Key must be unique and NOT NULL
SELECT prd_id, COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Rule: Text columns should not contain leading or trailing spaces
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Rule: Product cost cannot be negative or NULL
SELECT prd_id, prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Rule: Chronological order of dates (End Date must be >= Start Date)
SELECT prd_id, prd_start_dt, prd_end_dt
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- =====================================================================================
-- 3. Table: silver.crm_sales_details
-- =====================================================================================

-- Rule: Dates must fall within reasonable business boundaries (1900 - 2050)
-- Note: Invalid dates were converted to NULL in the load script, so we check for anomalies.
SELECT sls_ord_num, sls_order_dt, sls_ship_dt, sls_due_dt
FROM silver.crm_sales_details
WHERE YEAR(sls_order_dt) < 1900 OR YEAR(sls_order_dt) > 2050
   OR YEAR(sls_ship_dt) < 1900 OR YEAR(sls_ship_dt) > 2050
   OR YEAR(sls_due_dt) < 1900 OR YEAR(sls_due_dt) > 2050;

-- Rule: Shipping and Due dates cannot precede the Order date
SELECT sls_ord_num, sls_order_dt, sls_ship_dt, sls_due_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Rule: Mathematical validation (Sales = Quantity * Price) and checking for zero/negatives
SELECT sls_ord_num, sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
WHERE sls_sales != (sls_quantity * sls_price)
   OR sls_sales IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL
   OR sls_sales <= 0 
   OR sls_quantity <= 0 
   OR sls_price <= 0;


-- =====================================================================================
-- 4. Table: silver.erp_CUST_AZ12
-- =====================================================================================

-- Rule: Birthdates must be logical (Not in the future)
SELECT CID, BDATE
FROM silver.erp_CUST_AZ12
WHERE  BDATE > GETDATE();

-- Rule: Gender mapping consistency
-- Action: Manually review to ensure only 'Male', 'Female', 'n/a' exist
SELECT DISTINCT GEN
FROM silver.erp_CUST_AZ12;


-- =====================================================================================
-- 5. Table: silver.erp_LOC_A101
-- =====================================================================================

-- Rule: Country mapping consistency
-- Action: Manually review to ensure values like 'DE' or 'USA' are properly mapped to 'Germany', 'United States'
SELECT DISTINCT CNTRY
FROM silver.erp_LOC_A101

-- =====================================================================================
-- 6. Table: silver.erp_PX_CAT_G1V2
-- =====================================================================================

-- Rule: No leading/trailing spaces in categorical data
SELECT ID, CAT, SUBCAT, MAINTENANCE
FROM silver.erp_PX_CAT_G1V2
WHERE CAT != TRIM(CAT) 
   OR SUBCAT != TRIM(SUBCAT) 
   OR MAINTENANCE != TRIM(MAINTENANCE);
