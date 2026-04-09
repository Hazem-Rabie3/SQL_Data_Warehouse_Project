/*
Script Name: load_bronze_procedure.sql
Description: 
    This script creates or alters the 'bronze.load_bronze' stored procedure.
    The procedure performs a "Full Load" (Truncate and Load) for all tables 
    in the Bronze layer using BULK INSERT from CSV source files.
    
    Features:
    - Truncates existing data before loading.
    - Loads data for both CRM and ERP source systems.
    - Tracks and prints the execution time for each table and the total process.
    - Includes TRY...CATCH block for error handling.

	How to use:
		EXEC bronze.load_bronze

*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time datetime, @end_time datetime, @start_bronze datetime, @end_bronze datetime
	set @start_bronze = GETDATE();
	BEGIN TRY
	print '----------------------------------------------------'
	print 'Loading Bronze Layer'
	print '----------------------------------------------------'
	print '----------------- Loading crm Tables: -----------------'

	set @start_time = GETDATE();
	print '>> Truncating Table: bronze.crm_cust_info'
	TRUNCATE TABLE bronze.crm_cust_info;

	print '>> Inserting Data into Table: bronze.crm_cust_info'
	BULK INSERT bronze.crm_cust_info
	FROM "F:\Data Warehouse Project\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_crm\cust_info.csv"
	WITH(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
	);
	/*
	TO check if data loaded well with no errors, This called Full load.
	SELECT * FROM bronze.crm_cust_info;
	SELECT COUNT(*) FROM bronze.crm_cust_info;
	*/
	set @end_time = GETDATE();
	print 'Duration Time: ' + CAST( DATEDIFF(second,@start_time, @end_time) AS nvarchar)+ ' seconds';
	print '-------------------------------'

	set @start_time = GETDATE();
	print '>> Truncating Table: bronze.crm_prd_info' 
	TRUNCATE TABLE bronze.crm_prd_info;

	print '>> Inserting Data into Table: bronze.crm_prd_info'
	BULK INSERT bronze.crm_prd_info
	FROM "F:\Data Warehouse Project\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_crm\prd_info.csv"
	WITH(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
	);
	/* SELECT COUNT(*) FROM bronze.crm_prd_info */
	set @end_time = GETDATE();
	print 'Duration Time: ' + CAST( DATEDIFF(second,@start_time, @end_time) AS nvarchar)+ ' seconds';
	print '-------------------------------'

	set @start_time = GETDATE();
	print '>> Truncating Table: bronze.crm_sales_details'
	TRUNCATE TABLE bronze.crm_sales_details;

	print '>> Inserting Data into Table: bronze.crm_sales_details'
	BULK INSERT bronze.crm_sales_details
	FROM "F:\Data Warehouse Project\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_crm\sales_details.csv"
	WITH(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
	);
	set @end_time = GETDATE();
	print 'Duration Time: ' + CAST( DATEDIFF(second,@start_time, @end_time) AS nvarchar)+ ' seconds';
	print '-------------------------------'

	set @start_time = GETDATE();
	print '----------------- Loading erp Tables: -----------------' 
	print '>> Truncating Table: bronze.erp_CUST_AZ12'
	TRUNCATE TABLE bronze.erp_CUST_AZ12;

	print '>> Inserting Data into Table: bronze.erp_CUST_AZ12'
	BULK INSERT bronze.erp_CUST_AZ12
	FROM "F:\Data Warehouse Project\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_erp\CUST_AZ12.csv"
	WITH(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
	);
	set @end_time = GETDATE();
	print 'Duration Time: ' + CAST( DATEDIFF(second,@start_time, @end_time) AS nvarchar)+ ' seconds';
	print '-------------------------------'

	set @start_time = GETDATE();
	print '>> Truncating Table: bronze.erp_LOC_A101'
	TRUNCATE TABLE bronze.erp_LOC_A101;

	print '>> Inserting Data into Table: bronze.erp_LOC_A101'
	BULK INSERT bronze.erp_LOC_A101
	FROM "F:\Data Warehouse Project\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_erp\LOC_A101.csv"
	WITH(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
	);
	set @end_time =GETDATE();
	print 'Duration Time: ' + CAST( DATEDIFF(second,@start_time, @end_time) AS nvarchar)+ ' seconds';
	print '-------------------------------'

	set @start_time = GETDATE();
	print '>> Truncating Table: bronze.erp_PX_CAT_G1V2'
	TRUNCATE TABLE bronze.erp_PX_CAT_G1V2;

	print '>> Inserting Data into Table: bronze.erp_PX_CAT_G1V2'
	BULK INSERT bronze.erp_PX_CAT_G1V2
	FROM "F:\Data Warehouse Project\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_erp\PX_CAT_G1V2.csv"
	WITH(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
	);
	set @end_time = GETDATE();
	print 'Durtaion Time: ' + CAST( DATEDIFF(second, @start_time, @end_time) AS nvarchar) + ' seconds';

	set @end_bronze = GETDATE();
	print '======================================================='
	print 'Loading is completed successfully'
	print 'Durtaion Of Loading Bronze Layer: ' + CAST( DATEDIFF(second, @start_bronze, @end_bronze) AS nvarchar) + ' seconds';

	END TRY
	BEGIN CATCH
	print '########################################'
	print 'ERROR OCCURED DURING LOADING BRONZE LAYER'
	print 'ERROR Message' + ERROR_MESSAGE();
	print 'ERROR NUMBER' + CAST(ERROR_NUMBER() AS nvarchar);

	END CATCH
END
