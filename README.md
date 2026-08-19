# Healthcare Revenue Cycle Analytics

## Project Overview

A healthcare Revenue Cycle Analytics solution built using **SQL Server and Power BI** to analyze claims, payments, denials, accounts receivable, reimbursements, and payer/facility performance.

The project uses a **star-schema data warehouse** containing approximately **1.89 million records** across 8 dimension and fact tables.

The Power BI dashboard transforms transactional healthcare data into actionable revenue cycle insights and KPIs.

---

## Business Objectives

The solution was designed to help answer key revenue cycle questions:

- How many claims are being processed?
- What is the total billed and allowed amount?
- How much revenue has been collected?
- What are the major denial categories and denial codes?
- Which payers generate the highest claim and payment volumes?
- Which facilities have the highest billed amounts?
- What is the current accounts receivable balance?
- How is AR distributed across aging buckets?
- How does payment and denial performance change over time?

---

## Technology Stack

| Technology | Purpose |
|---|---|
| SQL Server | Data warehouse and SQL analysis |
| SQL | Data analysis, joins, aggregations, CTEs and KPI calculations |
| Power BI | Interactive dashboard and visualization |
| DAX | Measures and business KPIs |
| Star Schema | Dimensional data modeling |

---

## Data Warehouse

The solution follows a **star schema** consisting of dimension and fact tables.

### Dimension Tables

| Table | Rows | Description |
|---|---:|---|
| DimDate | 1,097 | Date and calendar attributes |
| DimPayer | 8 | Payer and insurance information |
| DimFacility | 5 | Healthcare facility information |
| DimPatient | 200,000 | Patient dimension |

### Fact Tables

| Table | Rows | Description |
|---|---:|---|
| FactClaims | 1,000,000 | Healthcare claim transactions |
| FactPayments | 585,147 | Payment and collection transactions |
| FactDenials | 100,374 | Claim denial transactions |
| FactAR | 200 | Accounts receivable records |

**Total records across the database: approximately 1.89 million**

---

## Data Model

The core relationships connect transactional facts to common healthcare dimensions:

```text
                    DimDate
                       |
                       |
DimPayer ---- FactClaims ---- DimPatient
                  |
                  |
             DimFacility
                  |
          ----------------
          |              |
    FactPayments    FactDenials
