-- ============================================================================
-- 00_SETUP.SQL
-- Purpose: Initial database setup and data loading for Snowflake MCP Server
-- Author: Generated for Snowflake MCP Server
-- Date: 2025-10-03
-- ============================================================================
-- This script creates the foundational database, schema, warehouse, and
-- loads sample financial services data from AWS S3.
-- ============================================================================

-- ============================================================================
-- STEP 1: Create Schema and Warehouse in MCP Database
-- ============================================================================
-- Note: MCP database already exists (created for MCP servers)
CREATE SCHEMA IF NOT EXISTS MCP.data;
CREATE WAREHOUSE IF NOT EXISTS mcp_wh 
    WAREHOUSE_SIZE = small
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Warehouse for MCP Server operations';

USE DATABASE MCP;
USE SCHEMA data;
USE WAREHOUSE mcp_wh;

-- ============================================================================
-- STEP 2: Create File Format for CSV Loading
-- ============================================================================
CREATE OR REPLACE FILE FORMAT csv_format  
    SKIP_HEADER = 1  
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'  
    TYPE = 'CSV';

-- ============================================================================
-- STEP 3: Create Dimension Tables
-- ============================================================================

-- CUSTOMERS DIMENSION
CREATE OR REPLACE TABLE dim_customers (
    customer_id VARCHAR(10) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    date_of_birth DATE,
    ssn_hash VARCHAR(32),
    address VARCHAR(200),
    city VARCHAR(50),
    state VARCHAR(2),
    zip_code VARCHAR(10),
    region VARCHAR(20),
    customer_segment VARCHAR(20),
    credit_score NUMBER(3,0),
    annual_income NUMBER(10,2),
    net_worth NUMBER(12,2),
    join_date DATE,
    status VARCHAR(20),
    acquisition_channel VARCHAR(30),
    lifetime_value NUMBER(10,2),
    risk_profile VARCHAR(10),
    CONSTRAINT uk_customers_email UNIQUE (email),
    CONSTRAINT pk_customers PRIMARY KEY (customer_id)
);

-- CAMPAIGNS DIMENSION
CREATE OR REPLACE TABLE dim_campaigns (
    campaign_id VARCHAR(10) NOT NULL,
    campaign_name VARCHAR(200) NOT NULL,
    campaign_type VARCHAR(20),
    objective VARCHAR(20),
    product_promoted VARCHAR(8),
    start_date DATE,
    end_date DATE,
    budget NUMBER(12,2),
    actual_spend NUMBER(12,2),
    target_audience VARCHAR(20),
    target_region VARCHAR(20),
    impressions NUMBER(10,0),
    clicks NUMBER(8,0),
    conversions NUMBER(8,0),
    revenue_generated NUMBER(12,2),
    roi NUMBER(8,2),
    status VARCHAR(20),
    CONSTRAINT pk_campaigns PRIMARY KEY (campaign_id)
);

-- ============================================================================
-- STEP 4: Create Fact Tables
-- ============================================================================

-- MARKETING RESPONSES FACT
CREATE OR REPLACE TABLE fact_marketing_responses (
    response_id VARCHAR(12) NOT NULL,
    customer_id VARCHAR(10) NOT NULL,
    campaign_id VARCHAR(10) NOT NULL,
    contacted_date DATE NOT NULL,
    geo_id VARCHAR(8),
    response_type VARCHAR(20),
    conversion_value NUMBER(10,2) DEFAULT 0,
    channel_used VARCHAR(20),
    engagement_score NUMBER(3,0),
    CONSTRAINT pk_marketing_responses PRIMARY KEY (response_id),
    CONSTRAINT fk_mkt_customer FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    CONSTRAINT fk_mkt_campaign FOREIGN KEY (campaign_id) REFERENCES dim_campaigns(campaign_id)
);

-- RISK ASSESSMENTS FACT
CREATE OR REPLACE TABLE fact_risk_assessments (
    assessment_id VARCHAR(10) NOT NULL,
    customer_id VARCHAR(10) NOT NULL,
    assessment_date DATE NOT NULL,
    credit_risk_score NUMBER(5,2),
    fraud_risk_score NUMBER(5,2),
    aml_risk_score NUMBER(5,2),
    overall_risk_rating VARCHAR(15),
    risk_factors VARCHAR(500),
    review_required NUMBER(1,0) DEFAULT 0,
    last_review_date DATE,
    next_review_date DATE,
    CONSTRAINT pk_risk_assessments PRIMARY KEY (assessment_id),
    CONSTRAINT fk_risk_customer FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id)
);

-- TRANSACTIONS FACT
CREATE OR REPLACE TABLE fact_transactions (
    transaction_id VARCHAR(16777216),
    account_id VARCHAR(16777216),
    customer_id VARCHAR(16777216),
    transaction_date TIMESTAMP_NTZ(9),
    transaction_type VARCHAR(16777216),
    amount NUMBER(38,2),
    balance_after NUMBER(38,2),
    merchant_name VARCHAR(16777216),
    merchant_category VARCHAR(16777216),
    channel VARCHAR(16777216),
    location VARCHAR(16777216),
    description VARCHAR(16777216),
    is_flagged NUMBER(38,0),
    fraud_score NUMBER(38,2)
);

