

# Prerequisites — Snowflake Objects Required

The MCP server and notebooks in this project reference Snowflake objects
that are built separately via a dbt project (not included in this repo).
This document describes what must exist before you run the SQL scripts
or notebooks.

## Database & Schemas

    AM_SKI_RESORT
      ├── RAW         — Landing zone (dbt sources)
      ├── STAGING     — Type-safe views (dbt staging layer)
      ├── MARTS       — Dimensional model: 25 tables (dbt marts layer)
      ├── SEMANTIC    — 11 semantic views for Cortex Analyst
      ├── AGENTS      — Cortex Agents, Search Services, UDFs
      └── MCP_SERVERS — MCP server definitions (created by 02_create_mcp_server.sql)

## MARTS Tables (25)

<table>
<colgroup>
<col style="width: 26%" />
<col style="width: 23%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr>
<th>Table</th>
<th>Rows</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td>DIM_CUSTOMER</td>
<td>8,000</td>
<td>Customer demographics, personas, pass types</td>
</tr>
<tr>
<td>DIM_DATE</td>
<td>1,436</td>
<td>Calendar with ski season, snow condition, holidays</td>
</tr>
<tr>
<td>DIM_LIFT</td>
<td>18</td>
<td>Lift metadata (type, capacity, vertical)</td>
</tr>
<tr>
<td>DIM_LOCATION</td>
<td>21</td>
<td>Resort locations and facilities</td>
</tr>
<tr>
<td>DIM_PRODUCT</td>
<td>31</td>
<td>F&amp;B and retail product catalog</td>
</tr>
<tr>
<td>DIM_TICKET_TYPE</td>
<td>18</td>
<td>Ticket type definitions</td>
</tr>
<tr>
<td>FACT_FEEDBACK</td>
<td>13,195</td>
<td>Guest feedback with sentiment, NPS, ratings</td>
</tr>
<tr>
<td>FACT_FOOD_BEVERAGE</td>
<td>1,277,124</td>
<td>F&amp;B transactions</td>
</tr>
<tr>
<td>FACT_GROOMING</td>
<td>11,021</td>
<td>Trail grooming runs</td>
</tr>
<tr>
<td>FACT_INCIDENTS</td>
<td>2,834</td>
<td>Safety incidents with severity and patrol response</td>
</tr>
<tr>
<td>FACT_LIFT_MAINTENANCE</td>
<td>144</td>
<td>Lift maintenance and inspection events</td>
</tr>
<tr>
<td>FACT_LIFT_SCANS</td>
<td>9,575,177</td>
<td>Individual lift scans with wait times</td>
</tr>
<tr>
<td>FACT_LESSONS</td>
<td>33,508</td>
<td>Ski school lessons</td>
</tr>
<tr>
<td>FACT_MARKETING</td>
<td>60</td>
<td>Marketing campaigns</td>
</tr>
<tr>
<td>FACT_PARKING</td>
<td>63,705</td>
<td>Parking lot utilization</td>
</tr>
<tr>
<td>FACT_PASS_USAGE</td>
<td>610,087</td>
<td>Daily visitor pass usage (skier-days)</td>
</tr>
<tr>
<td>FACT_RENTALS</td>
<td>164,016</td>
<td>Equipment rentals</td>
</tr>
<tr>
<td>FACT_SEASON_PASS_SALES</td>
<td>18,371</td>
<td>Season pass purchases</td>
</tr>
<tr>
<td>FACT_STAFFING</td>
<td>5,536</td>
<td>Daily staffing schedules by department</td>
</tr>
<tr>
<td>FACT_TICKET_SALES</td>
<td>142,091</td>
<td>Day ticket transactions</td>
</tr>
<tr>
<td>FACT_WEATHER</td>
<td>7,976</td>
<td>Daily weather observations</td>
</tr>
<tr>
<td>LIFT_METADATA</td>
<td>18</td>
<td>Lift reference data</td>
</tr>
<tr>
<td>LOCATION_METADATA</td>
<td>21</td>
<td>Location reference data</td>
</tr>
<tr>
<td>PRODUCT_CATALOG</td>
<td>31</td>
<td>Product reference data</td>
</tr>
<tr>
<td>TICKET_TYPE_METADATA</td>
<td>18</td>
<td>Ticket type reference data</td>
</tr>
</tbody>
</table>

