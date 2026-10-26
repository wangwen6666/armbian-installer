#!/bin/bash
# 构建「冬瓜HAOS」安装器：传入 HAOS 镜像直链（.img.gz / .img.xz / .img.zip），合成带 ddd 写盘菜单的 ISO
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "错误：未提供下载地址！"
  echo "用法: ./haos.sh <镜像直链>"
  exit 1
fi

DOWNLOAD_URL="$1"
filename=$(basename "$DOWNLOAD_URL")
OUTPUT_PATH="imm/$filename"
mkdir -p imm

echo "下载地址: $DOWNLOAD_URL"
echo "保存路径: $OUTPUT_PATH"

if ! curl -k -L -o "$OUTPUT_PATH" "$DOWNLOAD_URL"; then
  echo "下载失败！"
  exit 1
fi

echo "下载成功!"
file "$OUTPUT_PATH"

# 校验压缩包魔数，防止把错误页面当成镜像
magic=$(head -c 3 "$OUTPUT_PATH" | od -An -tx1 | tr -d ' \n')
case "$magic" in
  fd377a) echo "校验通过: xz" ;;   # xz
  1f8b*)  echo "校验通过: gzip" ;; # gzip
  504b03) echo "校验通过: zip" ;;  # zip
  *)
    echo "错误：下载到的文件不是有效的压缩镜像（魔数 $magic），可能命中了错误页面"
    exit 1
    ;;
esac

# 根据扩展名解压
extension="${filename##*.}"
case $extension in
  gz)
    echo "gz 正在解压 $OUTPUT_PATH"
    gunzip -f "$OUTPUT_PATH"
    final_name=$(find imm -name '*.img' -print -quit)
    mv "$final_name" "imm/haos.img"
    ;;
  zip)
    echo "zip 正在解压 $OUTPUT_PATH"
    unzip -j -o "$OUTPUT_PATH" -d imm/
    final_name=$(find imm -name '*.img' -print -quit)
    mv "$final_name" "imm/haos.img"
    ;;
  xz)
    echo "xz 正在解压 $OUTPUT_PATH"
    xz -d --keep "$OUTPUT_PATH"
    final_name="${OUTPUT_PATH%.*}"
    mv "$final_name" "imm/haos.img"
    ;;
  *)
    echo "不支持的压缩格式: $extension（仅支持 .gz/.xz/.zip）"
    exit 1
    ;;
esac

if [ ! -f "imm/haos.img" ]; then
  echo "错误：最终文件 imm/haos.img 不存在"
  exit 1
fi

echo "解压成功"
ls -lh imm/
echo "准备合成 冬瓜HAOS 安装器"

mkdir -p output
docker run --privileged --rm \
        -v "$(pwd)/output:/output" \
        -v "$(pwd)/supportFiles:/supportFiles:ro" \
        -v "$(pwd)/imm/haos.img:/mnt/haos.img" \
        debian:bookworm \
        /supportFiles/haos/build.sh
