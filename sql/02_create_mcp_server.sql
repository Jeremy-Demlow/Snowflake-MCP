USE DATABASE AM_SKI_RESORT;
USE WAREHOUSE COMPUTE_WH;

CREATE SCHEMA IF NOT EXISTS AM_SKI_RESORT.MCP_SERVERS
    WITH MANAGED ACCESS
    COMMENT = 'Snowflake-managed MCP server definitions';

USE SCHEMA MCP_SERVERS;

CREATE OR REPLACE MCP SERVER ski_resort_mcp
FROM SPECIFICATION
$$
tools:
  - name: "daily-summary-analyst"
    type: "CORTEX_ANALYST_MESSAGE"
    identifier: "AM_SKI_RESORT.SEMANTIC.SEM_DAILY_SUMMARY"
    description: "Executive daily summary analyst - ask natural language questions about resort KPIs including total visits, unique visitors, lift scans, wait times, ticket/rental/F&B revenue, and pass holder metrics. Supports season-over-season comparisons and date filtering."
    title: "Daily Summary Analyst"

  - name: "revenue-analyst"
    type: "CORTEX_ANALYST_MESSAGE"
    identifier: "AM_SKI_RESORT.SEMANTIC.SEM_REVENUE"
    description: "Revenue analyst covering ticket sales, rental revenue, and food & beverage performance. Ask about revenue by channel, ticket type, product category, location, and time period. Supports trend analysis and pricing insights."
    title: "Revenue Analyst"

  - name: "operations-analyst"
    type: "CORTEX_ANALYST_MESSAGE"
    identifier: "AM_SKI_RESORT.SEMANTIC.SEM_OPERATIONS"
    description: "Operations analyst for lift scans, wait times, capacity utilization, trail grooming, and lift maintenance. Covers 18 lifts with hourly patterns, terrain-level detail, and maintenance cost tracking."
    title: "Operations Analyst"

  - name: "resort-executive-agent"
    type: "CORTEX_AGENT_RUN"
    identifier: "AM_SKI_RESORT.AGENTS.RESORT_EXECUTIVE"
    description: "Executive BI partner with access to all resort analytics domains - revenue, operations, customers, staffing, weather, marketing, safety, and satisfaction. Best for cross-domain questions requiring synthesis across multiple data sources."
    title: "Resort Executive Agent"

  - name: "ski-ops-assistant-agent"
    type: "CORTEX_AGENT_RUN"
    identifier: "AM_SKI_RESORT.AGENTS.SKI_OPS_ASSISTANT"
    description: "Operations-focused assistant for lift supervisors and ops managers. Covers lift wait times, staffing coverage, weather conditions, and safety incidents. Optimized for quick actionable answers."
    title: "Ski Ops Assistant"

  - name: "feedback-search"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "AM_SKI_RESORT.AGENTS.FEEDBACK_SEARCH"
    description: "Semantic search over 13K+ guest feedback entries. Search by topic (e.g. 'long lift lines', 'great snow conditions', 'rude staff'). Returns feedback text, ratings, NPS scores, sentiment, and categories."
    title: "Guest Feedback Search"

  - name: "incident-search"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "AM_SKI_RESORT.AGENTS.INCIDENT_SEARCH"
    description: "Semantic search over 2.8K safety incidents. Search by scenario (e.g. 'collision on black diamond', 'equipment malfunction', 'beginner lost on trail'). Returns descriptions, severity, cause, trail, patrol response times."
    title: "Safety Incident Search"

  - name: "execute-sql"
    type: "SYSTEM_EXECUTE_SQL"
    description: "Execute read-only SQL queries against the AM_SKI_RESORT data warehouse. Use for ad-hoc analysis, data validation, or queries not covered by the analyst tools. Tables available in AM_SKI_RESORT.MARTS schema."
    title: "SQL Query Execution"

  - name: "resort-kpi-summary"
    type: "GENERIC"
    identifier: "AM_SKI_RESORT.AGENTS.RESORT_KPI_SUMMARY"
    description: "Returns a comprehensive JSON summary of resort KPIs for a given ski season (e.g. '2024-2025'). Includes visitation counts, revenue totals, operations metrics (wait times), satisfaction scores (NPS), and safety stats."
    title: "Resort KPI Summary"
    config:
      type: "function"
      warehouse: "COMPUTE_WH"
      input_schema:
        type: "object"
        properties:
          p_season:
            description: "Ski season identifier, e.g. 2024-2025"
            type: "string"

  - name: "weather-impact-report"
    type: "GENERIC"
    identifier: "AM_SKI_RESORT.AGENTS.WEATHER_IMPACT_REPORT"
    description: "Analyzes how weather conditions impact resort visitation for a date range. Returns weather summary, visitation by snow condition, and powder day uplift analysis. Pass start and end dates."
    title: "Weather Impact Report"
    config:
      type: "function"
      warehouse: "COMPUTE_WH"
      input_schema:
        type: "object"
        properties:
          p_start_date:
            description: "Start date for the analysis period (YYYY-MM-DD)"
            type: "string"
          p_end_date:
            description: "End date for the analysis period (YYYY-MM-DD)"
            type: "string"
