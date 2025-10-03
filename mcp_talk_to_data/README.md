# Snowflake MCP Server Implementation

This directory contains the complete implementation for a Snowflake-managed MCP server that exposes financial services data to AI agents.

## 📁 Files

| File | Purpose |
|------|---------|
| `00_setup.sql` | Database setup, tables, and data loading |
| `01_create_cortex_search.sql` | Create 5 Cortex Search services |
| `02_create_semantic_model.yaml` | Semantic model for Cortex Analyst |
| `03_create_cortex_analyst.sql` | Create Cortex Analyst service |
| `04_create_mcp_server.sql` | Create MCP server with all tools |
| `mcp.json.example` | Cursor configuration template |

## 🚀 Quick Setup

Run scripts in order:

```bash
# 1. Setup database (snowflake_mcp_db) and load data
snowsql -f 00_setup.sql

# 2. Create Cortex Search services
snowsql -f 01_create_cortex_search.sql

# 3. Upload semantic model
snowsql
> PUT file://02_create_semantic_model.yaml @snowflake_mcp_db.data.semantic_models AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

# 4. Create Cortex Analyst
snowsql -f 03_create_cortex_analyst.sql

# 5. Create MCP server and generate PAT
snowsql -f 04_create_mcp_server.sql
```

## 🔧 Configuration

### Database & Schema
- **Database:** `snowflake_mcp_db`
- **Schema:** `data`
- **Warehouse:** `mcp_wh`

### MCP Server
- **Name:** `financial_services_mcp`
- **Tools:** 6 (1 Cortex Analyst + 5 Cortex Search)
- **Role:** `mcp_user_role`

### Tables
- `dim_customers` - Customer master data
- `dim_campaigns` - Marketing campaigns
- `fact_transactions` - Transaction history
- `fact_support_tickets` - Support tickets
- `fact_risk_assessments` - Risk assessments
- `fact_marketing_responses` - Marketing responses

## 🔐 Security

PAT token generation:
```sql
ALTER USER <YOUR_USERNAME> ADD PROGRAMMATIC ACCESS TOKEN cursor_mcp_token
    ROLE_RESTRICTION = 'mcp_user_role'
    DAYS_TO_EXPIRY = 90;
```

**Save the token immediately - you cannot retrieve it later!**

## 🎯 MCP Tools

1. **financial_analyst** - Natural language SQL queries
2. **support_tickets_search** - Support ticket semantic search
3. **customer_search** - Customer data search
4. **campaigns_search** - Marketing campaign search
5. **transactions_search** - Transaction and fraud search
6. **risk_assessments_search** - Risk assessment search

## 📖 Full Documentation

See `../mcp_documentation/` for:
- Complete setup guide
- Architecture details
- End-to-end AI assistant prompt
- Troubleshooting tips

## 🔗 MCP Server URL

```
https://<YOUR-ORG-ACCOUNT>.snowflakecomputing.com/api/v2/databases/snowflake_mcp_db/schemas/data/mcp-servers/financial_services_mcp
```

Replace `<YOUR-ORG-ACCOUNT>` with your Snowflake account identifier (e.g., `abc12345.us-east-1`).
