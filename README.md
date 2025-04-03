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

## 2. Introduction to Test Deployment

### 2.1 When to test
- **Test in development** to ensure what you’re building doesn’t break pre-existing assertions and satisfies your requirements.  
- **Run tests automatically** as an approval/CI check in your PR.  
- Do you want the outcome of your tests to prevent a pipeline from running if they discover an error?

### 2.2 Manual vs Automated Test**
* **Manual**
    - When you first run a project  
    - During development  
* **Automated**
    - When you run dbt on a schedule (deployment jobs!)  
    - When you want to merge your code (git CI checks!)

### 2.3 Four types of important test
##### **2.3.1 Test 1: Test while Adding or Modifying dbt Code (Standard development best practice!)**
In **development**, it is critical to test your changes to modeling logic while you make changes. This can help individual developers find bugs before opening a pull request.
1. **Step 1**: Develop some code.
2. **Step 2**: Run `dbt build` (Testing occurs here).
3. **Step 3**:
    - **Step 3.1**: If successful, commit code and open a Pull Request (PR).
    - **Step 3.2**: If it fails, fix bugs and return to Step 2.

#### **2.3.2 Test 2: Test while deploying your data to production**
In **production**, it is important to continue testing your code to catch failures when they happen. This can empower the data team to catch data quality issues well before stakeholders are impacted.
1. **Step 1**: Deployment triggered
2. **Step 2**: Run `dbt build` (Testing occurs here).
3. **Step 3**:
    - **Step 3.1**: If successful, deployment complete.
    - **Step 3.2**: If it fails, Rollback / Alert / page on-call engineer.

#### **2.3.3 Test 3: Test while opening pull request (Continuous Intergration Test)**
When **proposing changes / opening a pull or merge request**, we can run automated tests against our proposed changes to catch any issues that may not have been caught in the development cycle mentioned above.
1. **Step 1**: Open Pull Request
2. **Step 2**: Run `dbt build --models state:modified+` (Testing occurs here).
3. **Step 3**:
    - **Step 3.1**: If successful, mark PR as successful, allow PR to be merged.
    - **Step 3.2**: If it fails, mark PR as fail, don't allow PR to be merged

#### **2.3.4 Test 4: Test in QA branch before your dbt code reaches main**
On a **middle / qa branch**, it can be helpful to test a batch of changes that have been made in an isolated testing environment before then merging the code to the main / production branch.
1. **Step 1**: Open Pull Request
2. **Step 2**: Run `dbt build` (Testing occurs here).
3. **Step 3**:
    - **Step 3.1**: If successful, open PR from QA branch to main branch.
    - **Step 3.2**: If it fails, fix issues

### 2.4 Testing command
`dbt test` runs tests defined on models, sources, snapshots, and seeds. It expects that you have already created those resources through the appropriate commands.  

