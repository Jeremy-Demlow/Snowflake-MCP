# End-to-End AI Assistant Prompt

Copy and paste this prompt into Cursor, Claude, or any MCP-compatible AI assistant to enable them to help you set up and use the Snowflake MCP Server.

---

## 🤖 PROMPT START

I need you to help me set up and use a Snowflake MCP (Model Context Protocol) Server that provides AI agents with access to governed financial services data. Here's what you need to know:

### Project Overview

This is a production-ready MCP server implementation that exposes 6 AI-powered tools:

1. **financial_analyst** - Cortex Analyst for natural language SQL queries
2. **support_tickets_search** - Semantic search over support tickets
3. **customer_search** - Customer data and segmentation search  
4. **campaigns_search** - Marketing campaign performance search
5. **transactions_search** - Transaction and fraud detection search
6. **risk_assessments_search** - Risk assessment and scoring search

### Repository Structure

```
mcp_talk_to_data/
├── 00_setup.sql                    # Database setup & data loading
├── 01_create_cortex_search.sql     # 5 Cortex Search services
├── 02_create_semantic_model.yaml   # Semantic model for Cortex Analyst
├── 03_create_cortex_analyst.sql    # Create Analyst service
├── 04_create_mcp_server.sql        # MCP server creation
└── mcp.json.example                # Cursor configuration

mcp_documentation/
├── README.md                       # Overview and quick start
├── SETUP_GUIDE.md                  # Detailed setup instructions
├── ARCHITECTURE.md                 # Technical architecture
└── END_TO_END_PROMPT.md            # This file
```

### Database Schema

**Database:** `snowflake_mcp_db`
**Schema:** `data`
**Warehouse:** `mcp_wh`

**Dimension Tables:**
- `dim_customers` - Customer demographics, segments, risk profiles
- `dim_campaigns` - Marketing campaign master data

**Fact Tables:**
- `fact_transactions` - Transaction history with fraud detection
- `fact_support_tickets` - Customer support interactions
- `fact_risk_assessments` - Credit, fraud, and AML risk scores
- `fact_marketing_responses` - Campaign response data

### Setup Process

The setup follows this sequence:

#### Phase 1: Foundation (00_setup.sql)
- Create database `snowflake_mcp_db` and schema `data`
- Create warehouse `mcp_wh`
- Create all dimension and fact tables
- Load sample data from AWS S3
- Create `semantic_models` stage

#### Phase 2: Search Services (01_create_cortex_search.sql)
- Create 5 Cortex Search services for semantic search
- Each service indexes specific tables for fast retrieval
- Target lag of 1 hour for data freshness

#### Phase 3: Semantic Model (02_create_semantic_model.yaml)
- Define business metrics and relationships
- Map natural language to database schema
- Include verified queries for validation
- Upload to `@semantic_models` stage

#### Phase 4: Cortex Analyst (03_create_cortex_analyst.sql)
- Create `financial_analyst` service
- Links to semantic model YAML file
- Enables natural language SQL generation

#### Phase 5: MCP Server (04_create_mcp_server.sql)
- Create MCP server `financial_services_mcp`
- Configure all 6 tools in specification
- Create `mcp_user_role` with minimal permissions
- Generate Programmatic Access Token (PAT)
- Grant necessary permissions

#### Phase 6: Client Configuration
- Update `mcp.json` with account URL and PAT token
- Enable tools in Cursor/Claude
- Test connection and tool availability

### Key Configuration Values

**Replace these placeholders:**
- `<YOUR-ORG-ACCOUNT>` - Your Snowflake account identifier (e.g., abc12345.us-east-1)
- `<YOUR_USERNAME>` - Your Snowflake username
- `<YOUR-PAT-TOKEN>` - PAT token generated in step 4

**MCP Server URL Format:**
```
https://<YOUR-ORG-ACCOUNT>.snowflakecomputing.com/api/v2/databases/snowflake_mcp_db/schemas/data/mcp-servers/financial_services_mcp
```

### Security & Governance

**Role:** `mcp_user_role`
**Permissions:**
- ✅ USAGE on database, schema, warehouse
- ✅ USAGE on MCP server
- ✅ USAGE on all Cortex Search services
- ✅ USAGE on Cortex Analyst
- ✅ SELECT on all tables
- ❌ NO WRITE access (read-only)

