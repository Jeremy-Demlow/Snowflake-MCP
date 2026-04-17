USE DATABASE AM_SKI_RESORT;
USE SCHEMA AGENTS;
USE WAREHOUSE COMPUTE_WH;

CREATE OR REPLACE CORTEX SEARCH SERVICE feedback_search
ON feedback_text
ATTRIBUTES feedback_id, customer_id, customer_segment, category, subcategory, rating, sentiment, nps_score, source, feedback_type
WAREHOUSE = COMPUTE_WH
TARGET_LAG = '1 hour'
AS (
    SELECT
        feedback_id,
        customer_id,
        customer_segment,
        feedback_date,
        visit_date,
        feedback_type,
        category,
        subcategory,
        rating,
        sentiment,
        sentiment_score,
        feedback_text,
        response_text,
        nps_score,
        likelihood_to_recommend,
        likelihood_to_return,
        source,
        resolved,
        response_time_days
    FROM AM_SKI_RESORT.MARTS.FACT_FEEDBACK
    WHERE feedback_text IS NOT NULL
);

CREATE OR REPLACE CORTEX SEARCH SERVICE incident_search
ON description
ATTRIBUTES incident_id, incident_type, severity, trail_name, customer_skill_level, cause, weather_factor, patrol_response_minutes, severity_score, location_id
WAREHOUSE = COMPUTE_WH
TARGET_LAG = '1 hour'
AS (
    SELECT
        incident_id,
        incident_date,
        incident_time,
        incident_type,
        severity,
        severity_score,
        location_id,
        lift_id,
        trail_name,
        customer_id,
        customer_segment,
        customer_age,
        customer_skill_level,
        description,
        cause,
        weather_factor,
        equipment_factor,
        first_aid_rendered,
        transport_required,
        patrol_response_minutes,
        resolution,
        followup_required
    FROM AM_SKI_RESORT.MARTS.FACT_INCIDENTS
    WHERE description IS NOT NULL
);

SELECT 'Testing feedback_search...' AS test_step;
SELECT * FROM TABLE(
    feedback_search(
        QUERY => 'long lift lines and wait times',
        MAX_RESULTS => 3
    )
);

SELECT 'Testing incident_search...' AS test_step;
SELECT * FROM TABLE(
    incident_search(
        QUERY => 'collision on advanced trail',
        MAX_RESULTS => 3
    )
);

SELECT 'Cortex Search Services created successfully' AS status;
