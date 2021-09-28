-- Some Key information about the dataset and Columns
-- Dataset Used: IDA Statement Of Credits and Grants - Historical Data
-- The International Development Association (IDA) credits are public and publicly guaranteed debt extended by the World Bank Group. IDA provides development credits, grants and guarantees to its recipient member countries to help meet their development needs. Credits from IDA are at concessional rates. Data are in U.S. dollars calculated using historical rates. This dataset contains historical snapshots of the IDA Statement of Credits and Grants including the latest available snapshot. The World Bank complies with all sanctions applicable to World Bank transactions.
-- Source: https://finances.worldbank.org/Loans-and-Credits/IDA-Statement-Of-Credits-and-Grants-Historical-Dat/tdwh-3krx

CREATE DATABASE `ida_records` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
CREATE TABLE `ida_disbursed` (
  `End_of_Period` text,
  `Credit_Number` varchar(200) NOT NULL,
  `Region` text,
  `Country_Code` text,
  `Country` text,
  `Borrower` text,
  `Credit_Status` text,
  `Service_Charge_Rate` double DEFAULT NULL,
  `Currency_of_Commitment` text,
  `Project_ID` text,
  `Project_Name` text,
  `Original_Principal_Amount` double DEFAULT NULL,
  `Cancelled_Amount` double DEFAULT NULL,
  `Undisbursed_Amount` int DEFAULT NULL,
  `Disbursed_Amount` double DEFAULT NULL,
  PRIMARY KEY (`Credit_Number`),
  CONSTRAINT `Credit Number` FOREIGN KEY (`Credit_Number`) REFERENCES `ida_repayment_info` (`Credit_Number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ida_repayment_info` (
  `Credit_Number` varchar(100) NOT NULL,
  `Repaid_to_IDA` double DEFAULT NULL,
  `Due_to_IDA` double DEFAULT NULL,
  `Exchange_Adjustment` double DEFAULT NULL,
  `Borrowers_Obligation` double DEFAULT NULL,
  `Sold_3rd_Party` double DEFAULT NULL,
  `Repaid_3rd_Party` double DEFAULT NULL,
  `Due_3rd_Party` double DEFAULT NULL,
  `Credits_Held` double DEFAULT NULL,
  `First_Repayment_Date` varchar(100) DEFAULT NULL,
  `Last_Repayment_Date` varchar(100) DEFAULT NULL,
  `Agreement_Signing_Date` varchar(100) DEFAULT NULL,
  `Board_Approval_Date` varchar(100) DEFAULT NULL,
  `Effective_Date_Most_Recent` varchar(100) DEFAULT NULL,
  `Closed_Date_Most_Recent` varchar(100) DEFAULT NULL,
  `Last_Disbursement_Date` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`Credit_Number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- looking at total principal amount vs total amount disbursed amuont
 -- Shows the countries in order of most disbursed percentage to least disbursed percentage
SELECT Country,Original_Principal_Amount, Disbursed_Amount, Cancelled_Amount,  (Disbursed_Amount/Original_Principal_Amount)*100 as Actual_disbursed_percentage
FROM ida_disbursed
group by Country
Order by 5 DESC;
-- The following countries have disbursed more than what was orignally agreed upon
-- Sao Tome and Principe,Grenada,Mozambique,Central Africa,Uzbekistan,Bhutan,St. Lucia,Eastern Africa,Georgia,Armenia,Mongolia,Tonga,Cambodia,Kyrgyz Republic,Albania,Eritrea,Angola,St. Kitts and Nevis,North Macedonia


-- Shows what % of amount still needs to be repaid
SELECT d.Country, d.Disbursed_Amount, r.Due_to_IDA, (r.Due_to_IDA/d.Disbursed_Amount)*100 as '% Amount to be repaid'
FROM ida_disbursed as d
INNER JOIN ida_repayment_info as r on d.Credit_number = r.Credit_Number
Group by d.Country
ORDER BY 4 DESC;
-- The following countries need to repay more than the amount they have disbursed
-- Zimbabwe,Lebanon,South Sudan

-- Top 10 Countries that owe the most money to IDA as of recently
SELECT d.Country, d.Disbursed_Amount, r.Due_to_IDA
FROM ida_disbursed as d
INNER JOIN ida_repayment_info as r on d.Credit_number = r.Credit_Number
Group by d.Country
Order by 3 DESC
LIMIT 10;
-- Lebanon,Iraq,South Sudan,Cambodia,Kyrgyz Republic,Fiji,Timor-Leste,Eritrea,Albania,Uzbekistan,

-- Top 10 Countries that have the most number of projects
SELECT Country, COUNT("Project Name") as "Number of Projects"
FROM ida_disbursed
GROUP BY Country
ORDER BY 2 DESC
LIMIT 10;
-- India,Bangladesh,Pakistan,Tanzania,Ghana,Senegal,Kenya,Ethiopia,Vietnam,Uganda

-- Seeing if the countries that have disbursed the most have a high number of projects
SELECT d.Country, d.Disbursed_Amount, count("p.Project Name") as "Number of Projects", r.Due_to_IDA
FROM ida_disbursed as d
INNER JOIN ida_repayment_info as r on d.Credit_number = r.Credit_Number
Group by d.Country
Order by 2 DESC;
-- Apart from India, no one other country from the list above has disbursed the most amount. Therefore, number of projects doesnt correlate to the amount disbursed. 
-- Hence proving causation doesnt mean corelation.


-- Breaking things down by region (Which region disbured the most amount)
SELECT d.Region, d.Disbursed_Amount
FROM ida_disbursed as d
INNER JOIN ida_repayment_info as r on d.Credit_number = r.Credit_Number
Group by d.Region
Order by 2 DESC;

-- Breaking things down by region (Which regions owe the most amount)

SELECT d.Region, r.Due_to_IDA
FROM ida_disbursed as d
INNER JOIN ida_repayment_info as r on d.Credit_number = r.Credit_Number
WHERE r.Due_to_IDA > 0
Group by d.Region
Order by 2 DESC;

-- Total aomunt disbursed by IDA and amount that has been repayed until now
SELECT sum(d.Disbursed_Amount) as Total_amount_disbursed, sum(r.Repaid_to_IDA) as Total_amount_repayed,  (sum(r.Repaid_to_IDA))/(sum(d.Disbursed_Amount))*100 as '%_still_remaining_to_be_paid'
FROM ida_disbursed as d
INNER JOIN ida_repayment_info as r on d.Credit_number = r.Credit_Number; 

-- Checking principal amount and cancelled amount and calculation percentage of amount that is cancelled
-- Also, checking the average percentage of amount that has been cancelled

SELECT `Original_Principal_Amount`, `Cancelled_Amount`
FROM ida_disbursed;
SELECT sum(`Original_Principal_Amount`) as total_principal_amount,sum(`Cancelled_Amount`) as total_cancelled_amount, (sum(`Cancelled_Amount`))/(sum(`Original_Principal_Amount`))* 100 as average_percentage_canacelled
FROM ida_disbursed;
-- On an average, 7% of the orignal principal amount gets cancelled before the disbursement


-- The total amount disbursed by every country over time

SELECT d.Country, r.Agreement_Signing_Date, d.Disbursed_Amount, 
SUM(d.Disbursed_Amount) OVER (Partition by d.Country ORDER BY d.Country, r.Credit_Number) as Rolling_amount_disbursed
FROM ida_disbursed as d
JOIN ida_repayment_info as r
ON d.Credit_Number = r.Credit_Number;




-- Checking the percentage of total disbursed amount sold to third party by each country

WITH disbursed_to_3rd_party (Country, Agreement_Signing_Date, Sold_3rd_Party, Rolling_amount_disbursed,Rolling_amount_3rd_party)
as
(
SELECT d.Country, r.Agreement_Signing_Date, r.Sold_3rd_Party, 
SUM(d.Disbursed_Amount) OVER (Partition by d.Country ORDER BY d.Country, r.Credit_Number) as Rolling_amount_disbursed,
SUM(r.Sold_3rd_Party) OVER (Partition by d.Country ORDER BY d.Country, r.Credit_Number) as Rolling_amount_3rd_party
FROM ida_disbursed as d
JOIN ida_repayment_info as r
ON d.Credit_Number = r.Credit_Number
)
SELECT *, ((Rolling_amount_3rd_party/Rolling_amount_disbursed)*100) as percentage_total_sold_3rd_party
FROM disbursed_to_3rd_party;


-- Temp Table

DROP TABLE IF EXISTS PercentSoldTo3rdParty;
CREATE TEMPORARY TABLE PercentSoldTo3rdParty(
Country text,
agreement_Signing_Date VARCHAR(100), -- Using Varchar for dates because the dates in the orignal dataset are not in a MySQL supported format
Sold_3rd_Party double,
Rolling_amount_disbursed double,
Rolling_amount_3rd_party double);
INSERT INTO PercentSoldTo3rdParty
SELECT d.Country, r.Agreement_Signing_Date, r.Sold_3rd_Party, 
SUM(d.Disbursed_Amount) OVER (Partition by d.Country ORDER BY d.Country, r.Credit_Number) as Rolling_amount_disbursed,
SUM(r.Sold_3rd_Party) OVER (Partition by d.Country ORDER BY d.Country, r.Credit_Number) as Rolling_amount_3rd_party
FROM ida_disbursed as d
JOIN ida_repayment_info as r
ON d.Credit_Number = r.Credit_Number;

SELECT *, ((Rolling_amount_3rd_party/Rolling_amount_disbursed)*100) as percentage_total_sold_3rd_party
FROM PercentSoldTo3rdParty;

-- Views to store data for visualizations

CREATE VIEW PercentSoldTo3rdParty as 
SELECT d.Country, r.Agreement_Signing_Date, r.Sold_3rd_Party, 
SUM(d.Disbursed_Amount) OVER (Partition by d.Country ORDER BY d.Country, r.Credit_Number) as Rolling_amount_disbursed,
SUM(r.Sold_3rd_Party) OVER (Partition by d.Country ORDER BY d.Country, r.Credit_Number) as Rolling_amount_3rd_party
FROM ida_disbursed as d
JOIN ida_repayment_info as r
ON d.Credit_Number = r.Credit_Number;

CREATE VIEW amount_due_region as
SELECT d.Region, r.Due_to_IDA
FROM ida_disbursed as d
INNER JOIN ida_repayment_info as r on d.Credit_number = r.Credit_Number
WHERE r.Due_to_IDA > 0
Group by d.Region
Order by 2 DESC;

CREATE VIEW amount_disbursed_region as 
SELECT d.Region, d.Disbursed_Amount
FROM ida_disbursed as d
INNER JOIN ida_repayment_info as r on d.Credit_number = r.Credit_Number
Group by d.Region
Order by 2 DESC;

CREATE VIEW number_of_projects_country as
SELECT d.Country, d.Disbursed_Amount, count("p.Project Name") as "Number of Projects", r.Due_to_IDA
FROM ida_disbursed as d
INNER JOIN ida_repayment_info as r on d.Credit_number = r.Credit_Number
Group by d.Country
Order by 4 DESC;

SELECT d.Country, r.Agreement_Signing_Date, SUM(d.Disbursed_Amount)
FROM ida_disbursed as d
JOIN ida_repayment_info as r
ON d.Credit_Number = r.Credit_Number
WHERE Country = 'India' and Agreement_Signing_Date LIKE '%2011%';




