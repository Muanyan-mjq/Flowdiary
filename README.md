# 随心耶

> Flowdiary — 记录生活，随心而动，一只萨摩耶陪你写日记

**随心耶** 是一个温暖治愈的日记 App，以萨摩耶小狗为形象贯穿全应用。支持 Markdown 写作、语音输入、塔罗星座、心情日历、番茄专注、等级养成等功能。使用 Flutter 开发，同时支持 Android 和 iOS。

---

## 下载

<br>

<div align="center">

[**🤖 下载 Android 版**](https://github.com/Muanyan-mjq/Flowdiary/releases/latest/download/app-release.apk)
<br><sub>v1.0.0 · 103 MB · 直接安装</sub>

<br>

[**🍎 下载 iOS 版**](https://github.com/Muanyan-mjq/Flowdiary/releases/latest/download/sui_xin_ye_unsigned.ipa)
<br><sub>v1.0.0 · 49 MB · 需 AltStore 侧载</sub>

</div>

<br>

> **iOS 用户看这里** — 安装只需 3 步：[AltServer](https://altstore.io) 装到电脑 → iPhone 连电脑装 AltStore → 用 AltStore 打开 IPA。之后每 7 天自动续签。

---

## 功能

### 日记
- **卡片流首页** — PageView 横向滑动，新笔记 / 最近日记 / 萨摩耶来信
- **四步写日记** — 天气 → 心情 → 事件标签 → 写作
- **Markdown 写作** — 标题、加粗、斜体、引用、待办、列表实时预览；6 种写作背景色；5 档字号调节；撤销/重做
- **语音输入** — 中文语音识别，说话自动转文字
- **添加配图** — 拍照或从相册选取，插入日记
- **动态小狗** — 根据天气 + 时间段自动切换萨摩耶形象（深夜/清晨/上午/中午/下午/傍晚/晚上）
- **草稿自动保存** — 离开写作页自动存草稿，红点提醒
- **日期跳转** — 首页标题点击弹出日历，快速跳转到任意日期的日记

### 发现（回忆隧道）
- **数据面板** — 累计日记数、记录天数、总字数
- **随机回忆** — 每天推送一篇历史日记
- **时间线** — 按年月分组，滑动浏览全部日记

### 社区（专注 / 待办）
- **待办清单** — 添加每日任务，打卡完成
- **番茄钟** — 专注计时器，圆形进度动画
- **完成激励** — 全部完成时展示夸夸文案（「全部完成，今天超棒」）

### 心情（塔罗 + 星座 + 八字）
- **塔罗牌** — 完整 78 张塔罗（22 张大阿尔卡纳 + 56 张小阿尔卡纳），翻牌动画，每日抽牌
- **12 星座详解** — 守护星、元素、性格关键词、优缺点、幸运色/数字、合拍星座
- **八字简析** — 输入出生信息，生成运势解读

### 我的（个人主页）
- **萨摩耶等级养成** — Lv1 萌新出窝 → Lv6 耶中之王，写越多等级越高，每个等级有专属配色
- **心情日历** — 月历按心情着色（开心金 / 难过蓝 / 平静绿 / 惊喜粉 / 生气红）
- **日签墙** — 每日签到收集好句子，6 色柔美渐变卡片，支持收藏和二维码分享
- **个人空间** — 可自定义背景色（暖米/浅灰/护眼绿/樱花粉/暗黑），展示最近日记

### 安全隐私
- **伪装密码** — 设置两个密码，一个进真实日记，一个进假日记空间
- **应用锁** — 支持指纹/面容识别 + 密码验证
- **本地加密** — 敏感数据使用 FlutterSecureStorage（iOS Keychain / Android Keystore）

### 其他
- **第一封信** — 首页「感谢相遇」卡片点击查看开发者写给用户的信
- **云端备份与同步** — 基于 Supabase
- **全局搜索** — 搜索全部日记
- **日记配图画廊** — 横向滚动 + 点击放大
- **收藏功能** — 收藏喜欢的日记
- **意见反馈** — 基于 Formspree，支持离线保存
- **主题色自定义** — 6 种主题色可选
- **天气集成** — 和风天气 API，自动获取当地天气

---

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.x（Dart） |
| 本地存储 | SharedPreferences + FlutterSecureStorage + path_provider |
| 数据库 | 本地 JSON 文件 + Supabase（云端） |
| 认证 | 本地密码（bcrypt 哈希）+ Supabase Auth |
| 生物识别 | local_auth（指纹 / 面容） |
| 语音输入 | speech_to_text（中文） |
| 通知 | flutter_local_notifications |
| 天气 | 和风天气 API + geolocator（定位） |
| Markdown | 自研简易渲染器（标题/粗体/斜体/引用/待办/列表/分割线） |
| 图片处理 | image_picker + image_gallery_saver |
| 分享 | share_plus + qr_flutter（二维码） |
| 主题 | flutter_colorpicker（取色器） |
| 意见反馈 | Formspree（在线提交 + 本地离线保存） |
| 动画 | Lottie + Flutter 内置动画 |
| 本地化 | flutter_localizations（中文/英文） |

---

## 项目结构

```
lib/
├── main.dart                          # 入口：主题提供器、认证网关、底部导航
├── models/                            # 数据模型
│   ├── diary_entry.dart               # 日记条目
│   ├── diary_input_state.dart         # 写作状态
│   ├── focus_task.dart                # 待办任务
│   └── monthly_card_model.dart        # 月度卡片
├── screens/                           # 页面（29 个）
│   ├── home_screen.dart               # 首页卡片流
│   ├── diary_wizard_screen.dart       # 写日记四步向导
│   ├── diary_detail_screen.dart       # 日记详情（Markdown 渲染）
│   ├── moo_space_tunnel_screen.dart   # 回忆隧道
│   ├── focus_screen.dart              # 专注 / 待办
│   ├── fortune_screen.dart            # 塔罗 / 星座 / 八字
│   ├── mood_calendar_screen.dart      # 心情日历
│   ├── monthly_view_screen.dart       # 月度视图
│   ├── list_view_screen.dart          # 列表视图
│   ├── profile_screen.dart            # 个人主页
│   ├── personal_space_screen.dart     # 个人空间
│   ├── daily_sign_square_screen.dart  # 日签墙
│   ├── daily_sign_detail_screen.dart  # 日签详情
│   ├── daily_sign_editor_screen.dart  # 日签编辑器
│   ├── daily_sign_share_screen.dart   # 日签分享
│   ├── login_screen.dart              # 登录 / 注册
│   ├── app_lock_screen.dart           # 应用锁
│   ├── decoy_screen.dart              # 假日记模式
│   ├── zodiac_detail_screen.dart      # 星座详情
│   ├── theme_screen.dart              # 主题色选择
│   ├── settings_screen.dart           # 设置
│   ├── search_screen.dart             # 搜索
│   ├── drafts_screen.dart             # 草稿箱
│   ├── favorites_screen.dart          # 收藏
│   ├── sync_screen.dart               # 云端备份
│   ├── feedback_screen.dart           # 意见反馈
│   ├── about_screen.dart              # 关于页
│   ├── timer_screen.dart              # 番茄钟
│   └── login_success_screen.dart      # 登录成功
├── steps/                             # 写作步骤
│   ├── weather_step.dart              # 步骤一：选天气
│   ├── mood_step.dart                 # 步骤二：选心情
│   ├── event_step.dart                # 步骤三：选事件标签
│   └── writing_step.dart              # 步骤四：Markdown 编辑器
├── widgets/                           # 可复用组件
│   ├── diary_card.dart                # 日记卡片（核心组件，含动态小狗）
│   ├── responsive_app_bar.dart        # 响应式导航栏（安全距离适配）
│   ├── app_drawer.dart                # 侧边栏抽屉
│   ├── timer_display.dart             # 番茄钟显示
│   ├── monthly_card_slider.dart       # 月度卡片滑动器
│   ├── monthly_card_item.dart         # 月度卡片项
│   ├── cloud_card.dart                # 云端状态卡片
│   ├── bottom_button.dart             # 底部按钮
│   ├── page_indicator.dart            # 页面指示器
│   └── staggered_entrance.dart        # 错落入场动画
├── services/                          # 服务层
│   ├── cloud_auth_service.dart        # 云端认证
│   ├── cloud_sync_service.dart        # 云端同步
│   ├── notification_service.dart      # 通知服务
│   ├── supabase_config.dart           # Supabase 配置
│   └── moo_location_weather_service.dart # 天气服务
└── utils/                             # 工具类
    ├── diary_storage.dart             # 日记本地存储
    ├── draft_storage.dart             # 草稿存储
    ├── letter_service.dart            # 给用户的第一封信
    ├── user_service.dart              # 用户管理（注册/登录/密码加密）
    ├── sign_storage.dart              # 签到存储
    ├── stats_storage.dart             # 统计数据
    ├── focus_storage.dart             # 待办存储
    ├── favorite_storage.dart          # 收藏存储
    ├── backup_storage.dart            # 备份存储
    ├── theme_service.dart             # 主题色存储
    ├── weather_service.dart           # 天气 API
    ├── image_utils.dart               # 图片处理工具
    ├── smooth_route.dart              # 平滑路由动画
    ├── biometric_service.dart         # 生物识别服务
    ├── chinese_calendar.dart          # 农历工具
    ├── cover_storage.dart             # 封面存储
    └── feedback_storage.dart          # 反馈存储（提交 + 本地历史）
```

---

## 快速开始

### 环境要求
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Android SDK（Android 开发）或 Xcode + macOS（iOS 开发）

### 安装运行

```bash
# 1. 克隆项目
git clone https://github.com/Muanyan-mjq/Flowdiary.git sui_xin_ye
cd sui_xin_ye

# 2. 安装依赖
flutter pub get

# 3. 运行（连接手机或模拟器）
flutter run
```

### 打包

```bash
# Android APK
flutter build apk --release

# iOS (需在 macOS 上，且配置好证书)
flutter build ios --release
```

### 可选配置

**天气功能**

本项目使用和风天气 API。如需启用天气功能：
1. 注册 [和风天气](https://dev.qweather.com/) 获取 API Key
2. 修改 `lib/utils/weather_service.dart` 中的 API Key

**云端同步**

云端功能基于 Supabase。如需启用：
1. 创建 [Supabase](https://supabase.com/) 项目
2. 在 `lib/services/supabase_config.dart` 中填入 URL 和 anon key

**意见反馈（Formspree）**

意见反馈功能使用 Formspree 作为邮件后端。如需启用：
1. 注册 [Formspree](https://formspree.io/) 创建项目，获取表单端点 ID
2. 修改 `lib/screens/feedback_screen.dart` 中的 `_formspreeEndpoint`

> 注：不配置上述服务也能正常使用全部本地功能。意见反馈会保存到本地。天气、云端、Formspree 均为可选模块。

---

## 设计理念

### 为什么是萨摩耶
萨摩耶以「微笑天使」著称，温暖、治愈、忠诚。我们希望这只白色小狗能陪伴用户的每一次记录，让写日记这件事变得不那么孤单。

### 给用户的第一封信
点击首页「感谢相遇」卡片，可以看到开发者写给用户的一封信——关于《窄门》的阅读感悟，关于为什么要做这个 App。文字或许不能永远准确，但可以帮我们保存很久。

### 等级养成
没有广告、没有付费。唯一的「货币」是坚持写日记——写 5 篇升 Lv2，写 200 篇成为「耶中之王」。用轻量的游戏化机制激励持续记录，而不是通过付费墙。

---

## iOS 适配说明

App 能在 iPhone 上正常运行：
- 安全距离已适配灵动岛和刘海屏
- 滚动使用 iOS 风格弹性回弹（BouncingScrollPhysics）
- 数据加密使用 iOS Keychain
- 生物识别支持 Face ID
- 本地化支持中文和英文

UI 采用 Material Design 风格，未做 Cupertino 原生风格适配。如需 iOS 原生风格，可替换部分组件为 Cupertino 系列。

---

## 开源协议

MIT License

Copyright (c) 2025 慕安延

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

## 联系方式

- GitHub: [@muanyan-mjq](https://github.com/muanyan-mjq)
- 邮箱: muanyan5@gmail.com
- 个人主页: [https://muanyan-mjq.github.io](https://muanyan-mjq.github.io)

---

*Made with ❤️ and Flutter*
