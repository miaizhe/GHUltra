# GHUltra

<div align="center">
  <p>一个现代化、多平台的 GitHub 客户端，专为 Windows 和 Android 平台打造。</p>
</div>

## ✨ 主要特性 (Features)

GHUltra 提供了丰富的功能来帮助你随时随地管理和浏览 GitHub：

- **🔑 授权登录**：基于 OAuth 的安全登录机制。
- **📱 仓库管理与浏览**：
  - 概览仓库信息
  - 浏览代码树并查看具体文件内容 (支持 Markdown 渲染)
  - 探索 GitHub Actions，查看工作流运行情况及详细日志 (Job Logs)
  - 查看项目的 Releases 
  - 查看仓库设置
- **🔍 强大搜索**：全局或局部搜索 GitHub 仓库。
- **🔔 消息通知**：实时接收和查看 GitHub 站内通知。
- **👤 账户中心**：管理你的个人信息和偏好设置。
- **✨ 流畅体验**：使用 `flutter_animate` 提供丝滑的界面动画，针对桌面端（Windows）进行了原生窗口管理优化。

## 🛠️ 技术栈 (Tech Stack)

- **框架**: [Flutter](https://flutter.dev/) (SDK >=3.0.0 <4.0.0)
- **核心依赖**:
  - `http` - 网络请求，与 GitHub API 交互
  - `shared_preferences` - 本地缓存与偏好设置
  - `flutter_animate` - 精美的 UI 动画效果
  - `webview_windows` & `webview_flutter` - 应用内网页视图
  - `window_manager` - 桌面端窗口管理
  - `flutter_markdown` - Markdown 文本渲染

## 📂 项目结构 (Project Structure)

```text
lib/
 ├── main.dart                 # 应用入口
 ├── screens/                  # 所有的页面 UI 组件
 │    ├── login_screen.dart    # 登录页
 │    ├── home_screen.dart     # 主页
 │    ├── repo_detail_screen.dart # 仓库详情页
 │    ├── workflow_run_detail_screen.dart # Actions 详情页
 │    └── ...
 ├── services/                 # 核心服务 (API/Auth)
 │    ├── github_service.dart  # GitHub API 封装
 │    └── oauth_service.dart   # OAuth 授权逻辑
 └── widgets/                  # 可复用的通用组件
      └── repo_card.dart       # 仓库卡片组件
```

## 🚀 快速开始 (Getting Started)

### 环境要求

- 安装 [Flutter SDK](https://docs.flutter.dev/get-started/install)
- 配置好 Android 或 Windows 的开发环境（取决于目标运行平台）

### 运行步骤

1. 克隆本项目到本地：
   ```bash
   git clone <repository_url>
   cd GHUltra
   ```

2. 获取依赖包：
   ```bash
   flutter pub get
   ```

3. 运行应用：
   ```bash
   # 运行 Windows 版本
   flutter run -d windows
   
   # 运行 Android 版本
   flutter run -d android
   ```

## 📄 许可证 (License)

本项目采用 [GNU General Public License v3.0 (GPL-3.0)](LICENSE) 许可证。
