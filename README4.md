# README4 - 自由流转功能实现说明

本文介绍本项目如何接入 HarmonyOS 自由流转中的“跨端迁移/应用接续”能力。

当前实现的是第一版稳定方案：迁移轻量业务状态，不迁移 Canvas 像素、不迁移正在执行的动画。

## 一、功能目标

用户在手机端使用抽奖应用时，可以通过 HarmonyOS 系统的应用接续入口，将任务流转到平板端继续使用。

接续后，平板端应恢复以下状态：

| 状态 | 说明 |
| --- | --- |
| 当前 Tab | 例如用户在手机上停留在“刮刮乐”或“记录”页，平板端继续打开同一页 |
| 抽奖历史 | 转盘和刮刮乐写入的 `wheel_history` 记录 |
| 签到日期 | `last_checkin` |
| 连续签到天数 | `checkin_streak` |

不迁移以下状态：

| 状态 | 原因 |
| --- | --- |
| 转盘旋转动画 | 动画是瞬时状态，跨端恢复意义不大 |
| Canvas 涂层像素 | 数据量大且恢复复杂 |
| 彩纸/星星粒子动画 | 视觉效果可在目标端重新生成 |

## 二、涉及文件

| 文件 | 作用 |
| --- | --- |
| `CanvasComponent-master/entry/src/main/module.json5` | 声明应用支持自由流转 |
| `CanvasComponent-master/entry/src/main/ets/entryability/EntryAbility.ts` | 保存源端状态，恢复目标端状态 |
| `CanvasComponent-master/entry/src/main/ets/pages/CanvasPage.ets` | 将当前 Tab 接入全局状态，供迁移使用 |

## 三、整体实现流程

自由流转的核心流程如下：

1. 在 `module.json5` 中配置 `"continuable": true`。
2. 用户在设备 A 上使用应用。
3. 系统发起应用接续。
4. 设备 A 调用 `EntryAbility.onContinue()`。
5. 应用把当前页面、历史记录、签到状态写入 `wantParam`。
6. 设备 B 启动同一个应用。
7. 设备 B 调用 `onCreate()` 或 `onNewWant()`。
8. 应用从 `want.parameters` 中取出迁移数据。
9. 将迁移数据写回 `AppStorage`。
10. 页面通过 `@StorageLink` / `@StorageProp` 自动恢复显示。

## 四、开启自由流转能力

文件：

```txt
CanvasComponent-master/entry/src/main/module.json5
```

关键代码：

```json5
"orientation": "auto_rotation",
"continuable": true,
"exported": true,
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `"orientation": "auto_rotation",` | 应用支持自动旋转，适配手机和平板横竖屏 |
| `"continuable": true,` | 声明该 Ability 支持跨端迁移/应用接续 |
| `"exported": true,` | 允许系统从外部入口启动该 Ability |

其中最关键的是：

```json5
"continuable": true
```

如果没有这一行，系统会认为当前 Ability 不支持应用接续。

## 五、EntryAbility 的实现

文件：

```txt
CanvasComponent-master/entry/src/main/ets/entryability/EntryAbility.ts
```

### 1. 导入接续需要的类型

代码：

```ts
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `AbilityConstant` | 提供 `OnContinueResult` 等 Ability 常量 |
| `UIAbility` | 当前应用入口 Ability 的基类 |
| `Want` | Ability 启动参数类型，目标端通过它接收迁移数据 |

### 2. 应用创建时初始化并恢复数据

代码：

```ts
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
  this.initStorage();
  this.restoreContinueData(want);
  hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {` | Ability 创建时执行，目标设备首次接续启动时会走这里 |
| `this.initStorage();` | 初始化需要迁移和持久化的全局状态 |
| `this.restoreContinueData(want);` | 从 `want.parameters` 中恢复迁移数据 |
| `hilog.info(..., 'Ability onCreate');` | 打印生命周期日志，方便 DevEco 日志排查 |
| `}` | 结束 `onCreate` 方法 |

### 3. 初始化全局和持久状态

代码：

