# Snowflake MCP Server for Financial Services

A comprehensive, production-ready Model Context Protocol (MCP) server implementation for Snowflake, designed to expose financial services data to AI agents through standardized interfaces.

## 🎯 Overview

This MCP server provides AI coding assistants like Cursor, Claude, CrewAI, and other MCP-compatible tools with direct access to governed Snowflake data through:

- **6 AI-Powered Tools** (1 Cortex Analyst + 5 Cortex Search Services)
- **Full Role-Based Access Control (RBAC)**
- **Semantic search across 5 data domains**
- **Natural language SQL generation**
- **Production-ready governance and security**

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Agent (Cursor/Claude)                  │
└───────────────────────────┬─────────────────────────────────┘
                            │ MCP Protocol (HTTP/JSON-RPC)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Snowflake-Managed MCP Server                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Tools (discoverable via /tools/list endpoint)       │   │
│  │  ├─ financial_analyst (Cortex Analyst)              │   │
│  │  ├─ support_tickets_search (Cortex Search)          │   │
│  │  ├─ customer_search (Cortex Search)                 │   │
│  │  ├─ campaigns_search (Cortex Search)                │   │
│  │  ├─ transactions_search (Cortex Search)             │   │
│  │  └─ risk_assessments_search (Cortex Search)         │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────────┘
                            │ Snowflake API
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Snowflake Data Cloud                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Data Layer (governed, secured)                      │   │
│  │  ├─ dim_customers                                    │   │
│  │  ├─ dim_campaigns                                    │   │
│  │  ├─ fact_transactions                                │   │
│  │  ├─ fact_support_tickets                             │   │
│  │  ├─ fact_risk_assessments                            │   │
│  │  └─ fact_marketing_responses                         │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 📚 Data Domains

### 1. **Customers** (`dim_customers`)
- Demographics, segments, and financial profiles
- 10,000+ customer records
- Fields: customer_id, name, email, segment, credit_score, lifetime_value, risk_profile

### 2. **Transactions** (`fact_transactions`)
- Transaction history with fraud detection
- 100,000+ transaction records
- Fields: transaction_id, amount, merchant, category, fraud_score, is_flagged

### 3. **Support Tickets** (`fact_support_tickets`)
- Customer support interactions
- Fields: ticket_id, category, status, satisfaction_score, resolution_time

### 4. **Marketing Campaigns** (`dim_campaigns`)
- Campaign performance and ROI
- Fields: campaign_id, name, budget, revenue_generated, roi, conversions

### 5. **Risk Assessments** (`fact_risk_assessments`)
- Credit, fraud, and AML risk scoring
- Fields: assessment_id, credit_risk_score, fraud_risk_score, aml_risk_score

## 🚀 Quick Start

### Prerequisites

1. **Snowflake Account** with:
   - `ACCOUNTADMIN` role (for setup)
   - Network policy configured (required for PATs)
   - Cortex features enabled

2. **Cursor IDE** or another MCP-compatible client

3. **SnowSQL** or Snowsight access

### Installation Steps

#### Step 1: Setup Database and Load Data
```bash
# Run in Snowflake (Snowsight or SnowSQL)
snowsql -f setup.sql
```

This creates:
- Database: `dash_mcp_db`
- Schema: `data`
- Warehouse: `dash_wh_s`
- All dimension and fact tables with sample data

#### Step 2: Create Cortex Search Services
```bash
snowsql -f 01_create_cortex_search.sql
```

Creates 5 Cortex Search services for semantic search:
- `support_tickets_search`
- `customer_search`
- `campaigns_search`
- `transactions_search`
- `risk_assessments_search`

#### Step 3: Upload Semantic Model and Create Cortex Analyst

First, upload the semantic model file:

**Option A: Using SnowSQL**
```bash
snowsql -a <your-account> -u <username>
PUT file://02_create_semantic_model.yaml @dash_mcp_db.data.semantic_models AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
```

**Option B: Using Snowsight UI**
1. Navigate to: Data > Databases > `dash_mcp_db` > `data` > Stages
2. Click on `semantic_models` stage
3. Click "+ Files" and upload `02_create_semantic_model.yaml`

Then create the Cortex Analyst:
```bash
snowsql -f 03_create_cortex_analyst.sql
```

#### Step 4: Create MCP Server
```bash
snowsql -f 04_create_mcp_server.sql
```

**Important**: This script will guide you to:
1. Create the MCP server with all 6 tools
2. Set up `mcp_user_role` with appropriate permissions
3. Generate a Programmatic Access Token (PAT)

