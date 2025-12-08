以下の質問とSQLを追加します
> AERO ビジネスラインには何件の注文が予定されていますか?
```sql
SELECT 
  COUNT(*) AS aero_order_count 
FROM snowflake_si_handson.raw_scm.orders AS o 
JOIN snowflake_si_handson.raw_scm.product AS p ON o.product_id = p.product_id 
WHERE p.business_line = 'AERO'
```

> 弊社の製造工場で在庫が不足している原材料はどれですか?
```sql
SELECT
  cf.mfg_plant_name,
  m.material_name,
  ci.quantity_on_hand,
  ci.safety_stock_level,
  ci.days_forward_coverage,
  ci.material_lead_time,
  ci.lead_time_variability
FROM
  snowflake_si_handson.raw_scm.mfg_inventory AS ci
  JOIN snowflake_si_handson.raw_scm.MFG_PLANT AS cf ON ci.MFG_PLANT_ID = cf.MFG_PLANT_ID
  JOIN snowflake_si_handson.raw_scm.raw_material AS m ON ci.material_id = m.material_id
WHERE
  quantity_on_hand < safety_stock_level
  AND DAYS_FORWARD_COVERAGE <= MATERIAL_LEAD_TIME + LEAD_TIME_VARIABILITY
```

> ノースカロライナ州シャーロット近郊の施設からの出荷品を表示してください
```sql
SELECT
  *
FROM
  snowflake_si_handson.raw_scm.shipment AS s
  JOIN snowflake_si_handson.raw_scm.MFG_PLANT AS cmf ON s.origin_facility_id = cmf.MFG_PLANT_ID
WHERE
  ST_DWITHIN(
    ST_MAKEPOINT(cmf.longitude, cmf.latitude)
    /* Facility Location */,
    ST_MAKEPOINT(-80.8431, 35.2271)
    /* Charlotte, NC: longitude, latitude */,
    50 * 1609.34
  )
  /* 50 miles converted to meters */
```
> 弊社の販売代理店全体のビル管理システムの平均在庫はどれくらいですか?
```sql
SELECT
  d.distributor_name,
  AVG(di.quantity_on_hand) AS average_inventory
FROM
  snowflake_si_handson.raw_scm.distributor_inventory AS di
  JOIN snowflake_si_handson.raw_scm.distributor AS d ON di.distributor_id = d.distributor_id
  JOIN snowflake_si_handson.raw_scm.product AS p ON di.product_id = p.product_id
WHERE
  p.product_name = 'Building Management System'
GROUP BY
  d.distributor_name
```
