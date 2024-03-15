
/*
	1. What are the top 5 brands by receipts scanned for most recent month?
	   (Assume the definition of most recent month is current month)
*/
SELECT 
	B.brandName,
	COUNT(DISTINCT R.receiptId) AS receipts_scanned,
	RANK() OVER (ORDER BY COUNT(DISTINCT R.receiptId) DESC) AS current_rank
FROM 
	Receipts R
	INNER JOIN ReceiptItems RI ON R.receiptId = RI.receiptId
	INNER JOIN Brands B ON RI.brandCode = B.brandCode
WHERE 
	R.dateScanned >= DATE_FORMAT(CURRENT_DATE, '%Y-%m-01') AND
	R.dateScanned < DATE_FORMAT(CURRENT_DATE + INTERVAL 1 MONTH, '%Y-%m-01')
GROUP BY B.brandName
ORDER BY receipts_scanned DESC
LIMIT 5

/*
	2. How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
		(Assume the definition of previous month is the current month minus one month)
		Action: Based on query result, compare difference of the ranking between the recent month compare and the previous month
		
*/

WITH CurrentMonth AS (
    SELECT 
        B.brandName,
        COUNT(DISTINCT R.receiptId) AS receipts_scanned,
        RANK() OVER (ORDER BY COUNT(DISTINCT R.receiptId) DESC) AS current_rank
    FROM 
        Receipts R
        INNER JOIN ReceiptItems RI ON R.receiptId = RI.receiptId
        INNER JOIN Brands B ON RI.brandCode = B.brandCode
    WHERE 
        R.dateScanned >= DATE_FORMAT(CURRENT_DATE, '%Y-%m-01') AND
        R.dateScanned < DATE_FORMAT(CURRENT_DATE + INTERVAL 1 MONTH, '%Y-%m-01')
    GROUP BY B.brandName
    ORDER BY receipts_scanned DESC
    LIMIT 5
),
PreviousMonth AS (
    SELECT 
        B.brandName,
        COUNT(DISTINCT R.receiptId) AS receipts_scanned,
        RANK() OVER (ORDER BY COUNT(DISTINCT R.receiptId) DESC) AS previous_rank
    FROM 
        Receipts R
        INNER JOIN ReceiptItems RI ON R.receiptId = RI.receiptId
        INNER JOIN Brands B ON RI.brandCode = B.brandCode
    WHERE 
        R.dateScanned >= DATE_FORMAT(CURRENT_DATE - INTERVAL 1 MONTH, '%Y-%m-01') AND
        R.dateScanned < DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')
    GROUP BY B.brandName
    ORDER BY receipts_scanned DESC
    LIMIT 5
)

-- select the top 5 brands for the current and previous months, then uses UNION ALL to combine these results

SELECT 
    CM.brandName AS Current_Month_Brand,
    CM.receipts_scanned AS Current_Month_Receipts,
    CM.current_rank AS Current_Month_Rank,
    PM.brandName AS Previous_Month_Brand,
    PM.receipts_scanned AS Previous_Month_Receipts,
    PM.previous_rank AS Previous_Month_Rank
FROM 
    CurrentMonth CM
    LEFT JOIN PreviousMonth PM ON CM.brandName = PM.brandName

UNION ALL

SELECT 
    PM.brandName,
    NULL AS Current_Month_Receipts,
    NULL AS Current_Month_Rank,
    PM.brandName AS Previous_Month_Brand,
    PM.receipts_scanned,
    PM.previous_rank
FROM 
    PreviousMonth PM
    LEFT JOIN CurrentMonth CM ON PM.brandName = CM.brandName
WHERE 
    CM.brandName IS NULL
ORDER BY Current_Month_Receipts DESC, Previous_Month_Receipts DESC;




/*
	3. When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
		(Assume 'rejected' means 'finished' in receipts table)
	   # Action: Based on query result, directly compare the average spend for receipts with 'Accepted' status to those with 'Rejected' status
*/
SELECT 
    rewardsReceiptStatus,
    AVG(totalSpent) AS AverageSpend
FROM 
    Receipts
WHERE 
    rewardsReceiptStatus IN ('Accepted', 'Finished')
GROUP BY rewardsReceiptStatus;

/*
	4. When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
		(Assume 'rejected' means 'finished' in receipts table)
	# Action: Based on query result, directly compare the total number of items purchased for receipts with 'Accepted' status to those with 'Rejected' status
*/
SELECT 
    rewardsReceiptStatus,
    SUM(purchasedItemCount) AS TotalItemsPurchased
FROM 
    Receipts
WHERE 
    rewardsReceiptStatus IN ('Accepted', 'Finished')
GROUP BY rewardsReceiptStatus;

/*
	5. Which brand has the most spend among users who were created within the past 6 months?
	    (Assume past 6 months includes current month and the result with 'the most spend' will be identified and presented as the top finding)
*/
SELECT 
    B.brandName,
    SUM(RI.finalPrice) AS total_spend
FROM 
    Users U
    INNER JOIN Receipts R ON U.id = R.userId
    INNER JOIN ReceiptItems RI ON R.receiptId = RI.receiptId
    INNER JOIN Brands B ON RI.brandCode = B.brandCode
WHERE 
    U.createdDate >= DATE_ADD(DATE_FORMAT(NOW(), '%Y-%m-01'), INTERVAL -6 MONTH)
GROUP BY B.brandName
ORDER BY total_spend DESC
LIMIT 1;


/*
	6. Which brand has the most transactions among users who were created within the past 6 months?
		(Assume past 6 months includes current month and transaction can be considered as a unique receipt)
*/
SELECT 
    B.brandName,
    COUNT(DISTINCT R.receiptId) AS transactions
FROM 
    Users U
    INNER JOIN Receipts R ON U.id = R.userId
    INNER JOIN ReceiptItems RI ON R.receiptId = RI.receiptId
    INNER JOIN Brands B ON RI.brandCode = B.brandCode
WHERE 
    U.createdDate >= DATE_ADD(DATE_FORMAT(NOW(), '%Y-%m-01'), INTERVAL -6 MONTH)
GROUP BY B.brandName
ORDER BY transactions DESC
LIMIT 1;