```ts
private initStorage(): void {
  AppStorage.setOrCreate('currentIndex', AppStorage.get<number>('currentIndex') || 0);
  PersistentStorage.persistProp('wheel_history', '');
  PersistentStorage.persistProp('last_checkin', '');
  PersistentStorage.persistProp('checkin_streak', 0);
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `private initStorage(): void {` | 定义私有初始化方法 |
| `AppStorage.setOrCreate('currentIndex', AppStorage.get<number>('currentIndex') || 0);` | 初始化当前 Tab，下标默认是 0，即转盘页 |
| `PersistentStorage.persistProp('wheel_history', '');` | 将抽奖历史声明为持久化属性 |
| `PersistentStorage.persistProp('last_checkin', '');` | 将上次签到日期声明为持久化属性 |
| `PersistentStorage.persistProp('checkin_streak', 0);` | 将连续签到天数声明为持久化属性 |
| `}` | 结束初始化方法 |

这里的作用有两个：

1. 本机重启后仍可保留历史和签到。
2. 自由流转恢复数据时，目标端有明确的全局状态容器。

### 4. 源端保存迁移状态

代码：

```ts
onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
  wantParam['currentIndex'] = AppStorage.get<number>('currentIndex') || 0;
  wantParam['wheelHistory'] = AppStorage.get<string>('wheel_history') || '';
  wantParam['lastCheckIn'] = AppStorage.get<string>('last_checkin') || '';
  wantParam['checkInStreak'] = AppStorage.get<number>('checkin_streak') || 0;
  hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onContinue');
  return AbilityConstant.OnContinueResult.AGREE;
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {` | 系统发起应用接续时调用，参数用于携带迁移数据 |
| `wantParam['currentIndex'] = AppStorage.get<number>('currentIndex') || 0;` | 保存当前 Tab 下标 |
| `wantParam['wheelHistory'] = AppStorage.get<string>('wheel_history') || '';` | 保存抽奖历史字符串 |
| `wantParam['lastCheckIn'] = AppStorage.get<string>('last_checkin') || '';` | 保存上次签到日期 |
| `wantParam['checkInStreak'] = AppStorage.get<number>('checkin_streak') || 0;` | 保存连续签到天数 |
| `hilog.info(..., 'Ability onContinue');` | 打印源端接续日志 |
| `return AbilityConstant.OnContinueResult.AGREE;` | 返回同意迁移，系统继续发起接续 |
| `}` | 结束 `onContinue` 方法 |

这一段运行在源设备上，例如手机端。

### 5. 目标端已有实例时恢复数据

代码：

```ts
onNewWant(want: Want) {
  this.restoreContinueData(want);
  hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onNewWant');
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `onNewWant(want: Want) {` | 当目标设备已有应用实例时，系统可能通过新 Want 传入迁移数据 |
| `this.restoreContinueData(want);` | 从新 Want 中恢复迁移数据 |
| `hilog.info(..., 'Ability onNewWant');` | 打印日志，确认目标端收到接续参数 |
| `}` | 结束 `onNewWant` 方法 |

为什么需要 `onNewWant()`：

- 如果目标端应用没有启动，通常走 `onCreate()`。
- 如果目标端应用已经存在，可能走 `onNewWant()`。

两个都写，接续恢复更稳。

### 6. 统一恢复迁移数据

代码：

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

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `private restoreContinueData(want: Want): void {` | 定义私有恢复方法 |
| `if (want === undefined || want.parameters === undefined) {` | 判断是否存在迁移参数 |
| `return;` | 如果没有参数，直接返回 |
| `}` | 结束空参数判断 |
| `const params = want.parameters;` | 取出迁移参数对象 |
| `if (params['currentIndex'] !== undefined) {` | 判断是否传来了当前 Tab |
| `AppStorage.setOrCreate('currentIndex', params['currentIndex'] as number);` | 将当前 Tab 写入全局状态 |
| `}` | 结束当前 Tab 恢复 |
| `if (params['wheelHistory'] !== undefined) {` | 判断是否传来了抽奖历史 |
| `AppStorage.setOrCreate('wheel_history', params['wheelHistory'] as string);` | 将抽奖历史写入全局状态 |
| `}` | 结束抽奖历史恢复 |
| `if (params['lastCheckIn'] !== undefined) {` | 判断是否传来了签到日期 |
| `AppStorage.setOrCreate('last_checkin', params['lastCheckIn'] as string);` | 将签到日期写入全局状态 |
| `}` | 结束签到日期恢复 |
| `if (params['checkInStreak'] !== undefined) {` | 判断是否传来了连续签到天数 |
| `AppStorage.setOrCreate('checkin_streak', params['checkInStreak'] as number);` | 将连续签到天数写入全局状态 |
| `}` | 结束连续签到天数恢复 |
| `}` | 结束恢复方法 |

这一段运行在目标设备上，例如平板端。

## 六、CanvasPage 的当前 Tab 迁移

文件：

```txt
CanvasComponent-master/entry/src/main/ets/pages/CanvasPage.ets
```

关键代码：

```ts
@StorageLink('currentIndex') currentIndex: number = 0;
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `@StorageLink('currentIndex')` | 将组件状态和 `AppStorage` 中的 `currentIndex` 双向绑定 |
| `currentIndex: number = 0;` | 当前 Tab 下标，默认 0 表示转盘页 |

原来这里使用的是：

```ts
@State currentIndex: number = 0;
```

`@State` 只属于当前组件，不方便 `EntryAbility.onContinue()` 读取。

改成 `@StorageLink` 后：

1. 用户切换 Tab 时，`currentIndex` 自动同步到 `AppStorage`。
2. `onContinue()` 可以从 `AppStorage` 读取当前 Tab。
3. 目标端恢复 `currentIndex` 后，页面会自动跳到对应 Tab。

Tab 切换代码：

```ts
.onChange((idx: number) => { this.currentIndex = idx; })
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `.onChange((idx: number) => {` | 监听 Tab 切换事件 |
| `this.currentIndex = idx;` | 将新的 Tab 下标写入 `currentIndex` |
| `})` | 结束 Tab 切换回调 |

因为 `currentIndex` 是 `@StorageLink`，所以这里赋值后，`AppStorage` 中的 `currentIndex` 也会更新。

## 七、迁移数据说明

当前通过 `wantParam` 携带的数据如下：

| wantParam 字段 | AppStorage 字段 | 类型 | 说明 |
| --- | --- | --- | --- |
| `currentIndex` | `currentIndex` | `number` | 当前 Tab |
| `wheelHistory` | `wheel_history` | `string` | 抽奖历史 |
| `lastCheckIn` | `last_checkin` | `string` | 上次签到日期 |
| `checkInStreak` | `checkin_streak` | `number` | 连续签到天数 |

选择这些数据的原因：

1. 数据量小，适合直接放入 `wantParam`。
2. 都是用户感知明显的状态。
3. 目标端恢复后，页面可以立即显示正确结果。

## 八、为什么不迁移 Canvas 像素

转盘和刮刮乐都使用 Canvas 绘制，但自由流转不适合直接迁移 Canvas 像素。

原因如下：

| 原因 | 说明 |
| --- | --- |
| 数据量大 | Canvas 像素数据可能远大于接续参数建议大小 |
| 设备尺寸不同 | 手机和平板 Canvas 尺寸不同，迁移像素会变形 |
| 恢复复杂 | 刮痕、粒子、动画都属于临时视觉状态 |
| 体验收益低 | 重新根据状态绘制更自然、更稳定 |

正确做法是迁移业务状态，例如当前页面、历史记录、奖品结果，然后在目标设备上重新绘制 UI。

## 九、如何发起自由流转

应用内部不需要自己写“发起流转”按钮。

发起流程由 HarmonyOS 系统完成：

1. 两台设备安装同一个应用。
2. 两台设备登录同一个华为账号。
3. 两台设备打开 Wi-Fi 和蓝牙。
4. 两台设备开启多设备协同/应用接续相关能力。
5. 在设备 A 上打开本应用并进行操作。
6. 在设备 B 上通过系统提供的接续入口打开本应用。
7. 系统调用设备 A 的 `onContinue()`。
8. 系统将 `wantParam` 传到设备 B。
9. 设备 B 调用 `onCreate()` 或 `onNewWant()`。
10. 应用恢复状态。

常见系统入口包括：

| 入口 | 说明 |
| --- | --- |
| Dock/任务栏接续图标 | 平板或大屏设备可能显示可接续应用入口 |
| 最近任务 | 系统多任务界面可能出现跨设备任务 |
| 多设备协同入口 | 系统智慧互联/超级终端相关页面 |

具体入口会因系统版本和设备型号不同而不同。

## 十、测试建议

### 1. 当前 Tab 恢复测试

测试步骤：

1. 在手机打开应用。
2. 切换到“刮刮乐”页。
3. 发起自由流转到平板。
4. 查看平板是否直接打开“刮刮乐”页。

预期结果：

```txt
平板端 currentIndex 恢复为 1
页面显示刮刮乐 Tab
```

### 2. 抽奖历史恢复测试

测试步骤：

1. 在手机转盘抽奖几次。
2. 切换到“记录”页，确认有历史记录。
3. 发起自由流转到平板。
4. 查看平板“记录”页。

预期结果：

```txt
平板端可以看到手机端产生的抽奖记录
```

### 3. 签到状态恢复测试

测试步骤：

1. 在手机点击签到。
2. 发起自由流转到平板。
3. 查看平板转盘页右上角签到状态。

预期结果：

```txt
平板端显示已签到和连续签到天数
```

### 4. 日志测试

在 DevEco Studio 日志中查看：

```txt
Ability onContinue
Ability onCreate
Ability onNewWant
```

如果源端出现 `Ability onContinue`，说明系统已经发起接续。

如果目标端出现 `Ability onCreate` 或 `Ability onNewWant`，说明目标端已经收到接续启动。

## 十一、当前版本限制

当前版本是轻量接续方案，有以下限制：

| 限制 | 说明 |
| --- | --- |
| 不恢复转盘旋转中状态 | 迁移后转盘会以静态页面显示 |
| 不恢复刮刮乐具体刮痕 | 迁移 Canvas 像素不稳定 |
| 不迁移大文件 | 当前只使用 `wantParam`，适合小数据 |
| 不做实时多端协同 | 当前是跨端迁移，不是两个设备同时操作 |

如果后续要迁移更复杂数据，可以继续接入：

1. 分布式数据对象：用于较复杂的临时业务数据。
2. 分布式文件：用于图片、文档、附件等文件资产。
3. 多端协同：用于两个设备同时交互的场景。

## 十二、总结

本项目的自由流转实现可以概括为：

```txt
module.json5 开启 continuable
EntryAbility.onContinue 保存状态
EntryAbility.onCreate/onNewWant 恢复状态
CanvasPage 使用 @StorageLink 同步当前 Tab
页面根据 AppStorage 自动刷新
```

这套方案适合当前抽奖应用，因为它迁移的是核心业务状态，而不是临时视觉效果。

