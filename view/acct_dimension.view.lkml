view: dim_account {
  derived_table: {
    # Commented out the left join with closestatus CTE as accstathist table is not present in poc environment
    #increment_key: "load_date"
    sql:
    SELECT
      acct.ACCTNBR,
      DATE(acct.DATELASTMAINT) as datelastmaint,
      CASE mjaccttypcat.MJACCTTYPCATCD
        WHEN 'DEP' THEN 1
        WHEN 'EXT' THEN 2
        WHEN 'LEAS' THEN 3
        WHEN 'LOAN' THEN 4
        WHEN 'OTH' THEN 5
        WHEN 'RR' THEN 6
        WHEN 'RTMT' THEN 7
      ELSE
      0
      END as major_account_type_code_number,
      mjaccttypcat.MJACCTTYPCATDESC,
      mjaccttyp.MJACCTTYPCD,
      mjaccttyp.MJACCTTYPDESC,
      mjmiacttyp.MIACCTTYPCD,
      mjmiacttyp.MIACCTTYPDESC,
      acct.CURRACCTSTATCD,
      acct.CONTRACTDATE,
      acct.BRANCHORGNBR,
      org.ORGNAME,
      acct.DATEMAT,
      mjmiacttyp.SERVICE_CODE,
      service.DESCRIPTION,
      IFNULL(acctbal.BALAMT, 0) as BALAMT,
      acct.CLOSEREASONCD,
      closestatus.EFFDATETIME AS close_eff_date,
    FROM
      `dna.acct_target` acct
    INNER JOIN
      `dna.mjmiaccttyp_target` mjmiacttyp
    ON
      mjmiacttyp.MJACCTTYPCD = acct.MJACCTTYPCD
      AND mjmiacttyp.MIACCTTYPCD = acct.CURRMIACCTTYPCD
    INNER JOIN
      `dna.mjaccttyp_target` mjaccttyp
    ON
      mjaccttyp.MJACCTTYPCD = acct.MJACCTTYPCD
    INNER JOIN
      `dna.mjaccttypcat_target` mjaccttypcat
    ON
      mjaccttypcat.MJACCTTYPCATCD = mjaccttyp.MJACCTTYPCATCD
    INNER JOIN
      `dna.org_target` org
    ON
      org.ORGNBR = acct.BRANCHORGNBR
    LEFT JOIN
      `dna.service_target` service
    ON
      service.CODE = mjmiacttyp.SERVICE_CODE
    LEFT JOIN (
      SELECT
        balance.ACCTNBR,
        balance.BALAMT
      FROM (
        SELECT
          acctbalhist.ACCTNBR,
          acctbalhist.BALAMT,
          RANK() OVER (PARTITION BY acctbalhist.ACCTNBR ORDER BY acctbalhist.EFFDATE DESC) AS LASTROW
        FROM
          `dna.acctbalhist_target` acctbalhist
        JOIN
          `dna.acctsubacct_target` acctsubacct
        ON
          acctsubacct.ACCTNBR = acctbalhist.ACCTNBR
          AND acctsubacct.SUBACCTNBR = acctbalhist.SUBACCTNBR
        --WHERE
          --acctsubacct.BALCATCD = 'NOTE'
          --AND acctsubacct.BALTYPCD = 'BAL' )
          ) balance
      WHERE
        balance.LASTROW = 1 ) acctbal
    ON
      acctbal.ACCTNBR = acct.ACCTNBR
    LEFT JOIN (
      SELECT
        stathist.ACCTNBR,
        stathist.EFFDATETIME
      FROM (
        SELECT
          acctacctstathist.ACCTNBR,
          acctacctstathist.EFFDATETIME,
          RANK() OVER(PARTITION BY acctacctstathist.ACCTNBR ORDER BY acctacctstathist.EFFDATETIME DESC, acctacctstathist.TIMEUNIQUEEXTN DESC) LASTROW
        FROM
          `dna.acctacctstathist_target` acctacctstathist
        --WHERE
          --acctacctstathist.ACCTSTATCD = 'CLS'
          ) stathist
      WHERE
        stathist.LASTROW = 1 ) closestatus
    ON
      closestatus.ACCTNBR = acct.ACCTNBR
      --where {% incrementcondition %} cast(acct.DATELASTMAINT as timestamp) {% endincrementcondition %}
      ;;
    sql_trigger_value: select max(DATE(DATELASTMAINT)) from `dna.acct_target`;;
  }

  dimension_group: load {
    description: "Date of data upload"
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    datatype: timestamp
    sql: cast(${TABLE}.DATELASTMAINT as TIMESTAMP);;
  }

  dimension: account_number {
    description: "The Account Number is a system-assigned primary key that uniquely identifies each account."
    group_label: "Account Info"
    primary_key: yes
    type: number
    sql: ${TABLE}.ACCTNBR ;;
  }

  dimension: major_account_type {
    description: "Identifies the type of major account"
    group_label: "Account Info"
    type: string
    sql: ${TABLE}.MJACCTTYPDESC ;;
  }

  dimension: major_account_type_category {
    description: "Identifies the category of major account type"
    group_label: "Account Info"
    type: string
    sql: ${TABLE}.MJACCTTYPCATDESC ;;
  }

  dimension: major_account_type_code {
    description: "Identifies the code of major account type"
    group_label: "Account Info"
    type: string
    sql: ${TABLE}.MJACCTTYPCD ;;
  }

  dimension: major_account_type_code_number {
    description: "Identifies the code number of the major account type"
    group_label: "Account Info"
    type: number
    sql: ${TABLE}.major_account_type_code_number ;;
  }

  dimension: product {
    type: string
    sql: ${TABLE}.MIACCTTYPDESC ;;
  }

  dimension: account_status {
    type: string
    sql: ${TABLE}.CURRACCTSTATCD ;;
  }

  dimension: open_date {
    type: date
    sql: ${TABLE}.CONTRACTDATE ;;
  }

  dimension: account_branch_number {
    type: number
    sql: ${TABLE}.BRANCHORGNBR ;;
  }

  dimension: account_branch_name {
    type: string
    sql: ${TABLE}.ORGNAME ;;
  }

  dimension: maturity_date {
    type: date
    sql: ${TABLE}.DATEMAT ;;
  }

  dimension: service_code {
    type: number
    sql: ${TABLE}.SERVICE_CODE ;;
  }

  dimension: service_desc {
    type: string
    sql: ${TABLE}.DESCRIPTION ;;
  }

  dimension: account_balance {
    type: number
    sql: ${TABLE}.BALAMT ;;
  }

  dimension: close_reason_code {
    type: string
    sql: ${TABLE}.CLOSEREASONCD ;;
  }

  dimension: close_eff_date {
    type: date
    sql: ${TABLE}.close_eff_date ;;
  }

  # dimension: transaction_number {
  #   type: number
  #   sql: ${TABLE}.transaction_number ;;
  # }

  # dimension: transaction_type_code {
  #   type: string
  #   sql: ${TABLE}.transaction_type_code ;;
  # }

  # dimension: transaction_amount {
  #   type: number
  #   sql: ${TABLE}.transaction_amount ;;
  # }

  measure: Sum_Account_Balance {
    description: "Sum of Account Balance"
    type: sum
    sql: ${TABLE}.BALAMT ;;
  }

  measure: Min_Account_Balance {
    description: "Min of Account Balance"
    type: min
    sql: ${TABLE}.BALAMT ;;
  }

  measure: Max_Account_Balance {
    description: "Max of Account Balance"
    type: max
    sql: ${TABLE}.BALAMT ;;
  }

  measure: Avg_Account_Balance {
    description: "Average of Account Balance"
    type: average
    sql: ${TABLE}.BALAMT ;;
  }

  measure: count {
    description: "Count"
    type: count
    drill_fields: []
  }


}
