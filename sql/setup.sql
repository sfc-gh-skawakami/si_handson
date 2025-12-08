// Step0: コンテキスト設定
USE ROLE accountadmin;

CREATE ROLE scm_intelligence_role;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE scm_intelligence_role;

-- ROLEをユーザーに付与(以下のSQLを参加者ユーザー分実行)
GRANT ROLE scm_intelligence_role TO USER ******; --(参加者ユーザー名に変更して実行)


// Step1: オブジェクトの作成 //
USE ROLE sysadmin;
--------- Create Database ---------
CREATE DATABASE IF NOT EXISTS snowflake_si_handson;
CREATE SCHEMA IF NOT EXISTS raw_scm;

GRANT USAGE ON DATABASE SNOWFLAKE_SI_HANDSON TO ROLE scm_intelligence_role;
GRANT USAGE ON SCHEMA RAW_SCM TO ROLE scm_intelligence_role;
GRANT CREATE AGENT ON FUTURE SCHEMAS on database SNOWFLAKE_SI_HANDSON TO ROLE scm_intelligence_role;
GRANT USAGE, OPERATE ON WAREHOUSE SI_HANDSON_WH TO ROLE scm_intelligence_role;
GRANT SELECT ON ALL TABLES IN SCHEMA RAW_SCM TO ROLE scm_intelligence_role;
GRANT SELECT ON FUTURE TABLES IN SCHEMA RAW_SCM TO ROLE scm_intelligence_role;

-- CREAE STAGE
CREATE OR REPLACE STAGE raw_data directory = (ENABLE = TRUE);

-- CREATE WAREHOUSE
CREATE WAREHOUSE IF NOT EXISTS si_handson_wh
  WAREHOUSE_SIZE = 'X-SMALL'
  WAREHOUSE_TYPE = 'STANDARD'
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE
	INITIALLY_SUSPENDED = TRUE
  COMMENT = 'si_handson_wh'
;


--------- Create Table ---------
-- -- CMF_PRODUCTION_CAPACITY
-- create or replace TABLE CMF_PRODUCTION_CAPACITY (
-- 	CMF_FACILITY_ID VARCHAR(36) NOT NULL COMMENT 'cmf_facilityへの外部キー',
-- 	COMPONENT_ID VARCHAR(36) NOT NULL COMMENT 'componentへの外部キー',
-- 	PRODUCTION_CAPACITY_PER_DAY NUMBER(38,0) COMMENT 'コンポーネントの1日あたりの生産能力',
-- 	PRODUCTION_CAPACITY_PER_WEEK NUMBER(38,0) COMMENT 'コンポーネントの週あたりの生産能力',
-- 	PRODUCTION_CAPACITY_PER_MONTH NUMBER(38,0) COMMENT 'コンポーネントの月あたりの生産能力',
-- 	CAPACITY_UTILIZATION NUMBER(5,4) COMMENT '現在利用されている能力の割合（例：0.85は85％）'
-- )COMMENT='異なるコンポーネントに対するCMFの生産能力'
-- ;

-- COMPONENT
-- create or replace TABLE COMPONENT (
-- 	COMPONENT_ID VARCHAR(36) NOT NULL COMMENT 'コンポーネントの一意識別子（UUID）',
-- 	COMPONENT_NAME VARCHAR(255) NOT NULL COMMENT 'コンポーネントの名称',
-- 	COMPONENT_DESCRIPTION VARCHAR(1024) COMMENT 'コンポーネントの説明',
-- 	BILL_OF_MATERIALS_ID VARCHAR(36) COMMENT '部品表テーブルへの外部キー（該当する場合）',
-- 	BUSINESS_LINE VARCHAR(10) COMMENT 'ビジネスライン（AERO、IA、BA、ESS）',
-- 	primary key (COMPONENT_ID)
-- )COMMENT='個々のコンポーネントに関する情報'
-- ;

