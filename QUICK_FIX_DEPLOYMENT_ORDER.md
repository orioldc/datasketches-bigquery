# Quick Fix: Function Deployment Order Issue

## Problem
The mathematical wrapper functions are failing to deploy because they depend on basic functions that haven't been created yet.

**Error you're seeing:**
```
bigquery error: Function not found: bq_util_functions.theta_sketch_get_estimate
```

## Immediate Solution

Try these commands in order:

### Option 1: Deploy in Phases
```bash
# 1. Deploy basic functions first (excluding math functions)
dataform run --tags "theta" --exclude-tags "math"

# 2. Then deploy all functions (math functions will now find their dependencies)
dataform run --tags "theta"
```

### Option 2: Manual Step-by-Step
```bash
# 1. Upload WebAssembly artifacts
make theta.upload

# 2. Deploy only basic functions first
dataform run theta/sqlx/theta_sketch_get_estimate.sqlx
dataform run theta/sqlx/theta_sketch_agg_union.sqlx
dataform run theta/sqlx/theta_sketch_agg_string.sqlx
dataform run theta/sqlx/theta_sketch_agg_int64.sqlx

# 3. Now deploy all functions (dependencies should resolve)
make theta.create
```

### Option 3: Force Recreation
```bash
# If the above doesn't work, try recreating everything
bq rm -f ${BQ_PROJECT}:${BQ_DATASET}.theta_sketch_get_estimate
bq rm -f ${BQ_PROJECT}:${BQ_DATASET}.theta_sketch_agg_union

# Then redeploy all
make theta.create
```

## Root Cause
The mathematical wrapper functions depend on basic functions like:
- `theta_sketch_get_estimate` 
- `theta_sketch_agg_union`

Dataform was trying to create the math functions before their dependencies existed.

## What We Fixed
1. **Added explicit dependencies** to all math functions
2. **Added "math" tag** so they can be excluded during initial deployment
3. **Updated installation guide** with proper deployment order

After these fixes are applied, `make theta.install` should work correctly for new installations.