-- ============================================================================
-- 04_CREATE_MCP_SERVER.SQL
-- Purpose: Create comprehensive MCP server with all tools
-- Author: Generated for Snowflake MCP Server
-- Date: 2025-10-03
-- ============================================================================
-- This script creates a Snowflake-managed MCP server that exposes multiple
-- tools including Cortex Search services and Cortex Analyst for AI agents.
-- ============================================================================

USE DATABASE MCP;
USE SCHEMA MCP_SERVERS;
USE WAREHOUSE mcp_wh;

-- ============================================================================
-- STEP 1: Create the MCP Server with all tools
-- ============================================================================
CREATE OR REPLACE MCP SERVER financial_services_mcp 
FROM SPECIFICATION
$$
tools:
  # ==========================================================================
  # CORTEX ANALYST: Natural Language SQL Generation
  # ==========================================================================
  - name: "financial_analyst"
    type: "CORTEX_ANALYST"
    identifier: "MCP.data.financial_analyst"
    description: "Ask natural language questions about customers, transactions, campaigns, support tickets, and risk assessments. The analyst will generate and execute SQL queries to answer your questions."
    title: "Financial Services Data Analyst"
    
  # ==========================================================================
  # CORTEX SEARCH: Support Tickets
  # ==========================================================================
  - name: "support_tickets_search"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "MCP.data.support_tickets_search"
    description: "Search through customer support tickets to find issues, patterns, and sentiment. Use this to analyze support ticket descriptions, categories, resolution status, and customer satisfaction."
    title: "Support Tickets Search"
    
  # ==========================================================================
  # CORTEX SEARCH: Customer Information
  # ==========================================================================
  - name: "customer_search"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "MCP.data.customer_search"
    description: "Search customer master data including demographics, segments, risk profiles, and financial information. Use this to find specific customers or analyze customer characteristics."
    title: "Customer Search"
    
  # ==========================================================================
  # CORTEX SEARCH: Marketing Campaigns
  # ==========================================================================
  - name: "campaigns_search"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "MCP.data.campaigns_search"
    description: "Search marketing campaign data to analyze campaign performance, objectives, and ROI. Use this to find campaigns by name, type, product, or target audience."
    title: "Marketing Campaigns Search"
    
  # ==========================================================================
  # CORTEX SEARCH: Transactions
  # ==========================================================================
  - name: "transactions_search"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "MCP.data.transactions_search"
    description: "Search transaction records to find patterns, suspicious activities, or specific merchant transactions. Use this for fraud detection and transaction analysis."
    title: "Transactions Search"
    
  # ==========================================================================
  # CORTEX SEARCH: Risk Assessments
  # ==========================================================================
  - name: "risk_assessments_search"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "MCP.data.risk_assessments_search"
    description: "Search customer risk assessment data including credit risk, fraud risk, AML scores, and review requirements. Use this to identify high-risk customers or analyze risk patterns."
    title: "Risk Assessments Search"
$$;

-- ============================================================================
-- STEP 2: Create a dedicated role for MCP access
-- ============================================================================
-- This role will have restricted access only to what's needed for MCP
CREATE ROLE IF NOT EXISTS mcp_user_role;

-- Grant database and schema access
GRANT USAGE ON DATABASE MCP TO ROLE mcp_user_role;
GRANT USAGE ON SCHEMA MCP.data TO ROLE mcp_user_role;
GRANT USAGE ON SCHEMA MCP.MCP_SERVERS TO ROLE mcp_user_role;

-- Grant usage on the warehouse
GRANT USAGE ON WAREHOUSE mcp_wh TO ROLE mcp_user_role;

-- Grant usage on the MCP server
GRANT USAGE ON MCP SERVER MCP.MCP_SERVERS.financial_services_mcp TO ROLE mcp_user_role;

-- Grant usage on all Cortex Search services
GRANT USAGE ON CORTEX SEARCH SERVICE MCP.data.support_tickets_search TO ROLE mcp_user_role;
GRANT USAGE ON CORTEX SEARCH SERVICE MCP.data.customer_search TO ROLE mcp_user_role;
GRANT USAGE ON CORTEX SEARCH SERVICE MCP.data.campaigns_search TO ROLE mcp_user_role;
GRANT USAGE ON CORTEX SEARCH SERVICE MCP.data.transactions_search TO ROLE mcp_user_role;
GRANT USAGE ON CORTEX SEARCH SERVICE MCP.data.risk_assessments_search TO ROLE mcp_user_role;

