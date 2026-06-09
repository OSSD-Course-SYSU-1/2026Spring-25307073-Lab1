# Canvas 抽奖应用项目说明

本文档由 `README1.md`、`README2.md`、`README3.md`、`README4.md` 汇总整理而来，用于集中介绍项目功能、代码结构、多端适配方案和自由流转实现。

## 一、项目概述

本项目是一个基于 HarmonyOS 的 Canvas 抽奖应用，使用 ArkTS 和 ArkUI 声明式开发完成。应用以 Canvas 绘图为核心，实现转盘抽奖、刮刮乐、抽奖记录、签到、粒子背景、中奖弹窗等功能，并进一步支持手机/平板、横屏/竖屏多端适配，以及第一版自由流转能力。

项目主工程目录：

```txt
CanvasComponent-master/
```

核心技术栈：

| 类型 | 内容 |
| --- | --- |
| 开发平台 | HarmonyOS |
| 开发语言 | ArkTS |
| UI 框架 | ArkUI 声明式开发 |
| 核心绘图 | Canvas 2D |
| 构建体系 | Hvigor / OHOS 工程 |
| 设备类型 | phone、tablet |
| 适配方向 | 手机、平板、横屏、竖屏 |
| 流转能力 | 跨端迁移 / 应用接续 |

## 二、项目结构

主要目录如下：

```txt
CanvasComponent-master/
├── AppScope/
│   └── app.json5
├── entry/
│   ├── src/main/module.json5
│   ├── src/main/ets/entryability/EntryAbility.ts
│   ├── src/main/ets/pages/CanvasPage.ets
│   ├── src/main/ets/view/
│   │   ├── WheelView.ets
│   │   ├── ScratchCardView.ets
│   │   ├── HistoryView.ets
│   │   ├── PrizeDialog.ets
│   │   ├── ConfettiEffect.ets
│   │   ├── StarParticle.ets
│   │   └── SlotMachineView.ets
│   ├── src/main/ets/viewmodel/
│   │   ├── DrawModel.ets
│   │   ├── PrizeData.ets
│   │   └── FillArcData.ets
│   └── src/main/resources/
├── build-profile.json5
├── oh-package.json5
└── hvigorfile.ts
```

核心文件职责：

| 文件 | 职责 |
| --- | --- |
| `EntryAbility.ts` | 应用入口、生命周期、自由流转保存与恢复 |
| `CanvasPage.ets` | 主页面、Tab 容器、多端内容区域计算、签到入口 |
| `WheelView.ets` | 转盘抽奖、连抽、转盘动画、中奖弹窗触发 |
| `ScratchCardView.ets` | 刮刮乐 Canvas 绘制、触摸刮开、横屏卡片适配 |
| `HistoryView.ets` | 抽奖历史记录展示、中奖率统计、清空记录 |
| `PrizeDialog.ets` | 中奖结果弹窗 |
| `ConfettiEffect.ets` | 彩纸庆祝动画 |
| `StarParticle.ets` | 星空粒子背景 |
| `DrawModel.ets` | 转盘 Canvas 绘制模型 |
| `CommonConstants.ets` | 通用常量 |
| `ColorConstants.ets` | 颜色和主题常量 |
| `StyleConstants.ets` | 样式常量 |

## 三、核心功能

### 1. 转盘抽奖

转盘功能由 `WheelView.ets` 和 `DrawModel.ets` 共同实现。

主要能力：

| 功能 | 说明 |
| --- | --- |
| Canvas 转盘绘制 | 使用 Canvas 绘制外环、扇区、文字、emoji 奖品 |
| 单次抽奖 | 点击中心 GO 按钮触发一次抽奖 |
| 3 连抽 / 5 连抽 | 支持连续多次抽奖并汇总结果 |
| 动画旋转 | 使用 `animateTo` 控制转盘旋转 |
| 中奖弹窗 | 抽奖结束后弹出中奖结果 |
| 彩纸动画 | 抽奖完成后触发庆祝粒子 |
| 历史记录 | 每次结果写入 `wheel_history` |

核心流程：

```txt
点击按钮
→ 生成随机角度
→ 根据角度计算奖品
→ 执行旋转动画
→ 保存历史记录
→ 弹出中奖结果
```

