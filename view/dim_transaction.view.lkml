view: dim_transaction {
  derived_table: {
    sql:
      WITH channel AS (
        SELECT rtxn.ORIGPOSTDATE ,
          rtxntyp.RTXNTYPCATCD ,
          rtxntypcat.RTXNTYPCATDESC ,
          rtxn.RTXNTYPCD ,
          rtxntyp.RTXNTYPDESC ,
          rtxn.ACCTNBR ,
          rtxn.RTXNNBR ,
          rtxnstathist.EFFDATE ,
          rtxnstathist.POSTDATE ,
          rtxnstathist.RTXNSTATCD ,
          rtxnstathist.CASHBOXNBR ,
          rtxnstathist.ORIGPERSNBR ,
          cashbox.CASHBOXTYPCD ,
          cashbox.CASHBOXDESC ,
          cashbox.BATCHCASHBOXYN ,
          cashbox.LOCORGNBR ,
          org.ORGNAME ,
          org.ORGTYPCD ,
          org.FCYN ,
          CASE
            WHEN rtxntyp.RTXNTYPCATCD = 'ATM' AND rtxn.RTXNTYPCD IN ('DDEP', 'DWTF', 'DWTH', 'DWTT') THEN 'ATM'
            WHEN cashbox.CashboxTypCd = 'ITMC' AND rtxntyp.RTXNTYPCATCD = 'DEP' THEN 'ITM'
            WHEN org.ORGNBR = 169 AND rtxntyp.RTXNTYPCATCD IN ('LOAN', 'DEP') THEN 'Contact Center'
            WHEN org.ORGNBR = 206 AND rtxn.RTXNSOURCECD = 'WWW' AND rtxnstathist.ORIGPERSNBR IS NOT NULL THEN 'Digital Banking'
            WHEN rtxntyp.RTXNTYPCATCD = 'ATM' AND rtxn.RTXNTYPCD IN ('PDEP', 'PPOS', 'PWTH') THEN 'POS'
            WHEN org.FCYN = TRUE AND cashbox.CashBoxTypCd != 'VRU' THEN 'Branch'
            WHEN cashbox.CashBoxTypCd = 'VRU' THEN 'IVR'
            ELSE 'Other'
          END AS channel_name
          FROM `dna.rtxn_target` rtxn
          JOIN `dna.rtxnstathist_target` rtxnstathist
          ON rtxnstathist.ACCTNBR = rtxn.ACCTNBR AND rtxnstathist.RTXNNBR = rtxn.RTXNNBR
          JOIN `dna.cashbox_target` cashbox
          ON cashbox.CASHBOXNBR = rtxnstathist.CASHBOXNBR
          JOIN `dna.org_target` org
          ON org.ORGNBR = cashbox.LOCORGNBR
          JOIN `dna.rtxntyp_target` rtxntyp
          ON rtxntyp.RTXNTYPCD = rtxn.RTXNTYPCD
          JOIN `dna.rtxntypcat_target` rtxntypcat
          ON rtxntypcat.RTXNTYPCATCD = rtxntyp.RTXNTYPCATCD
          WHERE rtxntyp.RTXNTYPCATCD != 'GL'
            AND rtxnstathist.RTXNSTATCD = 'C'),
        main AS (
        SELECT DISTINCT RTXNTYPCD,
        RTXNTYPDESC,
        RTXNTYPCATCD,
        RTXNTYPCATDESC,
        channel_name,
        if(channel_name = 'Digital Banking', 'Online', 'Offline') AS online_status
        FROM channel)
        SELECT * FROM main
         ;;
    sql_trigger_value: select max(DATE(DATELASTMAINT)) from `dna.rtxn_target`;;
  }


  dimension: channel_name {
    description: "Contains the name of the channel which supported the transaction."
    group_label: "Transaction Info"
    type: string
    sql: ${TABLE}.channel_name ;;
  }

  dimension: online_status {
    description: "Status of the transaction i.e Online or Offline"
    group_label: "Transaction Info"
    type: string
    sql: ${TABLE}.online_status ;;
  }

  dimension: transaction_category {
    description: "Identifies the Transaction category"
    group_label: "Transaction Info"
    type: string
    sql: ${TABLE}.RTXNTYPCATDESC ;;
  }

  dimension: transaction_category_code {
    description: "Identifies the Transaction category code"
    group_label: "Transaction Info"
    type: string
    sql: ${TABLE}.RTXNTYPCATCD ;;
  }

  dimension: transaction_type {
    description: "Identifies the Transaction Type"
    group_label: "Transaction Info"
    primary_key: yes
    type: string
    sql: ${TABLE}.RTXNTYPDESC;;
  }

  dimension: transaction_type_code {
    description: "The Transaction Type Code identifies the type of allotment performed."
    group_label: "Transaction Info"
    type: string
    sql: ${TABLE}.RTXNTYPCD ;;
  }

  measure: count {
    description: "Count"
    type: count
    drill_fields: [channel_name]
  }
}