**Generate PAT Token:**
```sql
ALTER USER <YOUR_USERNAME> ADD PROGRAMMATIC ACCESS TOKEN cursor_mcp_token
    ROLE_RESTRICTION = 'mcp_user_role'
    DAYS_TO_EXPIRY = 90;
```

⚠️ **SAVE THE TOKEN** - you cannot retrieve it again!

#### Step 5: Configure Cursor

1. Open Cursor Settings: `Cursor > Settings > Cursor Settings > Tools & MCP`
2. Click "Add Custom MCP"
3. Edit the `mcp.json` file:

```json
{
  "mcpServers": {
    "snowflake-financial-services": {
      "url": "https://YOUR-ORG-ACCOUNT.snowflakecomputing.com/api/v2/databases/dash_mcp_db/schemas/data/mcp-servers/financial_services_mcp_server",
      "headers": {
        "Authorization": "Bearer YOUR-PAT-TOKEN"
      }
    }
  }
}
```

Replace:
- `YOUR-ORG-ACCOUNT` with your Snowflake account identifier (e.g., `abc12345.us-east-1`)
- `YOUR-PAT-TOKEN` with the token from Step 4

4. Save the file
5. Hover over "snowflake-financial-services" in the MCP tools list
6. Click to enable the tools

#### Step 6: Verify Connection

Test the connection with curl:
```bash
curl -X POST "https://YOUR-ORG-ACCOUNT.snowflakecomputing.com/api/v2/databases/dash_mcp_db/schemas/data/mcp-servers/financial_services_mcp_server" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --header "Authorization: Bearer YOUR-PAT-TOKEN" \
  --data '{
    "jsonrpc": "2.0",
    "id": 12345,
    "method": "tools/list",
    "params": {}
  }'
```

Expected response:
```json
{
  "jsonrpc": "2.0",
  "id": 12345,
  "result": {
    "tools": [
      {
        "name": "financial_analyst",
        "description": "Ask natural language questions...",
        ...
      },
      ...
    ]
  }
}
```

## 💡 Usage Examples

### Example 1: Ask Natural Language Questions
```
User: "What is the average customer lifetime value by segment?"

Cursor will use the financial_analyst tool to:
1. Understand the question
2. Generate SQL using the semantic model
3. Execute the query
4. Return formatted results
```

### Example 2: Search Support Tickets
```
User: "Find all support tickets related to account balance issues"

Cursor will use the support_tickets_search tool to:
1. Perform semantic search on ticket descriptions
2. Return relevant tickets with context
3. Summarize patterns and sentiment
```

### Example 3: Analyze Campaign Performance
```
User: "Show me the top 5 marketing campaigns by ROI"

Cursor will use the campaigns_search tool to:
1. Search campaign data
2. Rank by ROI
3. Present results with insights
```

### Example 4: Fraud Detection
```
User: "Find suspicious transactions in the last 30 days"

Cursor will use the transactions_search tool to:
1. Search for flagged transactions
2. Filter by date range
3. Analyze patterns and risk scores
```

### Example 5: Risk Assessment
```
User: "How many high-risk customers require manual review?"

Cursor will use the risk_assessments_search tool to:
1. Filter by risk rating
2. Count review-required cases
3. Provide risk score distributions
```

## 🔧 Configuration

### Environment Variables
- `SNOWFLAKE_ACCOUNT`: Your Snowflake account identifier
- `SNOWFLAKE_PAT_TOKEN`: Programmatic Access Token

### Role Permissions
The `mcp_user_role` has:
- ✅ READ access to all tables
- ✅ USAGE on Cortex Search services
- ✅ USAGE on Cortex Analyst
- ✅ USAGE on MCP server
- ❌ NO WRITE access (read-only for safety)

### Security Best Practices
1. **Use PATs with role restrictions** - limit scope to `mcp_user_role`
2. **Set token expiration** - recommended 90 days or less
3. **Network policies** - restrict IP ranges if possible
4. **Audit regularly** - monitor MCP server usage
5. **Rotate tokens** - establish a rotation schedule

## 📊 Monitoring & Maintenance

### Check MCP Server Status
```sql
SHOW MCP SERVERS;
DESCRIBE MCP SERVER dash_mcp_db.data.financial_services_mcp_server;
```

### View Tool Usage
```sql
-- Query Snowflake query history for MCP activity
SELECT *
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE QUERY_TEXT LIKE '%cortex%'
  AND USER_NAME = 'YOUR_MCP_USER'
ORDER BY START_TIME DESC
LIMIT 100;
```