## Semantic Views (11)

These are Snowflake Semantic Views (not regular views) that provide a
business-layer abstraction for Cortex Analyst’s text-to-SQL engine.

<table>
<colgroup>
<col style="width: 32%" />
<col style="width: 19%" />
<col style="width: 47%" />
</colgroup>
<thead>
<tr>
<th>Semantic View</th>
<th>Purpose</th>
<th>Used By (Agent Tool)</th>
</tr>
</thead>
<tbody>
<tr>
<td>SEM_DAILY_SUMMARY</td>
<td>Executive daily KPIs: visits, revenue, ops</td>
<td>DailySummaryKPIs</td>
</tr>
<tr>
<td>SEM_REVENUE</td>
<td>Ticket, rental, F&amp;B revenue analytics</td>
<td>RevenueAnalytics</td>
</tr>
<tr>
<td>SEM_OPERATIONS</td>
<td>Lift scans, wait times, maintenance, grooming</td>
<td>LiftOperations / LiftOperationsAnalytics</td>
</tr>
<tr>
<td>SEM_CUSTOMER_BEHAVIOR</td>
<td>Visit cadence, persona mix, loyalty</td>
<td>CustomerAnalytics</td>
</tr>
<tr>
<td>SEM_CUSTOMER_SATISFACTION</td>
<td>Feedback, NPS, ratings, sentiment</td>
<td>CustomerSatisfaction</td>
</tr>
<tr>
<td>SEM_STAFFING_ANALYTICS</td>
<td>Labor hours, coverage, scheduling</td>
<td>StaffingAnalytics</td>
</tr>
<tr>
<td>SEM_WEATHER_ANALYTICS</td>
<td>Temperature, snowfall, conditions</td>
<td>WeatherAnalytics</td>
</tr>
<tr>
<td>SEM_MARKETING_ANALYTICS</td>
<td>Campaign performance and ROI</td>
<td>MarketingAnalytics</td>
</tr>
<tr>
<td>SEM_SAFETY_INCIDENTS</td>
<td>Incidents, severity, patrol response</td>
<td>SafetyIncidents / SafetyIncidentsAnalytics</td>
</tr>
<tr>
<td>SEM_PASSHOLDER_ANALYTICS</td>
<td>Pass utilization and retention</td>
<td>PassholderAnalytics</td>
</tr>
<tr>
<td>SEM_LESSONS_ANALYTICS</td>
<td>Ski school revenue and bookings</td>
<td>SkiSchoolAnalytics</td>
</tr>
</tbody>
</table>

## Cortex Agents (2)

<table>
<colgroup>
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 38%" />
</colgroup>
<thead>
<tr>
<th>Agent</th>
<th>Model</th>
<th>Tools</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td>RESORT_EXECUTIVE</td>
<td>claude-sonnet-4-5</td>
<td>10 semantic views</td>
<td>Executive BI partner across all analytics domains</td>
</tr>
<tr>
<td>SKI_OPS_ASSISTANT</td>
<td>claude-sonnet-4-5</td>
<td>4 semantic views</td>
<td>Operations-focused agent for lift supervisors</td>
</tr>
</tbody>
</table>

Both agents use `cortex_analyst_text_to_sql` tool specs pointing to the
semantic views above.

## What This Repo Creates

The SQL scripts in this directory create the **remaining** objects on
top of the prerequisites above:

<table>
<colgroup>
<col style="width: 47%" />
<col style="width: 52%" />
</colgroup>
<thead>
<tr>
<th>Script</th>
<th>Creates</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>00_create_cortex_search.sql</code></td>
<td>2 Cortex Search Services (feedback_search, incident_search)</td>
</tr>
<tr>
<td><code>01_create_custom_tools.sql</code></td>
<td>2 SQL UDFs (resort_kpi_summary, weather_impact_report)</td>
</tr>
<tr>
<td><code>02_create_mcp_server.sql</code></td>
<td>MCP Server (10 tools), RBAC role, OAuth integration</td>
</tr>
</tbody>
</table>
