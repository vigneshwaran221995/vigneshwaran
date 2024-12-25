USE ecomm;

SET SQL_SAFE_UPDATES = 0;

-- DATA CLEANING

-- Handling Missing Values and Outliers
-- MEAN IMPUTATION
UPDATE customer_churn c
JOIN (
	SELECT ROUND(AVG(WarehouseToHome)) AS avg_value
    FROM customer_churn
    WHERE WarehouseToHome IS NOT NULL
) AS avg_table
SET c.WarehouseToHome = avg_table.avg_value
WHERE c.WarehouseToHome IS NULL;

UPDATE customer_churn c
JOIN (
	SELECT ROUND(AVG(HourSpendOnApp)) AS avg_value
    FROM customer_churn
    WHERE HourSpendOnApp IS NOT NULL
) AS avg_table
SET c.HourSpendOnApp = avg_table.avg_value
WHERE c.HourSpendOnApp IS NULL;

UPDATE customer_churn c
JOIN (
	SELECT ROUND(AVG(OrderAmountHikeFromlastYear)) AS avg_value
    FROM customer_churn
    WHERE OrderAmountHikeFromlastYear IS NOT NULL
) AS avg_table
SET c.OrderAmountHikeFromlastYear = avg_table.avg_value
WHERE c.OrderAmountHikeFromlastYear IS NULL;

UPDATE customer_churn c
JOIN (
	SELECT ROUND(AVG(DaySinceLastOrder)) AS avg_value
    FROM customer_churn
    WHERE DaySinceLastOrder IS NOT NULL
) AS avg_table
SET c.DaySinceLastOrder = avg_table.avg_value
WHERE c.DaySinceLastOrder IS NULL;

-- MODE IMPUTATION
UPDATE customer_churn c
JOIN (
	SELECT Tenure
	FROM customer_churn
	WHERE Tenure IS NOT NULL
	GROUP BY Tenure
	ORDER BY COUNT(*) DESC
	LIMIT 1
) AS mode_table
SET c.Tenure = mode_table.Tenure
WHERE c.Tenure IS NULL;

UPDATE customer_churn c
JOIN (
	SELECT CouponUsed
	FROM customer_churn
	WHERE CouponUsed IS NOT NULL
	GROUP BY CouponUsed
	ORDER BY COUNT(*) DESC
	LIMIT 1
) AS mode_table
SET c.CouponUsed = mode_table.CouponUsed
WHERE c.CouponUsed IS NULL;

UPDATE customer_churn c
JOIN (
	SELECT OrderCount
	FROM customer_churn
	WHERE OrderCount IS NOT NULL
	GROUP BY OrderCount
	ORDER BY COUNT(*) DESC
	LIMIT 1
) AS mode_table
SET c.OrderCount = mode_table.OrderCount
WHERE c.OrderCount IS NULL;

-- OUTLIERS HANDLING
DELETE FROM customer_churn
WHERE WarehouseToHome > 100;

-- Dealing with Inconsistencies
-- REPLACE
UPDATE customer_churn
SET PreferredLoginDevice = CASE 
								WHEN PreferredLoginDevice = 'Phone' THEN 'Mobile Phone'
                                ELSE PreferredLoginDevice
						   END,
    PreferedOrderCat = CASE
							WHEN PreferedOrderCat = 'Mobile' THEN 'Mobile Phone'
                            ELSE PreferedOrderCat
					   END
WHERE PreferredLoginDevice = 'Phone' OR PreferedOrderCat = 'Mobile';

-- STANDARDIZE PAYMENT MODE VALUES
UPDATE customer_churn
SET PreferredPaymentMode = CASE
								WHEN PreferredPaymentMode = 'COD' THEN 'Cash on Delivery'
								WHEN PreferredPaymentMode = 'CC' THEN 'Credit Card'
								ELSE PreferredPaymentMode
						   END;    

-- DATA TARNSFORMATION

-- COLUMN RENAMING
ALTER TABLE customer_churn  
CHANGE COLUMN PreferedOrderCat PreferredOrderCat VARCHAR(20),
CHANGE COLUMN HourSpendOnApp HoursSpentOnApp INT;

-- CREATING NEW COLUMN
ALTER TABLE customer_churn
ADD COLUMN ComplaintReceived VARCHAR(3),
ADD COLUMN ChurnStatus VARCHAR(7);

UPDATE customer_churn
SET ComplaintReceived = IF(complain = 1, 'Yes', 'No'),
	ChurnStatus = IF(Churn = 1, 'Churned', 'Active');

