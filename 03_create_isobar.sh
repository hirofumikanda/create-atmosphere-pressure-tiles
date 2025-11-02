#!/bin/bash

# 引数の説明を表示する関数
show_usage() {
    echo "Usage: $0 [DATE] [START_HOUR] [END_HOUR]"
    echo "  DATE: 日付（YYYYMMDD形式、指定しない場合は全ファイル処理）"
    echo "  START_HOUR: 開始時間（0-384、DATEを指定した場合のみ有効）"
    echo "  END_HOUR: 終了時間（0-384、DATEを指定した場合のみ有効）"
    echo "  例: $0  # 全ファイル処理"
    echo "  例: $0 20251101  # 2025年11月1日の全時間"
    echo "  例: $0 20251101 0 12  # 2025年11月1日の0時間先から12時間先まで"
}

# ヘルプオプションの処理
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# 引数の設定
DATE=$1
START_HOUR=${2:-0}
END_HOUR=${3:-999}

if [[ -n "$DATE" ]]; then
    if [[ -n "$2" && -n "$3" ]]; then
        # 引数の検証
        if ! [[ "$START_HOUR" =~ ^[0-9]+$ ]] || ! [[ "$END_HOUR" =~ ^[0-9]+$ ]]; then
            echo "エラー: START_HOURとEND_HOURは数値で指定してください"
            show_usage
            exit 1
        fi

        if [[ $START_HOUR -gt $END_HOUR ]]; then
            echo "エラー: START_HOUR ($START_HOUR) はEND_HOUR ($END_HOUR) より小さくする必要があります"
            show_usage
            exit 1
        fi

        echo "Creating isobar data from $DATE (hours: $START_HOUR to $END_HOUR)"
    else
        echo "Creating isobar data from $DATE (all hours)"
    fi
else
    echo "Creating isobar data from all TIF files in tif/ directory"
fi

# isobarディレクトリを作成（存在しない場合）
mkdir -p isobar

# ファイルリストを作成
if [[ -n "$DATE" ]]; then
    if [[ -n "$2" && -n "$3" ]]; then
        # 特定の日付と時間範囲
        file_list=()
        for ((i=START_HOUR; i<=END_HOUR; i++)); do
            hour=$(printf "%03d" $i)
            file_pattern="tif/prmsl_hpa_${DATE}_${hour}.tif"
            if [[ -f "$file_pattern" ]]; then
                file_list+=("$file_pattern")
            fi
        done
    else
        # 特定の日付のすべてのファイル
        file_list=(tif/prmsl_hpa_${DATE}_*.tif)
    fi
else
    # すべてのTIFファイル
    file_list=(tif/*.tif)
fi

# ファイルを処理
for tif_file in "${file_list[@]}"; do
  if [[ -f "$tif_file" ]]; then
    # ファイル名から拡張子を除去してベース名を取得
    base_name=$(basename "$tif_file" .tif)
    echo "Processing $tif_file..."

    # 4hPa間隔で等圧線作成
    docker run --rm -v "$PWD":/work -w /work ghcr.io/osgeo/gdal:alpine-normal-latest \
      gdal_contour -a prmsl -i 4 \
        -f "GeoJSONSeq" \
        "$tif_file" \
        "isobar/isobar_4hpa_4326_${base_name#prmsl_hpa_}.ndjson"

    # ベクタータイル作成
    tippecanoe -f -P -o "isobar/prmsl_isobar_${base_name#prmsl_hpa_}.pmtiles" \
      "isobar/isobar_4hpa_4326_${base_name#prmsl_hpa_}.ndjson" \
      -l isobar \
      -Z0 -z4 \
      -pf -pk \
      --coalesce \
      --simplification=5 --simplify-only-low-zooms

    echo "Created isobar/prmsl_isobar_${base_name#prmsl_hpa_}.pmtiles"
  fi
done

echo "All isobar tiles created successfully!"