-- Grant usage on Cortex Analyst
GRANT USAGE ON CORTEX ANALYST MCP.data.financial_analyst TO ROLE mcp_user_role;

-- Grant read access to the underlying tables (needed for Cortex Analyst)
GRANT SELECT ON TABLE MCP.data.dim_customers TO ROLE mcp_user_role;
GRANT SELECT ON TABLE MCP.data.dim_campaigns TO ROLE mcp_user_role;
GRANT SELECT ON TABLE MCP.data.fact_transactions TO ROLE mcp_user_role;
GRANT SELECT ON TABLE MCP.data.fact_support_tickets TO ROLE mcp_user_role;
GRANT SELECT ON TABLE MCP.data.fact_risk_assessments TO ROLE mcp_user_role;
GRANT SELECT ON TABLE MCP.data.fact_marketing_responses TO ROLE mcp_user_role;

-- ============================================================================
-- STEP 3: Create or configure a user and assign the role
-- ============================================================================
-- IMPORTANT: Replace 'mcp_service_user' with your actual username

-- Example: If creating a new service user
-- CREATE USER IF NOT EXISTS mcp_service_user 
--   PASSWORD = 'YourSecurePassword123!'
--   DEFAULT_ROLE = mcp_user_role
--   MUST_CHANGE_PASSWORD = FALSE;

-- Grant the role to the user (replace with your username)
-- GRANT ROLE mcp_user_role TO USER mcp_service_user;

-- For existing users, just grant the role
-- GRANT ROLE mcp_user_role TO USER <YOUR_USERNAME>;

-- ============================================================================
-- STEP 4: Create a Programmatic Access Token (PAT)
-- ============================================================================
-- IMPORTANT: This must be run by a user with ACCOUNTADMIN role or appropriate privileges
-- Replace <YOUR_USERNAME> with the actual username that will connect to MCP

-- Note: You must have a network policy configured to use PATs
-- See: https://docs.snowflake.com/en/user-guide/security-access-tokens

/*
ALTER USER <YOUR_USERNAME> ADD PROGRAMMATIC ACCESS TOKEN cursor_mcp_token
    ROLE_RESTRICTION = 'mcp_user_role'
    DAYS_TO_EXPIRY = 90
    COMMENT = 'PAT for Cursor MCP Server access';
*/

-- The above command will return a token. SAVE THIS TOKEN - you cannot retrieve it again!
-- You will use this token in your mcp.json configuration file.

-- ============================================================================
-- STEP 5: Verify the MCP Server setup
-- ============================================================================
-- Check that the MCP server was created
SHOW MCP SERVERS;

-- Verify the role permissions
SHOW GRANTS TO ROLE mcp_user_role;

-- Display MCP server details
DESCRIBE MCP SERVER MCP.MCP_SERVERS.financial_services_mcp;

-- ============================================================================
-- SUCCESS! Your MCP server is ready
-- ============================================================================
SELECT '✅ MCP Server created successfully!' as status;
SELECT 'ℹ️  Server name: financial_services_mcp' as info;
SELECT 'ℹ️  Database: MCP' as info;
SELECT 'ℹ️  Schema: MCP_SERVERS' as info;
SELECT 'ℹ️  Total tools: 6 (1 Cortex Analyst + 5 Cortex Search Services)' as info;
SELECT '' as blank;
SELECT '📋 NEXT STEPS:' as next_steps;
SELECT '1. Create a PAT token using the ALTER USER command above' as step;
SELECT '2. Copy the token (you will not be able to retrieve it again)' as step;
SELECT '3. Update your mcp.json file with the server URL and token' as step;
SELECT '4. Configure Cursor to use the MCP server' as step;
SELECT '' as blank;
SELECT '🔗 MCP Server URL format:' as url_format;
SELECT 'https://<ACCOUNT_NAME>.snowflakecomputing.com/api/v2/databases/MCP/schemas/MCP_SERVERS/mcp-servers/financial_services_mcp' as url_example;

