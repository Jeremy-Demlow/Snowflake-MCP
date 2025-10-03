-- ============================================================================
-- 01_CREATE_CORTEX_SEARCH.SQL
-- Purpose: Create Cortex Search services for different data domains
-- Author: Generated for Snowflake MCP Server
-- Date: 2025-10-03
-- ============================================================================
-- This script creates multiple Cortex Search services that will be exposed
-- through the MCP server as tools for AI agents to query.
-- ============================================================================

USE DATABASE MCP;
USE SCHEMA data;
USE WAREHOUSE mcp_wh;

-- ============================================================================
-- 1. SUPPORT TICKETS SEARCH SERVICE
-- ============================================================================
-- Create Cortex Search service for support tickets
-- This enables semantic search over support ticket descriptions and resolutions
CREATE OR REPLACE CORTEX SEARCH SERVICE support_tickets_search
ON description
ATTRIBUTES customer_id, ticket_id, status, priority, satisfaction_score, assigned_agent, subject, category, subcategory
WAREHOUSE = mcp_wh
TARGET_LAG = '1 hour'
AS (
    SELECT 
        ticket_id,
        customer_id,
        subject,
        description,
        category,
        subcategory,
        priority,
        channel,
        status,
        assigned_agent,
        created_date,
        resolution_date,
        satisfaction_score,
        first_response_time_minutes,
        resolution_time_hours
    FROM fact_support_tickets
);

-- ============================================================================
-- 2. CUSTOMER SEARCH SERVICE
-- ============================================================================
-- Create Cortex Search service for customer information
-- Enables semantic search over customer data including segments and profiles
CREATE OR REPLACE CORTEX SEARCH SERVICE customer_search
ON address
ATTRIBUTES customer_id, first_name, last_name, email, city, state, credit_score, annual_income, status, region, customer_segment, risk_profile
WAREHOUSE = mcp_wh
TARGET_LAG = '1 hour'
AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        email,
        phone,
        address,
        city,
        state,
        zip_code,
        region,
        customer_segment,
        credit_score,
        annual_income,
        net_worth,
        join_date,
        status,
        acquisition_channel,
        lifetime_value,
        risk_profile
    FROM dim_customers
);

-- ============================================================================
-- 3. MARKETING CAMPAIGNS SEARCH SERVICE
-- ============================================================================
-- Create Cortex Search service for marketing campaigns
-- Enables semantic search over campaign data and performance metrics
CREATE OR REPLACE CORTEX SEARCH SERVICE campaigns_search
ON campaign_name
ATTRIBUTES campaign_id, campaign_type, objective, product_promoted, target_audience, status, start_date, end_date, roi, revenue_generated
WAREHOUSE = mcp_wh
TARGET_LAG = '1 hour'
AS (
    SELECT 
        campaign_id,
        campaign_name,
        campaign_type,
        objective,
        product_promoted,
        start_date,
        end_date,
        budget,
        actual_spend,
        target_audience,
        target_region,
        impressions,
        clicks,
        conversions,
        revenue_generated,
        roi,
        status
    FROM dim_campaigns
);

-- ============================================================================
-- 4. TRANSACTIONS SEARCH SERVICE
-- ============================================================================
-- Create Cortex Search service for transaction data
-- Enables semantic search over transaction descriptions and merchant info
CREATE OR REPLACE CORTEX SEARCH SERVICE transactions_search
ON description
ATTRIBUTES transaction_id, customer_id, transaction_type, amount, is_flagged, fraud_score, merchant_name, merchant_category, location
WAREHOUSE = mcp_wh
TARGET_LAG = '1 hour'
AS (
    SELECT 
        transaction_id,
        account_id,
        customer_id,
        transaction_date,
        transaction_type,
        amount,
        balance_after,
        merchant_name,
        merchant_category,
        channel,
        location,
        description,
        is_flagged,
        fraud_score
    FROM fact_transactions
);

-- ============================================================================
-- 5. RISK ASSESSMENTS SEARCH SERVICE
-- ============================================================================
-- Create Cortex Search service for risk assessment data
-- Enables semantic search over risk factors and assessment details
CREATE OR REPLACE CORTEX SEARCH SERVICE risk_assessments_search
ON risk_factors
ATTRIBUTES assessment_id, customer_id, credit_risk_score, fraud_risk_score, aml_risk_score, review_required, overall_risk_rating
WAREHOUSE = mcp_wh
TARGET_LAG = '1 hour'
AS (
    SELECT 
        assessment_id,
        customer_id,
        assessment_date,
        credit_risk_score,
        fraud_risk_score,
        aml_risk_score,
        overall_risk_rating,
        risk_factors,
        review_required,
        last_review_date,
        next_review_date
    FROM fact_risk_assessments
);

-- ============================================================================
-- VERIFICATION: Test all Cortex Search services
-- ============================================================================
-- Test Support Tickets Search
SELECT 'Testing Support Tickets Search...' as test_step;
SELECT * FROM TABLE(
    support_tickets_search(
        QUERY => 'account balance issues',
        MAX_RESULTS => 3
    )
);

-- Test Customer Search
SELECT 'Testing Customer Search...' as test_step;
SELECT * FROM TABLE(
    customer_search(
        QUERY => 'high value customers',
        MAX_RESULTS => 3
    )
);

-- Test Campaigns Search
SELECT 'Testing Campaigns Search...' as test_step;
SELECT * FROM TABLE(
    campaigns_search(
        QUERY => 'digital marketing campaigns',
        MAX_RESULTS => 3
    )
);

-- Test Transactions Search
SELECT 'Testing Transactions Search...' as test_step;
SELECT * FROM TABLE(
    transactions_search(
        QUERY => 'suspicious transactions',
        MAX_RESULTS => 3
    )
);

-- Test Risk Assessments Search
SELECT 'Testing Risk Assessments Search...' as test_step;
SELECT * FROM TABLE(
    risk_assessments_search(
        QUERY => 'high risk customers',
        MAX_RESULTS => 3
    )
);

SELECT '✅ All Cortex Search services created and tested successfully!' as status;

