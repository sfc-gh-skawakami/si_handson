# Snowflake Semantic Intelligence ハンズオン - サプライチェーン管理

このプロジェクトは、Snowflake Cortex の Semantic Intelligence 機能を学ぶためのハンズオンワークショップです。サプライチェーン管理のデータを用いて、自然言語の質問をSQLクエリに変換する方法を実践します。

## 📋 プロジェクト概要

Snowflake の Cortex Semantic Intelligence を使用して、サプライチェーン管理データに対する自然言語クエリを実現します。セマンティックモデルを定義することで、ビジネスユーザーが専門的なSQLの知識なしにデータを分析できるようになります。

### 主な機能

- 🤖 **自然言語クエリ**: 日本語の質問をSQLに自動変換
- 📊 **サプライチェーンデータモデル**: 製造、在庫、配送を含む包括的なデータモデル
- 🔗 **セマンティックモデル**: テーブル間の関係を定義し、クエリの精度を向上
- ✅ **検証済みクエリ**: よく使われる質問の例を提供

## 🏗️ データモデル

このプロジェクトは以下の要素を含むサプライチェーンネットワークをモデル化しています：

- **製造工場 (MFG_PLANT)**: 生産施設の情報と位置データ
- **原材料 (RAW_MATERIAL)**: 製造に使用される原材料
- **製品 (PRODUCT)**: 完成品（ビジネスライン: AERO、IA、BA、ESS）
- **製造在庫 (MFG_INVENTORY)**: 工場における原材料とコンポーネントの在庫レベル
- **販売代理店 (DISTRIBUTOR)**: 製品を配送する販売代理店
- **販売代理店在庫 (DISTRIBUTOR_INVENTORY)**: 販売代理店における製品の在庫レベル
- **注文 (ORDERS)**: 顧客と販売代理店からの注文
- **出荷 (SHIPMENT)**: 施設間、販売代理店、顧客への出荷情報

## 📁 リポジトリ構成

```
si_handson/
├── data/                           # サンプルデータ（CSV形式）
│   ├── distributor.csv            # 販売代理店データ
│   ├── distributor_inventory.csv  # 販売代理店在庫データ
│   ├── mfg_plant.csv              # 製造工場データ
│   ├── mfg_inventory.csv          # 製造在庫データ
│   ├── raw_material.csv           # 原材料データ
│   ├── product.csv                # 製品データ
│   ├── orders.csv                 # 注文データ
│   └── shipment.csv               # 出荷データ
├── semantic_models/                # Cortexセマンティックモデル定義
│   ├── scm.yaml                   # メインセマンティックモデル
│   └── supply_chain_network.yaml  # サプライチェーンネットワークモデル
├── sql/
│   ├── setup.sql                  # データベース・テーブルセットアップスクリプト
│   └── seup_personal.sql          # 個人用セットアップスクリプト
├── quick_start.md                  # クイックスタートガイドと例題クエリ
└── work.sql                        # 作業用SQLファイル
```

## 🚀 セットアップ手順

### 1. 前提条件

- Snowflakeアカウント
- `ACCOUNTADMIN` ロールへのアクセス権限
- Cortex機能が有効化されていること

### 2. データベース・テーブルの作成

`sql/setup.sql` を使用してセットアップを実行します：

```sql
-- Step 0: ロールの作成と権限付与
USE ROLE accountadmin;
CREATE ROLE scm_intelligence_role;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE scm_intelligence_role;

-- Step 1: データベースとスキーマの作成
USE ROLE sysadmin;
CREATE DATABASE IF NOT EXISTS snowflake_si_handson;
CREATE SCHEMA IF NOT EXISTS raw_scm;

-- Step 2: GitリポジトリからデータとスクリプトをロードGIT_REPOSITORY]
CREATE API INTEGRATION SI_GIT_INTEGRATION ...
CREATE GIT REPOSITORY SI_GIT_REPOSITORY ...

-- Step 3: データのロード
COPY INTO DISTRIBUTOR from @raw_data ...
```

詳細な手順は [sql/setup.sql](sql/setup.sql) を参照してください。

### 3. セマンティックモデルの配置

`semantic_models/scm.yaml` をSnowflakeにアップロードし、Cortex Analystで使用します。

## 💡 使用例

### 自然言語クエリの例

セマンティックモデルを使用すると、以下のような日本語の質問に答えることができます：

#### 1. ビジネスライン別の注文数
**質問**: 「AEROビジネスラインには何件の注文がありますか？」

```sql
SELECT COUNT(*) AS aero_order_count 
FROM snowflake_si_handson.raw_scm.orders AS o 
JOIN snowflake_si_handson.raw_scm.product AS p ON o.product_id = p.product_id 
WHERE p.business_line = 'AERO'
```

#### 2. 在庫不足の原材料
**質問**: 「弊社の製造工場で在庫が不足している原材料はどれですか？」

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

#### 3. 地理的クエリ（位置情報）
**質問**: 「ノースカロライナ州シャーロット近郊の施設からの出荷品を表示してください」

```sql
SELECT *
FROM snowflake_si_handson.raw_scm.shipment AS s
JOIN snowflake_si_handson.raw_scm.MFG_PLANT AS cmf ON s.origin_facility_id = cmf.MFG_PLANT_ID
WHERE ST_DWITHIN(
  ST_MAKEPOINT(cmf.longitude, cmf.latitude),
  ST_MAKEPOINT(-80.8431, 35.2271),
  50 * 1609.34
)
```

#### 4. 販売代理店の在庫分析
**質問**: 「各販売代理店におけるビル管理システムの平均在庫レベルはどれくらいですか？」

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

詳細な例は [quick_start.md](quick_start.md) を参照してください。

## 🔑 主要ファイル

- **[sql/setup.sql](sql/setup.sql)**: データベース、テーブル、ロールのセットアップスクリプト
- **[semantic_models/scm.yaml](semantic_models/scm.yaml)**: メインのセマンティックモデル定義（テーブル、リレーションシップ、検証済みクエリ）
- **[quick_start.md](quick_start.md)**: クイックスタートガイドと実践的なSQLクエリ例
- **[data/](data/)**: サプライチェーンデータのサンプルCSVファイル

## 📚 学習リソース

このハンズオンを通じて以下を学べます：

1. **Cortex Semantic Intelligence**: 自然言語からSQLへの変換
2. **セマンティックモデルの設計**: テーブル、ディメンション、メジャー、リレーションシップの定義
3. **検証済みクエリ**: よく使われる質問パターンの登録と再利用
4. **地理空間クエリ**: Snowflakeの位置情報関数（ST_MAKEPOINT、ST_DWITHIN）の活用
5. **サプライチェーン分析**: 在庫管理、注文追跡、出荷分析

## 🎯 対象者

- Snowflake Cortex機能を学びたい方
- 自然言語によるデータ分析に興味がある方
- サプライチェーン管理のデータモデリングを学びたい方
- セマンティックレイヤーの実装を体験したい方

## 📝 ライセンス

このプロジェクトはハンズオンワークショップ用の教育目的で作成されています。