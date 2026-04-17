USE DATABASE AM_SKI_RESORT;
USE SCHEMA AGENTS;
USE WAREHOUSE COMPUTE_WH;

CREATE OR REPLACE FUNCTION resort_kpi_summary(p_season VARCHAR)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
    SELECT OBJECT_CONSTRUCT(
        'season', p_season,
        'visitation', (
            SELECT OBJECT_CONSTRUCT(
                'total_visits', COUNT(*),
                'unique_visitors', COUNT(DISTINCT pu.customer_id),
                'avg_hours_per_visit', ROUND(AVG(pu.hours_on_mountain), 1),
                'avg_lift_rides_per_visit', ROUND(AVG(pu.total_lift_rides), 1),
                'weekend_visits', SUM(CASE WHEN d.is_weekend THEN 1 ELSE 0 END),
                'weekday_visits', SUM(CASE WHEN NOT d.is_weekend THEN 1 ELSE 0 END)
            )
            FROM AM_SKI_RESORT.MARTS.FACT_PASS_USAGE pu
            JOIN AM_SKI_RESORT.MARTS.DIM_DATE d ON pu.date_key = d.date_key
            WHERE d.ski_season = p_season
        ),
        'revenue', (
            SELECT OBJECT_CONSTRUCT(
                'ticket_revenue', ROUND(SUM(ts.purchase_amount), 2),
                'avg_ticket_price', ROUND(AVG(ts.purchase_amount), 2),
                'ticket_count', COUNT(*)
            )
            FROM AM_SKI_RESORT.MARTS.FACT_TICKET_SALES ts
            JOIN AM_SKI_RESORT.MARTS.DIM_DATE d ON ts.purchase_date_key = d.date_key
            WHERE d.ski_season = p_season
        ),
        'operations', (
            SELECT OBJECT_CONSTRUCT(
                'total_lift_scans', COUNT(*),
                'avg_wait_minutes', ROUND(AVG(ls.wait_time_minutes), 1),
                'max_wait_minutes', MAX(ls.wait_time_minutes)
            )
            FROM AM_SKI_RESORT.MARTS.FACT_LIFT_SCANS ls
            JOIN AM_SKI_RESORT.MARTS.DIM_DATE d ON ls.date_key = d.date_key
            WHERE d.ski_season = p_season
        ),
        'satisfaction', (
            SELECT OBJECT_CONSTRUCT(
                'avg_nps', ROUND(AVG(fb.nps_score), 1),
                'avg_rating', ROUND(AVG(fb.rating), 2),
                'total_feedback', COUNT(*),
                'positive_pct', ROUND(100.0 * SUM(CASE WHEN fb.sentiment = 'positive' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1)
            )
            FROM AM_SKI_RESORT.MARTS.FACT_FEEDBACK fb
            JOIN AM_SKI_RESORT.MARTS.DIM_DATE d ON d.full_date = fb.feedback_date
            WHERE d.ski_season = p_season
        ),
        'safety', (
            SELECT OBJECT_CONSTRUCT(
                'total_incidents', COUNT(*),
                'avg_severity', ROUND(AVG(fi.severity_score), 2),
                'avg_patrol_response_min', ROUND(AVG(fi.patrol_response_minutes), 1)
            )
            FROM AM_SKI_RESORT.MARTS.FACT_INCIDENTS fi
            JOIN AM_SKI_RESORT.MARTS.DIM_DATE d ON d.full_date = fi.incident_date
            WHERE d.ski_season = p_season
        )
    )
$$;

CREATE OR REPLACE FUNCTION weather_impact_report(p_start_date DATE, p_end_date DATE)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
    SELECT OBJECT_CONSTRUCT(
        'date_range', OBJECT_CONSTRUCT('start', p_start_date::VARCHAR, 'end', p_end_date::VARCHAR),
        'weather_summary', (
            SELECT OBJECT_CONSTRUCT(
                'total_days', COUNT(DISTINCT w.weather_date),
                'avg_snowfall', ROUND(AVG(w.snowfall_inches), 2),
                'total_snowfall', ROUND(SUM(w.snowfall_inches), 1),
                'powder_days', SUM(CASE WHEN w.is_powder_day THEN 1 ELSE 0 END),
                'high_wind_days', SUM(CASE WHEN w.is_high_wind THEN 1 ELSE 0 END),
                'storm_days', SUM(CASE WHEN w.storm_warning THEN 1 ELSE 0 END),
                'avg_temp_high', ROUND(AVG(w.temp_high_f), 1),
                'avg_temp_low', ROUND(AVG(w.temp_low_f), 1)
            )
            FROM AM_SKI_RESORT.MARTS.FACT_WEATHER w
            WHERE w.weather_date BETWEEN p_start_date AND p_end_date
        ),
        'visitation_by_condition', (
            SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
                'snow_condition', d.snow_condition,
                'visit_days', cnt,
                'avg_daily_visits', avg_visits,
                'avg_hours', avg_hours
            )) WITHIN GROUP (ORDER BY avg_visits DESC)
            FROM (
                SELECT
                    d.snow_condition,
                    COUNT(DISTINCT d.full_date) AS cnt,
                    ROUND(COUNT(*) / NULLIF(COUNT(DISTINCT d.full_date), 0), 0) AS avg_visits,
                    ROUND(AVG(pu.hours_on_mountain), 1) AS avg_hours
                FROM AM_SKI_RESORT.MARTS.FACT_PASS_USAGE pu
                JOIN AM_SKI_RESORT.MARTS.DIM_DATE d ON pu.date_key = d.date_key
                WHERE d.full_date BETWEEN p_start_date AND p_end_date
                  AND d.snow_condition IS NOT NULL
                GROUP BY d.snow_condition
            )
        ),
        'powder_day_impact', (
            SELECT OBJECT_CONSTRUCT(
                'powder_avg_visits', ROUND(AVG(CASE WHEN w.is_powder_day THEN daily.visit_count END), 0),
                'non_powder_avg_visits', ROUND(AVG(CASE WHEN NOT w.is_powder_day THEN daily.visit_count END), 0),
                'powder_uplift_pct', ROUND(
                    100.0 * (AVG(CASE WHEN w.is_powder_day THEN daily.visit_count END)
                           - AVG(CASE WHEN NOT w.is_powder_day THEN daily.visit_count END))
                    / NULLIF(AVG(CASE WHEN NOT w.is_powder_day THEN daily.visit_count END), 0), 1)
            )
            FROM (
                SELECT pu.visit_date, COUNT(*) AS visit_count
                FROM AM_SKI_RESORT.MARTS.FACT_PASS_USAGE pu
                WHERE pu.visit_date BETWEEN p_start_date AND p_end_date
                GROUP BY pu.visit_date
            ) daily
            JOIN AM_SKI_RESORT.MARTS.FACT_WEATHER w ON w.weather_date = daily.visit_date
        )
    )
$$;

SELECT resort_kpi_summary('2024-2025') AS kpi_test;
SELECT weather_impact_report('2024-11-01'::DATE, '2025-04-30'::DATE) AS weather_test;

SELECT 'Custom tools created and tested successfully' AS status;
