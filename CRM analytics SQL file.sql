create database crm_analytics;
use crm_analytics;

###accounts primary key ###
ALTER TABLE account
MODIFY COLUMN `Account ID` VARCHAR(18) NOT NULL;

ALTER TABLE account
ADD PRIMARY KEY (`Account ID`);

desc  account;

###LEAD PRIMARY KEY  ###

ALTER TABLE leads
MODIFY COLUMN `Lead ID` VARCHAR(18) NOT NULL;
ALTER TABLE leads
ADD PRIMARY KEY (`Lead ID`);
desc leads;

### Opportunity table ###
alter table `opportuinity table`
modify column `opportunity id` varchar(20) not null;
desc `opportuinity table`;
ALTER TABLE `opportuinity table`
ADD PRIMARY KEY (`Opportunity ID`);

### opportunity_produt###
alter table `opportuinity_product`
modify column `line item id` varchar(20) not null;

desc `opportuinity_product`;

select * from `opportuinity_product`;

ALTER TABLE `opportuinity_product`
ADD PRIMARY KEY (`Line Item ID`);

###user_table###
alter table `user_table`
modify column `user id` varchar(20) not null;

desc user_table;

select * from user_table;

ALTER TABLE `user_table`
ADD PRIMARY KEY (`user id`);


### refernce key / foriegn key ###
###Opportunity table → Account###
alter table `opportuinity table`
modify column `account id` varchar(20) not null; 

SELECT DISTINCT o.`Account ID`
FROM `opportuinity table` o
LEFT JOIN account a
ON o.`Account ID` = a.`Account ID`
WHERE a.`Account ID` IS NULL;

ALTER TABLE `opportuinity table`
MODIFY `Account ID` VARCHAR(18) NULL;

INSERT INTO account(`Account ID`)
SELECT DISTINCT o.`Account ID`
FROM `opportuinity table` o
LEFT JOIN account a
ON o.`Account ID` = a.`Account ID`
WHERE a.`Account ID` IS NULL;

ALTER TABLE `opportuinity table`
ADD CONSTRAINT fk_opp_account
FOREIGN KEY (`Account ID`)
REFERENCES account(`Account ID`);

###Opportunity_product → Opportunity table###

alter table `opportuinity_product`
modify column `opportunity id` varchar(20) not null;

ALTER TABLE opportuinity_product
ADD CONSTRAINT fk_lineitem_opp
FOREIGN KEY (`Opportunity ID`)
REFERENCES `opportuinity table`(`Opportunity ID`);

####Lead → Account (Converted Account)####
alter table leads
modify column `Converted Account ID` varchar(20) not null;

SELECT COUNT(*) AS total_leads,
SUM(CASE WHEN `Converted Account ID` IS NOT NULL AND `Converted Account ID` != '' THEN 1 ELSE 0 END) AS converted_leads
FROM leads;

SELECT DISTINCT l.`Converted Account ID`
FROM leads l
LEFT JOIN account a
ON l.`Converted Account ID` = a.`Account ID`
WHERE l.`Converted Account ID` IS NOT NULL
  AND l.`Converted Account ID` != ''
  AND a.`Account ID` IS NULL;
SET SQL_SAFE_UPDATES = 0;

UPDATE leads
SET `Converted Account ID` = NULL
WHERE `Converted Account ID` NOT IN (
    SELECT `Account ID` FROM account
);
ALTER TABLE leads
MODIFY `Converted Account ID` VARCHAR(18) NULL;
UPDATE leads l
LEFT JOIN account a
ON l.`Converted Account ID` = a.`Account ID`
SET l.`Converted Account ID` = NULL
WHERE a.`Account ID` IS NULL;

ALTER TABLE leads
ADD CONSTRAINT fk_lead_account
FOREIGN KEY (`Converted Account ID`)
REFERENCES account(`Account ID`);

###Lead → Opportunity (Converted Opportunity)###
ALTER TABLE leads
MODIFY `Converted Opportunity ID` VARCHAR(18) NULL;

UPDATE leads l
LEFT JOIN `opportuinity table` o
ON l.`Converted Opportunity ID` = o.`Opportunity ID`
SET l.`Converted Opportunity ID` = NULL
WHERE o.`Opportunity ID` IS NULL;

ALTER TABLE leads
ADD CONSTRAINT fk_lead_opp
FOREIGN KEY (`Converted Opportunity ID`)
REFERENCES `opportuinity table`(`Opportunity ID`);

###Created By / Modified By → User###
ALTER TABLE user_table
MODIFY `Created By ID` VARCHAR(18) NULL; 

ALTER TABLE account
MODIFY `Created By ID` VARCHAR(18);

ALTER TABLE account
ADD CONSTRAINT fk_account_user
FOREIGN KEY (`Created By ID`)
REFERENCES user_table(`User ID`);

###OPPORTUNITY DASHBOARD###
###KPIS VALUES###
### 1. TOTAL EXPECTED AMOUNT ###
	select sum(`expected amount`) as total_expected_amount
    from `opportuinity table`;
    
### 2.ACTIVE OPPORTUNITIES###
	SELECT COUNT(*) AS active_opportunities
FROM `opportuinity table`
WHERE Stage NOT IN ('Closed Won','Closed Lost');

DESCRIBE `opportuinity table`;

### 3.TOTAL OPPORTUNITIES ###
	select count(*) as total_opportunities
    from `opportuinity table`;
    
