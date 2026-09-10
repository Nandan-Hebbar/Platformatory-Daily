# INVM Connector Lag Impact & Message Loss Analysis Report (Updated & Refined)

> **Dataset Analyzed**: `/home/nandan-plf/NBB-analysis/complete_dump/`  
> **Target Query Deployment File**: [`ksql_deploy_queries.sql`](file:///home/nandan-plf/NBB-analysis/ksql_deploy_queries.sql)  
> **Key Technical Clarification**: Your observation is **100% correct**. The join condition in Queries [60] and [61] evaluates `INVM.KEY_1_SUBSTRING_KEY = INCT.ACCT_NO`. For **pre-existing accounts**, `INVM_TABLE` already contains the account key in its RocksDB state store, so the join **SUCCEEDS** and the transaction is emitted. The join **ONLY FAILS AND DROPS MESSAGES for Newly Opened Accounts** created during the lag window.

---

## 1. Corrected & Nuanced Technical Breakdown

### How `INVM_TABLE` Works in ksqlDB
In ksqlDB, `INVM_TABLE` is a stateful KSQL Table backed by log-compacted Kafka topic `INVM_STREAM_WITH_KEY` and materialized into a local RocksDB key-value state store.

```sql
-- Query [60] & [61] in Phase 7: INSERT INTO CASA_INTERMEDIATE
INSERT INTO CASA_INTERMEDIATE
SELECT INCT.JRNL_NO JOURNAL_NO, ...
FROM INCTV INCT
INNER JOIN GS GS WITHIN 30 MINUTES ON ((INCT.ACCT_NO+'%'+SUBSTRING(INCT.POST_DATE, 1, 10)+'%'+INCT.JRNL_NO = GS.ID))
INNER JOIN INVM_TABLE INVM ON ((INVM.KEY_1_SUBSTRING_KEY = INCT.ACCT_NO))  <-- JOIN CONDITION
INNER JOIN JS JS WITHIN 30 MINUTES ON (...)
INNER JOIN INCMNG_MSG_QUEUE_STREAM IMQ WITHIN 30 MINUTES ON (...)
```

### Scenario Analysis: Pre-Existing Accounts vs. Newly Opened Accounts

| Account Category | Description | State in `INVM_TABLE` (RocksDB) | `INNER JOIN` Result in Phase 7 (Q60/61) | Impact on `CASA_FINAL_TOPIC` |
| :--- | :--- | :--- | :--- | :--- |
| **Existing Accounts** *(Opened prior to lag window)* | Accounts opened days, months, or years ago. Already populated into `INVM_TABLE`. | **Key Exists** (State store has `ACCT_NO`). | **MATCHES & PASSES** | **NO DROP**. Message passes to `CASA_FINAL_TOPIC`. *(Note: Uses existing state attributes like `CURRENCY` and `CUSTOMER_NO`).* |
| **Newly Opened Accounts** *(Opened inside the 1-2 hour lag window)* | Accounts created in CBS between 00:54 AM and 02:00 AM. Account creation record is lagging behind in the CDC pipeline. | **Key Missing** (Creation event not yet ingested into RocksDB). | **NO MATCH (FAILS)** | **PERMANENT DROP**. Transaction is dropped at Phase 7 and never reaches `CASA_FINAL_TOPIC`. |

---

## 2. Why Dump Dump Analysis Showed "Missing Keys"

In our earlier test script, scanning `PRD_CBS_INVM_DATA_2026-09-09_0200-0203.jsonl`:
- That file was a **3-minute incremental CDC dump** (containing 9,880 updates emitted between 02:00 AM and 02:03 AM).
- It was **NOT** the full historical snapshot of the entire `INVM_TABLE` state store!
- In a running ksqlDB cluster, `INVM_TABLE` maintains state for **all pre-existing active accounts** across the entire bank.
- Therefore, for all pre-existing accounts, `INVM.KEY_1_SUBSTRING_KEY = INCT.ACCT_NO` evaluates to `TRUE` against RocksDB state.

---

## 3. Exact Conditions Under Which Messages DROP

A transaction message arriving on `INCTV` will **DROP** at Phase 7 and fail to reach `CASA_FINAL_TOPIC` under the following specific conditions:

```mermaid
flowchart TD
    A[INCTV Transaction Arrives at 02:00 AM] --> B{Account Type?}
    
    B -->|Pre-Existing Account| C[Key exists in INVM_TABLE RocksDB]
    C --> D[INVM Join PASSES ✅]
    
    B -->|Newly Opened Account inside 2h Lag Window| E[Key missing in INVM_TABLE RocksDB]
    E --> F[INVM Join FAILS ❌]
    F --> DROP1[❌ DROPPED AT PHASE 7\nNo record in CASA_FINAL_TOPIC]

    D --> G{Stream-Stream Joins GS / JS / IMQ\nwithin 30 Mins?}
    G -->|Matched| PASS[Emitted to CASA_FINAL_TOPIC ✅]
    G -->|Unmatched / Missing Queue Msg| DROP2[❌ DROPPED AT PHASE 7\nStream-Stream Join Failure]
```

### 1. Newly Opened Account (Connector Lag Impact)
- **Condition**: Account created in CBS within the last 1–2 hours.
- **Cause**: Connector lag prevents initial account creation record from populating `INVM_TABLE`.
- **Drop Point**: Phase 7 (`INNER JOIN INVM_TABLE`).

### 2. Unmatched Payment Engine Message (Queue / Remittance Failure)
- **Condition**: `INCTV` record arrives without a corresponding `GS` (CT_REM), `JS` (CT_PYMNT), or `IMQ` (INCMNG_MSG_QUEUE) record within 30 minutes.
- **Cause**: Payment Engine queue mismatch or delay exceeding 30 minutes.
- **Drop Point**: Phase 7 (`INNER JOIN GS`, `INNER JOIN JS`, `INNER JOIN IMQ`).

---

## 4. Summary Matrix of INVM Connector Lag Behavior

| Impact Metric | Pre-Existing Accounts | Newly Opened Accounts |
| :--- | :--- | :--- |
| **Account Key in `INVM_TABLE`** | Present in state store | Absent (Lagging in CDC stream) |
| **Phase 7 `INNER JOIN` Result** | **PASSED (Matched)** | **FAILED (Dropped)** |
| **Emitted to `CASA_FINAL_TOPIC`?** | **YES** | **NO** |
| **Data Integrity Impact** | Uses cached account attributes (`CURRENCY`, `CUSTOMER_NO`) until CDC updates catch up | Transaction completely missing from downstream topics |
