/*
=========================================================================
Create Database And Schemas
=========================================================================
This script creates a new database named 'Datawarehouse' after checking if it already exists.
If the database exists, it is dropped and recreated. 
Additionally, the script set up three schemas within the database: 
'bronze', 'silver' and 'gold'.
*/


use master;
GO
IF EXISTS(SELECT 1 from sys.databases where name = "DataWarehouse")
BEGIN
	ALTER DATABASE Datawarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE:
	DROP DATABASE Datawarehouse;
END;

GO
CREATE DATABASE DataWarehouse;
use DataWarehouse;
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
