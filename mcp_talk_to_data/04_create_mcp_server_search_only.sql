-- ============================================================================
-- CREATE MCP SERVER - SEARCH SERVICES ONLY
-- Purpose: Create MCP server with 5 Cortex Search services
-- ============================================================================

USE DATABASE MCP;
USE SCHEMA MCP_SERVERS;
USE WAREHOUSE mcp_wh;

-- ============================================================================
-- STEP 1: Create the MCP Server with Cortex Search tools only
-- ============================================================================
CREATE OR REPLACE MCP SERVER financial_services_mcp 
FROM SPECIFICATION
$$
tools:
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

-- Grant read access to the underlying tables
GRANT SELECT ON TABLE MCP.data.dim_customers TO ROLE mcp_user_role;
GRANT SELECT ON TABLE MCP.data.dim_campaigns TO ROLE mcp_user_role;
GRANT SELECT ON TABLE MCP.data.fact_transactions TO ROLE mcp_user_role;
GRANT SELECT ON TABLE MCP.data.fact_support_tickets TO ROLE mcp_user_role;
GRANT SELECT ON TABLE MCP.data.fact_risk_assessments TO ROLE mcp_user_role;
GRANT SELECT ON TABLE MCP.data.fact_marketing_responses TO ROLE mcp_user_role;

-- Grant role to user
GRANT ROLE mcp_user_role TO USER jd_service_account_admin;

-- ============================================================================
-- STEP 3: Verify the MCP Server setup
-- ============================================================================
SHOW MCP SERVERS;

-- Verify the role permissions
SHOW GRANTS TO ROLE mcp_user_role;

-- Display MCP server details
DESCRIBE MCP SERVER MCP.MCP_SERVERS.financial_services_mcp;

-- ============================================================================
-- SUCCESS!
-- ============================================================================
SELECT '✅ MCP Server created successfully!' as status;
SELECT 'ℹ️  Server name: financial_services_mcp' as info;
SELECT 'ℹ️  Database: MCP' as info;
SELECT 'ℹ️  Schema: MCP_SERVERS' as info;
SELECT 'ℹ️  Total tools: 5 Cortex Search Services' as info;
SELECT '' as blank;
SELECT '🔗 MCP Server URL:' as url_format;
SELECT 'https://<ACCOUNT_NAME>.snowflakecomputing.com/api/v2/databases/MCP/schemas/MCP_SERVERS/mcp-servers/financial_services_mcp' as url_example;
SELECT '' as blank;
SELECT '📋 Use your existing PAT token to test this MCP server!' as next_step;