-- CUSTOMER
-- create or replace TABLE CUSTOMER (
-- 	CUSTOMER_ID VARCHAR(36) NOT NULL COMMENT '顧客の一意識別子（UUID）',
-- 	CUSTOMER_NAME VARCHAR(255) NOT NULL COMMENT '顧客名',
-- 	ADDRESS VARCHAR(255) COMMENT '顧客の住所',
-- 	CITY VARCHAR(100) COMMENT '顧客の所在都市',
-- 	STATE VARCHAR(50) COMMENT '顧客の所在州/県',
-- 	COUNTRY VARCHAR(50) COMMENT '顧客の所在国',
-- 	ZIP_CODE VARCHAR(20) COMMENT '顧客の郵便番号',
-- 	CONTACT_PERSON_ID VARCHAR(36) COMMENT '連絡先テーブルへの外部キー（該当する場合）',
-- 	INDUSTRY VARCHAR(100) COMMENT '顧客の業種',
-- 	BUSINESS_LINE VARCHAR(10) COMMENT 'ビジネスライン（AERO、IA、BA、ESS）',
-- 	primary key (CUSTOMER_ID)
-- )COMMENT='直接顧客に関する情報'
-- ;

-- DISTRIBUTOR
create or replace TABLE DISTRIBUTOR (
	DISTRIBUTOR_ID VARCHAR(36) NOT NULL COMMENT '販売代理店の一意識別子（UUID）',
	DISTRIBUTOR_NAME VARCHAR(255) NOT NULL COMMENT '販売代理店の名称',
	ADDRESS VARCHAR(255) COMMENT '販売代理店の住所',
	CITY VARCHAR(100) COMMENT '販売代理店の所在都市',
	STATE VARCHAR(50) COMMENT '販売代理店の所在州/県',
	COUNTRY VARCHAR(50) COMMENT '販売代理店の所在国',
	ZIP_CODE VARCHAR(20) COMMENT '販売代理店の郵便番号',
	CONTACT_PERSON_ID VARCHAR(36) COMMENT '連絡先テーブルへの外部キー（該当する場合）',
	REGION_SERVED VARCHAR(100) COMMENT '販売代理店がサービスを提供する地理的地域',
	BUSINESS_LINE VARCHAR(10) COMMENT 'ビジネスライン（AERO、IA、BA、ESS）',
	primary key (DISTRIBUTOR_ID)
)COMMENT='販売代理店に関する情報'
;

-- DISTRIBUTOR_INVENTORY
create or replace TABLE DISTRIBUTOR_INVENTORY (
	DISTRIBUTOR_ID VARCHAR(36) NOT NULL COMMENT 'distributorへの外部キー',
	PRODUCT_ID VARCHAR(36) NOT NULL COMMENT 'productへの外部キー',
	QUANTITY_ON_HAND NUMBER(38,0) COMMENT '販売代理店で現在手元にある製品の数量',
	REORDER_POINT NUMBER(38,0) COMMENT '販売代理店が再注文すべき在庫レベル',
	SAFETY_STOCK_LEVEL NUMBER(38,0) COMMENT '販売代理店で維持すべき最低在庫レベル',
	LAST_UPDATED_TIMESTAMP TIMESTAMP_NTZ(9) COMMENT '最後の在庫更新のタイムスタンプ'
)COMMENT='販売代理店の場所における完成品の在庫レベル'
;

-- FACT_FACILITY
-- create or replace TABLE FAT_FACILITY (
-- 	FAT_FACILITY_ID VARCHAR(36) NOT NULL COMMENT 'FAT施設の一意識別子（UUID）',
-- 	FACILITY_NAME VARCHAR(255) NOT NULL COMMENT 'FAT施設の名称',
-- 	ADDRESS VARCHAR(255) COMMENT '施設の住所',
-- 	CITY VARCHAR(100) COMMENT '施設の所在都市',
-- 	STATE VARCHAR(50) COMMENT '施設の所在州/県',
-- 	COUNTRY VARCHAR(50) COMMENT '施設の所在国',
-- 	ZIP_CODE VARCHAR(20) COMMENT '施設の郵便番号',
-- 	LATITUDE NUMBER(10,6) COMMENT '施設の緯度座標',
-- 	LONGITUDE NUMBER(11,6) COMMENT '施設の経度座標',
-- 	PLANT_MANAGER_CONTACT_ID VARCHAR(36) COMMENT '連絡先テーブルへの外部キー（該当する場合）',
-- 	SQUARE_FOOTAGE NUMBER(10,2) COMMENT '施設の総平方フィート',
-- 	NUMBER_OF_EMPLOYEES NUMBER(38,0) COMMENT '施設の従業員数',
-- 	IS_ACTIVE BOOLEAN COMMENT '施設が現在稼働中かどうかを示す',
-- 	BUSINESS_LINE VARCHAR(10) COMMENT 'ビジネスライン（AERO、IA、BA、ESS）',
-- 	primary key (FAT_FACILITY_ID)
-- )COMMENT='最終組立・検査（FAT）施設に関する情報'
-- ;

