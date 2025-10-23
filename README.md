# SQL Interview Project: Credit Card Transaction Analysis

## Overview
This project presents 9 real-world SQL analytical problems solved using advanced SQL concepts such as **CTEs**, **Window Functions**, **Aggregations**, and **Date Functions**.  
It demonstrates SQL problem-solving and analytical thinking for interviews and practical data analysis.

---

## Dataset Information
**Table Name:** `credit_card_transcations`

| Column Name      | Description |
|------------------|-------------|
| transaction_id   | Unique identifier for each transaction |
| city             | City where the transaction occurred |
| transaction_date | Date of transaction |
| card_type        | Type of credit card used (Gold, Silver, Platinum, etc.) |
| exp_type         | Expense type (Bills, Fuel, Travel, etc.) |
| gender           | Gender of the cardholder |
| amount           | Transaction amount |

---

## Data Exploration

```sql
SELECT TOP 3 * FROM credit_card_transcations;
SELECT COUNT(*) FROM credit_card_transcations;
SELECT DISTINCT city FROM credit_card_transcations;
SELECT DISTINCT card_type FROM credit_card_transcations;
SELECT DISTINCT exp_type FROM credit_card_transcations;
SELECT DISTINCT gender FROM credit_card_transcations;
