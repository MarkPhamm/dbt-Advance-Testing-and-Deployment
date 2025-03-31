# dbt Advance Testing

## 1. Intro to Advance Testing

###  **1.1 Testing techniques**
Testing is used in software engineering to make sure that the code does what we expect it to. In Analytics Engineering, testing allows us to make sure that the SQL transformations we write produce a model that meets our assertions. In dbt, tests are compiled to select statements. These select statements are run against your materialized models to ensure they meet your assertions. Benefits of testing include: 
* Feel comfortable and confident in the code you are writing
* Ensure your code continues to work as expected
* To help data consumers make data-informed decisions on accurate data
* To increase the likelihood of success
* To build trust in the platform
* Save time as models documented with assertions helps future you (and others) contribute to the codebase

**Testing techniques**
* Interactive / adhoc queries
* Standalone saved query
* Expected Results 

**Testing Strategies:**
* Test on a schedule: The ultimate goal is a standalone test with expected results running automatically on a schedule.
* Take action: Failures should be fixed immediately or silenced. If there is too much noise, tests become meaningless

We should test in **development** by testing the models we build using ‘dbt test’ or ‘dbt build’. In deployment, we can create jobs with these same commands to run tests on a schedule. Testing should be **automated**, **fast**, **reliable**, **informative**, and **focused**.

| Testing Attribute | Description                                   |
|-------------------|-----------------------------------------------|
| Automated         | Low effort / repeatable                       |
| Fast              | If testing takes too long, no one will do it |
| Reliable          | Believe them when they say something works    |
| Informative       | Provides clues about what to fix based on errors |
| Focused           | Every test should validate one assumption      |


--------

### **1.2 What to test and why**
There are four key use cases for testing:

1.2.1. Tests on **one database object** can be what should be contained within the columns, what should be the constraints of the table, or simply what is the grain.
    * Assert something about the data that you think is True
    * Contents on the data
    * Constraints of the table
    * The grain of the table
    
    ```yml
    - unique 
    - not_null
    - accepted_values
    - dbt_expectations.expect_column_proportion_of_unique_values_to_be_between
    ```

1.2.2. Test **how one database object refers to another database object** by checking data in one table and comparing it to another table that is either a source of truth or is less modified, has less joins, or is less likely to become infected with bad data.
    * Compare values in one model to a source of truth in another model
    * Ensure data has neither been erroneously added or removed

    ```yml
    - relationships
    - dbt_utils.equality
    - dbt_expectations.expect_table_row_count_to_equal_other_table
    ```

1.2.3. Test **something unique about your data** like specific business logic. We can create singular tests using a simple SQL select statement and apply this to one particular model.
    * Test usually involve some business logics, edge case, rare event. Usually SQL tests
    ``` sql
    -- Negative Payment Assertion
    SELECT * FROM 
    ORDERS
    WHERE payments < 0

    -- Billing total should be the sum of all Parts:
    SELECT * FROM 
    ORDERS
    WHERE subtotal + tax + credits + ... != Total
    ```

1.2.4. Test the **freshness of your raw source data** (pipeline tests) to ensure our models don’t run on stale data.
    * See if your landing tools has added raw data to your source table in the last X hours
    * Get notified if your underlying raw source data is not up to date
    * Consider as the first steps of your job to prevent models from running if data is delayed
    
    ```bash
    dbt souce freshness
    ```

1.2.5. Temporary Testing while refactoring
    * Create confidence
    * Efficiently refactoring
    * Auditing your changes while in developement
    * ```audit_helper``` package to compare your new refactored model to your existing legacy model

--------

### **1.3 Five Level of testing**
| Level         | Description                              |
|---------------|------------------------------------------|
| L1 Infancy    | No tests                                 |
| L2 Toddlerhood| Primary key testing on your final models |
| L3 Childhood  | N=5 tests per model                      |
| L4 Adolescence| Add advanced tests from packages         |
| L5 Adulthood  | High test coverage; advanced testing strategies |

--------

### **1.4 Test coverage**
Establish norms in your company for what to test and when to test. Codify these norms using the package: `dbt_meta_testing` to ensure each object has the required tests.

- **Type of test**  
- **Where is it defined**  
- **What it acts upon**  
- **How to run test**  
- **When to run test**  

