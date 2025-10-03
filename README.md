# Snowflake MCP Servers for Cursor

Two production-ready Model Context Protocol (MCP) servers for Snowflake, designed to give Cursor AI assistant access to Snowflake documentation and financial services data.

## 🎯 What's Included

### 1. **Snowflake Documentation MCP** (`mcp_documentation/`)
Access Snowflake's official documentation from within Cursor for accurate SQL syntax and function references.

### 2. **Financial Services MCP** (`mcp_talk_to_data/`)
Semantic search across 250K+ records of financial services data including customers, transactions, campaigns, support tickets, and risk assessments.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Cursor AI Assistant                       │
└───────────────────────────┬─────────────────────────────────┘
                            │ MCP Protocol (HTTPS/JSON-RPC)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│           Snowflake Account (trb65519)                       │
│                                                              │
│  MCP Database (Centralized)                                  │
│  ├── MCP_SERVERS/ (schema)                                   │
│  │   ├── SNOWFLAKE_DOCS (1 tool)                            │
│  │   └── FINANCIAL_SERVICES_MCP (5 tools)                   │
│  │                                                           │
│  └── data/ (schema)                                          │
│      ├── Tables (6 tables, 251K records)                     │
│      └── Cortex Search Services (5 services)                 │
└─────────────────────────────────────────────────────────────┘
```

**Key Design Decision**: Everything centralized in the `MCP` database for easy management and cleanup.

---

## 🚀 Quick Start

### Prerequisites
1. Snowflake account with ACCOUNTADMIN role
2. Snowflake CLI installed (`brew install snowflake-cli`)
3. Cursor IDE
4. Snowflake Documentation Cortex Knowledge Extension (from Marketplace)

### Setup (15 minutes total)

#### Option 1: Documentation MCP (5 minutes)
```bash
cd mcp_documentation
snow sql -c <your-connection> -f setup_snowflake_docs_mcp.sql
```

Then generate PAT token in Snowsight and configure Cursor.

#### Option 2: Financial Services MCP (15 minutes)
```bash
cd mcp_talk_to_data
snow sql -c <your-connection> -f 00_setup.sql
snow sql -c <your-connection> -f 01_create_cortex_search.sql
snow sql -c <your-connection> -q "PUT file://02_create_semantic_model.yaml @MCP.data.semantic_models AUTO_COMPRESS=FALSE OVERWRITE=TRUE;"
snow sql -c <your-connection> -f 04_create_mcp_server_search_only.sql
```

Then generate PAT token and configure Cursor.

---

## 📊 What You Get

### Snowflake Documentation MCP
- **1 Tool**: `snowflake-docs`
- **Purpose**: Search Snowflake documentation for accurate syntax
- **Use Case**: Write correct Snowflake code on the first try

### Financial Services MCP
- **5 Tools**:
  1. `support_tickets_search` - 50,000 support tickets
  2. `customer_search` - 5,000 customers
  3. `campaigns_search` - 500 marketing campaigns
  4. `transactions_search` - 50,000 transactions
  5. `risk_assessments_search` - 10,000 risk assessments

---

## 🔐 Security Model

**Two Dedicated Roles**:
- `SNOWFLAKE_DOCS_ROLE` - Read-only access to documentation
- `mcp_user_role` - Read-only access to financial data

**PAT Token**: One token works for both servers with role restrictions for security.

**Network Policy**: Required for PAT tokens (Snowflake security best practice)

---

## 💡 Real-World Examples

### With Documentation MCP:
```
You: "Create a stored procedure with EXECUTE IMMEDIATE"
Cursor: *searches docs* → generates correct Snowflake Scripting syntax
```

### With Financial Services MCP:
```
You: "Find customers in California with credit scores above 750"
Cursor: *uses customer_search* → returns filtered results with details
```

```
You: "Show me high ROI marketing campaigns"  
Cursor: *uses campaigns_search* → finds campaigns with 300%+ ROI
```

```
You: "Find suspicious transactions"
Cursor: *uses transactions_search* → identifies flagged transactions
```

---

## 🔧 Configuration

### Cursor Setup

**Location**: `~/Library/Application Support/Cursor/User/globalStorage/mcp.json`

```json
{
  "mcpServers": {
    "snowflake-docs": {
      "url": "https://trb65519.snowflakecomputing.com/api/v2/databases/MCP/schemas/MCP_SERVERS/mcp-servers/SNOWFLAKE_DOCS",
      "headers": {
        "Authorization": "Bearer <YOUR-PAT-TOKEN>"
      }
    },
    "snowflake-financial-services": {
      "url": "https://trb65519.snowflakecomputing.com/api/v2/databases/MCP/schemas/MCP_SERVERS/mcp-servers/financial_services_mcp",
      "headers": {
        "Authorization": "Bearer <YOUR-PAT-TOKEN>"
      }
    }
  }
}
```

**After configuring**:
1. Reload Cursor: `⌘⇧P` → "Reload Window"
2. Settings → Tools & MCP → Enable the tools

---

## 📁 Repository Structure

```
Snowflake-MCP/
├── README.md                        # This file
├── SETUP_COMPLETE.md               # Setup completion summary
│
├── mcp_documentation/              # Snowflake Docs MCP
│   ├── README.md                   # Docs MCP guide
│   ├── setup_snowflake_docs_mcp.sql # Setup script
│   ├── mcp.json                    # Config with token
│   └── test_mcp_connection.sh      # Test script
│
└── mcp_talk_to_data/               # Financial Services MCP
    ├── README.md                   # Financial MCP guide
    ├── 00_setup.sql                # Database & data loading
    ├── 01_create_cortex_search.sql # Create 5 search services
    ├── 02_create_semantic_model.yaml # Semantic model (uploaded)
    ├── 04_create_mcp_server_search_only.sql # MCP server creation
    ├── mcp.json                    # Config with token
    └── test_financial_mcp.sh       # Test script
