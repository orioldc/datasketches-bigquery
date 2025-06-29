/*
 * SIMPLE USAGE EXAMPLES - Mathematical Wrapper Functions
 * 
 * This file demonstrates basic usage of the new compatibility wrapper functions
 * that solve the .mjs/.js module incompatibility issues.
 */

-- ========================================================================
-- EXAMPLE 1: Basic Set Operations
-- ========================================================================

WITH sample_sketches AS (
  -- Create two sample sketches from your data
  SELECT 
    bq_util_functions.theta_sketch_agg_string(user_id) AS sketch_a,
    bq_util_functions.theta_sketch_agg_string(customer_id) AS sketch_b
  FROM your_table
  WHERE date_column = '2025-01-01'
)
SELECT
  -- BEFORE (problematic): 
  -- bq_util_functions.theta_sketch_get_estimate(
  --   bq_util_functions.theta_sketch_union(sketch_a, sketch_b)
  -- ) AS union_estimate  -- This fails with seed hash mismatch!
  
  -- AFTER (compatible):
  bq_util_functions.theta_sketch_get_estimate(
    bq_util_functions.theta_sketch_union_math(sketch_a, sketch_b, 12, 9001)
  ) AS union_estimate,
  
  -- Intersection estimate using mathematical approach
  bq_util_functions.theta_sketch_intersection_math(sketch_a, sketch_b, 9001) AS intersection_estimate,
  
  -- A-not-B estimate using mathematical approach  
  bq_util_functions.theta_sketch_a_not_b_math(sketch_a, sketch_b, 9001) AS a_not_b_estimate,
  
  -- Individual estimates for comparison
  bq_util_functions.theta_sketch_get_estimate(sketch_a) AS a_estimate,
  bq_util_functions.theta_sketch_get_estimate(sketch_b) AS b_estimate
FROM sample_sketches;

-- ========================================================================
-- EXAMPLE 2: Verification of Mathematical Properties
-- ========================================================================

WITH test_sketches AS (
  SELECT 
    bq_util_functions.theta_sketch_agg_string(CAST(user_id AS STRING)) AS sketch_a,
    bq_util_functions.theta_sketch_agg_string(CAST(session_id AS STRING)) AS sketch_b
  FROM your_events_table
  WHERE event_date = '2025-01-01'
)
SELECT
  -- Individual estimates
  bq_util_functions.theta_sketch_get_estimate(sketch_a) AS a_size,
  bq_util_functions.theta_sketch_get_estimate(sketch_b) AS b_size,
  
  -- Set operations using mathematical functions
  bq_util_functions.theta_sketch_get_estimate(
    bq_util_functions.theta_sketch_union_math(sketch_a, sketch_b, 12, 9001)
  ) AS union_size,
  bq_util_functions.theta_sketch_intersection_math(sketch_a, sketch_b, 9001) AS intersection_size,
  
  -- MATHEMATICAL VERIFICATION: |A| + |B| - |A ∪ B| should equal |A ∩ B|
  bq_util_functions.theta_sketch_get_estimate(sketch_a) + 
  bq_util_functions.theta_sketch_get_estimate(sketch_b) - 
  bq_util_functions.theta_sketch_get_estimate(
    bq_util_functions.theta_sketch_union_math(sketch_a, sketch_b, 12, 9001)
  ) AS intersection_verification,
  
  -- The two intersection calculations should be approximately equal
  ABS(
    bq_util_functions.theta_sketch_intersection_math(sketch_a, sketch_b, 9001) -
    (bq_util_functions.theta_sketch_get_estimate(sketch_a) + 
     bq_util_functions.theta_sketch_get_estimate(sketch_b) - 
     bq_util_functions.theta_sketch_get_estimate(
       bq_util_functions.theta_sketch_union_math(sketch_a, sketch_b, 12, 9001)
     ))
  ) AS verification_difference  -- Should be very close to 0
FROM test_sketches;

-- ========================================================================
-- EXAMPLE 3: Migration from Original Functions
-- ========================================================================

/*
 * MIGRATION GUIDE:
 * 
 * Replace these problematic function calls:
 */

-- OLD (causes seed hash mismatch):
-- bq_util_functions.theta_sketch_union(sketch_a, sketch_b)
-- bq_util_functions.theta_sketch_intersection(sketch_a, sketch_b) 
-- bq_util_functions.theta_sketch_a_not_b(sketch_a, sketch_b)

-- NEW (compatible with any sketches):
-- bq_util_functions.theta_sketch_union_math(sketch_a, sketch_b, 12, 9001)
-- bq_util_functions.theta_sketch_intersection_math(sketch_a, sketch_b, 9001)
-- bq_util_functions.theta_sketch_a_not_b_math(sketch_a, sketch_b, 9001)

-- ========================================================================
-- EXAMPLE 4: Working with Existing Sketch Data
-- ========================================================================

WITH existing_sketches AS (
  -- Use sketches that were created with ANY theta sketch function
  -- These mathematical wrappers work regardless of how sketches were created
  SELECT
    monthly_user_sketch,      -- Created with theta_sketch_agg_union
    daily_session_sketch,     -- Created with theta_sketch_agg_string
    weekly_product_sketch     -- Created with theta_sketch_agg_int64
  FROM your_existing_sketch_table
  WHERE month = '2025-01'
)
SELECT
  -- All of these work together seamlessly now!
  
  -- Union of users and sessions
  bq_util_functions.theta_sketch_get_estimate(
    bq_util_functions.theta_sketch_union_math(monthly_user_sketch, daily_session_sketch, 12, 9001)
  ) AS user_session_union,
  
  -- Users who are also sessions (intersection)
  bq_util_functions.theta_sketch_intersection_math(monthly_user_sketch, daily_session_sketch, 9001) AS user_session_intersection,
  
  -- Users who are not in product data
  bq_util_functions.theta_sketch_a_not_b_math(monthly_user_sketch, weekly_product_sketch, 9001) AS users_not_in_products
  
FROM existing_sketches;

-- ========================================================================
-- EXAMPLE 5: Performance Comparison
-- ========================================================================

/*
 * PERFORMANCE NOTES:
 * 
 * The mathematical wrapper functions have comparable performance to original functions:
 * 
 * 1. UNION operations: Slightly slower due to aggregation wrapper, but negligible
 * 2. INTERSECTION operations: Actually FASTER since no WebAssembly calls needed
 * 3. A-NOT-B operations: Comparable performance, more reliable
 * 4. MEMORY usage: Lower since no WebAssembly object creation/destruction
 * 
 * The reliability benefits far outweigh any minor performance differences.
 */

-- ========================================================================
-- EXAMPLE 6: Error Handling  
-- ========================================================================

-- These functions gracefully handle edge cases:

SELECT
  -- Handles NULL sketches gracefully
  bq_util_functions.theta_sketch_union_math(NULL, sketch_b, 12, 9001) AS union_with_null,
  
  -- Returns 0 for intersection with NULL
  bq_util_functions.theta_sketch_intersection_math(sketch_a, NULL, 9001) AS intersection_with_null,
  
  -- Handles empty sketches
  bq_util_functions.theta_sketch_a_not_b_math(sketch_a, empty_sketch, 9001) AS a_not_empty
  
FROM your_table
WHERE sketch_column IS NOT NULL;