### 2. 刮刮乐

刮刮乐功能由 `ScratchCardView.ets` 实现。

主要能力：

| 功能 | 说明 |
| --- | --- |
| 随机奖品 | 每张卡随机选择奖品 |
| Canvas 涂层 | 先绘制奖品底层，再绘制金色涂层 |
| 触摸刮开 | 使用 `destination-out` 擦除涂层 |
| 进度统计 | 根据刮开面积估算百分比 |
| 自动揭晓 | 刮开达到约 45% 后自动显示结果 |
| 火花粒子 | 刮动时产生粒子效果 |
| 历史记录 | 揭晓后保存到 `wheel_history` |

核心流程：

```txt
生成奖品
→ 绘制奖品底层
→ 绘制金色涂层
→ 用户触摸刮开
→ 达到阈值后揭晓
→ 保存历史记录
```

### 3. 抽奖记录

抽奖记录由 `HistoryView.ets` 实现。

主要能力：

| 功能 | 说明 |
| --- | --- |
| 读取记录 | 从 `wheel_history` 读取历史数据 |
| 倒序展示 | 最新记录显示在最上方 |
| 判断中奖 | 根据奖品类型判断中奖/未中奖 |
| 统计中奖率 | 计算总次数和中奖率 |
| 清空记录 | 支持一键清空历史 |

记录格式：

```txt
timestamp|imagePath,timestamp|imagePath
```

最多保留最近 100 条记录。

### 4. 视觉增强

项目增加了多种视觉效果：

| 功能 | 文件 | 说明 |
| --- | --- | --- |
| 星空背景 | `StarParticle.ets` | 页面背景动态闪烁 |
| 彩纸庆祝 | `ConfettiEffect.ets` | 抽奖完成后触发庆祝 |
| 中奖弹窗 | `PrizeDialog.ets` | 显示奖品 emoji 和文案 |
| 暗色渐变主题 | `ColorConstants.ets` | 页面整体为深色霓虹风格 |

### 5. 签到系统

签到功能位于 `CanvasPage.ets`。

主要状态：

| 状态 | 说明 |
| --- | --- |
| `last_checkin` | 上次签到日期 |
| `checkin_streak` | 连续签到天数 |
| `checkedIn` | 当前页面是否显示已签到 |
| `checkInDays` | 当前显示的连续签到天数 |

签到数据已接入 `PersistentStorage`，可配合自由流转一起迁移。

## 四、多端适配实现

多端适配主要来自 `README3.md`，当前实现目标是让应用在手机、平板、横屏、竖屏下都能正常显示。

### 1. 统一内容区域

`CanvasPage.ets` 负责获取窗口宽高，并计算真正可用的内容区域：

```ts
const isSmallScreen: boolean = this.currentBreakpoint === 'sm';
const sidebarW = isSmallScreen ? 0 : 90;
const bottomTabH = isSmallScreen ? (fullW > fullH ? 50 : 64) : 0;
const cw = fullW - sidebarW;
const ch = fullH - bottomTabH;
AppStorage.setOrCreate('contentWidth', cw);
AppStorage.setOrCreate('contentHeight', ch);
AppStorage.setOrCreate('isLandscape', cw > ch);
```

含义：

| 逻辑 | 作用 |
| --- | --- |
| 短边小于 600vp | 使用手机布局 |
| 短边大于等于 600vp | 使用平板布局 |
| 手机布局 | 使用底部 Tab，需要扣除底部高度 |
| 平板布局 | 使用左侧 Tab，需要扣除侧边栏宽度 |
| `contentWidth/contentHeight` | 子页面统一使用的业务绘制区域 |

### 2. Tab 适配

手机和平板的 Tab 布局不同：

| 设备 | Tab 位置 | 代码策略 |
| --- | --- | --- |
| 手机 | 底部 | `BarPosition.End` |
| 平板 | 左侧 | `BarPosition.Start` + `.vertical(true)` |

这样可以避免手机屏幕横向空间不足，也让平板更接近大屏操作习惯。

### 3. 转盘适配

`WheelView.ets` 从 `AppStorage` 中读取：

