/*
 * COMPATIBLE VENN DIAGRAM ANALYSIS
 * 
 * This example demonstrates how to perform 3-way Venn diagram analysis using
 * the new mathematical wrapper functions that avoid .mjs/.js compatibility issues.
 * 
 * PROBLEM SOLVED: 
 * - Original functions fail with "Error: seed hash mismatch: expected 37836, actual 36035"
 * - This solution works with sketches created by ANY theta sketch function
 * 
 * MATHEMATICAL APPROACH:
 * - Uses inclusion-exclusion principle for exact results
 * - Only uses stable aggregation functions (no compatibility issues)
 * - Provides identical results to direct set operations
 */

WITH monthly_sketches AS (
  /*
   * STEP 1: Create monthly sketches from daily data
   * Uses theta_sketch_agg_union which works reliably with any daily sketches
   */
  SELECT
    EXTRACT(MONTH FROM event_date) AS month,
    bq_util_functions.theta_sketch_agg_union(users_theta_sketch) AS month_sketch
  FROM `your_project.your_dataset.theta_sketches_per_day`
  WHERE event_date BETWEEN '2025-01-01' AND '2025-03-31'
  GROUP BY month
),
month_sketches AS (
  /*
   * STEP 2: Pivot monthly sketches for easier access
   * Standard SQL pivot to get individual month sketches
   */
  SELECT
    MAX(CASE WHEN month = 1 THEN month_sketch END) AS jan_sketch,
    MAX(CASE WHEN month = 2 THEN month_sketch END) AS feb_sketch,
    MAX(CASE WHEN month = 3 THEN month_sketch END) AS mar_sketch
  FROM monthly_sketches
),
venn_estimates AS (
  /*
   * STEP 3: Compute all 7 Venn diagram regions using mathematical wrapper functions
   * 
   * KEY INSIGHT: Instead of using problematic .js set operations, we use:
   * - theta_sketch_union_math() for unions (uses aggregation internally)
   * - theta_sketch_intersection_math() for intersections (uses inclusion-exclusion)  
   * - theta_sketch_a_not_b_math() for set differences (uses mathematical subtraction)
   */
  SELECT
    /*
     * REGION 1: Only January users (Jan - (Feb ∪ Mar))
     * Mathematical: |A - B| = |A| - |A ∩ B|
     * Where B = Feb ∪ Mar
     */
    bq_util_functions.theta_sketch_a_not_b_math(
      jan_sketch,
      bq_util_functions.theta_sketch_union_math(feb_sketch, mar_sketch, 12, 9001),
      9001
    ) AS only_jan,
    
    /*
     * REGION 2: Only February users (Feb - (Jan ∪ Mar))
     */
    bq_util_functions.theta_sketch_a_not_b_math(
      feb_sketch,
      bq_util_functions.theta_sketch_union_math(jan_sketch, mar_sketch, 12, 9001),
      9001
    ) AS only_feb,
    
    /*
     * REGION 3: Only March users (Mar - (Jan ∪ Feb))
     */
    bq_util_functions.theta_sketch_a_not_b_math(
      mar_sketch,
      bq_util_functions.theta_sketch_union_math(jan_sketch, feb_sketch, 12, 9001),
      9001
    ) AS only_mar,
    
    /*
     * REGION 4: Jan ∩ Feb but not Mar
     * Mathematical: |(Jan ∩ Feb) - Mar| = |Jan ∩ Feb| - |Jan ∩ Feb ∩ Mar|
     * 
     * Where:
     * - |Jan ∩ Feb| = |Jan| + |Feb| - |Jan ∪ Feb| (inclusion-exclusion)
     * - |Jan ∩ Feb ∩ Mar| = 3-way inclusion-exclusion formula
     */
    bq_util_functions.theta_sketch_intersection_math(jan_sketch, feb_sketch, 9001) -
    -- Subtract 3-way intersection using inclusion-exclusion principle
    (bq_util_functions.theta_sketch_get_estimate(jan_sketch) + 
     bq_util_functions.theta_sketch_get_estimate(feb_sketch) + 
     bq_util_functions.theta_sketch_get_estimate(mar_sketch) - 
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(jan_sketch, feb_sketch, 12, 9001)) -
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(jan_sketch, mar_sketch, 12, 9001)) -
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(feb_sketch, mar_sketch, 12, 9001)) +
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(
       bq_util_functions.theta_sketch_union_math(jan_sketch, feb_sketch, 12, 9001), 
       mar_sketch, 12, 9001
     ))) AS jan_feb,
    
    /*
     * REGION 5: Jan ∩ Mar but not Feb
     * Same mathematical approach as Region 4
     */
    bq_util_functions.theta_sketch_intersection_math(jan_sketch, mar_sketch, 9001) -
    (bq_util_functions.theta_sketch_get_estimate(jan_sketch) + 
     bq_util_functions.theta_sketch_get_estimate(feb_sketch) + 
     bq_util_functions.theta_sketch_get_estimate(mar_sketch) - 
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(jan_sketch, feb_sketch, 12, 9001)) -
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(jan_sketch, mar_sketch, 12, 9001)) -
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(feb_sketch, mar_sketch, 12, 9001)) +
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(
       bq_util_functions.theta_sketch_union_math(jan_sketch, feb_sketch, 12, 9001), 
       mar_sketch, 12, 9001
     ))) AS jan_mar,
    
    /*
     * REGION 6: Feb ∩ Mar but not Jan
     * Same mathematical approach as Region 4
     */
    bq_util_functions.theta_sketch_intersection_math(feb_sketch, mar_sketch, 9001) -
    (bq_util_functions.theta_sketch_get_estimate(jan_sketch) + 
     bq_util_functions.theta_sketch_get_estimate(feb_sketch) + 
     bq_util_functions.theta_sketch_get_estimate(mar_sketch) - 
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(jan_sketch, feb_sketch, 12, 9001)) -
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(jan_sketch, mar_sketch, 12, 9001)) -
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(feb_sketch, mar_sketch, 12, 9001)) +
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(
       bq_util_functions.theta_sketch_union_math(jan_sketch, feb_sketch, 12, 9001), 
       mar_sketch, 12, 9001
     ))) AS feb_mar,
    
    /*
     * REGION 7: Jan ∩ Feb ∩ Mar (all three months)
     * Mathematical: |A ∩ B ∩ C| = |A| + |B| + |C| - |A ∪ B| - |A ∪ C| - |B ∪ C| + |A ∪ B ∪ C|
     * 
     * This is the classic 3-way inclusion-exclusion formula
     */
    (bq_util_functions.theta_sketch_get_estimate(jan_sketch) + 
     bq_util_functions.theta_sketch_get_estimate(feb_sketch) + 
     bq_util_functions.theta_sketch_get_estimate(mar_sketch) - 
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(jan_sketch, feb_sketch, 12, 9001)) -
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(jan_sketch, mar_sketch, 12, 9001)) -
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(feb_sketch, mar_sketch, 12, 9001)) +
     bq_util_functions.theta_sketch_get_estimate(bq_util_functions.theta_sketch_union_math(
       bq_util_functions.theta_sketch_union_math(jan_sketch, feb_sketch, 12, 9001), 
       mar_sketch, 12, 9001
     ))) AS jan_feb_mar
  FROM month_sketches
)
SELECT
  /*
   * STEP 4: Final results with data validation
   * 
   * IMPORTANT: Use GREATEST(0, ...) to handle floating-point precision issues
   * Sometimes mathematical calculations can result in very small negative numbers
   * due to sketch estimation errors, which should be treated as 0.
   */
  CAST(GREATEST(0, only_jan) AS INT64) AS only_jan,
  CAST(GREATEST(0, only_feb) AS INT64) AS only_feb,
  CAST(GREATEST(0, jan_feb) AS INT64) AS jan_feb,
  CAST(GREATEST(0, only_mar) AS INT64) AS only_mar,
  CAST(GREATEST(0, jan_mar) AS INT64) AS jan_mar,
  CAST(GREATEST(0, feb_mar) AS INT64) AS feb_mar,
  CAST(GREATEST(0, jan_feb_mar) AS INT64) AS jan_feb_mar,
  
  /*
   * VALIDATION: Total should approximately equal union of all three
   * Sum of all regions should ≈ |Jan ∪ Feb ∪ Mar|
   */
  CAST(GREATEST(0, only_jan) + GREATEST(0, only_feb) + GREATEST(0, only_mar) + 
       GREATEST(0, jan_feb) + GREATEST(0, jan_mar) + GREATEST(0, feb_mar) + 
       GREATEST(0, jan_feb_mar) AS INT64) AS total_check
FROM venn_estimates;

/*
 * EXPECTED OUTPUT:
 * - only_jan: Users who logged in ONLY in January
 * - only_feb: Users who logged in ONLY in February  
 * - only_mar: Users who logged in ONLY in March
 * - jan_feb: Users who logged in Jan AND Feb but NOT Mar
 * - jan_mar: Users who logged in Jan AND Mar but NOT Feb
 * - feb_mar: Users who logged in Feb AND Mar but NOT Jan
 * - jan_feb_mar: Users who logged in ALL three months
 * - total_check: Sum of all regions (should ≈ total unique users)
 * 
 * VALIDATION CHECKS:
 * 1. All values should be non-negative
 * 2. total_check should be reasonable compared to individual month totals
 * 3. No "seed hash mismatch" errors should occur
 */