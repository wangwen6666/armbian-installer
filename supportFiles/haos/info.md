#### 适用范围：x86-64 物理机 / 虚拟机
#### 安装器中的 haos-installer-x86_64.iso 用于快速把「冬瓜HAOS」写入硬盘
#### 当前内置版本：冬瓜HAOS x86-64-pc 18.3.1（2026-10-18 构建）
#### 出处：https://fw.wghaos.com/haos/x86-64-pc/ （冬瓜HAOS 官方下载站）

**安装步骤**
1. 用 Ventoy / Rufus / BalenaEtcher 把 `haos-installer-x86_64.iso` 写入 U 盘（或直接挂到虚拟机的光驱）
2. UEFI 启动进入 live 环境，自动以 root 登录
3. 输入 `ddd`，选择目标硬盘，输入大写 `YES` 确认写入
4. 写盘完成后关机、拔 U 盘（虚拟机卸载光驱），从硬盘启动
5. 首次启动初始化：
   - 冬瓜HAOS 伴侣：浏览器打开 `http://homeassistant.local:8124/`
   - 或 ttyd 命令行：`http://homeassistant.local:7681/`，执行 `ha-install -t` 查看进度
   - 初始化完成后访问 `http://homeassistant.local:8123/`

**注意**
- 冬瓜HAOS 为控制镜像体积做了裁剪，导入后**一定要先扩容**（虚拟机在磁盘管理里扩，物理机可刷到更大硬盘）
- 默认 root 密码 `1234`（仅 live 环境，与写入的 HAOS 无关）

> 如需更换版本，运行工作流时把 `download_url` 换成冬瓜官方对应版本的 `.img.xz` 直链即可。
