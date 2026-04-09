/*
===============================================================================
Stored Procedure: silver.load_silver
===============================================================================
Script Purpose:
    This stored procedure is responsible for executing the ETL (Extract, Transform, Load) 
    process to populate the 'Silver' layer of the data warehouse.
    
    Actions Performed:
    - Truncates existing data in the Silver layer tables to ensure a clean load.
    - Extracts raw data from the 'Bronze' layer.
    - Applies data cleansing, transformation, and standardization rules, including:
        * Deduplication using ROW_NUMBER().
        * Standardizing categorical text fields (e.g., Marital Status, Gender, Country).
        * Validating and converting dates to standard formats.
        * Handling NULLs and recalculating missing/incorrect metrics (e.g., Sales, Price).
    - Tracks and prints the execution duration for each table and the total process.
    - Implements structured error handling (TRY...CATCH) for safe execution.
===============================================================================
How To Use:
EXEC silver.load_silver;
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    BEGIN TRY
        DECLARE @start_time DATETIME, @end_time DATETIME, @start_silver DATETIME, @end_silver DATETIME;
        
        SET @start_silver = GETDATE();
        PRINT '----------------------------------------------------';
        PRINT 'Loading Silver Layer';
        PRINT '----------------------------------------------------';
        
        PRINT '----------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '----------------------------------------------------';
        -- ====================================================================
        -- Loading silver.crm_cust_info
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT 'Truncating silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        
        PRINT 'Inserting Into silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT 
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE 
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                ELSE 'n/a'
            END AS cst_marital_status,
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                ELSE 'n/a'
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT 
                *, 
                ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t 
        WHERE flag_last = 1; 
        
        SET @end_time = GETDATE();
        PRINT 'Duration Time: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
        PRINT '-------------------------------';

        -- ====================================================================
        -- Loading silver.crm_prd_info
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT 'Truncating silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        
        PRINT 'Inserting Into silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line)) 
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n\a'
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(LEAD(prd_start_dt - 1) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) AS DATE) AS prd_end_dt
        FROM bronze.crm_prd_info;
        
        SET @end_time = GETDATE();
        PRINT 'Duration Time: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
        PRINT '-------------------------------';

        -- ====================================================================
        -- Loading silver.crm_sales_details
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT 'Truncating silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        
        PRINT 'Inserting Into silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE 
                WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 OR sls_order_dt < 19000101 OR sls_order_dt > 20500101 THEN NULL
                ELSE CONVERT(DATE, CONVERT(CHAR(8), sls_order_dt))
            END AS sls_order_dt,
            CASE 
                WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 OR sls_ship_dt < 19000101 OR sls_ship_dt > 20500101 THEN NULL
                ELSE CONVERT(DATE, CONVERT(CHAR(8), sls_ship_dt))
            END AS sls_ship_dt,
            CASE 
                WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 OR sls_due_dt < 19000101 OR sls_due_dt > 20500101 THEN NULL
                ELSE CONVERT(DATE, CONVERT(CHAR(8), sls_due_dt))
            END AS sls_due_dt,
            CASE 
                WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != ABS(sls_quantity) * ABS(sls_price) 
                THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,   -- Recalculate sales if it is incorrect or missing
            sls_quantity,
            CASE 
                WHEN sls_price <= 0 OR sls_price IS NULL 
                THEN sls_sales / NULLIF(sls_quantity,0)
                ELSE sls_price
            END AS sls_price    -- Recalculate price if it is invalid
        FROM bronze.crm_sales_details;
        
        SET @end_time = GETDATE();
        PRINT 'Duration Time: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
        PRINT '-------------------------------';

        PRINT '----------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '----------------------------------------------------';
        -- ====================================================================
        -- Loading silver.erp_CUST_AZ12
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT 'Truncating silver.erp_CUST_AZ12';
        TRUNCATE TABLE silver.erp_CUST_AZ12;
        
        PRINT 'Inserting Into silver.erp_CUST_AZ12';
        INSERT INTO silver.erp_CUST_AZ12 (
            CID,
            BDATE,
            GEN
        )
        SELECT 
            CASE 
                WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
                ELSE CID
            END AS CID,
            CASE 
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,
            CASE 
                WHEN gen = UPPER(TRIM('F')) THEN 'Female'
                WHEN gen = UPPER(TRIM('M')) THEN 'Male'
                WHEN gen IS NULL OR gen = '' THEN 'n/a'
                ELSE gen
            END AS gen
        FROM bronze.erp_CUST_AZ12;
        
        SET @end_time = GETDATE();
        PRINT 'Duration Time: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
        PRINT '-------------------------------';

        -- ====================================================================
        -- Loading silver.erp_LOC_A101
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT 'Truncating silver.erp_LOC_A101';
        TRUNCATE TABLE silver.erp_LOC_A101;
        
        PRINT 'Inserting Into silver.erp_LOC_A101';
        INSERT INTO silver.erp_LOC_A101 (
            CID,
            CNTRY
        )
        SELECT 
            REPLACE(CID, '-', '') AS CID,
            CASE 
                WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
                WHEN TRIM(CNTRY) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(CNTRY) IS NULL OR TRIM(CNTRY) = '' THEN 'n/a'
                ELSE TRIM(CNTRY)
            END AS CNTRY
        FROM bronze.erp_LOC_A101;

        SET @end_time = GETDATE();
        PRINT 'Duration Time: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
        PRINT '-------------------------------';

        -- ====================================================================
        -- Loading silver.erp_PX_CAT_G1V2
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT 'Truncating silver.erp_PX_CAT_G1V2';
        TRUNCATE TABLE silver.erp_PX_CAT_G1V2;
        
        PRINT 'Inserting Into silver.erp_PX_CAT_G1V2';
        INSERT INTO silver.erp_PX_CAT_G1V2 (
            ID, 
            CAT, 
            SUBCAT, 
            MAINTENANCE
        )
        SELECT 
            ID,
            CAT,
            SUBCAT,
            MAINTENANCE
        FROM bronze.erp_PX_CAT_G1V2;

        SET @end_time = GETDATE();
        PRINT 'Duration Time: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
        PRINT '-------------------------------';

        -- ====================================================================
        -- Finalizing
        -- ====================================================================
        SET @end_silver = GETDATE();
        PRINT '=======================================================';
        PRINT 'Loading is completed successfully';
        PRINT 'Duration Of Loading Silver Layer: ' + CAST(DATEDIFF(second, @start_silver, @end_silver) AS VARCHAR) + ' seconds';

    END TRY
    BEGIN CATCH
        PRINT '########################################';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT 'ERROR Message: ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    END CATCH
END