```

---

## 🛠️ Monitoring & Maintenance

### Check Status
```sql
USE DATABASE MCP;
SHOW MCP SERVERS;
SHOW CORTEX SEARCH SERVICES IN SCHEMA data;
```

### View Tool Usage
```sql
SELECT *
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE QUERY_TEXT LIKE '%cortex%'
ORDER BY START_TIME DESC
LIMIT 100;
```

### Refresh Search Services
```sql
ALTER CORTEX SEARCH SERVICE MCP.data.support_tickets_search REFRESH;
```

---

## 🧹 Cleanup

Everything is centralized in one database for easy cleanup:

```sql
-- Remove everything (be careful!)
DROP DATABASE MCP CASCADE;
```

Or remove individual components:
```sql
-- Remove just the financial MCP server
DROP MCP SERVER MCP.MCP_SERVERS.financial_services_mcp;

-- Remove just the data
DROP SCHEMA MCP.data CASCADE;
```

---

## 📊 Data Summary

| Table | Records | Description |
|-------|---------|-------------|
| dim_customers | 5,000 | Customer demographics & segments |
| dim_campaigns | 500 | Marketing campaign performance |
| fact_marketing_responses | 136,369 | Campaign responses |
| fact_risk_assessments | 10,000 | Credit/fraud/AML risk scores |
| fact_transactions | 50,000 | Transaction history & fraud flags |
| fact_support_tickets | 50,000 | Customer support interactions |
| **Total** | **251,869** | |

---

## 🎓 Learning Path

### Phase 1: Get Started (15 min)
1. Set up Documentation MCP for better Snowflake coding
2. Test it with a simple stored procedure prompt

### Phase 2: Add Financial Data (15 min)
1. Load the financial services data
2. Create the search services
3. Test semantic searches

### Phase 3: Explore & Customize
1. Try different search queries
2. Add your own tables to the semantic model
3. Create custom Cortex Search services

### Phase 4: Production
1. Set up additional MCP servers for different use cases
2. Implement monitoring dashboards
3. Establish governance policies

---

## 🛠️ Troubleshooting

### Tools not showing in Cursor
- **Solution**: Reload Cursor window (`⌘⇧P` → "Reload Window")
- **Check**: Settings → Tools & MCP to enable tools

### PAT Token Expired
```sql
-- Generate new token in Snowsight
ALTER USER jd_service_account_admin 
ADD PROGRAMMATIC ACCESS TOKEN cursor_mcp_token_2
    ROLE_RESTRICTION = 'mcp_user_role'
    DAYS_TO_EXPIRY = 90;
```

### Search Returns No Results
```sql
-- Check data exists
SELECT COUNT(*) FROM MCP.data.fact_support_tickets;

-- Refresh the search service
ALTER CORTEX SEARCH SERVICE MCP.data.support_tickets_search REFRESH;
```

### Connection Test
```bash
# Test Documentation MCP
cd mcp_documentation
./test_mcp_connection.sh <YOUR-PAT-TOKEN>

# Test Financial Services MCP
cd mcp_talk_to_data
./test_financial_mcp.sh <YOUR-PAT-TOKEN>
```

---

## 🤝 Contributing

This is a working example you can customize:
- Add your own data tables
- Create domain-specific search services
- Set up multiple MCP servers for different teams
- Extend the semantic model

