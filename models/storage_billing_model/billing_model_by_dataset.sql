{{ config(materialized='table') }}


{% set region = "EU" %}
{% set active_logical_gib_price = 0.02 %}
{% set long_term_logical_gib_price = 0.01 %}
{% set active_physical_gib_price = 0.044 %}
{% set long_term_physical_gib_price = 0.022 %}


WITH
storage_sizes AS (
    SELECT
        table_schema AS dataset_name,
        project_id,
        -- Logical
        SUM(active_logical_bytes) / POWER(1024, 3) AS active_logical_gib,
        SUM(long_term_logical_bytes) / POWER(1024, 3) AS long_term_logical_gib,
        -- Physical
        SUM(active_physical_bytes) / POWER(1024, 3) AS active_physical_gib,
        SUM(active_physical_bytes - time_travel_physical_bytes)
        / POWER(1024, 3) AS active_no_time_travel_physical_gib,
        SUM(time_travel_physical_bytes)
        / POWER(1024, 3) AS time_travel_physical_gib,
        SUM(long_term_physical_bytes)
        / POWER(1024, 3) AS long_term_physical_gib
    FROM
        `{{ env_var('DBT_BIGQUERY_PROJECT') }}`.`region-{{ region }}`.INFORMATION_SCHEMA.TABLE_STORAGE_BY_ORGANIZATION
    WHERE
        -- filter out hidden datasets
        NOT STARTS_WITH(table_schema, "_")
    GROUP BY
        1, 2
),

cost_overview AS (
    SELECT
        project_id,
        dataset_name,
        -- logical
        active_logical_gib AS active_logical_gib,
        long_term_logical_gib AS long_term_logical_gib,
        -- physical
        active_no_time_travel_physical_gib AS active_no_time_travel_physical_gib, -- noqa: LT05
        time_travel_physical_gib AS time_travel_physical_gib,
        long_term_physical_gib AS long_term_physical_gib,
        -- compression ratio
        SAFE_DIVIDE(
            active_logical_gib, active_no_time_travel_physical_gib
        ) AS active_compression_ratio,
        SAFE_DIVIDE(
            long_term_logical_gib, long_term_physical_gib
        ) AS long_term_compression_ratio,
        -- costs logical
        active_logical_gib
        * {{ active_logical_gib_price }} AS active_logical_cost,
        long_term_logical_gib
        * {{ long_term_logical_gib_price }} AS long_term_logical_cost,
        -- costs physical
        active_physical_gib
        * {{ active_physical_gib_price }} AS active_physical_cost,
        long_term_physical_gib
        * {{ long_term_physical_gib_price }} AS long_term_physical_cost,
        active_no_time_travel_physical_gib
        * {{ active_physical_gib_price }} AS active_no_time_travel_physical_cost,
        -- Costs total
        (
            (active_logical_gib * {{ active_logical_gib_price }})
            + (long_term_logical_gib * {{ long_term_logical_gib_price }})
        )
        - (
            (active_physical_gib * {{ active_physical_gib_price }})
            + (long_term_physical_gib * {{ long_term_physical_gib_price }})
        ) AS total_cost_difference,
        (
            (active_logical_gib * {{ active_logical_gib_price }})
            + (long_term_logical_gib * {{ long_term_logical_gib_price }})
        )
        - (
            (active_no_time_travel_physical_gib * {{ active_physical_gib_price }})
            + (long_term_physical_gib * {{ long_term_physical_gib_price }})
        ) AS total_cost_difference_no_time_travel
    FROM
        storage_sizes
)

SELECT *
FROM cost_overview
ORDER BY 1, 2
