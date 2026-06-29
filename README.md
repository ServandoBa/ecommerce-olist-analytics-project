# Olist E-Commerce Analytics Engineering Project

Analytics engineering project built on the **Brazilian E-Commerce Public Dataset by Olist**. The project turns raw marketplace CSV files into documented and tested BigQuery data marts using Python, dbt, and SQL.

The goal is to provide a clean analytical layer for e-commerce reporting across orders, customers, products, sellers, payments, reviews, delivery performance, and geography.

## Business Objective

This project builds a reliable data model that can support common marketplace analytics questions, such as:

- How are GMV, revenue, payments, and order volume trending over time?
- Which products, sellers, categories, and regions drive marketplace performance?
- How does delivery performance affect customer reviews?
- What customer behavior patterns can be analyzed using the correct customer-level identifier?
- How can raw transactional Olist data be modeled into reusable facts and dimensions?

A key modeling rule is that **customer-level analysis must use `customer_unique_id`**. The field `customer_id` is transactional and is tied to an order/customer record.

## Dataset

The project uses the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), a historical marketplace dataset with approximately 100K orders placed between 2016 and 2018.

Main source entities:

| Source table | Rows | Grain |
| --- | ---: | --- |
| `raw_orders` | 99,441 | One row per order |
| `raw_customers` | 99,441 | One row per transactional customer record |
| `raw_order_items` | 112,650 | One row per order item |
| `raw_order_payments` | 103,886 | One row per order payment sequence |
| `raw_order_reviews` | 99,224 | One raw review record |
| `raw_products` | 32,951 | One row per product |
| `raw_sellers` | 3,095 | One row per seller |
| `raw_geolocation` | 1,000,163 | One geolocation observation |
| `raw_product_category_name_translation` | 71 | One row per category translation |

## Tech Stack

- **Python** for raw ingestion into BigQuery
- **Google BigQuery** as the cloud data warehouse
- **dbt Core + dbt-bigquery** for transformations, testing, and documentation
- **SQL** for modeling and business logic
- **dbt-utils** for surrogate keys and date spine utilities
- **Git / GitHub** for version control and portfolio presentation

## Architecture

```mermaid
flowchart LR
    CSV["Olist CSV files"] --> RAW["BigQuery Raw"]
    RAW --> STG["dbt Staging - views"]
    STG --> INT["dbt Intermediate - ephemeral"]
    INT --> MARTS["dbt Marts - tables"]
    MARTS --> DOCS["dbt Docs and Tests"]
```

The current dbt configuration materializes:

- Staging models as BigQuery views in `staging_olist_ecomm`
- Intermediate models as ephemeral models
- Mart models as BigQuery tables in `marts_olist_ecomm`

## Pipeline Layers

### 1. Raw Ingestion

The `Ingestion/` folder contains a Python notebook that loads the Olist CSV files into BigQuery raw tables. Each raw table includes a `loaded_ts_utc` audit timestamp and the ingestion flow validates loaded row counts against the source CSV files.

Raw data is defined in dbt through `models/staging/sources.yaml`.

### 2. Staging

The staging layer creates one model per raw source. These models standardize source data for downstream use through:

- Column selection and renaming
- Type casting and light cleanup
- Surrogate key generation for composite grains
- Source-aligned tests and documentation

Examples include `stg_orders`, `stg_customers`, `stg_order_items`, `stg_order_payments`, `stg_order_reviews`, `stg_products`, `stg_sellers`, and `stg_geolocation`.

### 3. Intermediate

The intermediate layer applies business logic and prepares analytical entities. It is materialized as ephemeral dbt models.

Implemented intermediate logic includes:

- Customer identity resolution using `customer_unique_id`
- Order amount and payment reconciliation metrics
- Fulfillment and delivery timing calculations
- Review deduplication and review timing metrics
- Product enrichment with category, weight, and dimensional attributes
- Geolocation centroid generation by ZIP code prefix

### 4. Data Marts

The Mart layer exposes fact and dimension tables designed for analysis and BI consumption.

Dimensions:

| Model | Grain | Purpose |
| --- | --- | --- |
| `dim_customers` | `customer_unique_id` | Customer identity, location, order history, recency, and repeat behavior |
| `dim_products` | `product_id` | Product categories, content attributes, weights, dimensions, and volume metrics |
| `dim_sellers` | `seller_id` | Seller identity and location attributes |
| `dim_geography` | ZIP code prefix | Latitude/longitude centroids and modal city/state |
| `dim_date` | Calendar day | Calendar attributes for date-based reporting |

