# GHUltra

<div align="center">
  <p>一个现代化、多平台的 GitHub 客户端，专为 macOS、Windows 和 Android 平台打造。</p>
</div>

## ✨ 主要特性 (Features)

GHUltra 提供了丰富的功能来帮助你随时随地管理和浏览 GitHub：

- **🔑 授权登录**：基于 OAuth 的安全登录机制，兼容双栈网络，并在桌面端支持外部浏览器调起以兼容 Passkey 认证。
- **📱 仓库管理与浏览**：
  - **仓库概览**：查看仓库基本信息，支持一键复制 HTTPS/SSH 克隆链接。
  - **创建与交互**：支持在应用内直接创建新仓库，以及对他人仓库进行 Fork 和 Star 操作。
  - **代码与文件**：浏览代码树，查看并编辑文件内容，完美支持 Markdown 渲染及相对路径在应用内的原生跳转。
  - **议题 (Issues)**：查看项目 Issues 列表，并在应用内原生浏览 Issue 详情与评论。
  - **分支同步**：对比与上游分支的差异，提供一键 Sync 同步上游分支功能。
  - **Actions 与 Releases**：探索 GitHub Actions 运行情况及日志，浏览并下载 Releases 产物。
- **🔍 强大搜索与深层链接**：
  - **全局与局部搜索**：支持全局代码、仓库搜索，以及在用户主页过滤特定仓库。
  - **深层链接 (Deep Linking)**：自动拦截应用内 Markdown 中的 GitHub 链接（包括相对路径和绝对路径），无缝跳转至对应的原生页面，并在遇到 404 等错误时进行友好提示。
- **👤 账户与用户中心**：管理你的个人信息，访问他人用户主页。
- **⚙️ 桌面端专属优化**：支持记录并恢复上次窗口大小。
- **✨ 流畅体验**：使用 `flutter_animate` 提供丝滑的界面动画，针对桌面端进行了原生窗口管理优化。

## 🛠️ 技术栈 (Tech Stack)

- **框架**: [Flutter](https://flutter.dev/) (跨平台支持)
- **核心依赖**:
  - `http` - 网络请求，与 GitHub REST API 交互
  - `shared_preferences` - 本地缓存与偏好设置
  - `flutter_animate` - 精美的 UI 动画效果
  - `webview_windows` & `webview_flutter` - 应用内网页视图
  - `window_manager` - 桌面端窗口管理
  - `flutter_markdown` - Markdown 文本渲染
- **CI/CD**: 配置了 GitHub Actions 自动化工作流，支持 macOS、Windows、Android 平台的自动构建与发布。

## 📂 项目结构 (Project Structure)

```text
lib/
 ├── main.dart                 # 应用入口及全局配置
 ├── l10n/                     # 国际化语言支持
 ├── screens/                  # 所有的页面 UI 组件
 │    ├── login_screen.dart    # 登录页
 │    ├── home_screen.dart     # 主页 (包含仓库搜索与创建)
 │    ├── repo_detail_screen.dart # 仓库详情与多标签页
 │    ├── issue_detail_screen.dart # 议题详情页
 │    ├── user_profile_screen.dart # 用户主页
 │    └── ...
 ├── services/                 # 核心服务
 │    ├── github_service.dart  # GitHub API 封装 (代码、仓库、Issue等)
 │    └── oauth_service.dart   # OAuth 授权逻辑 (双栈监听支持)
 ├── utils/                    # 工具类
 │    └── link_handler.dart    # 核心的深层链接拦截与路由处理
 └── widgets/                  # 可复用的通用组件
      └── repo_card.dart       # 仓库卡片组件
```

## 🚀 快速开始 (Getting Started)

### 环境要求

- 安装 [Flutter SDK](https://docs.flutter.dev/get-started/install)
- 配置好 macOS, Android 或 Windows 的开发环境（取决于目标运行平台）

### 运行步骤

1. 克隆本项目到本地：
   ```bash
   git clone https://github.com/miaizhe/GHUltra.git
   cd GHUltra
   ```

2. 获取依赖包：
   ```bash
   flutter pub get
   ```

3. 运行应用：
   ```bash
   # 运行 macOS 版本
   flutter run -d macos

   # 运行 Windows 版本
   flutter run -d windows
   
   # 运行 Android 版本
   flutter run -d android
   ```

## 📄 许可证 (License)

本项目采用 [GNU General Public License v3.0 (GPL-3.0)](LICENSE) 许可证。
