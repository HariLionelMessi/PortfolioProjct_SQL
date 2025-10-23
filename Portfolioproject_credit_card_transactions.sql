--=================================================================================================
-- SQL INTERVIEW PROJECT: CREDIT CARD TRANSACTION ANALYSIS
-- Objective: Solve 9 complex analytical problems using advanced SQL techniques (CTEs, Window Functions).
-- Table: credit_card_transcations
--=================================================================================================

-- DATA EXPLORATION
SELECT TOP 3 * FROM credit_card_transcations;
SELECT COUNT(*) FROM credit_card_transcations;
SELECT DISTINCT city FROM credit_card_transcations;
SELECT DISTINCT card_type FROM credit_card_transcations;
SELECT DISTINCT exp_type FROM credit_card_transcations;
SELECT DISTINCT gender FROM credit_card_transcations;



/*
PROBLEM 1: write a query to print top 5 cities 
with highest spends and their 
percentage contribution of total credit card spends 
*/
WITH CTE_total_cc_spent AS (
  -- Grand total spend (Denominator). CAST to BIGINT for safety.
  SELECT SUM(CAST(amount AS BIGINT)) AS total_cc_spent FROM credit_card_transcations
)

SELECT TOP 5 *,
  CAST ((cc_spent * 100.0 / total_cc_spent) AS decimal(4,2)) as pct_cc_spent
FROM  (
  -- Calculate total spend per city (Numerator).
  SELECT city, SUM(amount) as cc_spent FROM credit_card_transcations
  GROUP BY city) A
CROSS JOIN CTE_total_cc_spent
ORDER BY cc_spent DESC



/*
PROBLEM 2: write a query to print highest 
spend month and amount spent in that 
month for each card type
*/
WITH CTE_cardwise_yr_month_cc_spent AS (
  -- Aggregate total spend by card type and month.
  SELECT 
    card_type, DATEPART(YEAR, transaction_date) AS yr,
    DATEPART(MONTH, transaction_date) AS mth,
    SUM(amount) AS cc_amt_spent
  FROM credit_card_transcations
  GROUP BY card_type, DATEPART(YEAR, transaction_date),
  DATEPART(MONTH, transaction_date)
)

SELECT * FROM (
  -- Rank the spend within each card type partition.
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY card_type ORDER BY cc_amt_spent DESC) as rnk
  FROM CTE_cardwise_yr_month_cc_spent
) AS RankedData
WHERE rnk = 1



/*
PROBLEM 3: write a query to print the transaction 
details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total 
spends(We should have 4 rows in the o/p one for each card type)
*/
WITH CTE_running_sum AS (
  -- Calculate the cumulative spend for each card type.
  SELECT *,
    SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as running_sum
  FROM credit_card_transcations
)

SELECT * FROM (
  -- Rank transactions after the threshold is met, ordered by date/running sum.
  SELECT *,
    ROW_NUMBER() OVER(PARTITION BY card_type ORDER BY running_sum) as rnk
  FROM CTE_running_sum
  WHERE running_sum >= 1000000
) AS data 
WHERE rnk = 1


/*
PROBLEM 4: write a query to find city which had lowest percentage spend for gold card type
*/

WITH CTE_TotalGold AS (
  -- Grand total Gold spend (Denominator).
  SELECT SUM(amount) as total_gold_cc_spent FROM credit_card_transcations
  WHERE card_type = 'Gold'
),
CTE_CityGold AS (
  -- Gold spend per city (Numerator).
  SELECT TOP 1 city, SUM(amount) AS gold_cc_spent FROM credit_card_transcations
  WHERE card_type = 'Gold'
  GROUP BY city
  ORDER BY gold_cc_spent ASC
)

SELECT *,
  CAST (((100.0 * gold_cc_spent) / total_gold_cc_spent) AS DECIMAL(10,5) ) AS pct_gold_cc
FROM CTE_CityGold
CROSS JOIN CTE_TotalGold


/*
PROBLEM 5: write a query to print 3 columns:  
city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
*/
WITH city_exptype_cte AS (
  -- Aggregate total spend by city and expense type.
  SELECT 
    city, exp_type, SUM(amount) as cc_spent
  FROM credit_card_transcations
  GROUP BY city, exp_type
),
ranked_data_cte AS (
  -- Rank spend within each city for both high (DESC) and low (ASC) spend.
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY city ORDER BY cc_spent DESC) as max_spent,
    ROW_NUMBER() OVER (PARTITION BY city ORDER BY cc_spent ASC) as min_spent
  FROM city_exptype_cte
)

