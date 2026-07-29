##//Create Database//##
#Purpose: Create a new database to store all banking fraud transaction data.
CREATE DATABASE Banking_Fraud_DB;
USE Banking_Fraud_DB;

##//Create Table//##
#Create the Fraud_Transactions table to store customer, transaction, and fraud-related information.
CREATE TABLE Fraud_Transactions (
    Transaction_ID INT PRIMARY KEY,
    Customer_ID INT,
    Customer_Name VARCHAR(100),
    Age INT,
    Gender VARCHAR(20),
    Occupation VARCHAR(50),
    Annual_Income DECIMAL(12,2),
    Bank_Name VARCHAR(50),
    Account_Type VARCHAR(20),
    Transaction_Date DATE,
    Transaction_Time TIME,
    Amount DECIMAL(12,2),
    Transaction_Type VARCHAR(30),
    Merchant VARCHAR(100),
    Merchant_Category VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    Device_Type VARCHAR(30),
    Device_ID VARCHAR(50),
    IP_Address VARCHAR(50),
    Fraud VARCHAR(10),
    Fraud_Type VARCHAR(50),
    Risk_Score INT
);

##//Display All Records//##
##Purpose: Display all records from the Fraud_Transactions table to verify that the data has been imported successfully.
SELECT * FROM Fraud_Transactions;

##//Count Total Transactions//##
##Purpose: Count the total number of transactions available in the dataset.
SELECT COUNT(*) AS Total_Transactions
FROM Fraud_Transactions;

##//Count Fraud Transactions//##
##Purpose: Find the total number of fraudulent transactions in the dataset.
SELECT COUNT(*) AS Fraud_Transactions
FROM Fraud_Transactions
WHERE Fraud='Yes';

##//Calculate Fraud Rate//##
##Purpose: Calculate the percentage of fraudulent transactions compared to the total number of transactions
SELECT
ROUND(
COUNT(CASE WHEN Fraud='Yes' THEN 1 END)*100.0/
COUNT(*),2)
AS Fraud_Rate
FROM Fraud_Transactions;

##//Top Banks with Fraud Cases//##
##Purpose: Identify banks with the highest number of fraud transactions.
SELECT *
FROM Fraud_Transactions
ORDER BY Amount DESC
LIMIT 10;


SELECT DISTINCT Bank_Name
FROM Fraud_Transactions;

##//Fraud by State//##
##Purpose: Identify states with the highest number of fraud transactions.
SELECT
Bank_Name,
COUNT(*) AS Fraud_Count
FROM Fraud_Transactions
WHERE Fraud='Yes'
GROUP BY Bank_Name
ORDER BY Fraud_Count DESC;

##//Fraud by State//##
##Purpose: Identify states with the highest number of fraud transactions.
SELECT
State,
COUNT(*) AS Fraud_Count
FROM Fraud_Transactions
WHERE Fraud='Yes'
GROUP BY State
ORDER BY Fraud_Count DESC;

##//Fraud by Transaction Type//##
##Purpose: Analyze which transaction type (UPI, Card, NEFT, IMPS, etc.) has the highest fraud count.
SELECT
Transaction_Type,
COUNT(*) AS Fraud_Count
FROM Fraud_Transactions
WHERE Fraud='Yes'
GROUP BY Transaction_Type;

##//Top Fraud Merchants//##
##Purpose: Find merchants with the highest number of fraudulent transactions.
SELECT
Merchant,
COUNT(*) Fraud_Count
FROM Fraud_Transactions
WHERE Fraud='Yes'
GROUP BY Merchant
ORDER BY Fraud_Count DESC;

##//Average Transaction Amount//##
##Purpose: Calculate the average transaction amount across all transactions.
SELECT
AVG(Amount)
FROM Fraud_Transactions;

##//Top High-Risk Customers//##
##Purpose: Identify customers with the highest total fraud amount.
SELECT
Customer_ID,
SUM(Amount) AS Total_Amount
FROM Fraud_Transactions
WHERE Fraud='Yes'
GROUP BY Customer_ID
ORDER BY Total_Amount DESC
LIMIT 10;

##//Monthly Fraud Trend//##
##Purpose: Analyze monthly fraud transaction trends to identify seasonal patterns.
SELECT
MONTH(Transaction_Date) Month_No,
COUNT(*) Fraud_Count
FROM Fraud_Transactions
WHERE Fraud='Yes'
GROUP BY MONTH(Transaction_Date)
ORDER BY Month_No;

##//Rank Transactions by Amount//##
##Purpose: Rank all transactions based on transaction amount using a Window Function.
SELECT
Customer_ID,
Amount,
RANK() OVER(ORDER BY Amount DESC) AS Amount_Rank
FROM Fraud_Transactions;

##//Categorize Customers by Risk Score//##
##Purpose: Classify customers into High Risk, Medium Risk, and Low Risk based on their risk score.
SELECT
Customer_ID,
Risk_Score,
CASE
WHEN Risk_Score>=80 THEN 'High Risk'
WHEN Risk_Score>=50 THEN 'Medium Risk'
ELSE 'Low Risk'
END AS Risk_Level
FROM Fraud_Transactions;

##//Fraud Summary Using CTE//##
##Purpose: Create a Common Table Expression (CTE) to summarize fraud transactions by bank.
WITH FraudSummary AS
(
SELECT
Bank_Name,
COUNT(*) Fraud_Count
FROM Fraud_Transactions
WHERE Fraud='Yes'
GROUP BY Bank_Name
)
SELECT *
FROM FraudSummary;