-- COLUMN DROPPING
ALTER TABLE customer_churn
DROP COLUMN Churn,
DROP COLUMN Complain;

SET SQL_SAFE_UPDATES = 1;

-- DATA EXPLORATION AND ANALYSIS
-- 1
SELECT ChurnStatus,
	   COUNT(*) CustomerCount
FROM customer_churn
GROUP BY ChurnStatus
ORDER BY CustomerCount DESC;

-- 2 & 3
SELECT ChurnStatus,
	   ROUND(AVG(Tenure)) AvgTenure,
       SUM(CashbackAmount) TotalCashbackAmount
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- 4
SELECT ChurnStatus,
	   ROUND(
				(
					SELECT COUNT(*)
					FROM customer_churn 
					WHERE ComplaintReceived = 'Yes'
						  AND ChurnStatus = 'Churned'
				) / COUNT(*) * 100, 2
			) PercentageofChurnedCustomer
FROM customer_churn
WHERE ChurnStatus = 'Churned';	

-- 5
SELECT Gender,
	   COUNT(*) TotalComplaint
FROM customer_churn
WHERE ComplaintReceived = 'Yes'
GROUP BY Gender
ORDER BY TotalComplaint DESC;

-- 6
SELECT PreferredOrderCat,
	   CityTier,
       COUNT(*) ChurnedCount
FROM customer_churn
WHERE ChurnStatus = 'Churned' 
	  AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY ChurnedCount DESC
LIMIT 1;

-- 7
SELECT PreferredPaymentMode, COUNT(*) TotalPurchaseCount
FROM customer_churn
WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY TotalPurchaseCount DESC
LIMIT 1;

-- 8
SELECT PreferredLoginDevice, COUNT(*) DeviceCount
FROM customer_churn
WHERE DaySinceLastOrder > 10
GROUP BY PreferredLoginDevice
ORDER BY DeviceCount DESC;

-- 9
SELECT ChurnStatus,
	   COUNT(*) TotalCountofCustomer
FROM customer_churn
WHERE ChurnStatus = 'Active' AND HoursSpentOnApp > 3;

-- 10
SELECT ROUND(AVG(CashbackAmount), 2) AvgCashback
FROM customer_churn
WHERE HoursSpentOnApp >= 2;

-- 11
SELECT PreferredOrderCat,
       MAX(HoursSpentOnApp) MaxHoursSpent
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY MaxHoursSpent DESC;

-- 12
SELECT MaritalStatus, ROUND(AVG(OrderAmountHikeFromlastYear), 2) AvgOrderAmount
FROM customer_churn
GROUP BY MaritalStatus
ORDER BY MaritalStatus DESC;

-- 13
SELECT SUM(OrderAmountHikeFromlastYear) TotalOrderAmount
FROM customer_churn
WHERE MaritalStatus = 'Single' AND PreferredLoginDevice = 'Mobile Phone';

-- 14
SELECT PreferredPaymentMode, ROUND(AVG(NumberOfDeviceRegistered)) AvgDevicesRegistered
FROM customer_churn
WHERE PreferredPaymentMode = 'UPI';

-- 15
SELECT CityTier, 
	   COUNT(*) TotalCustomers
FROM customer_churn
GROUP BY CityTier
ORDER BY TotalCustomers DESC
LIMIT 1;

-- 16
SELECT MaritalStatus,
	   NumberOfAddress
FROM customer_churn
WHERE NumberOfAddress = (SELECT MAX(NumberOfAddress) FROM customer_churn);

-- 17
SELECT Gender,
	   SUM(CouponUsed) TotalCouponsUsed
FROM customer_churn
GROUP BY Gender
ORDER BY TotalCouponsUsed DESC
LIMIT 1;

-- 18
SELECT PreferredOrderCat,
	   ROUND(AVG(SatisfactionScore)) AvgSatisfactionScore
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY AvgSatisfactionScore;

-- 19
SELECT PreferredPaymentMode, COUNT(*) TotalOrderCount
FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card'
	  AND SatisfactionScore = (
									SELECT MAX(SatisfactionScore) 
                                    FROM customer_churn
							   );

-- 20
SELECT COUNT(*) CustomerCount
FROM customer_churn
WHERE HoursSpentOnApp = 1 
	  AND DaySinceLastOrder > 5;

-- 21 
SELECT ComplaintReceived, 
	   ROUND(AVG(SatisfactionScore)) AvgSatisfactionScore
FROM customer_churn
WHERE ComplaintReceived = 'Yes';

-- 22
SELECT PreferredOrderCat,
	   COUNT(*) CustomerCount
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY CustomerCount DESC;

