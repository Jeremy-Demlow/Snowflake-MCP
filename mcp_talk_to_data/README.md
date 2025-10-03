# Financial Services MCP Server

Snowflake-managed MCP server exposing financial services data through 5 semantic search tools.

## ✅ What's Built

**Database**: `MCP`  
**Schema for MCP Server**: `MCP.MCP_SERVERS`  
**Schema for Data**: `MCP.data`  
**MCP Server Name**: `financial_services_mcp`  
**Tools**: 5 Cortex Search services

---

## 📊 Data Loaded

| Table | Records | Description |
|-------|---------|-------------|
| `dim_customers` | 5,000 | Demographics, credit scores, segments |
| `dim_campaigns` | 500 | Marketing campaigns with ROI |
| `fact_marketing_responses` | 136,369 | Campaign engagement data |
| `fact_risk_assessments` | 10,000 | Credit/fraud/AML risk scores |
| `fact_transactions` | 50,000 | Transaction history with fraud flags |
| `fact_support_tickets` | 50,000 | Support interactions |

**Total**: 251,869 records

---

## 🔧 MCP Tools Available

1. **support_tickets_search** - Find support issues by description
2. **customer_search** - Search customers by demographics
3. **campaigns_search** - Find campaigns by performance  
4. **transactions_search** - Search transactions by description
5. **risk_assessments_search** - Find customers by risk profile

---

## 🚀 Setup Guide

### Step 1: Run Setup Scripts (10 minutes)

```bash
# Navigate to directory
cd /Users/jdemlow/github/Snowflake-MCP/mcp_talk_to_data

# 1. Create tables and load data (2 min)
snow sql -c myconnection -f 00_setup.sql

# 2. Create Cortex Search services (5-7 min to index)
snow sql -c myconnection -f 01_create_cortex_search.sql

# 3. Upload semantic model
snow sql -c myconnection -q "PUT file://02_create_semantic_model.yaml @MCP.data.semantic_models AUTO_COMPRESS=FALSE OVERWRITE=TRUE;"

# 4. Create MCP server (30 sec)
snow sql -c myconnection -f 04_create_mcp_server_search_only.sql
```

### Step 2: Generate PAT Token (2 minutes)

**In Snowsight** (https://app.snowflake.com/):
1. Open a SQL worksheet
2. Run:
```sql
USE ROLE ACCOUNTADMIN;

ALTER USER jd_service_account_admin 
ADD PROGRAMMATIC ACCESS TOKEN cursor_financial_mcp
    ROLE_RESTRICTION = 'mcp_user_role'
    DAYS_TO_EXPIRY = 90;
```
3. **Copy the token immediately!**

### Step 3: Test Connection (30 seconds)

```bash
./test_financial_mcp.sh YOUR-PAT-TOKEN
```

Expected: ✅ SUCCESS with 5 tools listed

### Step 4: Configure Cursor (2 minutes)

Add to Cursor's `mcp.json`:

```json
{
  "mcpServers": {
    "snowflake-financial-services": {
      "url": "https://<ACCOUNT_NAME>.snowflakecomputing.com/api/v2/databases/MCP/schemas/MCP_SERVERS/mcp-servers/financial_services_mcp",
      "headers": {
        "Authorization": "Bearer <YOUR-PAT-TOKEN>"
      }
    }
  }
}
```

**Then**: `⌘⇧P` → "Reload Window"

---

## 🧪 Example Queries

Once configured in Cursor, try:

### Customer Search
```
Find customers in California with credit scores above 750
```

### Support Tickets
```
Show me support tickets about account access problems
```

### Campaigns
```
Which marketing campaigns had ROI over 300%?
```

### Transactions
```
Find high-value transactions flagged as suspicious
```

### Risk Assessment
```
Show customers that require manual risk review
```

---

## 🔗 MCP Server Details

**Full URL**:
```
https://<ACCOUNT_NAME>.snowflakecomputing.com/api/v2/databases/MCP/schemas/MCP_SERVERS/mcp-servers/financial_services_mcp
```

**Database**: `MCP`  
**MCP Server Schema**: `MCP_SERVERS`  
**Data Schema**: `data`  
**Warehouse**: `mcp_wh`  
**Role**: `mcp_user_role` (read-only)

---

## 📋 Files

| File | Purpose | Status |
|------|---------|--------|
| `00_setup.sql` | Create tables & load data | ✅ Executed |
| `01_create_cortex_search.sql` | Create 5 search services | ✅ Executed |
| `02_create_semantic_model.yaml` | Semantic model definition | ✅ Uploaded |
| `04_create_mcp_server_search_only.sql` | MCP server creation | ✅ Executed |
| `mcp.json` | Cursor config with token | ✅ Configured |
| `test_financial_mcp.sh` | Test script | ✅ Tested |

---

## 🔐 Security & Access

**Role**: `mcp_user_role`

**Permissions**:
- ✅ USAGE on MCP database & schemas
- ✅ USAGE on MCP server  
- ✅ USAGE on all 5 Cortex Search services
- ✅ SELECT on all 6 data tables
- ✅ USAGE on mcp_wh warehouse
- ❌ NO WRITE access (read-only for safety)

---

## 🛠️ Maintenance

### Check Services
```sql
USE DATABASE MCP;
SHOW CORTEX SEARCH SERVICES IN SCHEMA data;
SHOW MCP SERVERS IN SCHEMA MCP_SERVERS;
```

### Refresh Search Index
```sql
ALTER CORTEX SEARCH SERVICE MCP.data.customer_search REFRESH;
```

### Monitor Usage
```sql
SELECT *
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE QUERY_TEXT LIKE '%cortex%'
ORDER BY START_TIME DESC
LIMIT 50;
```

---

## 📝 Notes

### About Cortex Analyst
The original design included Cortex Analyst for natural language SQL generation. However, the `CORTEX_ANALYST` MCP tool type is not yet available (feature announced Oct 2, 2025). 

**Ready for when available**:
- ✅ Semantic model uploaded
- ✅ Permissions configured
- ⏳ Waiting for full release

### Why 5 Tools Instead of 6?
Cortex Analyst isn't working in MCP yet, so we have:
- ❌ financial_analyst (Cortex Analyst) - Not available yet
- ✅ 5 Cortex Search services - All working!

---

## 🎯 What Makes This Different?

**Before MCP**:
- Manual data lookups
- Writing SQL to explore data
- Copy/paste between tools

**With MCP**:
- Natural language queries
- Instant filtered results
- Seamless integration in Cursor

---

## 🚀 Next Steps

1. ✅ **Done**: MCP servers created and tested
2. ✅ **Done**: Cursor configured
3. **You**: Reload Cursor and enable tools
4. **You**: Start asking questions!

---

**Built**: October 3, 2025  
**Account**: <ACCOUNT_NAME>.snowflakecomputing.com  
**Total Tools**: 6 (1 docs + 5 financial)