-- SUPPORT TICKETS FACT
CREATE OR REPLACE TABLE fact_support_tickets (
    ticket_id VARCHAR(11) NOT NULL,
    customer_id VARCHAR(10) NOT NULL,
    account_id VARCHAR(10),
    created_date DATE NOT NULL,
    geo_id VARCHAR(8),
    category VARCHAR(30),
    subcategory VARCHAR(50),
    priority VARCHAR(10),
    channel VARCHAR(20),
    subject VARCHAR(500),
    description VARCHAR(1000),
    status VARCHAR(20),
    assigned_agent VARCHAR(8),
    resolution_date DATE,
    resolution_time_hours NUMBER(8,2),
    satisfaction_score NUMBER(1,0),
    first_response_time_minutes NUMBER(8,2),
    CONSTRAINT pk_support_tickets PRIMARY KEY (ticket_id),
    CONSTRAINT fk_support_customer FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id)
);

-- ============================================================================
-- STEP 5: Create Stages and Load Data from S3
-- ============================================================================

-- Load Customers
CREATE OR REPLACE STAGE customers_stage  
    FILE_FORMAT = csv_format  
    URL = 's3://sfquickstarts/sfguide-getting-started-with-snowflake-mcp-server/customers/';

COPY INTO dim_customers FROM @customers_stage;

-- Load Campaigns
CREATE OR REPLACE STAGE campaigns_stage  
    FILE_FORMAT = csv_format  
    URL = 's3://sfquickstarts/sfguide-getting-started-with-snowflake-mcp-server/campaigns/';

COPY INTO dim_campaigns FROM @campaigns_stage;

-- Load Marketing Responses
CREATE OR REPLACE STAGE marketing_stage  
    FILE_FORMAT = csv_format  
    URL = 's3://sfquickstarts/sfguide-getting-started-with-snowflake-mcp-server/marketing/';

COPY INTO fact_marketing_responses FROM @marketing_stage;

-- Load Risk Assessments
CREATE OR REPLACE STAGE risk_assessments_stage  
    FILE_FORMAT = csv_format  
    URL = 's3://sfquickstarts/sfguide-getting-started-with-snowflake-mcp-server/risk_assessment/';

COPY INTO fact_risk_assessments FROM @risk_assessments_stage;

-- Load Transactions
CREATE OR REPLACE STAGE transactions_stage
    FILE_FORMAT = csv_format
    URL = 's3://sfquickstarts/sfguide-getting-started-with-snowflake-mcp-server/transactions/';

COPY INTO fact_transactions FROM @transactions_stage;

-- Load Support Tickets
CREATE OR REPLACE STAGE support_stage
    FILE_FORMAT = csv_format
    URL = 's3://sfquickstarts/sfguide-getting-started-with-snowflake-mcp-server/support/';

COPY INTO fact_support_tickets FROM @support_stage;

-- ============================================================================
-- STEP 6: Create Stage for Semantic Models
-- ============================================================================
CREATE OR REPLACE STAGE semantic_models 
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE') 
    DIRECTORY = (ENABLE = TRUE);

-- ============================================================================
-- STEP 7: Enable Cross-Region Inference for Cortex
-- ============================================================================
ALTER ACCOUNT SET cortex_enabled_cross_region = 'any_region';

-- ============================================================================
-- STEP 8: Verify Data Load
-- ============================================================================
SELECT 'Data Load Summary' AS info;
SELECT 'Customers loaded:' AS table_name, COUNT(*) AS row_count FROM dim_customers
UNION ALL
SELECT 'Campaigns loaded:', COUNT(*) FROM dim_campaigns
UNION ALL
SELECT 'Marketing responses loaded:', COUNT(*) FROM fact_marketing_responses
UNION ALL
SELECT 'Risk assessments loaded:', COUNT(*) FROM fact_risk_assessments
UNION ALL
SELECT 'Transactions loaded:', COUNT(*) FROM fact_transactions
UNION ALL
SELECT 'Support tickets loaded:', COUNT(*) FROM fact_support_tickets;

SELECT '✅ Setup complete! Database and tables created successfully.' AS status;
SELECT 'ℹ️  Database: MCP' AS info;
SELECT 'ℹ️  Schema: data' AS info;
SELECT 'ℹ️  Warehouse: mcp_wh' AS info;
SELECT '' AS blank;
SELECT '📋 NEXT STEPS:' AS next_steps;
SELECT '1. Run 01_create_cortex_search.sql to create search services' AS step;
SELECT '2. Upload 02_create_semantic_model.yaml to @semantic_models stage' AS step;
SELECT '3. Run 03_create_cortex_analyst.sql to create analyst service' AS step;
SELECT '4. Run 04_create_mcp_server.sql to create the MCP server' AS step;

SHOW MCP SERVERS;