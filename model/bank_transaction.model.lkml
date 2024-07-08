connection: "bfsi"

# include all the views
include: "/views/dna/**/*.view.lkml"
#include: "/core/dna/dashboards/dna/*.dashboard"
# include: "/dashboards/**/*.dashboard"


datagroup: poc_pilot_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: poc_pilot_default_datagroup

explore:  fact_bank_transaction{
  label: "Bank Transaction"
  view_label: "Bank Transaction"
  join: dim_account {
    type: left_outer
    view_label: "Account"
    relationship: many_to_one
    sql_on: ${fact_bank_transaction.account_number} = ${dim_account.account_number} ;;
  }
  join: dim_association {
    type: left_outer
    view_label: "Association"
    relationship: many_to_one
    sql_on: ${fact_bank_transaction.association_id} = ${dim_association.member_group_code} ;;
  }
  join: dim_member {
    type: left_outer
    view_label: "Member"
    relationship: many_to_one
    sql_on: ${fact_bank_transaction.member_id} = ${dim_member.member_id} ;;
  }
  join: dim_product_service {
    type: left_outer
    view_label: "Product Service"
    relationship: one_to_one
    sql_on: ${fact_bank_transaction.product_id} = ${dim_product_service.minor_account_type_code} ;;
  }
  join: dim_transaction_type {
    type: left_outer
    view_label: "Transaction Type"
    relationship: one_to_one
    sql_on: ${fact_bank_transaction.transaction_type_code} = ${dim_transaction_type.transaction_type_code} ;;
  }
  join: dim_cashbox {
    type: left_outer
    view_label: "Cashbox"
    relationship: many_to_one
    sql_on: ${fact_bank_transaction.cashbox_number} = ${dim_cashbox.cashbox_nbr} ;;
  }
}