SELECT  
  city,
  -- Use conditional aggregation to pivot the highest expense type (rnk=1 DESC).
  MAX(CASE WHEN max_spent=1 THEN exp_type END) as highest_expense_type,
  -- Use conditional aggregation to pivot the lowest expense type (rnk=1 ASC).
  MAX(CASE WHEN min_spent=1 THEN exp_type END) as lowest_expense_type
FROM ranked_data_cte
WHERE max_spent = 1 OR min_spent = 1
GROUP BY city


/*
PROBLEM 6: write a query to find percentage 
contribution of spends by females for 
each expense type
*/
WITH female_contribution AS (
  -- Aggregate total spend and total female spend using conditional sum.
  SELECT exp_type,
    SUM(amount) as total_amt_spent,
    SUM(CASE WHEN gender='F' THEN amount END) AS contribution_of_females
  FROM credit_card_transcations
  GROUP BY exp_type
)

SELECT *,
  CAST (
  ((100.0 * contribution_of_females) / total_amt_spent)
  AS DECIMAL(4,2)) as female_contrib_pct
FROM female_contribution


/*
PROBLEM 7 which card and expense type 
combination saw highest month 
over month growth in Jan-2014
*/
WITH initial_data_cte AS (
  -- Aggregate monthly spend by card/expense combination.
  SELECT 
    card_type,exp_type, FORMAT(transaction_date, 'yyyyMM') as yr_mth,
    SUM(amount) AS cc_spent
  FROM credit_card_transcations
  GROUP BY card_type, exp_type, FORMAT(transaction_date, 'yyyyMM')
),
prev_cc_spent_cte AS (
  -- Use LAG to fetch the spend from the previous month in the sequence.
  SELECT *,
    LAG(cc_spent,1) OVER (PARTITION BY card_type, exp_type ORDER BY yr_mth ASC) as prev_spent
  FROM initial_data_cte
)

SELECT TOP 1 * FROM prev_cc_spent_cte
WHERE yr_mth = '201401'
ORDER BY (cc_spent -prev_spent) DESC


/*
PROBLEM 8: During weekends, which city has the highest total spend to total number of transactions ratio (Average Transaction Value).
*/
WITH initial_data AS (
  -- Filter for weekend transactions only.
  SELECT 
    city,
    SUM(amount) as weekend_cc_spent,
    COUNT(1) as total_transactions
  FROM credit_card_transcations
  WHERE DATENAME(WEEKDAY, transaction_date) IN ('Saturday', 'Sunday')
  GROUP BY city
)

SELECT  TOP 1 *, (1.0 * weekend_cc_spent)/total_transactions as ratio FROM initial_data
ORDER BY ratio DESC


/*
PROBLEM 9: which city took least number of days to 
reach its 500th transaction after the first transaction in that city
*/
WITH initial_data AS(
  SELECT city, transaction_date, amount
  FROM credit_card_transcations
),

ranked_data AS (
  -- Rank all transactions within each city (rnk).
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY city ORDER BY transaction_date ASC) AS rnk
  FROM initial_data
),

condition_satisfied_cities AS (
  -- Filter for cities that have at least 500 transactions.
  SELECT city, COUNT(transaction_id) as total_transactions FROM credit_card_transcations
  GROUP BY city
  HAVING COUNT(transaction_id) >=500
),

final_data AS (
  -- Join the ranked data with satisfied cities, selecting only rnk 1 and rnk 500.
  SELECT A.city, transaction_date FROM ranked_data A
  INNER JOIN condition_satisfied_cities B
  ON A.city = B.city
  WHERE rnk IN (1, 500)
),

max_min_date_CTE AS (
  SELECT * FROM (
    -- Use LEAD to pair the 1st transaction date with the 500th transaction date on the same row.
    select *,
      LEAD(transaction_date, 1)  OVER (PARTITION BY city ORDER BY transaction_date) AS transaction_date_500th
    from final_data) AS data
  WHERE transaction_date_500th is NOT NULL
)

SELECT TOP 1 city FROM max_min_date_CTE
ORDER BY DATEDIFF(DAY, transaction_date, transaction_date_500th) ASC
