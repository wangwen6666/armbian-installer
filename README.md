# armbian-installer

一个基于 **Debian Live** 系统的 img 镜像安装器，用 GitHub Actions 自动构建打包。
让你能在 x86-64 设备（物理机 / 虚拟机）上，像装普通系统一样快速安装 **Armbian、iStoreOS、ImmortalWrt、EzOpWrt、eSirOpenWrt、冬瓜HAOS** 这类原本只提供 img 固件的小众系统。

## 背景解读

- 嵌入式设备的系统通常采用 img 格式，一般出现在 ARM 设备中，安装方式通常是线刷、烧录 SD 卡等。
- 但近年来，openwrt 和 armbian 也逐渐兼容适配通用型 x86-64 设备，随着软路由和 NAS 虚拟机逐渐普及。
- 显然针对 ARM 设备的烧录方法不太适合 x86-64 设备（含虚拟机）。无论是借助 PE 还是借助 dd 都需要传递固件文件，显得低效和复杂。
- 如何让 openwrt / armbian / HAOS 等小众 x86-64 的 Linux 系统像安装普通系统一样简单呢？希望本项目给你一个满意的答案。

## 使用方式

1. **虚拟机使用**：各种虚拟机直接选择 ISO 即可
2. **物理机使用**：建议将 ISO 放入 Ventoy 的 U 盘中（https://www.ventoy.net/cn/download.html ）
3. 启动进入 live 环境后，在终端输入 **`ddd`** 命令调出安装菜单，选目标硬盘 → 输入大写 `YES` 确认写入
   ![localhost lan - VMware ESXi 2025-03-20 10-14-45](https://github.com/user-attachments/assets/ddae80a0-9ff5-4d63-83b5-1f49da18b008)
4. live 系统 SSH 默认用户名 `root`，密码 `1234`
5. 视频教学：[![YouTube](https://img.shields.io/badge/YouTube-123456?logo=youtube&labelColor=ff0000)](https://youtu.be/6FWyACrNQIg)
   [![Bilibili](https://img.shields.io/badge/Bilibili-123456?logo=bilibili&logoColor=fff&labelColor=fb7299)](https://www.bilibili.com/video/BV1DQXVYFENr)
   - 【第二集】https://youtu.be/RRBFc58SwXQ
   - https://www.bilibili.com/video/BV1gPXCYyEc2

## 支持的安装器

在 Actions 页面选择对应工作流 → Run workflow → 构建完成后 ISO 自动发布到同名 Release。

| 工作流 | 产出 ISO | 安装的系统 | 可调参数 |
|---|---|---|---|
| `Build Armbian Installer ISO` | `armbian-installer-x86_64-<版本>.iso` | Armbian 26.8.3（UEFI x86） | `version_type`、`armbian_source` |
| `Build iStoreOS Installer ISO` | `istoreos-installer-x86_64.iso` | iStoreOS 25.12.6 | — |
| `Build ImmortalWrt Installer ISO` | `immortalwrt-installer-x86_64.iso` | ImmortalWrt | — |
| `Build EzOpWrt Installer ISO` | `ezopwrt-installer-x86_64.iso` | EzOpWrt | — |
| `Build eSirOpenWrt Installer ISO` | `esiropenwrt-installer-x86_64.iso` | eSirOpenWrt | — |
| `Build 冬瓜HAOS Installer ISO` | `haos-installer-x86_64.iso` | 冬瓜HAOS（国内优化版 Home Assistant OS） | `download_url` |
| `Build Custom OpenWrt Installer ISO` | 自定义 | 任意 OpenWrt 系固件 | `download_url` |

### Armbian 参数说明

**`version_type`**（二选一，均为无桌面 CLI 版；Armbian 26.x 起取消 standard/minimal 之分）

| 选项 | 实际系统 |
|---|---|
| `ubuntu26_minimal`（默认） | Ubuntu 26.04 (resolute) minimal |
| `debian13_minimal` | Debian 13 (trixie) minimal |

> 旧名称 `standard` / `ubuntu24_minimal` / `debian12_minimal` 仍兼容，传进来也能正常构建。

**`armbian_source`**（下载来源）

| 选项 | 说明 |
|---|---|
| `official`（默认） | 官方直链 `dl.armbian.com`，最原汁原味。注意官方 CDN 对云/数据中心 IP 有 bot 防护，CI 有概率被 403 |
| `github` | 从本仓库 Release（tag `armbian-26.8.3`）中转拉取，GitHub CDN 不会拦 CI，**最稳，推荐** |

### 冬瓜HAOS 参数说明

`download_url` 默认是冬瓜HAOS 官方最新版直链，来自 https://fw.wghaos.com/haos/x86-64-pc/ 。
支持 `.img.gz` / `.img.xz` / `.img.zip`，替换成任意版本的直链即可（官方 HAOS 镜像同样适用）。

> ⚠️ 冬瓜HAOS 为控制镜像体积做了裁剪，写盘后**一定要先扩容**（虚拟机在磁盘管理里扩，物理机建议直接刷到比镜像更大的盘），否则数据分区用不满。

## 核心机制：压缩镜像进 ISO + 写盘时流式解压

这是本项目当前的关键设计，也是踩了坑之后定下来的方案。

**做法**：ISO 里**不再放解压后的 `.img`**，而是直接放原始压缩包（`.img.xz` / `.img.gz`）。
`ddd` 写盘时按后缀自动选择处理方式：

```bash
.xz  →  xz -dc   image.img.xz | dd of=/dev/sdX bs=4M conv=fsync status=progress
.gz  →  gzip -dc image.img.gz | dd of=/dev/sdX bs=4M conv=fsync status=progress
其他 →  dd if=image.img of=/dev/sdX bs=4M conv=fsync status=progress
```

**为什么这么做**：

1. **绕开 GitHub Release 单文件 2 GiB 上限**。Armbian 26.8.3 解压后约 2.4 GB，塞进 ISO 后发布直接报 `size must be less than 2147483648`，构建再成功也发不出去。
2. **成品体积更小、下载更快**。Armbian 安装器从约 2.7 GB 降到约 1.3 GB。
3. **写盘不占双倍空间**。不需要先把镜像解压到硬盘上再 dd，低配瘦客户机也不会因为空间不够失败。
4. **构建更快**。省掉了把几百 MB 甚至 2 GB 数据再走一遍 `mksquashfs` 压缩的时间。

## 当前版本

| 组件 | 版本 |
|---|---|
| Armbian | **26.8.3**（2026-08，内核 6.18，Ubuntu 26.04 resolute / Debian 13 trixie） |
| iStoreOS | **25.12.6-2026102312**（x86_64 EFI） |
| 冬瓜HAOS | **18.3.1**（x86-64-pc，2026-10-18 构建） |
| 构建基础环境 | Debian **bookworm** (Debian 12) |

## 更新日志

### 2026-10-26

**修 Bug：GitHub API 限流导致构建失败**

- 现象：CI 日志报 `jq: error: Cannot iterate over null` + `未找到文件 xxx.img.xz`，构建直接退出。
- 根因：脚本用 `api.github.com` + `jq` 解析 release 资产取下载地址，未认证请求限流（每 IP 每小时 60 次）后返回的 JSON 里没有 `assets` 字段，`jq` 迭代 null 报错。
- 修复：Armbian / iStoreOS 两条线**彻底不再调用 `api.github.com`**，改为可预测的直链地址。

**修 Bug：Debian buster EOL 导致 ISO 实际未生成（"假成功"）**

- 现象：`Build Image` 步骤显示成功（1m24s），下一步 `mv: cannot stat 'output/...standard.iso'` 才发现 ISO 根本不存在。
- 根因：合成用的 Docker 镜像与 `debootstrap` 基础系统都是 **Debian 10 buster**（2024 年 EOL，软件源已撤档），debootstrap 必然失败；而脚本没有 `set -e`，中间错误被吞掉，最后一句 `ls` 成功就让步骤返回 0。
- 修复：全部 6 条构建线统一升级到 **bookworm**，`sources.list` 同步更新为 `bookworm` / `bookworm-security`，所有 `supportFiles/*/build.sh` 补 `set -e`，失败立即中断不再静默跳过。

**修 Bug：ISO 超过 2 GiB 无法发布**

- 见上文「核心机制」一节，改为压缩镜像进 ISO + 流式解压写盘，三条线（Armbian / 冬瓜HAOS / iStoreOS）已统一。

**版本升级**

- Armbian：`25.2.1` → **`26.8.3`**（跨越一年多，内核 6.12 → 6.18，基础发行版 noble→resolute、bookworm→trixie）
- iStoreOS：`22.03.7-2024122712` → **`25.12.6-2026102312`**（版本号收敛到 `istoreos.sh` 顶部 `ISTOREOS_VERSION` 一个变量，以后升级只改一处）
- Armbian 的 `version_type` 精简为 `ubuntu26_minimal` / `debian13_minimal` 两项（原来的 `standard` 与 `ubuntu24_minimal` 实际指向同一镜像）

**新增：冬瓜HAOS 安装器**

- 新增 `haos.sh` + `supportFiles/haos/`（合成脚本、`ddd`、grub/isolinux 启动配置）与工作流 `build-haos.yml`
- 使用**冬瓜HAOS**（国内优化版 Home Assistant OS）替换官方 HAOS，沿用 `ddd` 写盘安装，开机菜单与标题已改为「冬瓜HAOS」
- 默认内置冬瓜HAOS 18.3.1，可通过 `download_url` 参数替换任意版本

**其他改进**

- Armbian 下载增加 `.xz` 魔数校验、iStoreOS 增加 `.gz` 魔数校验，防止把 403 拦截页当镜像下载后在解压阶段莫名失败
- 新增 `.gitattributes` 强制脚本使用 LF 换行，避免 Windows 检出 CRLF 导致 CI 里 `./xxx.sh` 报「坏解释器」
- live 环境显式安装 `xz-utils`、`gzip`，并把 `gdisk` 补进依赖（脚本用到 `sgdisk`）
- Armbian 增加 `armbian_source` 开关，可在网页上直接切换 official / github 来源

> **已知待办**：`esir.sh`、`ezopwrt.sh`、`imm.sh` 三条线仍在用 `api.github.com` + `jq` 的写法，有同样的限流风险，尚未改造。

## ISO 自动制作流程

本项目基于开源项目 [debian-live](https://github.com/dpowers86/debian-live) 制作，代码全程开源，MIT 协议不变。

1. 构建一个 Debian live 系统，该系统带 EFI 引导。
2. 在该系统内融入我们需要的 img 镜像（保持压缩态）和自己制作的 `ddd` 写盘脚本，一起打包到 `filesystem.squashfs` 中。该过程包含了压缩，从而保证最终体积较小。
3. 最后将新的 squashfs 文件和相关文件一起打包为 ISO。

## 项目参考

- https://willhaley.com/blog/custom-debian-live-environment/
- https://github.com/dpowers86/debian-live
- https://github.com/sirpdboy/openwrt/releases
- https://github.com/esirplayground
- https://fw.wghaos.com/haos/x86-64-pc/ （冬瓜HAOS 官方下载站）
- https://fw.koolcenter.com/iStoreOS/ （iStoreOS 官方下载站）

### DONATE & 支持 ⬆️

[助力按钮](https://wkdaily.cpolar.top/01)
