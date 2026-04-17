# Prerequisites — Snowflake Objects Required

The MCP server and notebooks in this project reference Snowflake objects that are built
separately via a dbt project (not included in this repo). This document describes what
must exist before you run the SQL scripts or notebooks.

## Database & Schemas

```
AM_SKI_RESORT
  ├── RAW         — Landing zone (dbt sources)
  ├── STAGING     — Type-safe views (dbt staging layer)
  ├── MARTS       — Dimensional model: 25 tables (dbt marts layer)
  ├── SEMANTIC    — 11 semantic views for Cortex Analyst
  ├── AGENTS      — Cortex Agents, Search Services, UDFs
  └── MCP_SERVERS — MCP server definitions (created by 02_create_mcp_server.sql)
```

## MARTS Tables (25)

| Table | Rows | Description |
|-------|------|-------------|
| DIM_CUSTOMER | 8,000 | Customer demographics, personas, pass types |
| DIM_DATE | 1,436 | Calendar with ski season, snow condition, holidays |
| DIM_LIFT | 18 | Lift metadata (type, capacity, vertical) |
| DIM_LOCATION | 21 | Resort locations and facilities |
| DIM_PRODUCT | 31 | F&B and retail product catalog |
| DIM_TICKET_TYPE | 18 | Ticket type definitions |
| FACT_FEEDBACK | 13,195 | Guest feedback with sentiment, NPS, ratings |
| FACT_FOOD_BEVERAGE | 1,277,124 | F&B transactions |
| FACT_GROOMING | 11,021 | Trail grooming runs |
| FACT_INCIDENTS | 2,834 | Safety incidents with severity and patrol response |
| FACT_LIFT_MAINTENANCE | 144 | Lift maintenance and inspection events |
| FACT_LIFT_SCANS | 9,575,177 | Individual lift scans with wait times |
| FACT_LESSONS | 33,508 | Ski school lessons |
| FACT_MARKETING | 60 | Marketing campaigns |
| FACT_PARKING | 63,705 | Parking lot utilization |
| FACT_PASS_USAGE | 610,087 | Daily visitor pass usage (skier-days) |
| FACT_RENTALS | 164,016 | Equipment rentals |
| FACT_SEASON_PASS_SALES | 18,371 | Season pass purchases |
| FACT_STAFFING | 5,536 | Daily staffing schedules by department |
| FACT_TICKET_SALES | 142,091 | Day ticket transactions |
| FACT_WEATHER | 7,976 | Daily weather observations |
| LIFT_METADATA | 18 | Lift reference data |
| LOCATION_METADATA | 21 | Location reference data |
| PRODUCT_CATALOG | 31 | Product reference data |
| TICKET_TYPE_METADATA | 18 | Ticket type reference data |

## Semantic Views (11)

These are Snowflake Semantic Views (not regular views) that provide a business-layer
abstraction for Cortex Analyst's text-to-SQL engine.

| Semantic View | Purpose | Used By (Agent Tool) |
|---------------|---------|----------------------|
| SEM_DAILY_SUMMARY | Executive daily KPIs: visits, revenue, ops | DailySummaryKPIs |
| SEM_REVENUE | Ticket, rental, F&B revenue analytics | RevenueAnalytics |
| SEM_OPERATIONS | Lift scans, wait times, maintenance, grooming | LiftOperations / LiftOperationsAnalytics |
| SEM_CUSTOMER_BEHAVIOR | Visit cadence, persona mix, loyalty | CustomerAnalytics |
| SEM_CUSTOMER_SATISFACTION | Feedback, NPS, ratings, sentiment | CustomerSatisfaction |
| SEM_STAFFING_ANALYTICS | Labor hours, coverage, scheduling | StaffingAnalytics |
| SEM_WEATHER_ANALYTICS | Temperature, snowfall, conditions | WeatherAnalytics |
| SEM_MARKETING_ANALYTICS | Campaign performance and ROI | MarketingAnalytics |
| SEM_SAFETY_INCIDENTS | Incidents, severity, patrol response | SafetyIncidents / SafetyIncidentsAnalytics |
| SEM_PASSHOLDER_ANALYTICS | Pass utilization and retention | PassholderAnalytics |
| SEM_LESSONS_ANALYTICS | Ski school revenue and bookings | SkiSchoolAnalytics |

## Cortex Agents (2)

| Agent | Model | Tools | Description |
|-------|-------|-------|-------------|
| RESORT_EXECUTIVE | claude-sonnet-4-5 | 10 semantic views | Executive BI partner across all analytics domains |
| SKI_OPS_ASSISTANT | claude-sonnet-4-5 | 4 semantic views | Operations-focused agent for lift supervisors |

Both agents use `cortex_analyst_text_to_sql` tool specs pointing to the semantic views above.

## What This Repo Creates

The SQL scripts in this directory create the **remaining** objects on top of the
prerequisites above:

| Script | Creates |
|--------|---------|
| `00_create_cortex_search.sql` | 2 Cortex Search Services (feedback_search, incident_search) |
| `01_create_custom_tools.sql` | 2 SQL UDFs (resort_kpi_summary, weather_impact_report) |
| `02_create_mcp_server.sql` | MCP Server (10 tools), RBAC role, OAuth integration |
