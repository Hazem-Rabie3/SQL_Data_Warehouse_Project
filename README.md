# SQL Data Warehouse Project

A complete data warehousing solution built with SQL Server, covering everything from raw data ingestion to analytics-ready reporting views. The project follows the Medallion Architecture (Bronze, Silver, Gold) to progressively clean, transform, and structure data from two source systems — CRM and ERP.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Data Sources](#data-sources)
- [Layer Details](#layer-details)
- [Data Model](#data-model)
- [Quality Checks](#quality-checks)
- [How to Run](#how-to-run)
- [Requirements](#requirements)

---

## Project Overview

This project builds a data warehouse from scratch using Microsoft SQL Server. It takes raw CSV exports from a CRM and an ERP system, loads them into a staging area, cleans and standardizes them, and finally produces a star schema ready for business reporting and analysis.

The goal was to practice a full end-to-end data engineering workflow — database setup, ETL design, data quality enforcement, and dimensional modeling — using only T-SQL.

---

## Architecture

The warehouse is organized into three schemas, each representing a layer of data maturity:

```
Source Files (CSV)
      |
      v
  [ Bronze ]  — Raw data, loaded as-is from source files
      |
      v
  [ Silver ]  — Cleaned, standardized, and deduplicated data
      |
      v
  [  Gold  ]  — Business-ready views in a star schema (dim + fact)
```

This is a standard Medallion Architecture pattern. Each layer builds on the previous one, and each has a clear, single responsibility.

---

## Repository Structure

```
SQL_Data_Warehouse_Project/
|
|-- scripts/
|   |-- init_database.sql        # Creates the DataWarehouse database and schemas
|   |-- ddl_bronze.sql           # Creates raw staging tables in the bronze schema
|   |-- ddl_silver.sql           # Creates cleaned tables in the silver schema
|   |-- ddl_gold.sql             # Creates analytical views in the gold schema
|   |-- proc_load_bronze.sql     # Stored procedure to load CSV data into bronze
|   |-- proc_load_silver.sql     # Stored procedure to transform bronze into silver
|
|-- tests/
|   |-- quality_checks_silver.sql  # Data quality checks for the silver layer
|   |-- quality_checks_gold.sql    # Data quality checks for the gold layer
|
|-- docs/
    |-- data_architecture.png      # Diagram of the three-layer architecture
    |-- data_integration.png       # How CRM and ERP sources are mapped together
    |-- sales_mart_star_schema.png # The final star schema used in the gold layer
```

---

## Data Sources

Two source systems feed into this warehouse, both exported as CSV files:

**CRM System** — customer and product master data, plus sales transactions:
- `cust_info.csv` — customer demographics
- `prd_info.csv` — product catalog
- `sales_details.csv` — order-level sales records

**ERP System** — supplementary customer attributes:
- `cust_az12.csv` — customer birthdate and gender
- `loc_a101.csv` — customer country/location
- `px_cat_g1v2.csv` — product category and subcategory

---

## Layer Details

### Bronze — Raw Ingestion

The bronze layer holds raw data exactly as it comes from the source files. No transformations are applied here. The `bronze.load_bronze` stored procedure truncates each table and bulk-inserts from the CSV files.

Tables in this layer:
- `bronze.crm_cust_info`
- `bronze.crm_prd_info`
- `bronze.crm_sales_details`
- `bronze.erp_cust_az12`
- `bronze.erp_loc_a101`
- `bronze.erp_px_cat_g1v2`

### Silver — Cleaning and Standardization

The silver layer applies a series of transformations to make the data consistent and trustworthy. The `silver.load_silver` stored procedure handles all of this. Key transformations include:

- Deduplicating customers by keeping the most recent record per `cst_id`
- Expanding coded values to human-readable labels (e.g. `M` → `Male`, `S` → `Single`)
- Fixing integer-formatted dates (e.g. `20130701`) into proper `DATE` columns
- Recalculating sales amounts where `sales != quantity * price`
- Removing invalid or future birthdates
- Stripping prefixes and special characters from ID fields to enable joins between CRM and ERP
- Deriving product end dates using a `LEAD` window function
- Normalizing country codes (e.g. `US`, `USA` → `United States`)

A `dwh_create_date` audit column is added to every silver table to track when records were loaded.

### Gold — Analytical Views (Star Schema)

The gold layer is a set of SQL views that present the data in a format ready for reporting. No physical tables are created here — everything is a view on top of silver.

The model follows a star schema with two dimensions and one fact table:

- `gold.dim_customers` — one row per customer, joining CRM and ERP data, with a surrogate key
- `gold.dim_products` — one row per current product (historical versions are filtered out), with a surrogate key
- `gold.fact_sales` — one row per sales order line, referencing product and customer dimension keys

---

## Data Model

The gold layer implements a star schema designed for sales analysis:

```
gold.dim_customers           gold.dim_products
+------------------+         +------------------+
| customer_key (PK)|         | product_key (PK) |
| customer_id      |         | product_id       |
| customer_number  |         | product_number   |
| first_name       |         | product_name     |
| last_name        |         | category         |
| country          |         | subcategory      |
| marital_status   |         | maintenance      |
| gender           |         | cost             |
| birthdate        |         | product_line     |
| create_date      |         | start_date       |
+------------------+         +------------------+
         \                          /
          \                        /
           \                      /
            +--------------------+
            |  gold.fact_sales   |
            +--------------------+
            | order_number       |
            | product_key (FK)   |
            | customer_key (FK)  |
            | order_date         |
            | shipping_date      |
            | due_date           |
            | sales_amount       |
            | quantity           |
            | price              |
            +--------------------+
```

---

## Quality Checks

After loading each layer, quality check scripts are provided to validate the output.

**Silver checks** (`quality_checks_silver.sql`) verify:
- No null or duplicate primary keys
- No leading/trailing whitespace in string fields
- No negative or null cost values
- No invalid date formats or illogical date orders (e.g. order date after ship date)
- Sales amounts are consistent with `quantity * price`
- Birthdates fall within a reasonable range

**Gold checks** (`quality_checks_gold.sql`) verify:
- Surrogate keys in `dim_customers` and `dim_products` are unique
- Every row in `fact_sales` has a matching record in both dimension tables (no orphaned keys)

All checks are written to return no rows when the data is clean. Any result set from these queries indicates an issue that needs investigation.

---

## How to Run

Run the scripts in this order:

1. **Initialize the database**
   ```sql
   -- Creates the DataWarehouse database and bronze/silver/gold schemas
   -- WARNING: This drops and recreates the database if it already exists
   EXEC scripts/init_database.sql
   ```

2. **Create table structures**
   ```sql
   EXEC scripts/ddl_bronze.sql
   EXEC scripts/ddl_silver.sql
   EXEC scripts/ddl_gold.sql
   ```

3. **Load the bronze layer**
   ```sql
   EXEC bronze.load_bronze;
   ```

4. **Load the silver layer**
   ```sql
   EXEC silver.load_silver;
   ```

5. **Run quality checks**
   ```sql
   -- Review results from both files. Expect no rows returned.
   EXEC tests/quality_checks_silver.sql
   EXEC tests/quality_checks_gold.sql
   ```

6. **Query the gold layer**
   ```sql
   SELECT * FROM gold.dim_customers;
   SELECT * FROM gold.dim_products;
   SELECT * FROM gold.fact_sales;
   ```

Note: Before running `bronze.load_bronze`, update the file paths inside `proc_load_bronze.sql` to match where your CSV source files are located on disk.

---

## Requirements

- Microsoft SQL Server 2019 or later
- SQL Server Management Studio (SSMS) or any compatible SQL client
- Source CSV files placed in a local directory accessible to the SQL Server service account (required for `BULK INSERT`)
