{{ config(materialized='table') }}

WITH
slots_usage AS (
    SELECT
        job_id,
        reservation_id,
        -- round start time down
        total_slot_ms,
        -- round end time up
        TIMESTAMP_TRUNC(start_time, SECOND) AS start_time,
        TIMESTAMP_TRUNC(
            TIMESTAMP_ADD(end_time, INTERVAL 1 SECOND), SECOND
        ) AS end_time
    FROM
        `{{ env_var('DBT_BIGQUERY_PROJECT') }}`.`region-EU`.INFORMATION_SCHEMA.JOBS_BY_ORGANIZATION
    -- change your region here
    WHERE
        -- taking the last 7 complete days
        -- this includes jobs that in after the end of the time range
        -- we take care of this further down below
        start_time BETWEEN TIMESTAMP_SUB(
            DATE_TRUNC(CURRENT_TIMESTAMP(), DAY), INTERVAL 8 DAY
        )
        AND TIMESTAMP_SUB(DATE_TRUNC(CURRENT_TIMESTAMP(), DAY), INTERVAL 1 DAY)
),


slots_with_second_array AS (
    SELECT
        *,
        GENERATE_TIMESTAMP_ARRAY(
            start_time, end_time, INTERVAL 1 SECOND
        ) AS seconds_array
    FROM
        slots_usage
),

average_job_slots_per_second AS (
    SELECT
        job_id,
        reservation_id,
        ts,
        total_slot_ms,
        (total_slot_ms / 1000) / ARRAY_LENGTH(seconds_array) AS slots
    FROM
        slots_with_second_array
    LEFT JOIN
        UNNEST(seconds_array) AS ts
    WHERE
        -- this clause is to filter out jobs that end after the time range
        -- this filter would not be automatically pushed down
        ts
        <= TIMESTAMP_SUB(DATE_TRUNC(CURRENT_TIMESTAMP(), DAY), INTERVAL 1 DAY)
),

slots_per_second AS (
    SELECT
        ts,
        COUNT(job_id) AS jobs, -- is unique per second
        SUM(slots) AS slots
    FROM
        average_job_slots_per_second
    GROUP BY
        ts
)

SELECT *
FROM
    slots_per_second
ORDER BY
    ts
