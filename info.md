[![Github](https://img.shields.io/badge/Release文件可在国内加速站下载-FC7C0D?logo=github&logoColor=fff&labelColor=000&style=for-the-badge)](https://wkdaily.cpolar.top/archives/1) 

#### 适用范围:所有虚拟机和物理机
#### 此安装器本身的Debian Live系统SSH用户名:root 密码:1234
#### 安装器中的Armbian系统
#### web地址:插好网线 详见屏幕信息
#### ssh默认用户名 `root` 密码：1234
#### 当前内置版本:Armbian 26.8.3（内核 6.18，Ubuntu 26.04 resolute / Debian 13 trixie）
#### Armbian镜像出处:https://www.armbian.com/boards/uefi-x86 （官方 dl.armbian.com）

**安装步骤**
1. 用 Ventoy / Rufus / BalenaEtcher 把 ISO 写入 U 盘（或直接挂到虚拟机光驱）
2. UEFI 启动进入 live 环境，自动以 root 登录（密码 1234）
3. 输入 `ddd`，选择目标硬盘，输入大写 `YES` 确认写入
4. 写盘完成后关机、拔 U 盘（虚拟机卸载光驱），从硬盘启动

**说明**
- ISO 内为 `armbian.img.xz` 压缩态镜像，写盘时由 `ddd` 流式解压写入（`xz -dc | dd`），不占额外磁盘空间
- 写入后的 Armbian 默认 SSH 用户名 `root` 密码 `1234`，首次登录会强制修改密码并创建普通用户