### 4. WIN RATE % ###
# WIN=(CLOSED WON/TOTAL CLOSED)*100#
	SELECT 
ROUND(
SUM(CASE WHEN `Stage` = 'Closed Won' THEN 1 ELSE 0 END) /
NULLIF(SUM(CASE WHEN `Stage` LIKE 'Closed%' THEN 1 ELSE 0 END),0) * 100
,2) AS win_rate_percentage
FROM `opportuinity table`;

### 5. LOSS RATE % ###
SELECT  
ROUND(
    SUM(CASE WHEN `Stage` = 'Closed Lost' THEN 1 ELSE 0 END) /
    NULLIF(SUM(CASE WHEN `Stage` IN ('Closed Won','Closed Lost') THEN 1 ELSE 0 END),0) * 100
,2) AS loss_rate_percent
FROM `opportuinity table`;

### 6.OPPORTUNITY CONVERSION RATE ###
SELECT 
    (COUNT(CASE WHEN Won = 'TRUE' THEN 1 END) 
    / COUNT(*))*100 AS conversion_rate
FROM `opportuinity table` ;


### 7.FORECAST AMOUNT ###
###Salesforce Forecast = SUM(Amount × Probability%)###
SELECT  
SUM(`Amount` * (`Probability (%)` / 100)) AS forecast_amount
FROM `opportuinity table`
WHERE `Stage` NOT IN ('Closed Won','Closed Lost');

### charts values ###
###1.Opportuinity by Industry ###
select `industry`,count(*) as total_opportunities
from `opportuinity table`
group by `industry`
order by total_opportunities desc;

###2.MONTHWISE EXPECTED VS FORECAST AMT###
	SELECT 
DATE_FORMAT(STR_TO_DATE(`Close Date`, '%d-%m-%Y'), '%b-%Y') AS month,
SUM(`Expected Amount`) AS total_expected_amount,

SUM(
  `Amount` *
  CASE `Stage`
    WHEN 'Prospecting' THEN 0.10
    WHEN 'Qualification' THEN 0.20
    WHEN 'Needs Analysis' THEN 0.30
    WHEN 'Value Proposition' THEN 0.50
    WHEN 'Negotiation' THEN 0.75
    WHEN 'Closed Won' THEN 1.00
    WHEN 'Closed Lost' THEN 0.00
    ELSE 0.00
  END
) AS forecast_amount

FROM `opportuinity table`
GROUP BY month
ORDER BY month;

desc `opportuinity table`;
select * from  `opportuinity table`;

###  3.Expected Amount by Opportunity Type ###
SELECT 
`Opportunity Type`,
SUM(`Expected Amount`) AS total_expected_amount
FROM `opportuinity table`
GROUP BY `Opportunity Type`
ORDER BY total_expected_amount DESC;

###4.CLOSED WON VS TOTAL OPPORTUNITIES  BY YEAR  ###
	SELECT 
YEAR(STR_TO_DATE(`Close Date`, '%Y-%m-%d')) AS year,

COUNT(*) AS total_opportunities,

SUM(CASE WHEN `Stage` = 'Closed Won' THEN 1 ELSE 0 END) AS closed_won_opportunities

FROM `opportuinity table`
WHERE `Close Date` IS NOT NULL AND `Close Date` != ''
GROUP BY year
ORDER BY year; 

### 5. yaer wise closed won amt vs total amt###
SELECT
YEAR(STR_TO_DATE(`Close Date`, '%Y-%m-%d')) AS year,
SUM(`Amount`) AS total_amount,
SUM(CASE WHEN `Stage` = 'Closed Won' THEN `Amount` ELSE 0 END) AS closed_won_amount
FROM `opportuinity table`
WHERE `Close Date` IS NOT NULL AND `Close Date` != ''
GROUP BY year
ORDER BY year;


###LEAD CRM DASHBOARD ###
###KPIS###
 ### 1.TOTAL LEADS ###
 SELECT COUNT(*) AS total_leads
FROM leads;

 ###2.CONVERTED ACCOUNTS ###
 SELECT COUNT(DISTINCT `Converted Account ID`) AS converted_accounts
FROM leads
WHERE `Converted Account ID` IS NOT NULL AND `Converted Account ID` != '';


### 3.CONVERTED OPPORTUNINTY ###
SELECT COUNT(DISTINCT `Converted Opportunity ID`) AS converted_opportunities
FROM leads
WHERE `Converted Opportunity ID` IS NOT NULL AND `Converted Opportunity ID` != '';

###4.LEAD CONVERSION RATE ###
SELECT
    (COUNT(CASE WHEN Converted = 'TRUE' THEN 1 END) / COUNT(*))*100 AS lead_conversion_rate
FROM leadS;

### LEAD CHARTS ###
###1.LEAD BY SOURCE ###
SELECT 
`Lead Source`,
COUNT(*) AS total_leads
FROM leads
GROUP BY `Lead Source`
ORDER BY total_leads DESC;

### LEAD BY STAGE ###
SELECT 
`Status`,
COUNT(*) AS total_leads
FROM leads
GROUP BY `Status`
ORDER BY total_leads DESC;

### LEAD BY INDUSTRY ###
SELECT 
`Industry`,
COUNT(*) AS total_leads
FROM leads
GROUP BY `Industry`
ORDER BY total_leads DESC;


