**PAT Token:**
- Restricted to `mcp_user_role` only
- 90-day expiration (configurable)
- Requires network policy to be configured

### Common Commands for You to Help With

**Check Status:**
```sql
SHOW MCP SERVERS;
DESCRIBE MCP SERVER snowflake_mcp_db.data.financial_services_mcp;
SHOW GRANTS TO ROLE mcp_user_role;
```

**Test Tools:**
```sql
-- Test Cortex Search
SELECT * FROM TABLE(
    support_tickets_search(
        QUERY => 'account balance issues',
        MAX_RESULTS => 5
    )
);

-- Test Cortex Analyst
SELECT snowflake_mcp_db.data.financial_analyst!MESSAGE(
    'What is the average lifetime value by customer segment?'
);
```

**Generate PAT Token:**
```sql
ALTER USER <USERNAME> ADD PROGRAMMATIC ACCESS TOKEN cursor_mcp_token
    ROLE_RESTRICTION = 'mcp_user_role'
    DAYS_TO_EXPIRY = 90;
```

**Verify Connection (curl):**
```bash
curl -X POST "https://<ACCOUNT-URL>/api/v2/databases/snowflake_mcp_db/schemas/data/mcp-servers/financial_services_mcp" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --header "Authorization: Bearer <PAT-TOKEN>" \
  --data '{
    "jsonrpc": "2.0",
    "id": 12345,
    "method": "tools/list",
    "params": {}
  }'
```

### Usage Examples to Demonstrate

Once setup is complete, help me use these tools for:

**Business Questions:**
- "What is the average customer lifetime value by segment?"
- "Show me the top 5 marketing campaigns by ROI"
- "How many high-risk customers require manual review?"
- "What are the most common support ticket categories?"

**Pattern Discovery:**
- "Find support tickets about account balance issues"
- "Search for suspicious transactions in the last 30 days"
- "Find premium customers with high credit scores"
- "Which campaigns targeted millennials?"

**Analysis:**
- "Analyze support ticket satisfaction scores by category"
- "Show transaction volumes by merchant category"
- "Compare campaign ROI across different channels"
- "Identify customers at risk of churn"

### Troubleshooting Steps

If something doesn't work, help me:

1. **Connection Issues:**
   - Verify account URL format
   - Check PAT token validity
   - Test with curl command
   - Verify network policy

2. **Permission Issues:**
   - Check role grants
   - Verify user has role assigned
   - Ensure PAT token has role restriction

3. **Tool Issues:**
   - Verify MCP server exists
   - Check Cortex services are created
   - Test tools directly in Snowflake
   - Refresh search services if needed

4. **Data Issues:**
   - Verify tables have data
   - Check semantic model syntax
   - Validate YAML file upload
   - Test verified queries

### Your Role as AI Assistant

Please help me:

1. **Execute the setup** - Guide me through running each script in order
2. **Troubleshoot issues** - Debug any errors that occur
3. **Verify configuration** - Ensure everything is set up correctly
4. **Demonstrate usage** - Show me how to use each tool effectively
5. **Customize** - Help me adapt this for my specific use case
6. **Monitor** - Check usage and performance
7. **Scale** - Add new tools or data sources

### Important Notes

- All SQL scripts must be run in order (00 → 04)
- PAT token can only be viewed once when generated - save it!
- Network policy must be configured before using PATs
- Semantic model file must be uploaded before creating Cortex Analyst
- Test each phase before moving to the next

### Success Criteria

Setup is complete when:
- ✅ All 6 MCP tools appear in Cursor/Claude
- ✅ Tools can be enabled and respond to queries
- ✅ Natural language questions return accurate results
- ✅ Search queries find relevant data
- ✅ All permissions are properly restricted
- ✅ Connection test (curl) succeeds

### Getting Started

Let's begin! Ask me:
1. What's my Snowflake account URL?
2. Do I want to run the full setup or start from a specific phase?
3. Am I using Cursor, Claude, or another MCP client?
4. Do I have ACCOUNTADMIN access?
5. Is my network policy already configured?

Then guide me step-by-step through the entire process, verifying each step before moving to the next.

---

## 🤖 PROMPT END

**Usage:** Copy everything between "PROMPT START" and "PROMPT END" and paste it into your AI assistant. The assistant will then have full context to help you set up and use the Snowflake MCP Server from start to finish.

