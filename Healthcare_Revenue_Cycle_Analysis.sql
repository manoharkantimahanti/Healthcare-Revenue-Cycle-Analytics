/*
=========================================================
Healthcare Revenue Cycle Analytics
SQL Analysis Portfolio
=========================================================

Database Model:
- DimDate
- DimFacility
- DimPatient
- DimPayer
- FactClaims
- FactPayments
- FactDenials
- FactAR

Purpose:
Analyze claims, payments, denials, and accounts receivable
to support healthcare revenue cycle decision-making.
=========================================================
*/


/* =====================================================
   1. CLAIM VOLUME AND FINANCIAL SUMMARY
   ===================================================== */

SELECT
    COUNT(*) AS Total_Claims,
    SUM(ChargeAmount) AS Total_Charges,
    SUM(AllowedAmount) AS Total_Allowed_Amount,
    SUM(BilledAmount) AS Total_Billed_Amount
FROM FactClaims;


/* =====================================================
   2. CLAIM STATUS ANALYSIS
   ===================================================== */

SELECT
    ClaimStatus,
    COUNT(*) AS Claim_Count,
    SUM(BilledAmount) AS Total_Billed_Amount
FROM FactClaims
GROUP BY ClaimStatus
ORDER BY Claim_Count DESC;


/* =====================================================
   3. PAYMENT / COLLECTION SUMMARY
   ===================================================== */

SELECT
    COUNT(*) AS Total_Payments,
    SUM(PaidAmount) AS Total_Paid_Amount,
    SUM(PatientResp) AS Total_Patient_Responsibility
FROM FactPayments;


/* =====================================================
   4. MONTHLY PAYMENT TREND
   ===================================================== */

SELECT
    YEAR(PaymentDate) AS Payment_Year,
    MONTH(PaymentDate) AS Payment_Month,
    SUM(PaidAmount) AS Total_Payments,
    COUNT(*) AS Payment_Count
FROM FactPayments
GROUP BY
    YEAR(PaymentDate),
    MONTH(PaymentDate)
ORDER BY
    Payment_Year,
    Payment_Month;


/* =====================================================
   5. DENIAL SUMMARY
   ===================================================== */

SELECT
    COUNT(*) AS Total_Denials,
    COUNT(DISTINCT ClaimKey) AS Claims_With_Denials
FROM FactDenials;


/* =====================================================
   6. DENIALS BY CATEGORY
   ===================================================== */

SELECT
    DenialCategory,
    COUNT(*) AS Denial_Count
FROM FactDenials
GROUP BY DenialCategory
ORDER BY Denial_Count DESC;


/* =====================================================
   7. DENIAL TREND BY MONTH
   ===================================================== */

SELECT
    YEAR(DenialDate) AS Denial_Year,
    MONTH(DenialDate) AS Denial_Month,
    COUNT(*) AS Denial_Count
FROM FactDenials
GROUP BY
    YEAR(DenialDate),
    MONTH(DenialDate)
ORDER BY
    Denial_Year,
    Denial_Month;


/* =====================================================
   8. TOP DENIAL CODES
   ===================================================== */

SELECT TOP 10
    DenialCode,
    DenialCategory,
    COUNT(*) AS Denial_Count
FROM FactDenials
GROUP BY
    DenialCode,
    DenialCategory
ORDER BY Denial_Count DESC;


/* =====================================================
   9. CLAIMS AND DENIALS BY PAYER
   ===================================================== */

SELECT
    p.PayerName,
    COUNT(DISTINCT c.ClaimKey) AS Total_Claims,
    COUNT(DISTINCT d.ClaimKey) AS Denied_Claims
FROM FactClaims c
INNER JOIN DimPayer p
    ON c.PayerKey = p.PayerKey
LEFT JOIN FactDenials d
    ON c.ClaimKey = d.ClaimKey
GROUP BY p.PayerName
ORDER BY Total_Claims DESC;


/* =====================================================
   10. CLAIMS BY FACILITY
   ===================================================== */

SELECT
    f.FacilityName,
    f.StateCode,
    COUNT(c.ClaimKey) AS Total_Claims,
    SUM(c.BilledAmount) AS Total_Billed_Amount,
    SUM(c.AllowedAmount) AS Total_Allowed_Amount
FROM FactClaims c
INNER JOIN DimFacility f
    ON c.FacilityKey = f.FacilityKey
GROUP BY
    f.FacilityName,
    f.StateCode
ORDER BY Total_Billed_Amount DESC;


/* =====================================================
   11. PAYMENT PERFORMANCE BY CLAIM
   ===================================================== */

