Step-by-Step Live Tracking & Failure Proof Runbook
mermaid
flowchart LR
    Step1["1. Capture INCT Journal<br/>(02:00 AM Peak)"] --> Step2["2. Check INVM Connector Lag"]
    Step2 --> Step3["3. Inspect Payment Streams<br/>(30-Min Join Delta)"]
    Step3 --> Step4["4. Run Phase 7 Diagnostic"]
    Step4 --> Step5["5. Check Final Emission"]
Step 1: Pick Candidate Transactions from INCT (Core Banking)
Extract transactions posted between 02:00 AM and 02:03 AM from last night's core banking CDC topic:

sql
-- In ksqlDB CLI:
SET 'ksql.streams.auto.offset.reset' = 'earliest';
SELECT 
  PAYLOAD->JRNL_NO AS JRNL_NO,
  PAYLOAD->ACCT_NO AS ACCT_NO,
  PAYLOAD->POST_DATE AS POST_DATE,
  PAYLOAD->POST_TIME AS POST_TIME,
  ROWTIME AS KAFKA_INGEST_TS,
  TIMESTAMPTOSTRING(ROWTIME, 'yyyy-MM-dd HH:mm:ss', 'GMT+3') AS INGEST_TIME_GMT3
FROM INCT_STREAM
WHERE ROWTIME >= STRINGTOTIMESTAMP('2026-09-10 02:00:00', 'yyyy-MM-dd HH:mm:ss', 'GMT+3')
  AND ROWTIME <= STRINGTOTIMESTAMP('2026-09-10 02:03:00', 'yyyy-MM-dd HH:mm:ss', 'GMT+3')
EMIT CHANGES LIMIT 20;
Step 2: Check INVM Connector Lag at 02:00 AM
Check if the INVM source connector had consumer lag when your selected transactions were posted:

bash
# In shell (Kafka Consumer Group Offset Check):
kafka-consumer-groups --bootstrap-server <kafka-broker>:9092 \
  --describe --group connect-invm-source-connector
Proof Criteria: Compare INVM event ROWTIME vs payload->op_ts (CDC timestamp). If ROWTIME - op_ts > 30 mins, INVM_TABLE in RocksDB was stale at the moment Core Banking posted the journal.
Step 3: Track Payment Engine Streams & Check 30-Minute Window Drift
For your selected JRNL_NO and ACCT_NO, verify whether matching records exist in all 4 payment streams within the 30-minute join window:

sql
-- Check Booking Request Stream
SELECT PAYLOAD->TXN_POS_NUM, PAYLOAD->GEN_DT, PAYLOAD->ACNTG_REF, ROWTIME
FROM BOOKING_REQUEST_STREAM
WHERE PAYLOAD->ACNTG_REF = '<YOUR_JRNL_NO>'
EMIT CHANGES;
-- Check Payment Stream (CT_PYMNT)
SELECT PAYLOAD->TXN_POS_NUM, PAYLOAD->BEN_ACNT, ROWTIME
FROM CT_PYMNT_STREAM
WHERE PAYLOAD->BEN_ACNT = '<YOUR_ACCT_NO>'
EMIT CHANGES;
-- Check Remittance Stream (CT_REM)
SELECT PAYLOAD->TXN_POS_NUM, PAYLOAD->ORD_CUST_NM, ROWTIME
FROM CT_REM_STREAM
EMIT CHANGES;
-- Check Incoming Queue Stream (IMQ)
SELECT PAYLOAD->QUEUE_POS_NUM, PAYLOAD->CHNL_ID, ROWTIME
FROM INCMNG_MSG_QUEUE_STREAM
EMIT CHANGES;
Failure Proof 1 (Time Window Expiration): Calculate ABS(INCTV.ROWTIME - BOOKING_REQUEST.ROWTIME). If this delta exceeds 30 minutes (1800000 ms), Phase 4 (BR_INCT) drops the record.
Failure Proof 2 (Missing Message): If CT_PYMNT, CT_REM, or IMQ returns 0 rows for that TXN_POS_NUM, Phase 7's 4-way INNER JOIN drops the record.
Step 4: Run Diagnostic Query for Phase 7 (CASA_INTERMEDIATE)
Simulate Phase 7 

Query 60/61
 for your test JRNL_NO to see which join arm fails:

sql
SELECT 
  INCT.JRNL_NO,
  INCT.ACCT_NO,
  INVM.CUSTOMER_NO,
  GS.ID AS GS_ID,
  JS.ID AS JS_ID,
  IMQ.PAYLOAD->CHNL_ID AS CHNL_ID
FROM INCTV INCT
LEFT JOIN GS GS WITHIN 30 MINUTES ON ((INCT.ACCT_NO+'%'+SUBSTRING(INCT.POST_DATE, 1, 10)+'%'+INCT.JRNL_NO = GS.ID))
LEFT JOIN INVM_TABLE INVM ON ((INVM.KEY_1_SUBSTRING_KEY = INCT.ACCT_NO))
LEFT JOIN JS JS WITHIN 30 MINUTES ON ((INCT.ACCT_NO+'%'+SUBSTRING(INCT.POST_DATE, 1, 10)+'%'+INCT.JRNL_NO = JS.ID))
LEFT JOIN INCMNG_MSG_QUEUE_STREAM IMQ WITHIN 30 MINUTES ON (GS.C_TXN_POS_NUM = IMQ.PAYLOAD->QUEUE_POS_NUM)
WHERE INCT.JRNL_NO = '<YOUR_JRNL_NO>'
EMIT CHANGES;
How to read the diagnostic output:
If INVM.CUSTOMER_NO IS NULL $\rightarrow$ Account missing/delayed in INVM_TABLE (Connector Lag / New Account).
If GS_ID IS NULL or JS_ID IS NULL $\rightarrow$ Payment engine 30-minute join window expired.
If CHNL_ID IS NULL $\rightarrow$ INCMNG_MSG_QUEUE message missing or delayed.
Step 5: Check CASA_FINAL_TOPIC Emission
Finally, confirm if the message reached the output topic:

sql
SELECT * FROM CASA_FINAL_TOPIC 
WHERE JOURNAL_NO = '<YOUR_JRNL_NO>' 
EMIT CHANGES;
If Step 4 returned a valid row but Step 5 returned 0 rows, the drop occurred at Phase 10 (Query 75) due to HAVING COUNT(ID) = 1 window deduplication.

TIP

If you plan to set up a recurring script or run continuous monitoring across multiple peak hours, you can use the /schedule command or /goal command for extended automated monitoring.
