/*

Script Name: ddl_bronze.sql
Description: 
    This script creates the bronze tables in bronze schema, 
     dropping existing tables if they already exist.
    
    It includes data from two main source systems:
    1. CRM  - Customers, Products, Sales
    2. ERP  - Customers, Locations, Categories

   The Bronze layer represents raw, unprocessed data ingested directly 
      from the source systems.

*/


CREATE TABLE bronze.crm_cust_info(
cst_id INT,
cst_key nvarchar(50),
cst_firstname nvarchar(50),
cst_lastname nvarchar(50),
cst_material_status nvarchar(20),
cst_gndr nvarchar(20),
cst_create_date datetime
)


CREATE TABLE bronze.crm_prd_info(
prd_id INT,
prd_key nvarchar(50),
prd_nm nvarchar(50),
prd_cost INT,
prd_line nvarchar(20),
prd_start_dt datetime,
prd_end_dt datetime
)

CREATE TABLE bronze.crm_sales_details(
sls_ord_num nvarchar(50),
sls_prd_key nvarchar(50),
sls_cust_id INT,
sls_order_dt INT,
sls_ship_dt INT,
sls_due_dt INT,
sls_sales INT,
sls_quantity INT,
sls_price INT
)

CREATE TABLE bronze.erp_CUST_AZ12(
CID nvarchar(50),
BDATE date,
GEN nvarchar(20)
)

CREATE TABLE bronze.erp_LOC_A101(
CID nvarchar(50),
CNTRY nvarchar(20)
)

CREATE TABLE bronze.erp_PX_CAT_G1V2(
ID nvarchar(50),
CAT nvarchar(50),
SUBCAT nvarchar(50),
MAINTENANCE nvarchar(20)
)
