{{ config(materialized='table') }}

WITH
slots_per_second AS (
    SELECT *
    FROM
        {{ ref('slots_per_second') }}

),

seconds_meeting_threshold AS (
    SELECT
        -- calculate the seconds in a week
        -- there might be times where no job was running
        60 * 60 * 24 * 7 AS seconds_in_week,
        threshold_slots,
        COUNTIF(slots >= threshold_slots) AS num_of_seconds_ge_threshold_slots
    FROM
        slots_per_second
    LEFT JOIN
        -- creates a fanout that we group by
        UNNEST([100, 200, 500, 1300, 2100]) AS threshold_slots
    GROUP BY
        1, 2
)

SELECT
    threshold_slots,
    num_of_seconds_ge_threshold_slots,
    seconds_in_week,
    num_of_seconds_ge_threshold_slots
    / seconds_in_week AS pct_of_seconds_ge_threshold_slots
FROM
    seconds_meeting_threshold
ORDER BY
    1