### Refresh Cortex Search Services
```sql
-- Cortex Search services auto-refresh based on TARGET_LAG
-- Manual refresh (if needed):
ALTER CORTEX SEARCH SERVICE support_tickets_search REFRESH;
```

### Update Semantic Model
```sql
-- Upload new version of YAML file
PUT file://02_create_semantic_model.yaml @semantic_models AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- Recreate Cortex Analyst
CREATE OR REPLACE CORTEX ANALYST SERVICE financial_analyst
    SEMANTIC_MODEL_FILE = '@semantic_models/02_create_semantic_model.yaml';
```

## 🎓 Jeremy Howard-Style Learning Path

### Phase 1: Understanding the Basics
1. Read the [MCP specification](https://modelcontextprotocol.io/)
2. Review Snowflake's [Cortex Search documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search)
3. Understand [Cortex Analyst](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)

### Phase 2: Hands-On Implementation
1. Run the setup scripts in order (setup.sql → 04_create_mcp_server.sql)
2. Test each Cortex Search service individually
3. Ask simple questions to Cortex Analyst
4. Configure Cursor and test the MCP connection

### Phase 3: Customization
1. Add your own tables to the semantic model
2. Create additional Cortex Search services
3. Customize tool descriptions for your use case
4. Add more complex verified queries

### Phase 4: Scale & Production
1. Set up multiple MCP servers for different teams/roles
2. Implement comprehensive monitoring
3. Create custom dashboards for usage analytics
4. Establish governance policies

## 🛠️ Troubleshooting

### Issue: "Loading tools..." never completes in Cursor

**Solution 1**: Test connection with curl (see Step 6)
- If curl fails, check PAT token and account URL
- Verify network policy allows your IP

**Solution 2**: Check role permissions
```sql
SHOW GRANTS TO ROLE mcp_user_role;
```

**Solution 3**: Verify MCP server exists
```sql
SHOW MCP SERVERS;
```

### Issue: Cortex Search returns no results

**Solution 1**: Check if data exists
```sql
SELECT COUNT(*) FROM fact_support_tickets;
```

**Solution 2**: Test search service directly
```sql
SELECT * FROM TABLE(
    support_tickets_search(
        QUERY => 'test query',
        MAX_RESULTS => 5
    )
);
```

**Solution 3**: Refresh the search service
```sql
ALTER CORTEX SEARCH SERVICE support_tickets_search REFRESH;
```

### Issue: PAT token expired

**Solution**: Generate a new token
```sql
ALTER USER <YOUR_USERNAME> ADD PROGRAMMATIC ACCESS TOKEN cursor_mcp_token_2
    ROLE_RESTRICTION = 'mcp_user_role'
    DAYS_TO_EXPIRY = 90;
```
Update `mcp.json` with the new token.

### Issue: Semantic model errors

**Solution 1**: Validate YAML syntax
- Use a YAML validator online
- Check indentation (use spaces, not tabs)

**Solution 2**: Verify file upload
```sql
LIST @semantic_models;
```

**Solution 3**: Check semantic model format
- Ensure all required fields are present
- Verify table and column names match your schema

## 📁 File Structure

```
Snowflake-MCP/
├── README.md                          # This file
├── setup.sql                          # Initial database setup
├── 01_create_cortex_search.sql        # Cortex Search services
├── 02_create_semantic_model.yaml      # Semantic model for Analyst
├── 03_create_cortex_analyst.sql       # Cortex Analyst setup
├── 04_create_mcp_server.sql          # MCP server creation
├── mcp.json.example                   # Cursor configuration template
├── MCP_SETUP_GUIDE.md                # Detailed setup instructions
└── END_TO_END_PROMPT.md              # AI assistant prompt
```

## 🤝 Contributing

This is a template project designed to be customized for your specific use case. Feel free to:

1. **Fork and modify** for your data model
2. **Add new Cortex Search services** for additional tables
3. **Extend the semantic model** with more relationships
4. **Create domain-specific MCP servers** for different teams

## 📄 License

This project is provided as-is for educational and commercial use.

## 🙏 Acknowledgments

- Built following Jeremy Howard's principles of education and clarity
- Based on Snowflake's MCP server documentation
- Inspired by the Model Context Protocol community

## 📞 Support

For issues specific to:
- **Snowflake**: Contact Snowflake Support or check [docs.snowflake.com](https://docs.snowflake.com)
- **MCP Protocol**: See [modelcontextprotocol.io](https://modelcontextprotocol.io/)
- **Cursor**: Visit [cursor.sh](https://cursor.sh/)

---

Built with ❄️ by the Snowflake community