SELECT
    c.ClaimNumber,
    c.BilledAmount,
    SUM(p.PaidAmount) AS Total_Paid,
    SUM(p.PatientResp) AS Patient_Responsibility,
    c.BilledAmount - SUM(p.PaidAmount) AS Remaining_Balance
FROM FactClaims c
LEFT JOIN FactPayments p
    ON c.ClaimKey = p.ClaimKey
GROUP BY
    c.ClaimNumber,
    c.BilledAmount
ORDER BY Remaining_Balance DESC;


/* =====================================================
   12. ACCOUNTS RECEIVABLE SUMMARY
   ===================================================== */

SELECT
    COUNT(*) AS Total_AR_Records,
    SUM(Billed_Amount) AS Total_Billed,
    SUM(Balance_Amount) AS Total_AR_Balance
FROM FactAR;


/* =====================================================
   13. AR AGING ANALYSIS
   ===================================================== */

SELECT
    Aging_Bucket,
    COUNT(*) AS AR_Record_Count,
    SUM(Balance_Amount) AS Total_AR_Balance
FROM FactAR
GROUP BY Aging_Bucket
ORDER BY Aging_Bucket;


/* =====================================================
   14. AR STATUS ANALYSIS
   ===================================================== */

SELECT
    Status,
    COUNT(*) AS Record_Count,
    SUM(Balance_Amount) AS Total_Balance
FROM FactAR
GROUP BY Status
ORDER BY Total_Balance DESC;


/* =====================================================
   15. AR BY INSURANCE
   ===================================================== */

SELECT
    Insurance_Name,
    COUNT(*) AS AR_Record_Count,
    SUM(Billed_Amount) AS Total_Billed,
    SUM(Balance_Amount) AS Total_Balance
FROM FactAR
GROUP BY Insurance_Name
ORDER BY Total_Balance DESC;


/* =====================================================
   16. CLAIM PAYMENT RATE
   ===================================================== */

WITH ClaimPayments AS
(
    SELECT
        c.ClaimKey,
        c.BilledAmount,
        COALESCE(SUM(p.PaidAmount), 0) AS TotalPaid
    FROM FactClaims c
    LEFT JOIN FactPayments p
        ON c.ClaimKey = p.ClaimKey
    GROUP BY
        c.ClaimKey,
        c.BilledAmount
)
SELECT
    SUM(BilledAmount) AS Total_Billed,
    SUM(TotalPaid) AS Total_Paid,
    CAST(
        100.0 * SUM(TotalPaid) /
        NULLIF(SUM(BilledAmount), 0)
        AS DECIMAL(10,2)
    ) AS Payment_Rate_Percent
FROM ClaimPayments;


/* =====================================================
   17. DENIAL RATE
   ===================================================== */

WITH ClaimDenials AS
(
    SELECT DISTINCT
        ClaimKey
    FROM FactDenials
)
SELECT
    COUNT(c.ClaimKey) AS Total_Claims,
    COUNT(d.ClaimKey) AS Denied_Claims,
    CAST(
        100.0 * COUNT(d.ClaimKey) /
        NULLIF(COUNT(c.ClaimKey), 0)
        AS DECIMAL(10,2)
    ) AS Denial_Rate_Percent
FROM FactClaims c
LEFT JOIN ClaimDenials d
    ON c.ClaimKey = d.ClaimKey;


/* =====================================================
   18. CLAIM TURNAROUND TIME
   ===================================================== */

SELECT
    AVG(
        DATEDIFF(
            DAY,
            ServiceDate,
            SubmitDate
        )
    ) AS Avg_Service_To_Submission_Days
FROM FactClaims
WHERE ServiceDate IS NOT NULL
  AND SubmitDate IS NOT NULL;


/* =====================================================
   19. TOP PAYERS BY BILLED AMOUNT
   ===================================================== */

SELECT TOP 10
    p.PayerName,
    p.PayerType,
    COUNT(c.ClaimKey) AS Claim_Count,
    SUM(c.BilledAmount) AS Total_Billed
FROM FactClaims c
INNER JOIN DimPayer p
    ON c.PayerKey = p.PayerKey
GROUP BY
    p.PayerName,
    p.PayerType
ORDER BY Total_Billed DESC;


/* =====================================================
   20. DATE DIMENSION ANALYSIS
   ===================================================== */

SELECT
    d.Year,
    d.Month,
    COUNT(c.ClaimKey) AS Claim_Count,
    SUM(c.BilledAmount) AS Total_Billed
FROM DimDate d
LEFT JOIN FactClaims c
    ON c.ServiceDate = d.Date
GROUP BY
    d.Year,
    d.Month
ORDER BY
    d.Year,
    d.Month;