$$;

CREATE ROLE IF NOT EXISTS ski_resort_mcp_role
    COMMENT = 'Least-privilege role for MCP server access';

GRANT USAGE ON DATABASE AM_SKI_RESORT TO ROLE ski_resort_mcp_role;
GRANT USAGE ON SCHEMA AM_SKI_RESORT.MCP_SERVERS TO ROLE ski_resort_mcp_role;
GRANT USAGE ON SCHEMA AM_SKI_RESORT.AGENTS TO ROLE ski_resort_mcp_role;
GRANT USAGE ON SCHEMA AM_SKI_RESORT.SEMANTIC TO ROLE ski_resort_mcp_role;
GRANT USAGE ON SCHEMA AM_SKI_RESORT.MARTS TO ROLE ski_resort_mcp_role;

GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ski_resort_mcp_role;

GRANT USAGE ON MCP SERVER AM_SKI_RESORT.MCP_SERVERS.ski_resort_mcp TO ROLE ski_resort_mcp_role;

GRANT SELECT ON SEMANTIC VIEW AM_SKI_RESORT.SEMANTIC.SEM_DAILY_SUMMARY TO ROLE ski_resort_mcp_role;
GRANT SELECT ON SEMANTIC VIEW AM_SKI_RESORT.SEMANTIC.SEM_REVENUE TO ROLE ski_resort_mcp_role;
GRANT SELECT ON SEMANTIC VIEW AM_SKI_RESORT.SEMANTIC.SEM_OPERATIONS TO ROLE ski_resort_mcp_role;
GRANT SELECT ON SEMANTIC VIEW AM_SKI_RESORT.SEMANTIC.SEM_CUSTOMER_BEHAVIOR TO ROLE ski_resort_mcp_role;
GRANT SELECT ON SEMANTIC VIEW AM_SKI_RESORT.SEMANTIC.SEM_STAFFING_ANALYTICS TO ROLE ski_resort_mcp_role;
GRANT SELECT ON SEMANTIC VIEW AM_SKI_RESORT.SEMANTIC.SEM_WEATHER_ANALYTICS TO ROLE ski_resort_mcp_role;
GRANT SELECT ON SEMANTIC VIEW AM_SKI_RESORT.SEMANTIC.SEM_MARKETING_ANALYTICS TO ROLE ski_resort_mcp_role;
GRANT SELECT ON SEMANTIC VIEW AM_SKI_RESORT.SEMANTIC.SEM_CUSTOMER_SATISFACTION TO ROLE ski_resort_mcp_role;
GRANT SELECT ON SEMANTIC VIEW AM_SKI_RESORT.SEMANTIC.SEM_SAFETY_INCIDENTS TO ROLE ski_resort_mcp_role;
GRANT SELECT ON SEMANTIC VIEW AM_SKI_RESORT.SEMANTIC.SEM_PASSHOLDER_ANALYTICS TO ROLE ski_resort_mcp_role;
GRANT SELECT ON SEMANTIC VIEW AM_SKI_RESORT.SEMANTIC.SEM_LESSONS_ANALYTICS TO ROLE ski_resort_mcp_role;

GRANT USAGE ON CORTEX SEARCH SERVICE AM_SKI_RESORT.AGENTS.FEEDBACK_SEARCH TO ROLE ski_resort_mcp_role;
GRANT USAGE ON CORTEX SEARCH SERVICE AM_SKI_RESORT.AGENTS.INCIDENT_SEARCH TO ROLE ski_resort_mcp_role;

GRANT USAGE ON FUNCTION AM_SKI_RESORT.AGENTS.RESORT_KPI_SUMMARY(VARCHAR) TO ROLE ski_resort_mcp_role;
GRANT USAGE ON FUNCTION AM_SKI_RESORT.AGENTS.WEATHER_IMPACT_REPORT(DATE, DATE) TO ROLE ski_resort_mcp_role;

GRANT SELECT ON ALL TABLES IN SCHEMA AM_SKI_RESORT.MARTS TO ROLE ski_resort_mcp_role;

CREATE OR REPLACE SECURITY INTEGRATION ski_resort_mcp_oauth
    TYPE = OAUTH
    OAUTH_CLIENT = CUSTOM
    ENABLED = TRUE
    OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
    OAUTH_REDIRECT_URI = 'http://localhost:8080/callback'
    OAUTH_ALLOW_NON_TLS_REDIRECT_URI = TRUE
    COMMENT = 'OAuth integration for MCP server access';

SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('SKI_RESORT_MCP_OAUTH') AS oauth_secrets;

SHOW MCP SERVERS IN SCHEMA AM_SKI_RESORT.MCP_SERVERS;
DESCRIBE MCP SERVER AM_SKI_RESORT.MCP_SERVERS.ski_resort_mcp;
SHOW GRANTS TO ROLE ski_resort_mcp_role;

SELECT 'MCP Server + RBAC setup complete' AS status;
SELECT 'MCP URL: https://<ACCOUNT>.snowflakecomputing.com/api/v2/databases/AM_SKI_RESORT/schemas/MCP_SERVERS/mcp-servers/ski_resort_mcp' AS mcp_url;