```ts
@StorageProp('contentWidth') contentWidth: number = 360;
@StorageProp('contentHeight') contentHeight: number = 640;
```

然后使用同一套尺寸控制：

| 对象 | 使用尺寸 |
| --- | --- |
| 主 Canvas | `screenWidth/screenHeight` |
| 覆盖 Canvas | `screenWidth/screenHeight` |
| 旋转中心 | `screenWidth / 2`、`screenHeight / 2` |
| GO 按钮 | 根据较短边缩放 |
| Stack 容器 | `screenWidth/screenHeight` |

这样解决了手机竖屏 GO 按钮不在中心、手机横屏转盘过大等问题。

### 4. 刮刮乐适配

`ScratchCardView.ets` 同样读取 `contentWidth/contentHeight`，并根据横竖屏决定卡片比例。

手机横屏时使用横向卡片：

```ts
if (this.compactLandscape) {
  ch = Math.min(this.screenHeight * 0.76, 220);
  cw = Math.min(ch * 2.05, this.screenWidth * 0.78);
}
```

竖屏时使用更接近普通卡片的比例：

```ts
cw = Math.min(this.screenWidth * 0.78, 420);
ch = Math.min(cw * 1.18, this.screenHeight * 0.82);
```

这样可以避免平板竖屏、手机横屏时刮刮乐初始画面跑出屏幕。

### 5. 适配场景总结

| 场景 | 显示策略 |
| --- | --- |
| 手机竖屏 | 底部 Tab，转盘居中，刮刮乐竖向卡片 |
| 手机横屏 | 底部 Tab，转盘缩小，刮刮乐横向卡片 |
| 平板竖屏 | 左侧 Tab，内容区域扣除侧边栏 |
| 平板横屏 | 左侧 Tab，Canvas 使用宽屏内容区 |

## 五、自由流转实现

自由流转内容来自 `README4.md`，当前实现的是 HarmonyOS 自由流转中的“跨端迁移 / 应用接续”能力。

### 1. 实现目标

用户在手机端使用应用后，可以通过系统接续入口流转到平板继续使用。

当前迁移的数据：

| 数据 | 字段 | 说明 |
| --- | --- | --- |
| 当前 Tab | `currentIndex` | 恢复转盘、刮刮乐或记录页 |
| 抽奖历史 | `wheel_history` | 恢复历史记录 |
| 签到日期 | `last_checkin` | 恢复签到状态 |
| 连续签到天数 | `checkin_streak` | 恢复连续天数 |

暂不迁移：

| 数据 | 原因 |
| --- | --- |
| Canvas 像素 | 数据量大，且不同设备尺寸不一致 |
| 转盘旋转中动画 | 瞬时状态，跨端恢复意义不大 |
| 粒子动画 | 可在目标端重新生成 |

### 2. 开启接续能力

在 `module.json5` 中配置：

```json5
"continuable": true
```

作用：告诉系统当前 `EntryAbility` 支持跨端迁移。

### 3. 源端保存状态

在 `EntryAbility.ts` 中实现：

```ts
onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
  wantParam['currentIndex'] = AppStorage.get<number>('currentIndex') || 0;
  wantParam['wheelHistory'] = AppStorage.get<string>('wheel_history') || '';
  wantParam['lastCheckIn'] = AppStorage.get<string>('last_checkin') || '';
  wantParam['checkInStreak'] = AppStorage.get<number>('checkin_streak') || 0;
  return AbilityConstant.OnContinueResult.AGREE;
}
```

作用：

| 代码 | 含义 |
| --- | --- |
| `currentIndex` | 保存当前页面 |
| `wheelHistory` | 保存抽奖历史 |
| `lastCheckIn` | 保存签到日期 |
| `checkInStreak` | 保存连续签到天数 |
| `AGREE` | 同意系统发起迁移 |

### 4. 目标端恢复状态

在 `EntryAbility.ts` 中实现：