-- 23
SELECT MaritalStatus,
	   ROUND(AVG(CashbackAmount), 2) AvgCashbackAmount
FROM customer_churn
WHERE MaritalStatus = 'Married';

-- 24
SELECT PreferredLoginDevice,
	   ROUND(AVG(NumberOfDeviceRegistered)) AvgNumberofDevicesRegistered
FROM customer_churn
GROUP BY PreferredLoginDevice
HAVING PreferredLoginDevice <> 'Mobile Phone';

-- 25
SELECT PreferredOrderCat,
	   COUNT(*) OrderCount
FROM customer_churn
WHERE CouponUsed > 5
GROUP BY PreferredOrderCat
ORDER BY OrderCount DESC;

-- 26
SELECT PreferredOrderCat,
	   ROUND(AVG(CashbackAmount), 2) AvgCashbackAmount
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY AvgCashbackAmount DESC
LIMIT 3;

-- 27
SELECT PreferredPaymentMode, ROUND(AVG(Tenure)) Avg_Tenure, COUNT(*) OrderCount
FROM customer_churn
GROUP BY PreferredPaymentMode
HAVING Avg_Tenure = 10 AND OrderCount > 500;


SELECT COUNT(*) OrderCount
FROM customer_churn
WHERE ChurnStatus = 'Churned' AND
	  Tenure > (SELECT AVG(Tenure) FROM customer_churn);



-- 28
SELECT 
	CASE
		WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
		WHEN WarehouseToHome <= 10 THEN 'Close Distance'
		WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
		ELSE 'Far Distance'
	END AS DistanceCategory,
	ChurnStatus,
	COUNT(*) CustomerCount
FROM customer_churn
GROUP BY DistanceCategory, ChurnStatus
ORDER BY FIELD(DistanceCategory,
			   'Very Close Distance',
               'Close Distance',
               'Moderate Distance',
               'Far Distance'
			  ),
		 ChurnStatus;


SELECT 
	CASE
		WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
		WHEN WarehouseToHome <= 10 THEN 'Close Distance'
		WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
		ELSE 'Far Distance'
	END AS DistanceCategory,
	COUNT(*) CustomerCount,
    Gender,
    PreferredOrderCat
FROM customer_churn
WHERE ChurnStatus = 'Churned'
GROUP BY DistanceCategory, Gender, PreferredOrderCat
HAVING DistanceCategory = 'Far Distance';


-- 29
SELECT *
FROM customer_churn
WHERE MaritalStatus = 'Married'
	  AND CityTier = 1
      AND OrderCount > (
							SELECT ROUND(AVG(OrderCount))
                            FROM customer_churn
                       )
ORDER BY CustomerID;

-- 30 a)
CREATE TABLE customer_returns (
	ReturnID INT PRIMARY KEY,
    CustomerID INT,
    ReturnDate DATE NOT NULL,
    RefundedAmount INT,
    FOREIGN KEY (CustomerID) REFERENCES customer_churn (CustomerID)
);

INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundedAmount) 
VALUES
	(1001, 50022, '2023-01-01', 2130),
	(1002, 50316, '2023-01-23', 2000),
	(1003, 51099, '2023-02-14', 2290),
	(1004, 52321, '2023-03-08', 2510),
	(1005, 52928, '2023-03-20', 3000),
	(1006, 53749, '2023-04-17', 1740),
	(1007, 54206, '2023-04-21', 3250),
	(1008, 54838, '2023-04-30', 1990);

-- 30 b)
SELECT 
	r.*,
    c.Tenure,
    c.PreferredLoginDevice,
    c.CityTier,
    c.WarehouseToHome,
    c.PreferredPaymentMode,
    c.Gender,
    c.HoursSpentOnApp,
    c.NumberOfDeviceRegistered,
    c.PreferredOrderCat,
    c.SatisfactionScore,
    c.MaritalStatus,
    c.NumberOfAddress,
    c.OrderAmountHikeFromlastYear,
    c.CouponUsed,
    c.OrderCount,
    c.DaySinceLastOrder,
    c.CashbackAmount
FROM customer_returns r
JOIN customer_churn c
ON c.CustomerID = r.CustomerID
WHERE c.ChurnStatus = 'Churned' AND c.ComplaintReceived = 'Yes';

SELECT PreferredPaymentMode, COUNT(*), Gender
FROM customer_churn
WHERE ChurnStatus = 'Churned'
GROUP BY PreferredPaymentMode, Gender
HAVING PreferredPaymentMode = 'Debit Card';