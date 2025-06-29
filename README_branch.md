# How to use the branch
 
 Option 1: Clone the Fork and Branch

  # Clone the fork directly
  git clone https://github.com/orioldc/datasketches-bigquery.git
  cd datasketches-bigquery

  # Switch to the compatibility fix branch
  git checkout theta-sketch-compatibility-fix

  # Deploy the new functions
  make install

  Option 2: Add the Fork as a Remote

  # If they already have the original repo
  git remote add oriol-fork https://github.com/orioldc/datasketches-bigquery.git
  git fetch oriol-fork

  # Check out the branch
  git checkout -b theta-sketch-compatibility-fix oriol-fork/theta-sketch-compatibility-fix

  Option 3: Download Specific Files

  People can download just the new functions they need:
  - https://github.com/orioldc/datasketches-bigquery/blob/theta-sketch-compatibility-fix/theta/sqlx/theta_sketch_union_math.sqlx
  - https://github.com/orioldc/datasketches-bigquery/blob/theta-sketch-compatibility-fix/theta/sqlx/theta_sketch_intersection_math.sqlx
  - etc.

  Share Instructions

  You can share your branch like this:

  ## Using the Theta Sketch Compatibility Fix

  To use the mathematical wrapper functions that solve .mjs/.js compatibility issues:

  ### Quick Start
  ```bash
  git clone https://github.com/orioldc/datasketches-bigquery.git
  cd datasketches-bigquery
  git checkout theta-sketch-compatibility-fix

  Direct Branch Link

  https://github.com/orioldc/datasketches-bigquery/tree/theta-sketch-compatibility-fix

  New Functions Available

  - theta_sketch_union_math() - Compatible union
  - theta_sketch_intersection_math() - Mathematical intersection
  - theta_sketch_a_not_b_math() - Mathematical A-not-B
  - Plus documentation and examples

  Usage

  Replace problematic functions:
  -- OLD (broken): theta_sketch_intersection(sketchA, sketchB)
  -- NEW (works):  theta_sketch_intersection_math(sketchA, sketchB, 9001)
