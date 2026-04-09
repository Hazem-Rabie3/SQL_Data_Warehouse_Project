/*
===============================================================================
Script Name: ddl_bronze.sql
===============================================================================
Script Purpose:
    This script creates the bronze tables in the 'bronze' schema, 
    dropping existing tables if they already exist.
    
    It includes data from two main source systems:
    1. CRM  - Customers, Products, Sales
    2. ERP  - Customers, Locations, Categories

    The Bronze layer represents raw, unprocessed data ingested directly 
    from the source systems.
===============================================================================
*/

-- ============================================================================
-- Table: bronze.crm_cust_info
-- Description: Stores raw customer information ingested from the CRM system
-- ============================================================================
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;

CREATE TABLE bronze.crm_cust_info (
    cst_id             INT,
    cst_key            NVARCHAR(50),
    cst_firstname      NVARCHAR(50),
    cst_lastname       NVARCHAR(50),
    cst_marital_status NVARCHAR(20),
    cst_gndr           NVARCHAR(20),
    cst_create_date    DATETIME
);

-- ============================================================================
-- Table: bronze.crm_prd_info
-- Description: Stores raw product information ingested from the CRM system
-- ============================================================================
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;

CREATE TABLE bronze.crm_prd_info (
    prd_id             INT,
    prd_key            NVARCHAR(50),
    prd_nm             NVARCHAR(50),
    prd_cost           INT,
    prd_line           NVARCHAR(20),
    prd_start_dt       DATETIME,
    prd_end_dt         DATETIME
);

-- ============================================================================
-- Table: bronze.crm_sales_details
-- Description: Stores raw sales transactions ingested from the CRM system
-- ============================================================================
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num        NVARCHAR(50),
    sls_prd_key        NVARCHAR(50),
    sls_cust_id        INT,
    sls_order_dt       INT,
    sls_ship_dt        INT,
    sls_due_dt         INT,
    sls_sales          INT,
    sls_quantity       INT,
    sls_price          INT
);

-- ============================================================================
-- Table: bronze.erp_CUST_AZ12
-- Description: Stores raw customer demographic data ingested from the ERP system
-- ============================================================================
IF OBJECT_ID('bronze.erp_CUST_AZ12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_CUST_AZ12;

CREATE TABLE bronze.erp_CUST_AZ12 (
    CID                NVARCHAR(50),
    BDATE              DATE,
    GEN                NVARCHAR(20)
);

-- ============================================================================
-- Table: bronze.erp_LOC_A101
-- Description: Stores raw geographical location data ingested from the ERP system
-- ============================================================================
IF OBJECT_ID('bronze.erp_LOC_A101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_LOC_A101;

CREATE TABLE bronze.erp_LOC_A101 (
    CID                NVARCHAR(50),
    CNTRY              NVARCHAR(20)
);

-- ============================================================================
-- Table: bronze.erp_PX_CAT_G1V2
-- Description: Stores raw product category data ingested from the ERP system
-- ============================================================================
IF OBJECT_ID('bronze.erp_PX_CAT_G1V2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_PX_CAT_G1V2;

CREATE TABLE bronze.erp_PX_CAT_G1V2 (
    ID                 NVARCHAR(50),
    CAT                NVARCHAR(50),
    SUBCAT             NVARCHAR(50),
    MAINTENANCE        NVARCHAR(20)
);
