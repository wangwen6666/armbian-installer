#!/bin/bash
# 构建 iStoreOS 安装器：从官方下载站拉取最新 iStoreOS x86_64 EFI 镜像，合成安装器 ISO
mkdir -p openwrt

# ===== 版本 / 下载配置 =====
# 官方下载站（无需 GitHub API，不会被限流；国内直连快，CI 也可访问）
# 版本更新时只需改 ISTOREOS_VERSION，文件名可在
# https://fw.koolcenter.com/iStoreOS/x86_64_efi/ 目录里查最新一条
ISTOREOS_VERSION="25.12.6-2026102312"
FILE_NAME="istoreos-${ISTOREOS_VERSION}-x86-64-squashfs-combined-efi.img.gz"
OUTPUT_PATH="openwrt/istoreos.img.gz"
DOWNLOAD_URL="https://fw.koolcenter.com/iStoreOS/x86_64_efi/${FILE_NAME}"

# 先探测可达性（GET range），避免把 404/拦截页当镜像下载
HTTP_CODE=$(curl -sL -r 0-0 -o /dev/null -w "%{http_code}" "$DOWNLOAD_URL" || true)
if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "206" ]]; then
  echo "错误：无法下载 iStoreOS 镜像 (HTTP $HTTP_CODE) -> $DOWNLOAD_URL"
  exit 1
fi

echo "下载地址: $DOWNLOAD_URL"
echo "下载文件: $FILE_NAME -> $OUTPUT_PATH"
if ! curl -L -o "$OUTPUT_PATH" "$DOWNLOAD_URL"; then
  echo "下载失败！"
  exit 1
fi

# 校验 gzip 魔数（1f 8b），防止下载到错误页面后再 gzip -d 才报错
if ! head -c 3 "$OUTPUT_PATH" | od -An -tx1 | grep -q "1f 8b"; then
  echo "错误：下载到的不是有效的 .img.gz（魔数校验失败），内容如下："
  file "$OUTPUT_PATH"
  exit 1
fi

echo "下载istoreos成功!"
echo "正在解压为:istoreos.img"
gzip -d openwrt/istoreos.img.gz
ls -lh openwrt/
echo "准备合成 istoreos 安装器"

mkdir -p output
docker run --privileged --rm \
        -v $(pwd)/output:/output \
        -v $(pwd)/supportFiles:/supportFiles:ro \
        -v $(pwd)/openwrt/istoreos.img:/mnt/istoreos.img \
        debian:buster \
        /supportFiles/istoreos/build.sh