-- FAT_INVENTORY
-- create or replace TABLE FAT_INVENTORY (
-- 	FAT_FACILITY_ID VARCHAR(36) NOT NULL COMMENT 'fat_facilityへの外部キー',
-- 	COMPONENT_ID VARCHAR(36) COMMENT 'componentへの外部キー（該当する場合、product_idが入力されている場合はNULL）',
-- 	PRODUCT_ID VARCHAR(36) COMMENT 'productへの外部キー（該当する場合、component_idが入力されている場合はNULL）',
-- 	QUANTITY_ON_HAND NUMBER(38,0) COMMENT '現在手元にあるコンポーネント/製品の数量',
-- 	QUANTITY_ON_ORDER NUMBER(38,0) COMMENT '現在注文中のコンポーネント/製品の数量',
-- 	REORDER_POINT NUMBER(38,0) COMMENT '再注文すべき在庫レベル',
-- 	SAFETY_STOCK_LEVEL NUMBER(38,0) COMMENT '維持すべき最低在庫レベル',
-- 	LAST_UPDATED_TIMESTAMP TIMESTAMP_NTZ(9) COMMENT '最後の在庫更新のタイムスタンプ'
-- )COMMENT='FAT施設におけるコンポーネントと完成品の在庫レベル'
-- ;

-- FAT_PRODUCTION_SCHEDULE
create or replace TABLE FAT_PRODUCTION_SCHEDULE (
	FAT_FACILITY_ID VARCHAR(36) NOT NULL COMMENT 'fat_facilityへの外部キー',
	PRODUCT_ID VARCHAR(36) NOT NULL COMMENT 'productへの外部キー',
	SCHEDULED_START_DATE TIMESTAMP_NTZ(9) COMMENT '生産の計画開始日',
	SCHEDULED_COMPLETION_DATE TIMESTAMP_NTZ(9) COMMENT '生産の計画完了日',
	ACTUAL_START_DATE TIMESTAMP_NTZ(9) COMMENT '生産の実際の開始日',
	ACTUAL_COMPLETION_DATE TIMESTAMP_NTZ(9) COMMENT '生産の実際の完了日',
	QUANTITY_SCHEDULED NUMBER(38,0) COMMENT '生産予定の単位数',
	QUANTITY_COMPLETED NUMBER(38,0) COMMENT '実際に完了した単位数',
	STATUS VARCHAR(50) COMMENT '生産注文のステータス（例：計画済、進行中、完了、遅延）'
)COMMENT='FAT施設における完成品の生産スケジュール'
;

-- MFG_INVENTORY
create or replace TABLE MFG_INVENTORY (
	MFG_PLANT_ID VARCHAR(36) NOT NULL COMMENT 'MFG_PLANTへの外部キー',
	MATERIAL_ID VARCHAR(36) COMMENT '原材料テーブルへの外部キー（該当する場合）',
	COMPONENT_ID VARCHAR(36) COMMENT 'componentへの外部キー（該当する場合、material_idが入力されている場合はNULL）',
	QUANTITY_ON_HAND NUMBER(38,0) COMMENT '現在手元にある材料/コンポーネントの数量',
	QUANTITY_ON_ORDER NUMBER(38,0) COMMENT '現在注文中の材料/コンポーネントの数量',
	SAFETY_STOCK_LEVEL NUMBER(38,0) COMMENT '維持すべき最低在庫レベル',
	LAST_UPDATED_TIMESTAMP TIMESTAMP_NTZ(9) COMMENT '最後の在庫更新のタイムスタンプ',
	MATERIAL_LEAD_TIME NUMBER(38,0) COMMENT 'この原材料を調達するのに必要な日数',
	DAYS_FORWARD_COVERAGE NUMBER(38,0) COMMENT 'CMF施設での原材料の現在の手持ち在庫が、その材料の予想需要に基づいて、さらなる補充がない場合に生産を維持できる日数',
	LEAD_TIME_VARIABILITY NUMBER(38,0) COMMENT '材料のリードタイムの変動性（日数で測定）'
)COMMENT='CMFにおける原材料とコンポーネントの在庫レベル'
;

