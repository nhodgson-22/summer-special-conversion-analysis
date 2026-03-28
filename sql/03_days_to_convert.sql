-- This query calculates summary statistics for time to conversion among
-- Summer Special purchasers who became active members.
-- It returns the average, minimum, and maximum days between the end of the
-- 90-day Summer Special period and the member’s conversion date.
-- Negative values indicate early conversions before the promotion ended.
WITH summer_special_summary AS (
  SELECT
    ss.member_id,
    COUNT(ss.membership_type) AS purchase_count,
    MAX(ss.join_date) AS latest_summer_special_date,
    SUM(ss.revenue) AS total_paid,
    cam.current_membership_type AS current_membership,
    cam.date_joined AS date_converted,
    CASE
      WHEN cam.current_membership_type IS NOT NULL THEN 1
      ELSE 0
    END AS converted_flag
  FROM
    `inbound-lattice-487001-i3.GitHub_project_1.summer_special_memberships` ss
  LEFT JOIN
    `inbound-lattice-487001-i3.GitHub_project_1.current_active_members` cam
  ON
    ss.member_id = cam.member_id
  GROUP BY
    ss.member_id,
    cam.current_membership_type,
    cam.date_joined
),
summer_special_conversions AS (
SELECT
  CONCAT('M', CAST(ROW_NUMBER() OVER (ORDER BY member_id) AS STRING)) AS anonymized_member_id,
  purchase_count,
  total_paid,
  current_membership,
  converted_flag,
  CASE
    WHEN summer_special_summary.date_converted IS NOT NULL THEN
      DATE_DIFF(
        summer_special_summary.date_converted,
        DATE_ADD(summer_special_summary.latest_summer_special_date, INTERVAL 90 DAY),
        DAY
      )
    ELSE NULL
  END AS days_to_convert
FROM
  summer_special_summary)

SELECT
  ROUND(AVG(days_to_convert), 0) AS avg_days_to_convert,
  MIN(days_to_convert) AS min_days_to_convert,
  MAX(days_to_convert) AS max_days_to_convert
FROM summer_special_conversions
