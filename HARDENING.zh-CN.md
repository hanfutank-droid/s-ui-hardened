# s-ui v1.5.5 加固说明

本仓库基于官方 [`alireza0/s-ui`](https://github.com/alireza0/s-ui) 的 `v1.5.5` 标签和提交：

```text
1ca4fc80f900ec4a56426c9dae663657b3bd8f81
```

前端子模块固定为：

```text
1ffd0f0485b8853b47be4fb0f4a4e526a5d63cc2
```

## 加固内容

- 面板默认只监听 `127.0.0.1:2095`。
- 订阅服务默认只监听 `127.0.0.1:2096`。
- 会话 Cookie 使用 `HttpOnly` 和 `SameSite=Lax`。
- 通过 TLS 或可信反向代理 HTTPS 访问时，Cookie 自动使用 `Secure`。
- 全新安装会在服务启动前替换上游默认的 `admin/admin`。
- 安装程序不下载或执行远程脚本。
- 已有数据库在升级前备份到 `/var/backups/s-ui/时间戳/`。
- 不安装上游 `s-ui.sh` 动态管理脚本；更新必须通过固定源码重新构建。

## 自动构建

`.github/workflows/hardened-release.yml` 从当前提交和锁定依赖构建 Linux amd64 静态包。

工作流会：

1. 检出固定的前端子模块。
2. 使用 `npm ci` 构建前端。
3. 运行 `go vet` 和 Go 包编译测试。
4. 使用 musl 和 CGO 构建静态 Linux amd64 ELF。
5. 检查目标架构和静态链接。
6. 生成压缩包和 `SHA256SUMS`。
7. 推送 `v*-hardened.*` 标签时创建 GitHub Release。

可选的 Naive 出站模块没有启用，因为它需要额外的 Chromium/Cronet 工具链。常规 sing-box、QUIC、gRPC、uTLS、ACME、gVisor 和 Tailscale 功能保留。

## 安装

下载 Release 中的压缩包和 `SHA256SUMS`，验证后运行：

```bash
sha256sum -c SHA256SUMS
tar -xzf s-ui-v1.5.5-hardened-linux-amd64.tar.gz
cd s-ui-v1.5.5-hardened-linux-amd64
sudo ./install.sh
```

面板默认不开放公网。通过 SSH 隧道访问：

```bash
ssh -L 2095:127.0.0.1:2095 root@YOUR_SERVER
```

然后打开 `http://127.0.0.1:2095/app/`。

## 上游与许可证

本项目是上游 GPL-3.0 项目的修改版本。原始版权、许可证和提交历史均予以保留；本仓库不代表上游作者对这些修改提供认可或支持。