-- MFG_PLANT
create or replace TABLE MFG_PLANT (
	MFG_PLANT_ID VARCHAR(36) COMMENT '各製造工場の一意識別子',
	MFG_PLANT_NAME VARCHAR(255) COMMENT '製造工場の名称',
	ADDRESS VARCHAR(255) COMMENT '製造工場の住所',
	CITY VARCHAR(100) COMMENT '製造工場が所在する都市名',
	STATE VARCHAR(50) COMMENT '製造工場が所在する州の略称（米国の場合）',
	COUNTRY VARCHAR(50) COMMENT '製造工場が所在する国',
	ZIP_CODE VARCHAR(20) COMMENT '米国内の特定地域を表す5桁のコード',
	LATITUDE NUMBER(10,6) COMMENT '地理的な緯度座標',
	LONGITUDE NUMBER(11,6) COMMENT '製造工場の位置の経度',
	PLANT_MANAGER_CONTACT_ID VARCHAR(36) COMMENT '各製造工場を管理する担当者の一意識別子',
	SQUARE_FOOTAGE NUMBER(10,2) COMMENT '平方フィートで測定された製造工場の規模',
	NUMBER_OF_EMPLOYEES NUMBER(38,0) COMMENT '製造工場の従業員数',
	IS_ACTIVE BOOLEAN COMMENT '製造工場が現在稼働中かどうかを示す',
	BUSINESS_LINE VARCHAR(10) COMMENT '製造工場が属するビジネスライン'
)COMMENT='このテーブルには製造工場の記録が含まれており、各記録には工場名、所在地の詳細、工場管理者の連絡先情報、平方フィート数、従業員数、ビジネスラインが含まれています。'
;

-- ORDERS
create or replace TABLE ORDERS (
	ORDER_ID VARCHAR(36) NOT NULL COMMENT '注文の一意識別子（UUID）',
	CUSTOMER_ID VARCHAR(36) COMMENT '顧客への外部キー（該当する場合）',
	DISTRIBUTOR_ID VARCHAR(36) COMMENT '販売代理店への外部キー（該当する場合）',
	ORDER_DATE TIMESTAMP_NTZ(9) COMMENT '注文が行われた日時',
	PRODUCT_ID VARCHAR(36) NOT NULL COMMENT '製品への外部キー',
	QUANTITY NUMBER(38,0) NOT NULL COMMENT '注文された製品の数量',
	UNIT_PRICE NUMBER(10,2) NOT NULL COMMENT '注文時の単価',
	TOTAL_PRICE NUMBER(10,2) NOT NULL COMMENT '注文行の合計価格',
	ORDER_STATUS VARCHAR(50) COMMENT '注文のステータス（例：発注済、出荷済、配達済、キャンセル）',
	primary key (ORDER_ID)
)COMMENT='顧客と販売代理店の注文に関する情報'
;

-- PRODUCT
create or replace TABLE PRODUCT (
	PRODUCT_ID VARCHAR(36) NOT NULL COMMENT '製品の一意識別子（UUID）',
	PRODUCT_NAME VARCHAR(255) NOT NULL COMMENT '製品名',
	PRODUCT_DESCRIPTION VARCHAR(1024) COMMENT '製品の説明',
	PRODUCT_CATEGORY VARCHAR(100) COMMENT '製品カテゴリ',
	UNIT_PRICE NUMBER(10,2) COMMENT '製品の単価',
	BUSINESS_LINE VARCHAR(10) COMMENT 'ビジネスライン（AERO、IA、BA、ESS）',
	primary key (PRODUCT_ID)
)COMMENT='完成品に関する情報'
;

-- RAW_MATERIAL
create or replace TABLE RAW_MATERIAL (
	MATERIAL_ID VARCHAR(36) COMMENT '各原材料の一意識別子',
	MATERIAL_NAME VARCHAR(16777216) COMMENT 'サプライチェーンネットワークで使用される原材料の名称',
	MATERIAL_DESCRIPTION VARCHAR(16777216) COMMENT '原材料の詳細説明',
	MATERIAL_COST NUMBER(10,2) COMMENT 'サプライヤーからの原材料のコスト'
)COMMENT='このテーブルには様々な原材料の記録が含まれています。各記録には、一意の識別子と、材料の説明的な名称と説明が含まれています。'
;

