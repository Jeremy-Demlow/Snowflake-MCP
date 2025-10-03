-- ============================================================================
-- 03_CREATE_CORTEX_ANALYST.SQL
-- Purpose: Upload semantic model and create Cortex Analyst service
-- Author: Generated for Snowflake MCP Server
-- Date: 2025-10-03
-- ============================================================================
-- This script uploads the semantic model YAML file and creates a Cortex
-- Analyst service that can answer natural language questions about the data.
-- ============================================================================

USE DATABASE MCP;
USE SCHEMA data;
USE WAREHOUSE mcp_wh;

-- ============================================================================
-- STEP 1: Upload the semantic model file to internal stage
-- ============================================================================
-- NOTE: Before running this script, you need to upload the YAML file manually:
--
-- From SnowSQL or via Snowsight:
-- PUT file:///path/to/02_create_semantic_model.yaml @semantic_models AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--
-- Or use the Snowsight UI:
-- 1. Go to Data > Databases > snowflake_mcp_db > data > Stages
-- 2. Click on semantic_models stage
-- 3. Click "+ Files" and upload 02_create_semantic_model.yaml
-- ============================================================================

-- Verify the file was uploaded successfully
LIST @semantic_models;

-- ============================================================================
-- STEP 2: Create Cortex Analyst service
-- ============================================================================
-- The Cortex Analyst service uses the semantic model to answer natural
-- language questions by generating and executing SQL queries
CREATE OR REPLACE CORTEX ANALYST SERVICE financial_analyst
    SEMANTIC_MODEL_FILE = '@semantic_models/02_create_semantic_model.yaml';

-- ============================================================================
-- STEP 3: Test the Cortex Analyst service
-- ============================================================================
-- Test with sample questions to verify the service is working

SELECT '🧪 Test 1: Customer Segmentation Analysis' as test_name;
SELECT snowflake_mcp_db.data.financial_analyst!MESSAGE(
    'What is the average lifetime value by customer segment?'
) as response;

SELECT '🧪 Test 2: Support Ticket Analysis' as test_name;
SELECT snowflake_mcp_db.data.financial_analyst!MESSAGE(
    'Show me the top 5 support ticket categories by volume and their average satisfaction scores'
) as response;

SELECT '🧪 Test 3: Campaign Performance' as test_name;
SELECT snowflake_mcp_db.data.financial_analyst!MESSAGE(
    'Which marketing campaigns had the highest ROI?'
) as response;

SELECT '🧪 Test 4: Transaction Analysis' as test_name;
SELECT snowflake_mcp_db.data.financial_analyst!MESSAGE(
    'What are the total transaction volumes by merchant category in the last 30 days?'
) as response;

SELECT '🧪 Test 5: Risk Assessment' as test_name;
SELECT snowflake_mcp_db.data.financial_analyst!MESSAGE(
    'How many high-risk customers do we have and what is their average fraud risk score?'
) as response;

-- ============================================================================
-- STEP 4: Grant necessary permissions
-- ============================================================================
-- Grant usage on the Cortex Analyst service to the role that will use it
-- Replace 'YOUR_ROLE' with the actual role name

-- GRANT USAGE ON CORTEX ANALYST financial_analyst TO ROLE YOUR_ROLE;

SELECT '✅ Cortex Analyst service created successfully!' as status;
SELECT 'ℹ️  Service name: financial_analyst' as info;
SELECT 'ℹ️  Semantic model: @semantic_models/02_create_semantic_model.yaml' as info;