Facts:

| Model | Grain | Purpose |
| --- | --- | --- |
| `fct_orders` | One row per order | Order lifecycle, revenue, payment reconciliation, delivery metrics, and review timing |
| `fct_order_items` | One row per order item | Product, seller, item price, freight, and item revenue analysis |
| `fct_payments` | One row per payment sequence | Payment method, installments, and payment amount analysis |
| `fct_reviews` | Deduplicated review/order grain | Review scores, score segments, comments, and response timing |

## Data Quality and Documentation

The project includes dbt tests and schema documentation across staging and mart models.

Implemented tests include:

- `unique` and `not_null` checks for primary keys and required fields
- `relationships` tests for foreign key integrity
- `accepted_values` tests for controlled categorical fields
- `dbt_utils.unique_combination_of_columns` for composite grains

Mart documentation is maintained in `models/marts/schema.yml`, including model-level descriptions, column descriptions, and data tests. Additional modeling notes and KPI definitions are available in `docs/data_model.md`.

Known data quirks are handled in the model design rather than hidden, including duplicate raw review records, non-unique geolocation ZIP prefixes, products without categories, and orders without items or payments.

## Current Project Status

Completed:

- Raw ingestion from the 9 Olist source files into BigQuery
- dbt source definitions for the raw layer
- Staging models with tests and documentation
- Intermediate models for enrichment and business logic
- Data mart dimensions and facts
- Mart-level documentation and relationship tests
- Custom schema naming macro for `*_olist_ecomm` BigQuery datasets
- Successful controlled dbt build on the `dev` target

Not currently implemented:

- Airflow orchestration
- BI dashboards
- ML feature layer or predictive models
- Incremental fact models with partitioning and clustering

## How to Run Locally

Install dependencies:

```bash
dbt deps
```

Validate the dbt project and connection:

```bash
dbt debug
dbt parse
dbt compile
```

Build and test the pipeline with the configured target:

```bash
dbt build --target dev
```

Generate dbt documentation:

```bash
dbt docs generate
```

This project requires a valid dbt BigQuery profile and access to the configured BigQuery project and raw dataset.

## Repository Structure

```text
ecomm_analytics_project/
|-- Ingestion/              # Python notebook and ingestion configuration
|-- docs/                   # Data model notes and KPI definitions
|-- macros/                 # dbt macros, including schema naming logic
|-- models/
|   |-- staging/            # Source-aligned cleaning and standardization models
|   |-- intermediate/       # Business logic and enrichment models
|   |-- marts/              # Analytics-ready facts, dimensions, docs, and tests
|-- seeds/                  # Reserved for dbt seeds
|-- dbt_project.yml         # dbt project configuration
|-- packages.yml            # dbt package dependencies
|-- README.md
```

## Notes and Limitations

- The Olist dataset is historical and static, so time-based trends reflect the dataset period rather than live marketplace activity.
- `customer_unique_id` is the correct key for customer-level analytics; `customer_id` is transactional.
- Geolocation records are not unique by ZIP prefix, so the model aggregates centroids for geographic analysis.
- Raw review data contains duplicates by design; the mart layer exposes deduplicated review records for analysis.

## Covered Project Phases

Current phases already covered in this repository:

- [x] Raw ingestion zone: Python-based loading of the 9 Olist source files into BigQuery raw tables with `loaded_ts_utc` audit metadata.
- [x] Raw source documentation: dbt source definitions and raw table metadata in `models/staging/sources.yaml`.
- [x] Staging zone: source-aligned dbt views for cleaning, typing, renaming, surrogate keys, and basic tests.
- [x] Intermediate zone: ephemeral dbt models for joins, enrichment, deduplication, customer identity logic, geolocation centroids, and order metrics.
- [x] Data mart zone: analytics-ready fact and dimension tables for customers, products, sellers, geography, dates, orders, order items, payments, and reviews.
- [x] Testing and documentation: dbt schema tests, relationship tests, model descriptions, column descriptions, and generated documentation support.
- [x] Deployment validation: controlled dbt build on the `dev` target using the `*_olist_ecomm` schema naming convention.

## Next Steps

Potential future enhancements:

- Add orchestration with Airflow or a similar scheduler
- Add incremental strategies, partitioning, and clustering for larger-scale fact tables
- Build BI dashboards on top of the mart layer
- Add a feature layer for machine learning use cases
- Add CI checks for dbt parse, compile, and tests