-- SHIPMENT
create or replace TABLE SHIPMENT (
	SHIPMENT_ID VARCHAR(36) NOT NULL COMMENT '出荷の一意識別子（UUID）',
	ORIGIN_FACILITY_ID VARCHAR(36) COMMENT '出荷元施設（CMFまたはFAT）への外部キー',
	DESTINATION_FACILITY_ID VARCHAR(36) COMMENT '出荷先施設（FAT、販売代理店、または顧客）への外部キー',
	SHIP_DATE DATE COMMENT '出荷された日付',
	EXPECTED_DELIVERY_DATE DATE COMMENT '出荷の予定配達日',
	ACTUAL_DELIVERY_DATE DATE COMMENT '出荷の実際の配達日',
	SHIPPING_COST NUMBER(10,2) COMMENT '出荷コスト',
	TRACKING_NUMBER VARCHAR(50) COMMENT '出荷の追跡番号',
	primary key (SHIPMENT_ID)
)COMMENT='施設、販売代理店、顧客間の出荷に関する情報'
;

-- TRANSPORT_COST_SURCHARGE
-- create or replace TABLE TRANSPORT_COST_SURCHARGE (
-- 	SOURCE_FACILITY_ID VARCHAR(36) NOT NULL COMMENT '原材料を移送する過剰在庫を持つ発送元CMF施設の一意識別子',
-- 	DESTINATION_FACILITY_ID VARCHAR(36) NOT NULL COMMENT '原材料を受け取る低在庫の送信先CMF施設の一意識別子',
-- 	TRANSPORT_COST_SURCHARGE NUMBER(3,2) NOT NULL COMMENT '距離と輸送の難しさに応じたこれらの施設間の輸送コスト乗数'
-- )COMMENT='ある部品製造施設（CMF）から別の施設へ原材料を移動させる際の輸送コスト追加料金'
-- ;

// Step2: GITリポジトリからデータとスクリプトを取得 //
-- GIT連携のため、AIP統合を作成する
-- CREATE API INTEGRATION IF NOT EXISTS SI_GIT_INTEGRATION
CREATE OR REPLACE API INTEGRATION SI_GIT_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-skawakami/si_handson.git')
  ENABLED = TRUE;

-- GIT統合の作成
CREATE OR REPLACE GIT REPOSITORY SI_GIT_REPOSITORY
  API_INTEGRATION = SI_GIT_INTEGRATION
  ORIGIN = 'https://github.com/sfc-gh-skawakami/si_handson.git';

-- チェック
ls @SI_GIT_REPOSITORY/branches/main;

// Step 3: Load data to tables

-- GITHUBからデータをファイルを持ってくる
COPY FILES INTO @raw_data FROM @SI_GIT_REPOSITORY/branches/main/data;

-- テーブルへデータをロードする
-- COPY INTO CMF_PRODUCTION_CAPACITY from @raw_data files=('cmf_production_capacity.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');
-- COPY INTO COMPONENT from @raw_data files=('component.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;
-- COPY INTO CUSTOMER from @raw_data files=('customer.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;
COPY INTO DISTRIBUTOR from @raw_data files=('distributor.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;
COPY INTO DISTRIBUTOR_INVENTORY from @raw_data files=('distributor_inventory.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;;
-- COPY INTO FAT_FACILITY from @raw_data files=('fat_facility.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;;
-- COPY INTO FAT_INVENTORY from @raw_data files=('fat_inventory.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;;
-- COPY INTO FAT_PRODUCTION_SCHEDULE from @raw_data files=('fat_production_schedule.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;;
COPY INTO MFG_INVENTORY from @raw_data files=('mfg_inventory.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;;
COPY INTO MFG_PLANT from @raw_data files=('mfg_plant.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;;
COPY INTO ORDERS from @raw_data files=('orders.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;;
COPY INTO PRODUCT from @raw_data files=('product.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;;
COPY INTO RAW_MATERIAL from @raw_data files=('raw_material.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;;
COPY INTO SHIPMENT from @raw_data files=('shipment.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;;
-- COPY INTO TRANSPORT_COST_SURCHARGE from @raw_data files=('transport_cost_surcharge.csv') FILE_FORMAT = (FORMAT_NAME= 'csv_ff');;;


// Step 4: Enable Cross region inference (required to use claude-4-sonnet)
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';
