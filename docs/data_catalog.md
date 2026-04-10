This document serves as a comprehensive Data Dictionary for the Gold Layer views. It provides Data Analysts and BI Developers with clear definitions of the customer, product, and sales metrics required for building accurate dashboards
### 1. View: `gold.dim_customers`
**Description:** Customer dimension table containing consolidated and cleansed demographic details for all customers.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `customer_key` | INT | Surrogate key uniquely identifying each customer record in the dimension table. |
| `customer_id` | INT | Original Business Key/ID from the source CRM system. |
| `customer_number` | NVARCHAR | Alternate unique customer identifier or account number (e.g., AW00011000). |
| `first_name` | NVARCHAR | Customer's first name. |
| `last_name` | NVARCHAR | Customer's last name. |
| `country` | NVARCHAR | Standardized country of residence for the customer. |
| `gender` | NVARCHAR | Customer's gender (e.g., Male, Female). |
| `marital_status` | NVARCHAR | Customer's marital status (n/a, Married, Single). |
| `birthdate` | DATE | Customer's date of birth. |
| `create_date` | DATETIME | Timestamp indicating when the record was inserted into the data warehouse. |

---

### 2. View: `gold.dim_products`
**Description:** Product dimension table containing details about products, their categories, and maintenance status.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `product_key` | INT | Surrogate key uniquely identifying each product in the dimension table. |
| `product_id` | INT | Original Business Key/ID from the source CRM system. |
| `product_number` | NVARCHAR | Product SKU or unique code (e.g., FR-R92B-58). |
| `product_name` | NVARCHAR | Full descriptive name of the product. |
| `category_id` | NVARCHAR | Category code linked to the product (e.g., CO_RF). |
| `category` | NVARCHAR | Main product category name (e.g., Components, Bikes). |
| `subcategory` | NVARCHAR | Product subcategory name (e.g., Road Frames, Mountain Bikes). |
| `maintenance` | NVARCHAR | Indicator if the product requires maintenance (n/a, Yes, No). |
| `cost` | INT | Standard cost of the product. |
| `product_line` | NVARCHAR | Product line classification (e.g., Road, Mountain). |
| `start_date` | DATE | The effective start date for this product record, used for tracking historical changes. |

---

### 3. View: `gold.fact_sales`
**Description:** Sales fact table containing transactional metrics and foreign keys linking to the dimension tables.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `order_number` | NVARCHAR | Degenerate dimension representing the unique transactional order number (e.g., SO56591). |
| `product_key` | INT | Foreign key linking to `dim_products` to identify the item sold. |
| `customer_key` | INT | Foreign key linking to `dim_customers` to identify the buyer. |
| `order_date` | DATE | The date the sales order was officially placed. |
| `ship_date` | DATE | The date the order was shipped to the customer. |
| `due_date` | DATE | The date by which the order delivery is due. |
| `sales_amount` | INT | Total sales revenue for the transaction line item (Calculated: Quantity * Price). |
| `quantity` | INT | The number of product units purchased in the transaction. |
| `price` | INT | The selling price per single unit of the product. |
