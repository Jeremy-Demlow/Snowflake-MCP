-- ============================================================================
-- SNOWFLAKE DOCUMENTATION MCP SERVER SETUP
-- Purpose: Create MCP server to expose Snowflake docs to Cursor
-- Based on: Snowflake MCP documentation example
-- ============================================================================

-- Step 1: Create database and schema for MCP server
CREATE DATABASE IF NOT EXISTS MCP;
CREATE SCHEMA IF NOT EXISTS MCP.MCP_SERVERS;

USE DATABASE MCP;
USE SCHEMA MCP_SERVERS;

-- Step 2: Create MCP server pointing to Snowflake Documentation
-- Note: This assumes you have the Snowflake Documentation Cortex Knowledge Extension
-- installed from Snowflake Marketplace. If not, install it first from:
-- https://app.snowflake.com/marketplace
CREATE OR REPLACE MCP SERVER MCP.MCP_SERVERS.SNOWFLAKE_DOCS 
FROM SPECIFICATION 
$$
  tools:
    - name: "snowflake-docs"
      type: "CORTEX_SEARCH_SERVICE_QUERY"
      identifier: "snowflake_documentation.shared.cke_snowflake_docs_service"
      description: "Search Snowflake documentation for accurate syntax, functions, and best practices. Use this to validate SQL syntax, find function signatures, and get authoritative guidance on Snowflake features."
      title: "Snowflake Documentation Search"
$$;

-- Step 3: Create restrictive role to just access docs search service
CREATE ROLE IF NOT EXISTS SNOWFLAKE_DOCS_ROLE;

-- Step 4: Grant the role to your user (REPLACE WITH YOUR USERNAME)
GRANT ROLE SNOWFLAKE_DOCS_ROLE TO USER jd_service_account_admin;

-- Step 5: Grant permissions
GRANT USAGE ON DATABASE MCP TO ROLE SNOWFLAKE_DOCS_ROLE;
GRANT USAGE ON SCHEMA MCP.MCP_SERVERS TO ROLE SNOWFLAKE_DOCS_ROLE;
GRANT USAGE ON MCP SERVER MCP.MCP_SERVERS.SNOWFLAKE_DOCS TO ROLE SNOWFLAKE_DOCS_ROLE;

-- Step 6: Verify the MCP server
SHOW MCP SERVERS;

-- Step 7: Check grants
SHOW GRANTS TO ROLE SNOWFLAKE_DOCS_ROLE;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
SELECT '✅ MCP Server created successfully!' as status;
SELECT 'ℹ️  Next: Generate PAT token and configure Cursor' as next_step;
SELECT '' as blank;
SELECT '📋 TO GENERATE PAT TOKEN, RUN:' as instructions;
SELECT 'ALTER USER jd_service_account_admin ADD PROGRAMMATIC ACCESS TOKEN cursor_docs_token' as step1;
SELECT '  ROLE_RESTRICTION = ''SNOWFLAKE_DOCS_ROLE''' as step2;
SELECT '  DAYS_TO_EXPIRY = 90;' as step3;


SHOW MCP SERVERS;