```ts
private restoreContinueData(want: Want): void {
  if (want === undefined || want.parameters === undefined) {
    return;
  }
  const params = want.parameters;
  if (params['currentIndex'] !== undefined) {
    AppStorage.setOrCreate('currentIndex', params['currentIndex'] as number);
  }
  if (params['wheelHistory'] !== undefined) {
    AppStorage.setOrCreate('wheel_history', params['wheelHistory'] as string);
  }
  if (params['lastCheckIn'] !== undefined) {
    AppStorage.setOrCreate('last_checkin', params['lastCheckIn'] as string);
  }
  if (params['checkInStreak'] !== undefined) {
    AppStorage.setOrCreate('checkin_streak', params['checkInStreak'] as number);
  }
}
```

恢复入口：

| 方法 | 场景 |
| --- | --- |
| `onCreate()` | 目标设备首次启动应用 |
| `onNewWant()` | 目标设备已有应用实例 |

### 5. 当前 Tab 恢复

`CanvasPage.ets` 将当前 Tab 改成：

```ts
@StorageLink('currentIndex') currentIndex: number = 0;
```

这样用户切换 Tab 后，`currentIndex` 会自动同步到 `AppStorage`。目标设备恢复 `currentIndex` 后，页面会打开到对应 Tab。

### 6. 发起方式

应用内部不需要写“发起流转”按钮，流转由 HarmonyOS 系统入口触发。

测试条件：

| 条件 | 说明 |
| --- | --- |
| 两台设备 | 例如手机和平板 |
| 同一应用 | 两端安装相同 `bundleName` 的应用 |
| 同一华为账号 | 系统接续依赖账号和信任关系 |
| Wi-Fi 和蓝牙开启 | 用于发现和连接设备 |
| 系统支持应用接续 | 设备和系统版本需要支持自由流转 |
| `continuable: true` | 应用必须声明支持接续 |

测试步骤：

1. 手机打开应用。
2. 切到“刮刮乐”或“记录”页。
3. 做几次抽奖，产生历史记录。
4. 点击签到。
5. 通过平板系统的应用接续入口打开该应用。
6. 检查平板是否恢复当前 Tab、抽奖记录和签到状态。

## 六、运行与验证建议

由于该项目是 HarmonyOS 工程，建议使用 DevEco Studio 打开内层工程：

```txt
D:\CanvasComponent-master\CanvasComponent-master
```

建议验证以下场景：

| 场景 | 验证点 |
| --- | --- |
| 手机竖屏 | 底部 Tab 不出屏，转盘 GO 居中 |
| 手机横屏 | 转盘不超出屏幕，刮刮乐为横向卡片 |
| 平板竖屏 | 左侧 Tab 正常，刮刮乐不跑出屏幕 |
| 平板横屏 | 转盘和刮刮乐都在内容区内 |
| 应用接续 | 当前 Tab、历史记录、签到状态恢复 |

DevEco 日志中可关注：

```txt
Ability onContinue
Ability onCreate
Ability onNewWant
```

如果能看到 `Ability onContinue`，说明源端已被系统发起接续。

如果目标端能看到 `onCreate` 或 `onNewWant`，说明目标设备收到接续启动。

## 七、文档对应关系

原四份 README 的内容已经汇总进本文档：

| 原文档 | 内容 | 在本文中的位置 |
| --- | --- | --- |
| `README1.md` | 初始 Canvas 转盘项目、架构、核心代码说明 | 项目概述、项目结构、转盘抽奖 |
| `README2.md` | 新增刮刮乐、历史记录、彩纸动画、签到等功能 | 核心功能、视觉增强、签到系统 |
| `README3.md` | 多端适配实现和逐行解释 | 多端适配实现 |
| `README4.md` | 自由流转实现和逐行解释 | 自由流转实现 |

如果需要看每一段代码的逐行解释，可以继续查看 `README3.md` 和 `README4.md`；如果只需要项目总览和答辩说明，阅读本文档即可。

## 八、总结

本项目最终形成了一个支持多端体验的 HarmonyOS Canvas 抽奖应用：

```txt
Canvas 转盘抽奖
+ 刮刮乐玩法
+ 抽奖历史
+ 签到系统
+ 动态视觉效果
+ 手机/平板横竖屏适配
+ 自由流转应用接续
```

整体实现思路是：业务状态放入 `AppStorage` / `PersistentStorage`，界面根据真实内容区域自适应绘制，跨端迁移时只迁移轻量业务状态，在目标设备上重新绘制 UI。

