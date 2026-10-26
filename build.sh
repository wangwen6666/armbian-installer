#!/bin/bash
# 构建 Armbian 安装器：拉取官方 Armbian 26.8.3 (UEFI x86) 镜像，合成安装器 ISO
mkdir -p armbian

# ===== 版本 / 下载源配置 =====
# 官方最新稳定版：Armbian 26.8.3（2026-08，内核 6.18；Ubuntu 26.04=resolute / Debian 13=trixie）
# 说明：26.x 起发行版代号变了（noble->resolute、bookworm->trixie），且 UEFI x86 只提供
#       “minimal CLI” 与桌面版，故 standard / *_minimal 都映射到对应的 minimal CLI 原版镜像。
#
# 下载源 SOURCE（通过环境变量 ARMbian_SOURCE 切换，默认 official）：
#   official = 官方直链 dl.armbian.com（最“原汁原味”）。注意：官方 CDN 对云/数据中心 IP
#              有 bot 防护，GitHub Actions 的 runner 也是云 IP，有概率被 403 拦截。
#   github   = 本仓库 Release 中转（GitHub CDN 不会拦 CI，最稳）。需先把对应 .img.xz
#              上传到本仓库 tag "armbian-26.8.3" 的 Release，再设 ARMbian_SOURCE=github。
# 用法示例：在 build.yml 的 env 里加  ARMbian_SOURCE: github
SOURCE="${ARMbian_SOURCE:-official}"

# 读取环境变量（与 build.yml 的 version_type 选项保持一致；旧名称保留兼容）
VERSION_TYPE="${VERSION_TYPE:-ubuntu26_minimal}"
case "$VERSION_TYPE" in
  debian12_minimal|debian13_minimal)
    echo "构建 debian13(trixie)-minimal armbian..."
    FRIENDLY="Trixie_current_minimal"
    FILE_NAME="Armbian_26.8.3_Uefi-x86_trixie_current_6.18.45_minimal.img.xz"
    ;;
  ubuntu24_minimal|ubuntu26_minimal)
    echo "构建 ubuntu26(resolute)-minimal armbian..."
    FRIENDLY="Resolute_current_minimal"
    FILE_NAME="Armbian_26.8.3_Uefi-x86_resolute_current_6.18.45_minimal.img.xz"
    ;;
  *)
    echo "构建 standard(ubuntu26 resolute CLI) armbian..."
    FRIENDLY="Resolute_current_minimal"
    FILE_NAME="Armbian_26.8.3_Uefi-x86_resolute_current_6.18.45_minimal.img.xz"
    ;;
esac

OUTPUT_PATH="armbian/armbian.img.xz"

# 直接拼接下载地址，不再调用 api.github.com（避免未认证请求被限流 -> jq 报 null）
if [[ "$SOURCE" = "github" ]]; then
  DOWNLOAD_URL="https://github.com/wangwen6666/armbian-installer/releases/download/armbian-26.8.3/${FILE_NAME}"
else
  DOWNLOAD_URL="https://dl.armbian.com/uefi-x86/${FRIENDLY}"
fi

# 先探测可达性（GET range，避免把 403/404 的 HTML 页当镜像下载）
HTTP_CODE=$(curl -sL -r 0-0 -o /dev/null -w "%{http_code}" "$DOWNLOAD_URL" || true)
if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "206" ]]; then
  echo "错误：无法下载 Armbian 镜像 (HTTP $HTTP_CODE) -> $DOWNLOAD_URL"
  if [[ "$SOURCE" != "github" ]]; then
    echo "提示：官方直链可能被 CI 的云 IP 拦截。请在 build.yml 的 env 中设置 ARMbian_SOURCE: github，"
    echo "      并先把 $FILE_NAME 上传到本仓库 tag 'armbian-26.8.3' 的 Release 后再构建。"
  fi
  exit 1
fi

echo "下载地址: $DOWNLOAD_URL"
echo "下载文件: $FILE_NAME -> $OUTPUT_PATH"
if ! curl -L -o "$OUTPUT_PATH" "$DOWNLOAD_URL"; then
  echo "下载失败！"
  exit 1
fi

# 校验确实是 xz 镜像（魔数 fd 37 7a 58 5a），防止下到错误 HTML 页后 xz -d 才报错
if ! head -c 5 "$OUTPUT_PATH" | od -An -tx1 | grep -q "fd 37 7a 58 5a"; then
  echo "错误：下载到的不是有效的 .img.xz（魔数校验失败），可能命中了拦截页"
  file "$OUTPUT_PATH"
  exit 1
fi

echo "下载armbian成功!"
file armbian/armbian.img.xz
echo "正在解压为:armbian.img"
xz -d armbian/armbian.img.xz
ls -lh armbian/
echo "准备合成 armbian 安装器"

mkdir -p output
docker run --privileged --rm \
        -v $(pwd)/output:/output \
        -v $(pwd)/supportFiles:/supportFiles:ro \
        -v $(pwd)/armbian/armbian.img:/mnt/armbian.img \
        debian:bookworm \
        /supportFiles/build.sh
