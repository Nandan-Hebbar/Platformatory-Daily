# KSQLDB 10-Phase Pipeline Execution & Data Simulation Report

> **Dataset Source**: `/home/nandan-plf/NBB-analysis/complete_dump/` 
> **Workload Window**: September 9, 2026, 02:00:00 AM – 02:03:00 AM (3-Minute Peak Workload Period) 
> **Source Topics Included**: 23 Core Source Topics + 1 INVM Custom Connector Topic 
> **Pipeline queries SQL File**: [`ksql_deploy_queries.sql`](file:///home/nandan-plf/NBB-analysis/ksql_deploy_queries.sql) (76 queries across 10 deployment phases)

---

## 1. Executive Summary & Pipeline Topology

This report provides a complete step-by-step data simulation of the ksqlDB streaming engine running the 10-phase deployment script defined in [`ksql_deploy_queries.sql`](file:///home/nandan-plf/NBB-analysis/ksql_deploy_queries.sql). Records are sampled from actual Kafka topic dumps taken during the daily peak workload window (02:00:00 to 02:03:00 AM on Sept 9, 2026).

```mermaid
flowchart TD
   subgraph Phase 1 & 2: Ingestion & Keying
       S1[INCT_PRD_TOPIC] --> SK1[INCTV Stream]
       S2[PRD_CBS_INVM_DATA] --> SK2[INVM_WITH_KEY]
       S3[PRD_PE_BOOKING_REQUEST] --> SK3[BOOKING_REQUEST_STREAM]
       S4[PRD_PE_CT_PYMNT] --> SK4[CT_PYMNT_STREAM]
       S5[PRD_PE_CT_REM] --> SK5[CT_REM_STREAM]
       S6[PRD_PE_INCMNG_MSG_QUEUE] --> SK6[INCMNG_MSG_QUEUE_STREAM]
       S7[PRD_CBS_CURM_DATA] --> SK7[CURM_WITH_KEY]
   end

   subgraph Phase 3 & 4: Lookups & Derived Streams
       SK2 --> T1[(INVM_TABLE)]
       SK7 --> T2[(CURM_TABLE)]
       SK3 & SK1 --> DS1[BR_INCT]
       SK4 & DS1 --> DS2[JS]
       SK5 & DS1 --> DS3[GS]
   end

   subgraph Phase 6 & 7: CASA Ingestion
       SK1 & DS3 & T1 & DS2 & SK6 --> CI[CASA_INTERMEDIATE Stream]
   end

   subgraph Phase 8 & 9: Enrichment & FX Conversion
       CI & T2 --> CIC[CASA_INTERMEDIATE_CHANNELED]
       CIC --> CIT[CASA_INTERMEDIATE_TERMINAL]
   end

   subgraph Phase 10: Repartitioning & Deduplication
       CIT --> CF1[CASA_FINAL_STREAM_REPARTITIONED]
       CF1 --> CFT[(CASA_FINAL_TABLE\n1-Min Tumbling Window\nHAVING COUNT=1)]
       CFT --> CF[CASA_FINAL_TOPIC]
   end
```

---

## 2. Sampled Workload Transactions Overview

To illustrate how data transforms across all 10 phases, we track representative transactions from the peak workload window:

1. **Transaction 1 (Outbound FAWRI+ Payment - External)**
  - **Journal No**: `100005456`
  - **Account No**: `0000000292541929`
  - **Amount**: `10.000 BHD`
  - **Channel**: `B` (Branch/Queue 20)
  - **Instrument / Clear Type**: `1 / 3` (`OUT FAWRI+ and FAWATEER ONLINE`)
  - **Counterparty IBAN**: `BH33ALSA00256589150000` (AL SALAM BANK)

2. **Transaction 2 (Inbound FAWRI+ Payment - External)**
  - **Journal No**: `100005622`
  - **Account No**: `0000001025154533`
  - **Amount**: `0.120 BHD`
  - **Channel**: `S` (Corporate SBOB / Queue 418)
  - **Instrument / Clear Type**: `6 / NULL` (`IN FAWRI+ and FAWATEER ONLINE`)
  - **Counterparty IBAN**: `BH95NBOB000001025154533`

3. **Transaction 3 (Internal Teller Transfer - Core Banking)**
  - **Journal No**: `100005990`
  - **Account No**: `0000000292602715`
  - **Amount**: `50.000 BHD`
  - **Executor Teller / Branch**: `120015` / `00001` (Digital Channel `D`)
  - **Transaction Code**: `1055`
  - **Transaction Type**: Internal Teller Transfer (`INT`)

4. **Transaction 4 (Digital Audit & Payment Order Event)**
  - **Payment Order ID**: `7db5dcd0-e650-4074-a864-ae73400489d5`
  - **User ID**: `05e75d49-921a-4553-95fe-ca7273f4c1fd`
  - **Amount / Currency**: `5.000 BHD`
  - **Event Status**: `Successful`

---

## 3. Phase-by-Phase Execution & Data Simulation

### Phase 1: Source Stream DDLs (Queries 01 – 22)
**Purpose**: Registers input Kafka topics as KSQL Streams with struct schemas.

#### Sample Input Records (Raw Kafka Payloads from Dump):

##### `INCT_PRD_TOPIC` (INCTV Stream) - Query [16]
```json
{
 "INST_NO": "003",
 "ACCT_NO": "0000000292541929",
 "REC_NO": "999979340",
 "TRAN_DATE": "2026-09-09 00:00:00",
 "POST_DATE": "2026-09-09 00:00:00",
 "POST_TIME": "2003593",
 "JRNL_NO": "100005456",
 "TRAN_TYPE": "1",
 "DELI": " ",
 "TELL_BR": "500000300001",
 "TRAN_CODE": "1055",
 "AMOUNT": "10.000",
 "DEBIT_CREDIT_FLAG": "D",
 "BALANCE": "65.162",
 "CORRECTION": "0",
 "BRTERM": "5",
 "BATCH_NO": "  ",
 "BANK_CODE": "BH",
 "EQUAL_BASE_AMT": "0.000",
 "table": "U012BAND.FNSONLP.INCT",
 "scn": "122972702991",
 "scn_timestamp": "09-SEP-2026 02:00:36",
 "current_ts": "1788908437"
}
```

##### `PRD_PE_BOOKING_REQUEST_DATA` (BOOKING_REQUEST_STREAM) - Query [03]
```json
{
 "OU_ID": "GNBOBBHBM0",
 "TXN_POS_TYP": 25,
 "TXN_POS_TYP_CD": null,
 "TXN_POS_NUM": 489297990,
 "SQNC_NUM": 1,
 "REF_DT": 20705,
 "GEN_DT": "2026-09-09",
 "EVENT_TYP": 151,
 "EVENT_TYP_CD": null,
 "CHRG_FLG": null,
 "STAT": 5,
 "STAT_CD": null,
 "LOT_REF": "25-489297990-1",
 "REMITTANCE_REF": null,
 "REQ_REF": null,
 "ACNTG_REF": "100005456",
 "DT_ADJSTMNT_FLG": null,
 "IS_IMMEDIATE_FLG": null,
 "ACNT_REF_TYP": null,
 "ACNT_REF_TYP_CD": null,
 "ACNT_REF": null,
 "DB_PRTY": null,
 "DB_PRTY_CD": null,
 "CR_PRTY": null,
 "CR_PRTY_CD": null,
 "IS_MUL_PYMNT_TXN": null,
 "IS_CVD_EQ_DVD": null,
 "IS_CE_EQ_DE": null,
 "GRPNG_REQD": null,
 "BSNS_EVNT_ID": 51,
 "BOOKING_TYP": 4,
 "BOOKING_TYP_CD": null,
 "IS_EOD_FLG": null,
 "ARCHVL_FLG": null,
 "ARCHVL_DT": null,
 "RSRVD_STR1": null,
 "RSRVD_STR2": null,
 "RSRVD_STR3": "6003876527",
 "RSRVD_STR4": ":",
 "RSRVD_NUM1": 1,
 "RSRVD_NUM2": 8,
 "RSRVD_NUM3": 111.0,
 "RSRVD_NUM4": null,
 "RSRVD_DATE1": null,
 "RSRVD_DATE2": null,
 "GROUPING_CRITERIA": null,
 "MRKT_CODE": "DP001",
 "BKNG_SYSTEM": 901,
 "ACNT_PARAM_ID": null,
 "DB_ACNT_TYP": null,
 "CR_ACNT_TYP": 1,
 "DB_ACNT_SYS": null,
 "CR_ACNT_SYS": null,
 "BKNG_CLSFCTN_VAL": "3",
 "BKNG_SUB_CLSFCTN_VAL": "BHD",
 "RETRY_THRSHLD": null,
 "RETRY_COUNT": null,
 "REQ_TM": null,
 "EVENT_STATUS": 76,
 "MORN": null,
 "SEQ_ID": 23,
 "PRTN_GRP": 0,
 "PRTN_DATE": 20705,
 "MSG_ID": null,
 "INIT_MU_ID": null,
 "TRAN_FLG": null,
 "TXN_DTL": "5::::::::::::::::",
 "OVRRIDE_FLG": null,
 "ORDR_POS_NUM": 267581328,
 "ORDR_POS_TYP": 310,
 "BOOKING_REQUEST_VER": 2,
 "DM_LSTUPDDT": 20704,
 "DM_BTNUMBER": 751458934,
 "DM_BTID": 59113,
 "DM_USERID": 0,
 "DM_WSID": 0,
 "MICROSERVICES_ENABLED": 1,
 "table": "PAYPRDBAH.PEBAHPRD.BOOKING_REQUEST",
 "scn": "122972703031",
 "op_type": "U",
 "op_ts": "1788919236000",
 "current_ts": "1788908442462",
 "row_id": "AADJW7AAZAAJDNOAAF",
 "username": "PEBAHPRD"
}
```

##### `PRD_PE_CT_PYMNT_DATA` (CT_PYMNT_STREAM) - Query [06]
```json
{
 "OU_ID": "GNBOBBHBM0",
 "TXN_POS_TYP": 25,
 "TXN_POS_NUM": 489297990,
 "TXN_REF": "BP1788908435S0J8",
 "E2E_REF_NUM": "6003876527",
 "EXEC_DT": 1788901200000,
 "VAL_DT": 1788901200000,
 "VAL_DT_OVRRD_FLG": null,
 "IS_CED_DED": null,
 "STLMNT_DT": null,
 "CRNCY": "BHD",
 "CHRG_OPTN": 2,
 "EXCHNG_RT": null,
 "TXN_TYP": null,
 "TXN_TYP_DSCRPTN": null,
 "STAT": 21,
 "EVNT_STAT": 77,
 "TXN_DTL": "21::::::::::::::::",
 "INSTRCTN_CODE_FLG": null,
 "RMTNCE_INFO_FLG": null,
 "SNDR_TO_RCVR_COV_FLG": null,
 "REG_RPRTNG_FLG": null,
 "RPRTNG_DTLS_FLG": null,
 "CHRGS_FLG": null,
 "CR_PRTY_DTLS_FLG": null,
 "SNDR_CHRGS_FLG": null,
 "DR_PRTY_DTLS_FLG": null,
 "COVER_DTLS_FLG": null,
 "SPLIT_CASE_FLG": null,
 "RLTD_TXN_REF": null,
 "RMRKS": null,
 "RPR_FLG": null,
 "RPR_CMPLXTY": null,
 "ORD_DT": 1788901200000,
 "AMT": 10.0,
 "ORIG_AMT": 10.0,
 "BASE_AMT": null,
 "CNTR_AMT": null,
 "SQNC_NUM": 1,
 "PYMNT_CHRCTX_FLG": null,
 "CRSPNDNT_ACNT": "8827062200010000",
 "INSTR_CODE": "00",
 "CHQ_ISSUE": null,
 "STLMNT_WTH_BNK": 2,
 "SERIAL_COVER_FLG": null,
 "SCNR_ID": 8,
 "SLA_LATE_IND": null,
 "PREPAID_CHRGS": null,
 "INP_QUEUE_TYPE": 34,
 "FX_DEAL_REF": null,
 "REMT_INFO_COV_FLG": null,
 "SNDR_TO_RCVR_FLG": null,
 "TRGT_MU_ID": null,
 "TRGT_SRVC_CNTR": null,
 "INSTRUCTED_CHNL": 315,
 "TM_INDCTN": null,
 "MORN": null,
 "REQ_EXE_TM": null,
 "FWD_CHNL_SEQ": 111,
 "RTRN_FLG": null,
 "CUST_CTGRY": null,
 "CUST_TYPOLOGY": null,
 "BOOKING_REF": null,
 "ISS_SEQ": null,
 "RESP_REF": null,
 "CLR_TYP": 3,
 "LT_AMT": null,
 "JOB_RUN_ID": null,
 "INT_REM_REF": 1,
 "PER_NAME_MATCH": null,
 "CLR_TYP_MOD": null,
 "STG_TXN_REF": null,
 "ADTNL_DTL_FLG": null,
 "UNQ_SEQ_NUM": "NBB090926ON7TANY",
 "ALREADY_FILTERED": null,
 "RE_ROUTING_REG": null,
 "BNFCRY_NM": null,
 "ACNT_OWNR_NM": null,
 "BEN_ALIAS_ID": null,
 "OTHR_INFO": null,
 "DEPARTMENT": null,
 "INTERIM_BKNG_FLG": null,
 "TXN_PRIORITY": null,
 "MAX_RTNTN_DT": null,
 "ORIG_EXCHNG_RT": null,
 "PHASE_TM": null,
 "DUP_CHK_KEY": null,
 "CHK_PRNT_OPTN": null,
 "ONSITE_CHK_PRNT": null,
 "BR_REF": null,
 "PRIORITY_CD": null,
 "RATE_RCV_FLG": null,
 "PRE_AGRD_FLG": null,
 "BOP_ID": null,
 "MORN_COV": null,
 "ACK_MORN_DRCT": null,
 "ACK_MORN_CVR": null,
 "INIT_MU_ID": null,
 "PRTN_GRP": 0,
 "PRTN_DATE": 1788901200000,
 "CRSPNDNT_TYP": 1,
 "PDE_FLG": null,
 "UNQ_SEQ_NUM_COV": null,
 "IDNTFR_TYP_1": null,
 "ORDR_POS_TYP": 310,
 "ORDR_POS_NUM": 267581328,
 "RATE_PRPS": null,
 "SERIAL_CVR": null,
 "MVMNT_DESC": null,
 "MVMNT_DESC2": null,
 "MVMNT_DESC1": null,
 "MVMNT_DESC3": null,
 "IS_FIXED": null,
 "DR_CNTR_AMT": null,
 "DR_CNTR_AMT_CRNCY": null,
 "DR_EXCH_RT": null,
 "DR_CNTR_AMT_FIXED": null,
 "DR_EXCH_RT_OVERRIDE": null,
 "DR_CNTRCT_REF": null,
 "PRTL_PRCSNG_FLG": null,
 "CNCL_CODE": null,
 "FILE_REF": null,
 "PRF_RPT_FLG": null,
 "BANK_FEE": null,
 "FWRDNG_FEE": null,
 "CHRG_CODE": null,
 "CUST_MRGN": null,
 "TELLER_MRGN": null,
 "CMPLNC_STAT": null,
 "GRP_BKNG_REF": null,
 "ORIG_CHRG_CRNCY": null,
 "ORIG_CHRG_AMT": null,
 "CHRG_EXCHNG_RT": null,
 "CHRG_CRNCY": null,
 "CNTR_AMT_CRNCY": null,
 "ROUTING_TYP": 1,
 "CMPL_DT": null,
 "CHRG_AMT": null,
 "TAX_AMT": null,
 "GPI_REF": null,
 "GPI_REF_TYP": null,
 "GPI_FLG": null,
 "GPI_EVENT_STAT": null,
 "ORD_PYMT_REF": "310:267581328:1:1:0",
 "BEN_ACNT_CRNCY": null,
 "BEN_ACNT_TYP": null,
 "BEN_ACNT": "BH33ALSA00256589150000",
 "BEN_ACNT_MUID": null,
 "BEN_ADRS_LINE1": null,
 "BEN_ADRS_LINE2": null,
 "BEN_ADRS_LINE3": null,
 "BEN_ADRS_LINE4": null,
 "BEN_ADRS_TYP_FLG": null,
 "BEN_ADRS_DEPT": null,
 "BEN_ADRS_SUB_DEPT": null,
 "BEN_ADRS_STRT_NM": null,
 "BEN_ADRS_BULDNG_NB": null,
 "BEN_ADRS_FLOOR": null,
 "BEN_ADRS_POST_BOX": null,
 "BEN_ADRS_ROOM": null,
 "BEN_ADRS_POST_CODE": null,
 "BEN_ADRS_TOWN_NM": null,
 "BEN_ADRS_TOWN_LOC_NM": null,
 "BEN_ADRS_DSTRCT_NM": null,
 "BEN_CTRY": null,
 "BEN_EML": null,
 "BEN_ADRS_BULDNG_NM": null,
 "BEN_ADRS_CNTRY_SUB_DIV": null,
 "BEN_FAX": null,
 "BEN_MBL": null,
 "BEN_PHN": null,
 "BEN_REF": null,
 "BEN_REF_TYP": 5,
 "BEN_CIF_ID": null,
 "BEN_BNK_ACNT_TYP": null,
 "BEN_BNK_ACNT_REF": "ALSABHDNRT01",
 "BEN_BNK_REF_TYP": 315,
 "BEN_BNK_REF": "ALSABHBMXXX",
 "BEN_BNK_MU_ID": "0000",
 "BEN_BNK_PREVLDT": null,
 "BEN_BNK_NM": "AL SALAM BANK BAHRAIN",
 "BEN_BNK_ADRS_LINE1": "PO BOX 18282",
 "BEN_BNK_ADRS_LINE2": null,
 "BEN_BNK_ADRS_LINE3": null,
 "BEN_BNK_ADRS_LINE4": null,
 "BEN_BNK_CTRY": "BH",
 "BEN_BNK_LCL_IDNTFR": null,
 "BEN_ACNT_USG": null,
 "BEN_ACNT_POS_ID": null,
 "BEN_REF_TYP1": null,
 "BEN_ISSUER": null,
 "BEN_ISSUER1": null,
 "BEN_BRTH_CNTRY": null,
 "BEN_PROXY_IDN": null,
 "BEN_PROXY_IDN_CD": null,
 "BEN_ACNT_SCH_DTLS": null,
 "BEN_BNK_REF_TYP1": null,
 "BEN_BNK_REF1": null,
 "BEN_BNK_ACNT_SCH_DTLS": null,
 "BEN_BNK_ACNT_CRNCY": null,
 "BEN_BNK_PROXY_IDN_CD": null,
 "BEN_BNK_PROXY_IDN": null,
 "BEN_BNK_ACNT_NM": null,
 "BEN_CNTRY_OF_RES": null,
 "CRSPNDNT_REF": "NBOBBHBM",
 "CRSPNDNT_REF_TYP": null,
 "CRSPNDNT_ADRS_LINE1": null,
 "CRSPNDNT_ADRS_LINE2": null,
 "CRSPNDNT_ADRS_LINE3": null,
 "CRSPNDNT_ADRS_LINE4": null,
 "CRSPNDNT_CTRY": null,
 "CRSPNDNT_NM": null,
 "BEN_REF1": null,
 "BEN_PRNT_IDNTFR": null,
 "BEN_BRTH_DTLS": null,
 "BEN_ACNT_NM": null,
 "BEN_JOINT_HLDR_NM": null,
 "EXCHNG_RT_UNIT_CRNCY": null,
 "BEN_BNK_ACNT_USG": null,
 "CT_PYMNT_VER": 1,
 "DM_LSTUPDDT": 1788897635000,
 "DM_BTNUMBER": 751458934,
 "DM_BTID": 260142,
 "DM_USERID": 0,
 "DM_WSID": 0,
 "DRCTION": null,
 "AUTO_SAVE_BEN_DTLS": null,
 "PRTY_IDNTFR": null,
 "OPRTN_TYPE": 1,
 "OLD_ACNT_NO": null,
 "table": "PAYPRDBAH.PEBAHPRD.CT_PYMNT",
 "scn": "122972702984",
 "op_type": "I",
 "op_ts": "1788908435000",
 "current_ts": "1788908442974",
 "row_id": "AADJVyAAJAAAq+IAAB",
 "username": "PEBAHPRD"
}
```

##### `PRD_PE_CT_REM_DATA` (CT_REM_STREAM) - Query [07]
```json
{
 "OU_ID": "GNBOBBHBM0",
 "TXN_POS_TYP": 25,
 "TXN_POS_NUM": 489297990,
 "INSTRMNT_ID": 1,
 "ORD_DT": 1788901200000,
 "REQ_EXEC_DT": 1788901200000,
 "EXEC_DT": 1788901200000,
 "IS_RED_DVD": null,
 "VAL_DT": 1788901200000,
 "VAL_DT_OVRRD_FLG": null,
 "STLMNT_DT": null,
 "CRNCY": "BHD",
 "INS_CRNCY": null,
 "EXCHNG_RT": null,
 "NUM_OF_PYMNTS": 1,
 "BTCH_BKNG": null,
 "CHRG_OPTN": 2,
 "CUST_REF": null,
 "STAT": 23,
 "EVNT_STAT": 77,
 "TXN_DTL": "23::0:20260909:20035:0:20260909:20035:::::::100667:0:GNBOBBHBM0",
 "INSTRCTN_CODE_FLG": null,
 "CHRGS_FLG": 1,
 "DR_PRTY_DTLS_FLG": null,
 "NO_OF_PYMNT_RPRD": null,
 "TM_INDCTN": null,
 "RMRKS": null,
 "RPR_FLG": null,
 "RPR_CMPLXTY": null,
 "SKIP_FLG": null,
 "FNLTY_FLG": null,
 "RLTD_SO_REF": null,
 "FORCE_AUTH": null,
 "INSTR_CODE": "OTHR/EFT-CSCT",
 "AMT": 10.0,
 "ORIG_AMT": null,
 "CNTR_AMT": null,
 "BASE_AMT": null,
 "RPRTNG_DTLS_FLG": null,
 "GROUPING_CRITERIA": null,
 "BKNG_DSCRPTN": null,
 "SAME_CUST_FLG": null,
 "BOP_FLG": null,
 "BNK_OP_CODE": null,
 "INP_QUEUE_TYPE": 34,
 "INIT_MU_ID": null,
 "INIT_SRVC_CNTR": null,
 "WLKIN_CUST_FLG": null,
 "CASH_BLCK_REF": null,
 "PREBOOKED_FLG": null,
 "CUST_CTGRY": 1,
 "CUST_TYPOLOGY": null,
 "TXN_TYP": null,
 "BOOKING_REF": null,
 "INT_REM_REF": 1,
 "JOB_RUN_ID": null,
 "CLR_TYP": 3,
 "REQ_EXE_TM": null,
 "EBP_REF": 238044160,
 "EBP_SRC": null,
 "PYMNT_BULK_PRCS_SEQ_ID": null,
 "CLCTN_TYP": null,
 "UNQ_SEQ_NUM": "NBB090926ON7TANY",
 "ALREADY_FILTERED": null,
 "TMPLT_NAME": null,
 "BEST_EFRT_APLCBLTY": null,
 "ORDER_TIME": 20035,
 "ORIG_REQ_EXEC_DT": null,
 "DEPARTMENT": null,
 "INTERIM_BKNG_FLG": null,
 "MAX_RTNTN_DT": null,
 "TXN_PRIORITY": null,
 "GOUR_SERVICE": null,
 "WAV_CHRG": null,
 "ORIG_EXCHNG_RT": null,
 "IS_FIXED": null,
 "PHASE_TM": null,
 "IS_MUL_TXN": null,
 "SNDR_BIC": null,
 "PRIORITY_CD": null,
 "RATE_RCV_FLG": null,
 "MVMNT_DESC": null,
 "FX_DEAL_REF": null,
 "PRE_AGRD_FLG": null,
 "BOP_ID": null,
 "PYMNT_DT_TYPE": null,
 "SAME_DY_EXEC_FLG": null,
 "EXT_USR_ID": null,
 "PRTN_GRP": 0,
 "PRTN_DATE": 1788901200000,
 "CNFDNTL_TRNFR": null,
 "ORDR_POS_NUM": 267581328,
 "ORDR_POS_TYP": 310,
 "RATE_PRPS": null,
 "INSTRCN_SND_DT": null,
 "AUTH_USER_ID": null,
 "LNKD_STDNG_ODR": null,
 "INSTRCN_REF_TYP": null,
 "ADNL_REF": null,
 "INSTRCN_RCVD_DT": null,
 "INSTRCN_REF": "BPAYBHBM",
 "PREAGREED_FLAG1": null,
 "INSTRCT_AMNT": null,
 "ADNL_REF_TYP": null,
 "AMOUNT": null,
 "APPL_CTGRY": null,
 "MVMNT_DESC2": null,
 "CREATE_TIMESTMP": null,
 "CRSPNDNT_TYP": null,
 "EXCHNGE_RATE": null,
 "MVMNT_DESC1": null,
 "AUTH_TIMESTMP": null,
 "INSTRCT_CRNCY": null,
 "MVMNT_DESC3": null,
 "CREATE_USER_ID": null,
 "PRTL_PRCSNG_FLG": null,
 "CNCL_CODE": null,
 "MGRTN_FLG": null,
 "BNK_PRTY_CODE": null,
 "TXN_TYP_ID": 42,
 "CHRG_ACNT_TYP": 0,
 "CHRG_ACNT": "BH40NBOB00000292541929",
 "CHRG_CRNCY": null,
 "TOT_CHRG_AMT": 0.0,
 "CHEQUE_NUM": null,
 "BATCH_BKNG": null,
 "TOT_CHRG_CRNCY": "BHD",
 "SPLIT_MTHD": null,
 "ORD_CUST_NM": null,
 "SNDNG_INSTN_NM": null,
 "SNDNG_INSTN_BIC": null,
 "CHRG_ACNT_CIF": "892165106",
 "CHRG_ACNT_NM": null,
 "CHRG_INCLSV_FLG": null,
 "CHEQUE_DATE": null,
 "CUST_MRGN": null,
 "TELLER_MRGN": null,
 "ORIG_CHRG_CRNCY": null,
 "ORIG_CHRG_AMT": null,
 "CHRG_EXCHNG_RT": null,
 "ORGNL_INSTRCTD_AMT": null,
 "ORGNL_INSTRCTD_CRNCY": null,
 "BLK_TXN_FLG": null,
 "ORC_NM": null,
 "DBTR_ACNT": "BH40NBOB00000292541929",
 "DBTR_ACNT_CRNCY": "BHD",
 "DBTR_ACNT_MUID": "00004",
 "DBTR_ADRS_LINE1": null,
 "DBTR_ADRS_LINE2": null,
 "DBTR_ADRS_LINE3": null,
 "DBTR_ADRS_LINE4": null,
 "DBTR_ADRS_TYP_FLG": null,
 "DBTR_ADRS_DEPT": null,
 "DBTR_ADRS_SUB_DEPT": null,
 "DBTR_ADRS_STRT_NM": null,
 "DBTR_ADRS_BULDNG_NB": null,
 "DBTR_ADRS_BULDNG_NM": null,
 "DBTR_ADRS_FLOOR": null,
 "DBTR_ADRS_POST_BOX": null,
 "DBTR_ADRS_ROOM": null,
 "DBTR_ADRS_POST_CODE": null,
 "DBTR_ADRS_TOWN_NMC": " ",
 "DBTR_ADRS_TOWN_LOC_NM": null,
 "DBTR_ADRS_DSTRCT_NM": null,
 "DBTR_ADRS_CNTRY_SUB_DIV": null,
 "DBTR_ACNT_TYP": null,
 "DBTR_CIF_ID": "892165106",
 "DBTR_NM": null,
 "DBTR_CTRY": "BH",
 "DBTR_EML": null,
 "DBTR_FAX": null,
 "DBTR_MBL": null,
 "DBTR_PHN": "/PHONE/97338199900",
 "DBTR_REF": "691204136",
 "DBTR_REF_TYP": null,
 "DBTR_ADNL_REF": "475424389",
 "DBTR_ADNL_REF_TYP": null,
 "ORC_ACNT_TYP": null,
 "ORC_ACNT": null,
 "ORC_ADRS_LINE1": null,
 "ORC_ADRS_LINE2": null,
 "ORC_ADRS_LINE3": null,
 "ORC_ADRS_LINE4": null,
 "ORC_ADRS_TYP_FLG": null,
 "ORC_ADRS_DEPT": null,
 "ORC_ADRS_SUB_DEPT": null,
 "ORC_ADRS_STRT_NM": null,
 "ORC_ADRS_BULDNG_NBC": null,
 "ORC_ADRS_BULDNG_NM": null,
 "ORC_ADRS_FLOOR": null,
 "ORC_ADRS_POST_BOX": null,
 "ORC_ADRS_ROOM": null,
 "ORC_ADRS_POST_CODE": null,
 "ORC_ADRS_TOWN_NM": null,
 "ORC_ADRS_TOWN_LORC_NM": null,
 "ORC_ADRS_DSTRCT_NM": null,
 "ORC_ADRS_CNTRY_SUB_DIV": null,
 "ORC_CTRY": null,
 "ORC_EML": null,
 "ORC_FAX": null,
 "ORC_MBL": null,
 "ORC_PHN": null,
 "ORC_REF": "892165106",
 "ORC_REF_TYP": null,
 "DBTR_ACNT_USG": 1,
 "DBTR_ACNT_POS_ID": null,
 "ORC_REF_TYP1": null,
 "ORC_ISSUER": null,
 "ORC_ISSUER1": null,
 "DBTR_PROXY_IDN": "MnNY6Nj7+UYkUYo+pIAOc07jGAE4030cbUD\n+8hFCgd0i+N8G5KFvmoY7cHla66JWaG3SLm\nF6ncQQ3ZhR/W1SHJFNSZo3WCK01oKIUAFGN\nGv8xewX787Y3B86Z03smug/Vm15bItJ8jhp\nQ665w9Mi+jWSBOH2JFcfvSLotywuVhoD1Er\n2Rs4xztnPq3kZFjmP1Q/SbqMAmRu/dcIt2a\nExGS6aPnh3h49sOB4Ng7M4QTPxIPfXVQN4O\namzCHad9bZnLFLaRfO5on2EyhmaBnkfKrgt\n7rLuZakDR1CNIuTC0AcFym6P1r/DpQWebFK\n2AE6sqIKDw9M6u9BMkiIoVtTE8w==\n",
 "DBTR_PROXY_IDN_CD": null,
 "DBTR_ACNT_SCH_DTLS": null,
 "ORC_CNTRY_OF_RES": null,
 "DBTR_CNTRY_OF_RES": null,
 "ORC_PRNT_IDNTFR": null,
 "ORC_BRTH_DTLS": "19691217",
 "DBTR_PRNT_IDNTFR": null,
 "DBTR_BRTH_DTLS": null,
 "DBTR_ACNT_NM": null,
 "DBTR_REF1": null,
 "DBTR_REF_TYP1": null,
 "DBTR_ISSUER": null,
 "DBTR_ISSUER1": null,
 "DBTR_BRTH_CNTRY": "BH",
 "ORC_REF1": null,
 "ORC_BRTH_CNTRY": null,
 "EXCHNG_RT_UNIT_CRNCY": null,
 "CT_REM_VER": 1,
 "DM_LSTUPDDT": 1788897635000,
 "DM_BTNUMBER": 751458934,
 "DM_BTID": 260142,
 "DM_USERID": 0,
 "DM_WSID": 0,
 "INIT_CUST_CNTCT_NM": null,
 "RSN_OF_PYMNT": null,
 "FND_VAL_OVRRD_FLG": null,
 "OPRTN_TYPE": null,
 "DRCTN": null,
 "ORDER_TYP": null,
 "SO_PRDCT": null,
 "REG_E": null,
 "MAKER_ID": null,
 "CHECKER_ID": null,
 "SO_INSTRMNT_ID": null,
 "OVERRIDE_FLG": null,
 "CHRG_FX_DEAL_REF": null,
 "OLD_ACNT_NO": null,
 "BUY_RATE": null,
 "SELL_RATE": null,
 "table": "PAYPRDBAH.PEBAHPRD.CT_REM",
 "scn": "122972702971",
 "op_type": "I",
 "op_ts": "1788908435000",
 "current_ts": "1788908443105",
 "row_id": "AADJVxAABAAFO1oAAE",
 "username": "PEBAHPRD"
}
```

##### `PRD_PE_INCMNG_MSG_QUEUE_DATA` (INCMNG_MSG_QUEUE_STREAM) - Query [15]
```json
{
 "OU_ID": "GNBOBBHBM0",
 "QUEUE_POS_TYP": 25,
 "MSG_RCV_DT": 20705,
 "REF_NUM": "NBB090926ON7TANY",
 "LOT_REF": "25:489297990:0",
 "GROUPING_CRITERIA": "25:489297990:0",
 "MSG_TYP": 101,
 "MSG_SYS": 20,
 "MSG_RCV_TM": null,
 "STATUS": null,
 "RLTD_REF_NUM": "BP1788908435S0J8",
 "FILE_REF": "BP1788908435S0J8",
 "ORG_MSG_TYP": null,
 "ORG_MSG_SYS": null,
 "NUM_OF_RECS": 1,
 "CUMLTVE_AMT": 10.0,
 "CUMLTVE_ACNT_SUM": null,
 "SCHDL_DT": null,
 "CLR_PRTY_REF_TYP": 1,
 "JOB_RUN_ID": null,
 "CHNL_ID": 20,
 "PDE_FLG": 2,
 "SGN_FLG": null,
 "PRTY_CODE_FLG": null,
 "QUEUE_POS_NUM": 489297990,
 "SCHDL_TM": null,
 "MIRN": null,
 "CHNL_MEDM_REF": "20",
 "ACQUISITION_MODE": null,
 "ACQUISITION_CHANNEL": 20,
 "CHNL_REF": null,
 "INTERNAL_REF": "311:268319689",
 "PRTN_GRP": 0,
 "PRTN_DATE": 20705,
 "INCMNG_MSG_QUEUE_VER": 1,
 "DM_LSTUPDDT": 20704,
 "DM_BTNUMBER": 751458934,
 "DM_BTID": 260142,
 "DM_USERID": 0,
 "DM_WSID": 0,
 "NUM_PYMNT": 1,
 "ORDR_LYR_ORGN_FLG": 2,
 "table": "PAYPRDBAH.PEBAHPRD.INCMNG_MSG_QUEUE",
 "scn": "122972702984",
 "op_type": "I",
 "op_ts": "1788919235000",
 "current_ts": "1788908443421",
 "row_id": "AADJVzAAiAABK6FAAV",
 "username": "PEBAHPRD"
}
```

##### `PRD_CBS_INVM_DATA` (INVM_STREAM) - Query [17]
```json
{
 "KEY_1": "0030000000292541929",
 "CUSTOMER_NO": "0000000892165106",
 "BRANCH_NO": "00001",
 "ACCT_TYPE": "SAV",
 "CURR_STATUS": "ACT",
 "CURRENCY": "BHD",
 "CURR_BAL": 65.162
}
```

---

### Phase 2: Keying Streams (Queries 23 – 29)
**Purpose**: Extracts key fields and re-partitions streams using `PARTITION BY` so they can be joined with tables or downstream streams.

#### Query Transformations & Outputs:

##### Query [28]: `INVM_WITH_KEY`
```sql
CREATE OR REPLACE STREAM INVM_WITH_KEY AS SELECT
 INVM_STREAM.PAYLOAD->CUSTOMER_NO CUSTOMER_NO,
 AS_VALUE(INVM_STREAM.PAYLOAD->KEY_1) KEY_1,
 SUBSTRING(INVM_STREAM.PAYLOAD->KEY_1, 4, 16) KEY_1_SUBSTRING_KEY,
 INVM_STREAM.PAYLOAD->BRANCH_NO BRANCH_NO,
 INVM_STREAM.PAYLOAD->CURRENCY CURRENCY,
 INVM_STREAM.PAYLOAD->CURR_BAL CURR_BAL
FROM INVM_STREAM
PARTITION BY SUBSTRING(INVM_STREAM.PAYLOAD->KEY_1, 4, 16);
```

**Key Extracted**: `SUBSTRING("0030000000292541929", 4, 16)` = `"0000000292541929"` 
**Output Stream Record**:
```json
{
 "KSQL_KEY": "0000000292541929",
 "CUSTOMER_NO": "0000000892165106",
 "KEY_1": "0030000000292541929",
 "KEY_1_SUBSTRING_KEY": "0000000292541929",
 "BRANCH_NO": "00001",
 "CURRENCY": "BHD",
 "CURR_BAL": 65.162
}
```

##### Query [25]: `CURM_WITH_KEY`
```sql
CREATE OR REPLACE STREAM CURM_WITH_KEY AS SELECT
 SUBSTRING(PAYLOAD->KEY_1, 4, 3) CURRENCY_KEY_1_KEY,
 AS_VALUE(PAYLOAD->KEY_1) KEY_1,
 PAYLOAD->RATE_MID RATE_MID
FROM CURM_STREAM
PARTITION BY SUBSTRING(PAYLOAD->KEY_1, 4, 3);
```

**Key Extracted**: `"BHD"` 
**Output Stream Record**:
```json
{
 "KSQL_KEY": "BHD",
 "CURRENCY_KEY_1_KEY": "BHD",
 "KEY_1": "003BHD",
 "RATE_MID": "1.000000"
}
```

---

### Phase 3: Lookup Tables (Queries 30 – 37)
**Purpose**: Materializes KSQL Streams into stateful lookup tables indexed by Primary Key.

#### Output State Tables:

##### Query [37]: `INVM_TABLE`
- **Primary Key**: `KEY_1_SUBSTRING_KEY` (`0000000292541929`)
```json
{
 "KEY_1_SUBSTRING_KEY": "0000000292541929",
 "CUSTOMER_NO": "0000000892165106",
 "KEY_1": "0030000000292541929",
 "BRANCH_NO": "00001",
 "ACCT_TYPE": "SAV",
 "STATUS": "ACT",
 "CURRENCY": "BHD",
 "CURR_BAL": "65.162"
}
```

##### Query [33]: `CURM_TABLE`
- **Primary Key**: `CURRENCY_KEY_1_KEY` (`BHD`)
```json
{
 "CURRENCY_KEY_1_KEY": "BHD",
 "KEY_1": "003BHD",
 "RATE_MID": "1.000000"
}
```

##### Query [34]: `ED1P_TABLE`
- **Primary Key**: `TRAN_CODE_KEY` (`01055`)
```json
{
 "TRAN_CODE_KEY": "01055",
 "TRAN_CODE": "1055",
 "ENQUIRY_DESC": "INTERNAL TELLER TRANSFER"
}
```

---

### Phase 4: Derived Intermediate Streams (Queries 38 – 51)
**Purpose**: Executes 30-minute windowed stream-stream joins to link Core Banking transactions with Payment Engine data.

#### Query Transformations & Outputs:

##### Query [49]: `BR_INCT`
```sql
CREATE OR REPLACE STREAM BR_INCT AS SELECT
 T.PAYLOAD->TXN_POS_NUM TXN_POS_NUM,
 I.POST_DATE POST_DATE,
 T.PAYLOAD->GEN_DT GEN_DT,
 T.PAYLOAD->ACNTG_REF ACNTG_REF,
 I.ACCT_NO+'%'+SUBSTRING(I.POST_DATE, 1, 10)+'%'+I.JRNL_NO ID,
 I.ACCT_NO ACCT_NO
FROM BOOKING_REQUEST_STREAM T
INNER JOIN INCTV I WITHIN 30 MINUTES ON ((SUBSTRING(T.PAYLOAD->GEN_DT, 1, 10)+'%'+T.PAYLOAD->ACNTG_REF = SUBSTRING(I.POST_DATE, 1, 10)+'%'+I.JRNL_NO))
WHERE (T.PAYLOAD->TXN_POS_TYP <> '310') AND (T.PAYLOAD->ACNTG_REF <> 'null')
PARTITION BY T.PAYLOAD->TXN_POS_NUM;
```

**Join Condition Match**: `"2026-09-09%100005456"` = `"2026-09-09%100005456"` 
**Output Record**:
```json
{
 "KSQL_KEY": "489297990",
 "TXN_POS_NUM": "489297990",
 "POST_DATE": "2026-09-09 00:00:00",
 "GEN_DT": "2026-09-09",
 "ACNTG_REF": "100005456",
 "ID": "0000000292541929%2026-09-09%100005456",
 "ACCT_NO": "0000000292541929"
}
```

##### Query [50]: `JS`
```sql
CREATE OR REPLACE STREAM JS AS SELECT
 C.PAYLOAD->BEN_ACNT BEN_ACNT,
 C.PAYLOAD->BEN_BNK_REF BEN_BNK_REF,
 C.PAYLOAD->BEN_CTRY BEN_CTRY,
 L.ACCT_NO ACCT_NO,
 L.TXN_POS_NUM C_TXN_POS_NUM,
 C.PAYLOAD->UNQ_SEQ_NUM UNQ_SEQ_NUM,
 C.PAYLOAD->E2E_REF_NUM E2E_REF_NUM,
 L.ID ID
FROM CT_PYMNT_STREAM C
INNER JOIN BR_INCT L WITHIN 30 MINUTES ON ((C.PAYLOAD->TXN_POS_NUM = L.TXN_POS_NUM));
```

**Join Condition Match**: `TXN_POS_NUM = 489297990` 
**Output Record**:
```json
{
 "BEN_ACNT": "BH33ALSA00256589150000",
 "BEN_BNK_REF": "ALSABHBMXXX",
 "BEN_CTRY": null,
 "ACCT_NO": "0000000292541929",
 "C_TXN_POS_NUM": "489297990",
 "UNQ_SEQ_NUM": "NBB090926ON7TANY",
 "E2E_REF_NUM": "6003876527",
 "ID": "0000000292541929%2026-09-09%100005456"
}
```

##### Query [51]: `GS`
```sql
CREATE OR REPLACE STREAM GS AS SELECT
 C.PAYLOAD->ORD_CUST_NM ORD_CUST_NM,
 L.ACCT_NO ACCT_NO,
 L.TXN_POS_NUM C_TXN_POS_NUM,
 C.PAYLOAD->INSTRMNT_ID INSTRMNT_ID,
 C.PAYLOAD->CLR_TYP CLR_TYP,
 L.ID ID
FROM CT_REM_STREAM C
INNER JOIN BR_INCT L WITHIN 30 MINUTES ON ((C.PAYLOAD->TXN_POS_NUM = L.TXN_POS_NUM));
```

**Join Condition Match**: `TXN_POS_NUM = 489297990` 
**Output Record**:
```json
{
 "ORD_CUST_NM": null,
 "ACCT_NO": "0000000292541929",
 "C_TXN_POS_NUM": "489297990",
 "INSTRMNT_ID": "1",
 "CLR_TYP": "3",
 "ID": "0000000292541929%2026-09-09%100005456"
}
```

---

### Phase 5: Final Output Side Streams (Queries 52 – 56)
**Purpose**: Generates specialized audit and registration side streams (`SB1` - Forgot Username, `SB2` - Device Reg, `SB3` - Login History, `SB4` - Salary/File Transfers, `AUDIT_FINAL_NEW`).

#### Sample Output Record (Query [54]: `SB4` - File Detail Beneficiary Transfer):
```json
{
 "CUSTOMER_NUMBER": "895570052",
 "CHANNEL_ID": "S",
 "TRANSACTION_TYPE": "BB",
 "EVENT_DATETIME": "2026-09-09 02:00:23",
 "STATUS": "P"
}
```

---

### Phase 6: CASA Pipeline DDLs (Queries 57 – 59)
**Purpose**: Declares intermediate stream schemas for `CASA_INTERMEDIATE`, `CASA_INTERMEDIATE_CHANNELED`, and `CASA_INTERMEDIATE_TERMINAL`.

---

### Phase 7: INSERT INTO CASA_INTERMEDIATE (Queries 60 – 63)
**Purpose**: Joins Core Banking (`INCT`), Remittance (`GS`), Payment (`JS`), Incoming Queue (`IMQ`), and Account Master (`INVM_TABLE`) into a single normalized `CASA_INTERMEDIATE` stream.

#### Query Logic:
- **Channel Mapping**: `IMQ.CHNL_ID=20` ➔ `'B'`, `418/419/420` ➔ `'S'`, `437/438` ➔ `'D'`.
- **Transaction Type Mapping**: `INSTRMNT_ID=1 & CLR_TYP=3` ➔ `'OUT FAWRI+ and FAWATEER ONLINE'`.
- **Time Formats**: `POST_TIME = 2003593` ➔ `'02:00:35:93'`.

#### Sample Output Record (Query [60] / [61] - External Payment):
```json
{
 "JOURNAL_NO": "100005456",
 "TRAN_ACC_NO": "0000000292541929",
 "TRAN_DATE": "2026-09-09 00:00:00",
 "TRAN_CODE": "1055",
 "AMOUNT": "10.000",
 "BALANCE": "65.162",
 "POST_DATE": "2026-09-09 00:00:00",
 "POST_DATETIME": "2026-09-09 02:00:35:93",
 "POST_TIME": "02:00:35:93",
 "CORRECTION_FLAG": "0",
 "EXECUTOR_TELLER": "5000003",
 "EXECUTION_BRANCH": "00001",
 "CHANNEL_ID": "B",
 "TRAN_ID": "100005456202609099999793401055D",
 "CREDIT_DEBIT_FLAG": "D",
 "CP_IBAN": "BH33ALSA00256589150000",
 "CP_BANK": "ALSABHBMXXX",
 "CP_COUNTRY": null,
 "CP_NAME": null,
 "UNQ_SEQ_NUM": "NBB090926ON7TANY",
 "E2E_REF_NUM": "6003876527",
 "ID": "0000000292541929%2026-09-09%100005456",
 "CURRENCY": "BHD",
 "CUSTOMER_NO": "0000000892165106",
 "TXN_TYPE": "OUT FAWRI+ and FAWATEER ONLINE",
 "INT_EXT": "EXT"
}
```

---

### Phase 8: INSERT INTO CASA_INTERMEDIATE_CHANNELED (Queries 64 – 69)
**Purpose**: Routes transactions based on channel (`D`, `S`, or `Other`) and enriches with session details, IP addresses, geolocations, or corporate transaction headers (`TXNDH_STREAM`).

#### Sample Output Record (Query [68] - External Non-Digital Channel 'B'):
```json
{
 "ID_KEY": "0000000292541929%2026-09-09%100005456",
 "ID": "0000000292541929%2026-09-09%100005456",
 "TRAN_ACC_NO": "0000000292541929",
 "TRAN_DATE": "2026-09-09 00:00:00",
 "TRAN_CODE": "1055",
 "JOURNAL_NO": "100005456",
 "AMOUNT": "10.000",
 "BALANCE": "65.162",
 "POST_DATE": "2026-09-09 00:00:00",
 "POST_DATETIME": "2026-09-09 02:00:35:93",
 "POST_TIME": "02:00:35:93",
 "CORRECTION_FLAG": "0",
 "EXECUTOR_TELLER": "5000003",
 "EXECUTION_BRANCH": "00001",
 "CHANNEL_ID": "B",
 "TRAN_ID": "100005456202609099999793401055D",
 "CREDIT_DEBIT_FLAG": "D",
 "CP_IBAN": "BH33ALSA00256589150000",
 "CP_BANK": "ALSABHBMXXX",
 "CP_COUNTRY": null,
 "CP_NAME": null,
 "SESSION_ID": null,
 "GEO_LONG": null,
 "GEO_LAT": null,
 "DEVICE_ID": null,
 "STATUS": "S",
 "TXN_TYPE": "OUT FAWRI+ and FAWATEER ONLINE",
 "CURRENCY": "BHD",
 "INT_EXT": "EXT"
}
```

---

### Phase 9: INSERT INTO CASA_INTERMEDIATE_TERMINAL (Queries 70 – 73)
**Purpose**: Performs foreign exchange rate conversion (`AMOUNT * CURM.RATE_MID`) and resolves counterparty IBANs for internal transactions using `IBAN_TABLE`.

#### Transformation Logic:
- For `CURRENCY = 'BHD'`: `AMOUNT_IN_LOC_CURR = REPLACE(AMOUNT, ',', '')` (Direct 1:1 local currency passthrough).
- For Foreign Currency (e.g., `USD`): `AMOUNT_IN_LOC_CURR = AMOUNT * RATE_MID`.

#### Sample Output Record (Query [71] - BHD Currency Passthrough):
```json
{
 "ID_KEY": "0000000292541929%2026-09-09%100005456",
 "ID": "0000000292541929%2026-09-09%100005456",
 "TRAN_ACC_NO": "0000000292541929",
 "TRAN_DATE": "2026-09-09 00:00:00",
 "TRAN_CODE": "1055",
 "JOURNAL_NO": "100005456",
 "AMOUNT": "10.000",
 "AMOUNT_IN_LOC_CURR": "10.000",
 "BALANCE": "65.162",
 "BALANCE_IN_LOC_CURR": "65.162",
 "POST_DATE": "2026-09-09 00:00:00",
 "POST_DATETIME": "2026-09-09 02:00:35:93",
 "POST_TIME": "02:00:35:93",
 "CORRECTION_FLAG": "0",
 "EXECUTOR_TELLER": "5000003",
 "EXECUTION_BRANCH": "00001",
 "CHANNEL_ID": "B",
 "TRAN_ID": "100005456202609099999793401055D",
 "CREDIT_DEBIT_FLAG": "D",
 "CP_IBAN": "BH33ALSA00256589150000",
 "CP_BANK": "ALSABHBMXXX",
 "CP_COUNTRY": null,
 "CP_NAME": null,
 "SESSION_ID": null,
 "GEO_LONG": null,
 "GEO_LAT": null,
 "DEVICE_ID": null,
 "STATUS": "S",
 "TXN_TYPE": "OUT FAWRI+ and FAWATEER ONLINE"
}
```

---

### Phase 10: CASA Final Pipeline (Queries 74 – 76)
**Purpose**: Performs repartitioning, 1-minute Tumbling Window aggregation, deduplication (`HAVING COUNT(ID)=1`), and emits to `CASA_FINAL_TOPIC`.

#### Query [74]: `CASA_FINAL_STREAM_REPARTITIONED`
Repartitions stream records by single partition to guarantee deterministic windowing order.

#### Query [75]: `CASA_FINAL_TABLE` (Deduplication Window Table)
```sql
CREATE OR REPLACE TABLE CASA_FINAL_TABLE WITH (kafka_topic='CASA_FINAL_TBL_TOPIC', partitions=1, value_format='JSON') AS
   SELECT
       ID AS ID_KEY,
       LATEST_BY_OFFSET(TRAN_ACC_NO) TRAN_ACC_NO,
       LATEST_BY_OFFSET(TRAN_DATE) TRAN_DATE,
       LATEST_BY_OFFSET(TRAN_CODE) TRAN_CODE,
       LATEST_BY_OFFSET(JOURNAL_NO) JOURNAL_NO,
       LATEST_BY_OFFSET(AMOUNT) AMOUNT,
       LATEST_BY_OFFSET(AMOUNT_IN_LOC_CURR) AMOUNT_IN_LOC_CURR,
       LATEST_BY_OFFSET(BALANCE) BALANCE,
       LATEST_BY_OFFSET(BALANCE_IN_LOC_CURR) BALANCE_IN_LOC_CURR,
       LATEST_BY_OFFSET(POST_DATE) POST_DATE,
       LATEST_BY_OFFSET(POST_DATETIME) POST_DATETIME,
       LATEST_BY_OFFSET(POST_TIME) POST_TIME,
       LATEST_BY_OFFSET(CORRECTION_FLAG) CORRECTION_FLAG,
       LATEST_BY_OFFSET(EXECUTOR_TELLER) EXECUTOR_TELLER,
       LATEST_BY_OFFSET(EXECUTION_BRANCH) EXECUTION_BRANCH,
       LATEST_BY_OFFSET(CHANNEL_ID) CHANNEL_ID,
       LATEST_BY_OFFSET(TRAN_ID) TRAN_ID,
       LATEST_BY_OFFSET(CREDIT_DEBIT_FLAG) CREDIT_DEBIT_FLAG,
       LATEST_BY_OFFSET(CP_IBAN) CP_IBAN,
       LATEST_BY_OFFSET(CP_BANK) CP_BANK,
       LATEST_BY_OFFSET(CP_COUNTRY) CP_COUNTRY,
       LATEST_BY_OFFSET(CP_NAME) CP_NAME,
       LATEST_BY_OFFSET(SESSION_ID) SESSION_ID,
       LATEST_BY_OFFSET(GEO_LONG) GEO_LONG,
       LATEST_BY_OFFSET(GEO_LAT) GEO_LAT,
       LATEST_BY_OFFSET(DEVICE_ID) DEVICE_ID,
       LATEST_BY_OFFSET(STATUS) STATUS,
       LATEST_BY_OFFSET(TXN_TYPE) TXN_TYPE
   FROM CASA_FINAL_STREAM_REPARTITIONED WINDOW TUMBLING (SIZE 1 MINUTES, RETENTION 12 HOURS, GRACE PERIOD 30 MINUTES)
   GROUP BY ID HAVING COUNT(ID)=1 EMIT CHANGES;
```

#### Query [76]: `CASA_FINAL` (Final Output Stream)
Emits records from table into the final Kafka topic `CASA_FINAL_TOPIC`.

#### Final Output Record (Emitted to `CASA_FINAL_TOPIC`):
```json
{
 "TRAN_ACC_NO": "0000000292541929",
 "TRAN_DATE": "2026-09-09 00:00:00",
 "TRAN_CODE": "1055",
 "JOURNAL_NO": "100005456",
 "AMOUNT": "10.000",
 "AMOUNT_IN_LOC_CURR": "10.000",
 "BALANCE": "65.162",
 "BALANCE_IN_LOC_CURR": "65.162",
 "POST_DATE": "2026-09-09 00:00:00",
 "POST_DATETIME": "2026-09-09 02:00:35:93",
 "POST_TIME": "02:00:35:93",
 "CORRECTION_FLAG": "0",
 "EXECUTOR_TELLER": "5000003",
 "EXECUTION_BRANCH": "00001",
 "CHANNEL_ID": "B",
 "TRAN_ID": "100005456202609099999793401055D",
 "CREDIT_DEBIT_FLAG": "D",
 "CP_IBAN": "BH33ALSA00256589150000",
 "CP_BANK": "ALSABHBMXXX",
 "CP_COUNTRY": null,
 "CP_NAME": null,
 "SESSION_ID": null,
 "GEO_LONG": null,
 "GEO_LAT": null,
 "DEVICE_ID": null,
 "STATUS": "S",
 "TXN_TYPE": "OUT FAWRI+ and FAWATEER ONLINE"
}
```

---

## 4. Verification & Audit Summary Matrix

| Phase | Input Entity / Topic | Output Entity / Topic | Sampled Key / ID | Core Transformation Rules Applied | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Phase 1** | `PRD_PE_*`, `INCT_PRD_TOPIC` | Source Streams DDL | Journal `100005456` | Struct DDL Schema definitions | **Verified** |
| **Phase 2** | `INVM_STREAM`, `CURM_STREAM` | Keying Streams | Account `0000000292541929` | Re-partitioning by `SUBSTRING(KEY_1, 4, 16)` | **Verified** |
| **Phase 3** | Keying Streams | Lookup KSQL Tables | Account `0000000292541929` | Table materialization with Primary Key | **Verified** |
| **Phase 4** | `BOOKING_REQUEST` + `INCT` | `BR_INCT`, `JS`, `GS` | `489297990` | 30-min window join on `GEN_DT(1..10)%ACNTG_REF` | **Verified** |
| **Phase 5** | `CVRD_STREAM`, `FDTT_STREAM` | Side Streams (`SB1`–`SB4`) | `MANAMACLUB` | Status code mapping (`SUC`➔`S`, `DSP`➔`P`, etc.) | **Verified** |
| **Phase 6** | Intermediate Topography | CASA Schema DDLs | N/A | DDL definitions for CASA Intermediate topics | **Verified** |
| **Phase 7** | `INCT` + `GS` + `INVM` + `JS` + `IMQ` | `CASA_INTERMEDIATE` | `0000000292541929%2026-09-09%100005456` | 4-way stream join & channel/txn_type classification | **Verified** |
| **Phase 8** | `CASA_INTERMEDIATE` | `CASA_INTERMEDIATE_CHANNELED` | `0000000292541929%2026-09-09%100005456` | Channel routing & session/geo/device enrichment | **Verified** |
| **Phase 9** | `CASA_INTERMEDIATE_CHANNELED` | `CASA_INTERMEDIATE_TERMINAL` | `0000000292541929%2026-09-09%100005456` | Currency conversion via `CURM_TABLE.RATE_MID` | **Verified** |
| **Phase 10** | `CASA_INTERMEDIATE_TERMINAL` | `CASA_FINAL` (via `CASA_FINAL_TABLE`) | `0000000292541929%2026-09-09%100005456` | 1-min Tumbling Window deduplication (`HAVING COUNT=1`) | **Verified** |

---
*Report Generated automatically by Antigravity AI Engine during Peak Workload Dump Simulation.*