The tests to run can be selected using the `--select` flag discussed in the [node select syntax docs](https://docs.getdbt.com/reference/node-selection/syntax).

```bash
# 1. Run all tests
dbt test

# 2.Run tests for specific models
dbt test --select one_specific_model
dbt test --select customers orders

# 3.Run tests for models in a subfolder
dbt test --select matts.core.*

# 4.Run tests for all models in a package
dbt test --select some_package.*

## Note: We currently don't have any installed packages that contain tests.*

# 5.Run specific test types

## 5.1 Singular tests only
dbt test --select test_type:singular

## 5.2 Generic tests only
dbt test --select test_type:generic

# 6.Combined model and test type selections

## 6.1 Singular tests for specific models
dbt test --select one_specific_model, test_type:singular
dbt test --select orders, test_type:singular

## 6.2 Generic tests for specific models
dbt test --select one_specific_model, test_type:generic

# 7 Run source tests only
dbt test --select source:*

# 8 Run only source tests for a particular source and all its table
dbt test --select source:jaffle_shop

# 9 Run only source tests for a particular source and on of its table
dbt test --select source:jaffle_shop.orders

# 10 Store failures of your tests for easier debugging
dbt test --store failures
```

### 2.5 Testing command during deployment
```bash
# Good (Waste alot of compute engines but if the test fail, you have to rebuild your models)
dbt run # Building model
dbt test # Testing model ()

# Better (Checking raw model)
dbt test -s source:* # Testing raw source
dbt run # Building model
dbt test --exclude source:* # Other tests

# Best (run test as soon as possible -> job stop immediately in DAGs)
dbt build -fail-fast
```

### 2.6 Storing Test Failure in the Database

Traditional Way
* Run ```dbt test```
* Test Fails
* View logs -> Click into debug logs
* Find the SQL that was run
* Copy the correct part of it
* Paste it into a statement tab
* Preview data to see what rows failed

Better way: Use ```--store-failures```
* **Caveat**: A test's result will always replace previous failures for the same test.
* **Save all failures**

### 2.7 Testing Packages

#### 2.7.1 dbt_utils
`dbt_utils` is a one-stop-shop for several key functions and tests that you’ll use every day in your project.

**Here are some useful tests in `dbt_utils`:**
- `expression_is_true`
- `cardinality_equality`
- `unique_where`
- `not_null_where`
- `not_null_proportion`
- `unique_combination_of_columns`

#### 2.7.2 dbt_expectations
`dbt_expectations` contains a large number of tests that you may not find native to dbt or `dbt_utils`. If you are familiar with Python’s `great_expectations`, this package might be for you!

**Here are some useful tests in `dbt_expectations`:**
- `expect_column_values_to_be_between`
- `expect_row_values_to_have_data_for_every_n_datepart`
- `expect_column_values_to_be_within_n_moving_stdevs`
- `expect_column_median_to_be_between`
- `expect_column_values_to_match_regex_list`
- `expect_column_values_to_be_increasing`

#### 2.7.3 audit_helper
This package is utilized when you are making significant changes to your models, and you want to be sure the updates do not change the resulting data. The audit helper functions will only be run in the IDE, rather than a test performed in deployment.

**Here are some useful tools in `audit_helper`:**
- `compare_relations`
- `compare_queries`
- `compare_column_values`
- `compare_relation_columns`
- `compare_all_columns`
- `compare_column_values_verbose`

## 3. Custom Tests

### 3.1 Singular Test
Singular tests are built when you want to test an assumption about one particular model. The test should return any rows that fail the assumption. All you need is a SELECT statement in a new .sql file stored in the /tests/ folder.

```sql
-- This singular test tests the assumption that the amount column of the orders model is always greater than 5.

select 
    amount 
from {{ ref('orders') }} 
where amount <= 5
```

### 3.2 Custom Generic Test
Custom generic tests are built when you want to test the same assumption on multiple models. We can build a macro-like test, with input parameters, and apply it to any relevant models.  

You need a Jinja test tag, test name, parameters, and your SELECT statement in a new .sql file stored in the /tests/generic folder.
* UNIQUE
* NOT_NULL
* ACCEPTED_VALUES
* RELATIONSHIPS

```sql
{% test not_null(model, column_name) %}

select *  
from {{ model }}  
where {{ column_name }} is null  

{% endtest %}
```

### 3.3 Overwriting native tests

You can overwrite any test that dbt ships with. In fact, you can overwrite any *macro* that dbt utilizes!

Why would you do this?  
You may want to test for not-null-ness only under certain circumstances across your entire project, like when the column_id is not your test case, i.e., not equal to 00000.

```sql
--this is the not_null test
{% test not_null(model, column_name ) %}

select *
from {{ model }}
where {{ column_name }} is null

{% endtest %}

-- this is the not_null test, with a mod!
{% test not_null(model, column_name, column_id ) %}

select *
from {{ model }}
where {{ column_name }} is null
and {{ column_id }} is not in ('00000')

{% endtest %}
```