**Project Repo**:
```bash
.
├── dbt_project.yml
└── models/
    ├── marts/
    │   ├── core/
    │   │   ├── _core.md
    │   │   ├── _core.yml
    │   │   ├── dim_customers.sql
    │   │   ├── fct_orders.sql
    │   │   └── intermediate/
    │   │       ├── _ _intermediate.yml
    │   │       ├── _ customer_orders_grouped.sql
    │   │       ├── _ customer_payments_grouped.sql
    │   │       └── _ order_payments__joined.sql
    ├── finance/
    │   ├── marketing/
    │   └── product/
    └── staging/
        ├── github/
        │   ├── _github.yml
        │   ├── _ stg.github_commits.sql
        │   └── _ stg.github_issues.sql
        ├── slack/
        └── zendesk/
└── tests/
    ├── test_order_payments_negative.sql
    └── test_brand_categories.sql
```
1.4.1. **Generic Tests**
* Test define in YML file: ```_core.yml```, ```_intermediate.yml```, ```_github.yml```
* Test act on:
    * columns in raw dats
    * columns in model
* To run test:
    * dbt test
    * dbt build
* When 
    * developement adhoc
    * production jobs

1.4.2. **Specific Test**
* Test defined in ```test/*.sql``` files
* Test act on: 
    * any models and fields specifically referenced
* To run test:
    * dbt test
    * dbt build
* When 
    * developement adhoc
    * production jobs

1.4.3. **Source Freshness Tests**
* Test defined: in staging/*.yml files (eg: ```_github.yml```)
* Test act on: 
    * a declared column in underlying raw data
* To run test:
    * dbt source freshness
* When
    * production jobs

1.4.4. **Project Tests**
* Test defined: in ```dbt_project.yml```
* Test act on: 
    * your whole project to test whether you have defined tests (or doc) in you *.yml files
* To run test:
    * dbt run-operation
    * github action
* When
    * developement adhoc
    * during continuous intergration checks (CI)

--------

### **1.5 Testing Package:** ```dbt_meta_testing```

dbt Model Development Workflow  
1.5.1. **Add new model to marts folder**  
   - Create new SQL model file under `models/marts/`  

1.5.2. **Run `run-operation`, which should fail**  
   ```bash
   dbt run-operation <operation_name> --args '<args>'
   ```
   *Expected: Failure (verifies the test catches issues pre-implementation)*  

1.5.3. **Add tests**  
   - Add schema or data tests in `.yml` files  
   - Create custom test files in `tests/`  

1.5.4. **Re-run `run-operation`, should now pass**  
   ```bash
   dbt run-operation <operation_name> --args '<args>'
   ```
   *Verifies fixes work*  

1.5.5. **Standardize this test and put it in a CI check**  
   - Add to `dbt_project.yml` under `tests:`  
   - Configure in CI (e.g., GitHub Actions):  
     ```yaml
     - name: Run dbt tests
       run: dbt test
     ```

1.5.6. **Open a PR, see the test pass**  
   - CI automatically runs tests on PR  
   - Verify pass in GitHub/GitLab checks  
```
**Key Notes**:  
- Steps 2 and 4 use the same command to compare before/after states  
- CI checks (Step 5) prevent merging untested code  
- PR validation (Step 6) ensures team review  

Other Project Test
Python Packages
* ```dbt-coverage```
    * Compute coverage from catalog.json and manifest.json files found in a dbt project, e.g. jaffle_shop.
* pre-commit-dbt
    * A comprehensive list of hooks to ensure the quality of your dbt projects.
    * Check-model-has-tests: Check the model has a number of tests.
    * Check-source-has-tests-by-name: Check the source has a number of tests by test name.
    * See Enforcing rules at scale with pre-commit-dbt


dbt Packages
* ```dbt_dataquality```: 
    * Access and report on the outputs from dbt source freshness (sources.json and manifest.json) and dbt test (run_results.json and manifest.json)
    * Optionally tag tests and visualize quality by type

* ```dbt-project-evaluator```
    * This package highlights areas of a dbt project that are misaligned with dbt Labs' best practices. Specifically, this package tests for:
    * This package is in its early stages!
