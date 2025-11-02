# NOAA GFS気圧データ 等圧線ベクタータイル＆terrainRGBタイル変換ツール

NOAA Global Forecast System（GFS）の気圧データを取得し、各種タイル形式に変換するためのスクリプトです。

## 機能

1. **データ取得** (`01_fetch_prmsl.sh`): GFSから海面気圧データ（PRMSL）をダウンロード・抽出
2. **GeoTiff変換** (`02_create_geotiff.sh`): GRIB2ファイルをGeoTiffに変換
3. **等圧線作成** (`03_create_isobar.sh`): 等圧線ベクタータイルを作成(4hPa毎)
4. **TerrainRGB作成** (`03_create_prmsl_terrainRGB.sh`): 気圧データをTerrainRGB形式のラスタータイルに変換

## 使用方法

### 個別スクリプト実行

各スクリプトは個別に実行でき、時間範囲を指定可能です：

```bash
# ヘルプ表示
./01_fetch_prmsl.sh --help

# 基本的な使用方法
./01_fetch_prmsl.sh [DATE] [START_HOUR] [END_HOUR]
```

#### 例

```bash
# 今日のデータを0-23時間先まで取得
./01_fetch_prmsl.sh

# 2025年11月1日のデータを0-23時間先まで取得
./01_fetch_prmsl.sh 20251101

# 2025年11月1日のデータを6-18時間先まで取得
./01_fetch_prmsl.sh 20251101 6 18

# 2025年11月1日のデータを0-12時間先まで取得
./01_fetch_prmsl.sh 20251101 0 12
```

### パイプライン実行

`run_pipeline.sh`を使用して全ステップまたは特定のステップを一括実行できます：

```bash
# 全ステップ実行（今日のデータ、0-23時間先）
./run_pipeline.sh

# 特定の日付と時間範囲で全ステップ実行
./run_pipeline.sh 20251101 0 12

# 特定のステップのみ実行
./run_pipeline.sh 20251101 0 12 fetch    # データ取得のみ
./run_pipeline.sh 20251101 0 12 geotiff  # GeoTiff作成のみ
./run_pipeline.sh 20251101 0 12 isobar   # 等圧線作成のみ
./run_pipeline.sh 20251101 0 12 terrainrgb # TerrainRGB作成のみ
```

## 引数の詳細

- **DATE**: 日付（YYYYMMDD形式）
  - 省略時は今日の日付
  - 例: `20251101`

- **START_HOUR**: 開始時間（0-384）
  - GFSの予報時間（時間先）
  - 省略時は0

- **END_HOUR**: 終了時間（0-384）
  - GFSの予報時間（時間先）
  - 省略時は23（データ取得）、999（その他スクリプト）

- **STEPS**: 実行ステップ（パイプラインスクリプトのみ）
  - `all`: 全ステップ実行（デフォルト）
  - `fetch`: データ取得のみ
  - `geotiff`: GeoTiff作成のみ
  - `isobar`: 等圧線作成のみ
  - `terrainrgb`: TerrainRGB作成のみ

## 出力ファイル

### ディレクトリ構造

```
grib2/           # GRIB2ファイル（元データ）
tif/             # GeoTiffファイル（hPa単位に変換済み）
tif_3857/        # Web Mercator投影済みTiffファイル
tif_3857_terrainrgb/ # TerrainRGB形式Tiffファイル
isobar/          # 等圧線geojson及びベクタータイル(4hPa毎)
terrainrgb/      # TerrainRGBラスタータイル
```

### ファイル名規則

- GRIB2: `prmsl_YYYYMMDD_HHH.grib2`
- GeoTiff: `prmsl_hpa_YYYYMMDD_HHH.tif`
- 等圧線: `prmsl_isobar_YYYYMMDD_HHH.pmtiles`
- TerrainRGB: `prmsl_hpa_YYYYMMDD_HHH_3857_terrainrgb.pmtiles`

## 必要なツール
`aws CLI`及び`Docker`に加えて以下のツールを別途インストールしてください：

```bash
# Tippecanoe（ベクタータイル生成）
# https://github.com/felt/tippecanoe のインストール手順に従ってください

# PMTiles（タイル形式変換）
# https://github.com/protomaps/go-pmtiles のインストール手順に従ってください

# mbutil（MBTiles操作）
# https://github.com/mapbox/mbutil のインストール手順に従ってください
```

## 等圧線ベクタータイル仕様
- レイヤ名
  - isobar
- 属性
  - prmsl
    - 海面換算大気圧（hPa）。4hPa毎に格納。

## 注意事項

- GFSデータは通常384時間先（16日先）まで利用可能です。
- AWS S3からのダウンロードにはインターネット接続が必要です。
- データの利用に当たっては、NOAAの利用規約に従ってください。
  - [NOAA GFS Data](https://registry.opendata.aws/noaa-gfs-bdp-pds/)
