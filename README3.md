# README3 - 多端适配实现说明

本文说明本项目如何实现手机、平板、横屏、竖屏的多端适配，并逐行解释参与多端适配的关键代码。

项目中的多端适配主要由三个文件协作完成：

| 文件 | 职责 |
| --- | --- |
| `CanvasComponent-master/entry/src/main/ets/pages/CanvasPage.ets` | 统一计算页面可用宽高，决定手机/平板 Tab 形态 |
| `CanvasComponent-master/entry/src/main/ets/view/WheelView.ets` | 根据可用区域重绘转盘，保证 GO 按钮在转盘中心 |
| `CanvasComponent-master/entry/src/main/ets/view/ScratchCardView.ets` | 根据可用区域重绘刮刮乐，手机横屏使用横向卡片布局 |

## 一、整体适配思路

本项目不是为每一种设备写一套页面，而是通过下面这套流程实现多端适配：

1. `CanvasPage` 获取当前窗口尺寸。
2. 使用较短边判断当前是手机布局还是平板布局。
3. 手机布局使用底部 Tab，平板布局使用左侧竖向 Tab。
4. `CanvasPage` 扣除底部 Tab 或侧边栏占用的空间，得到真实内容区域。
5. 将真实内容区域写入 `AppStorage`。
6. `WheelView` 和 `ScratchCardView` 从 `AppStorage` 读取内容区域尺寸。
7. 子组件只按照真实内容区域绘制 Canvas，不再按照整屏窗口绘制。
8. 横屏时压缩高度、缩小控件、调整布局比例，避免内容超出屏幕。

核心共享变量如下：

| 变量 | 含义 |
| --- | --- |
| `contentWidth` | 当前页面可用于业务内容的宽度 |
| `contentHeight` | 当前页面可用于业务内容的高度 |
| `isLandscape` | 当前内容区域是否为横屏比例 |
| `currentBreakpoint` | 当前页面断点，`sm` 表示手机小屏，`md` 表示平板/大屏 |

## 二、CanvasPage 的多端适配代码

`CanvasPage` 是整个页面的入口。它负责识别设备尺寸，并把可用区域告诉子组件。

### 1. 状态变量

代码：

```ts
@State currentIndex: number = 0;
@State checkedIn: boolean = false;
@State checkInDays: number = 0;
@State currentBreakpoint: string = 'sm';
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `@State currentIndex: number = 0;` | 记录当前选中的 Tab，`0` 表示转盘页 |
| `@State checkedIn: boolean = false;` | 记录当天是否已经签到 |
| `@State checkInDays: number = 0;` | 记录连续签到天数 |
| `@State currentBreakpoint: string = 'sm';` | 记录当前布局断点，默认使用手机小屏布局 |

### 2. 页面出现时读取窗口尺寸

代码：

```ts
aboutToAppear(): void {
  window.getLastWindow(context)
    .then((wc) => {
      wc.setWindowLayoutFullScreen(true);
      const wp = wc.getWindowProperties();
      const vpW = uiContext!.px2vp(wp.windowRect.width);
      const vpH = uiContext!.px2vp(wp.windowRect.height);
      this.currentBreakpoint = Math.min(vpW, vpH) >= 600 ? 'md' : 'sm';
      this.updateContentSize(vpW, vpH);

      wc.on('windowSizeChange', (size: window.Size) => {
        const w = uiContext!.px2vp(size.width);
        const h = uiContext!.px2vp(size.height);
        this.currentBreakpoint = Math.min(w, h) >= 600 ? 'md' : 'sm';
        this.updateContentSize(w, h);
      });
    })
    .catch((e: Error) => { Logger.error('Fullscreen error: ' + JSON.stringify(e)); });

  this.checkDaily();
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `aboutToAppear(): void {` | 页面即将显示时执行初始化逻辑 |
| `window.getLastWindow(context)` | 获取当前应用最后创建的窗口对象 |
| `.then((wc) => {` | 获取窗口成功后进入回调，`wc` 是窗口实例 |
| `wc.setWindowLayoutFullScreen(true);` | 将窗口设置为全屏布局，内容可覆盖完整窗口区域 |
| `const wp = wc.getWindowProperties();` | 获取窗口属性，包含窗口宽高 |
| `const vpW = uiContext!.px2vp(wp.windowRect.width);` | 将窗口像素宽度转换为 ArkUI 使用的 vp 单位 |
| `const vpH = uiContext!.px2vp(wp.windowRect.height);` | 将窗口像素高度转换为 vp 单位 |
| `this.currentBreakpoint = Math.min(vpW, vpH) >= 600 ? 'md' : 'sm';` | 用较短边判断设备类型，短边大于等于 600 走平板布局，否则走手机布局 |
| `this.updateContentSize(vpW, vpH);` | 根据窗口宽高计算真实内容区域 |
| `wc.on('windowSizeChange', (size: window.Size) => {` | 监听窗口尺寸变化，用于横竖屏切换 |
| `const w = uiContext!.px2vp(size.width);` | 将变化后的窗口宽度转换为 vp |
| `const h = uiContext!.px2vp(size.height);` | 将变化后的窗口高度转换为 vp |
| `this.currentBreakpoint = Math.min(w, h) >= 600 ? 'md' : 'sm';` | 旋转后重新判断手机/平板布局 |
| `this.updateContentSize(w, h);` | 旋转后重新计算内容区域 |
| `});` | 结束窗口尺寸变化监听 |
| `})` | 结束窗口获取成功回调 |
| `.catch((e: Error) => { Logger.error(...); });` | 如果窗口获取失败，写入日志 |
| `this.checkDaily();` | 检查每日签到状态 |
| `}` | 结束 `aboutToAppear` 方法 |

### 3. 计算真实内容区域

代码：

```ts
updateContentSize(fullW: number, fullH: number): void {
  const isSmallScreen: boolean = this.currentBreakpoint === 'sm';
  const sidebarW = isSmallScreen ? 0 : 90;
  const bottomTabH = isSmallScreen ? (fullW > fullH ? 50 : 64) : 0;
  const cw = fullW - sidebarW;
  const ch = fullH - bottomTabH;
  AppStorage.setOrCreate('contentWidth', cw);
  AppStorage.setOrCreate('contentHeight', ch);
  AppStorage.setOrCreate('isLandscape', cw > ch);
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `updateContentSize(fullW: number, fullH: number): void {` | 定义内容区域计算方法，参数是窗口完整宽高 |
| `const isSmallScreen: boolean = this.currentBreakpoint === 'sm';` | 判断当前是否是手机小屏布局 |
| `const sidebarW = isSmallScreen ? 0 : 90;` | 手机没有侧边栏，平板侧边 Tab 占用 90vp 宽度 |
| `const bottomTabH = isSmallScreen ? (fullW > fullH ? 50 : 64) : 0;` | 手机使用底部 Tab，横屏预留 50vp，竖屏预留 64vp；平板没有底部 Tab |
| `const cw = fullW - sidebarW;` | 用完整窗口宽度减去侧边栏宽度，得到业务内容宽度 |
| `const ch = fullH - bottomTabH;` | 用完整窗口高度减去底部 Tab 高度，得到业务内容高度 |
| `AppStorage.setOrCreate('contentWidth', cw);` | 将业务内容宽度写入全局存储，供子组件读取 |
| `AppStorage.setOrCreate('contentHeight', ch);` | 将业务内容高度写入全局存储，供子组件读取 |
| `AppStorage.setOrCreate('isLandscape', cw > ch);` | 根据内容区域宽高判断是否为横屏 |
| `}` | 结束内容区域计算方法 |

这一段是多端适配的核心。之前手机底部 Tab 超出屏幕，就是因为子页面按整屏高度绘制，没有扣掉底部 Tab。现在 `contentHeight` 已经扣除了底部 Tab。

### 4. 根据设备切换 Tab 位置

代码：

```ts
Tabs({
  barPosition: this.currentBreakpoint === 'sm' ? BarPosition.End : BarPosition.Start,
  index: this.currentIndex
}) {
  TabContent() { WheelView() }
    .tabBar(this.tabBuilder(0))
  TabContent() { ScratchCardView() }
    .tabBar(this.tabBuilder(1))
  TabContent() { HistoryView() }
    .tabBar(this.tabBuilder(2))
}
.vertical(this.currentBreakpoint !== 'sm')
.barWidth(this.currentBreakpoint === 'sm' ? '100%' : 90)
.barHeight(this.currentBreakpoint === 'sm' ? undefined : '100%')
.width(StyleConstants.FULL_PERCENT)
.height(StyleConstants.FULL_PERCENT)
.onChange((idx: number) => { this.currentIndex = idx; })
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `Tabs({` | 创建 Tab 容器 |
| `barPosition: this.currentBreakpoint === 'sm' ? BarPosition.End : BarPosition.Start,` | 手机将 Tab 放在底部，平板将 Tab 放在左侧 |
| `index: this.currentIndex` | 设置当前选中的 Tab |
| `}) {` | 结束 Tabs 参数并开始声明 Tab 内容 |
| `TabContent() { WheelView() }` | 第一个 Tab 显示转盘页面 |
| `.tabBar(this.tabBuilder(0))` | 给转盘 Tab 使用自定义 Tab 按钮 |
| `TabContent() { ScratchCardView() }` | 第二个 Tab 显示刮刮乐页面 |
| `.tabBar(this.tabBuilder(1))` | 给刮刮乐 Tab 使用自定义 Tab 按钮 |
| `TabContent() { HistoryView() }` | 第三个 Tab 显示历史记录页面 |
| `.tabBar(this.tabBuilder(2))` | 给历史记录 Tab 使用自定义 Tab 按钮 |
| `}` | 结束 Tab 内容声明 |
| `.vertical(this.currentBreakpoint !== 'sm')` | 平板使用竖向 Tab，手机使用横向底部 Tab |
| `.barWidth(this.currentBreakpoint === 'sm' ? '100%' : 90)` | 手机 Tab 宽度占满底部，平板侧边 Tab 宽度为 90vp |
| `.barHeight(this.currentBreakpoint === 'sm' ? undefined : '100%')` | 平板侧边 Tab 高度占满，手机高度交给系统默认计算 |
| `.width(StyleConstants.FULL_PERCENT)` | Tabs 宽度占满父容器 |
| `.height(StyleConstants.FULL_PERCENT)` | Tabs 高度占满父容器 |
| `.onChange((idx: number) => { this.currentIndex = idx; })` | 用户切换 Tab 时更新当前索引 |

### 5. 签到条改为浮层

代码：

```ts
if (this.currentIndex === 0) {
  Row() {
    if (this.checkedIn) {
      Text(`已签到 ${this.checkInDays} 天`)
        .fontSize(11).fontColor('rgba(255,215,0,0.6)')
    } else {
      Text('签到')
        .fontSize(12).fontColor('#FFD700').fontWeight(600)
        .onClick(() => { this.doCheckIn(); })
    }
  }
  .width('100%')
  .justifyContent(FlexAlign.End)
  .padding({ right: 16, top: 8 })
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `if (this.currentIndex === 0) {` | 只有在转盘页面显示签到条 |
| `Row() {` | 使用横向容器承载签到文字 |
| `if (this.checkedIn) {` | 判断当天是否已签到 |
| ``Text(`已签到 ${this.checkInDays} 天`)`` | 已签到时显示连续签到天数 |
| `.fontSize(11).fontColor('rgba(255,215,0,0.6)')` | 设置已签到文字大小和颜色 |
| `} else {` | 未签到时显示可点击入口 |
| `Text('签到')` | 显示签到按钮文字 |
| `.fontSize(12).fontColor('#FFD700').fontWeight(600)` | 设置签到入口的字体样式 |
| `.onClick(() => { this.doCheckIn(); })` | 点击后执行签到逻辑 |
| `}` | 结束签到状态判断 |
| `}` | 结束 Row 容器 |
| `.width('100%')` | 签到条宽度占满屏幕 |
| `.justifyContent(FlexAlign.End)` | 将签到文字靠右显示 |
| `.padding({ right: 16, top: 8 })` | 设置右上角边距 |
| `}` | 结束签到条条件渲染 |

这里的关键点是：签到条放在 `Stack` 里作为浮层，不再放在 Tabs 上方的 Column 中，所以不会把手机底部 Tab 挤出屏幕。

## 三、WheelView 的多端适配代码

`WheelView` 负责转盘绘制。它必须保证三件事：

1. 转盘不超出手机横屏屏幕。
2. GO 按钮始终在转盘中心。
3. Canvas 旋转中心和视觉中心一致。

### 1. 读取父页面计算出的内容区域

代码：

```ts
@StorageProp('contentWidth') contentWidth: number = 360;
@StorageProp('contentHeight') contentHeight: number = 640;
@State pageLandscape: boolean = false;
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `@StorageProp('contentWidth') contentWidth: number = 360;` | 从全局存储读取业务内容宽度，默认 360vp |
| `@StorageProp('contentHeight') contentHeight: number = 640;` | 从全局存储读取业务内容高度，默认 640vp |
| `@State pageLandscape: boolean = false;` | 记录当前转盘内容区是否为横屏，变化后会触发 UI 刷新 |

### 2. 根据内容区域计算转盘画布大小

代码：

```ts
updateWheelSize(): void {
  const w: number = this.contentWidth > 0 ? this.contentWidth : 360;
  const h: number = this.contentHeight > 0 ? this.contentHeight : 640;
  this.pageLandscape = w > h;
  this.screenWidth = w;
  this.screenHeight = Math.max(this.pageLandscape ? 220 : 320, h);
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `updateWheelSize(): void {` | 定义根据 `AppStorage` 内容区更新转盘尺寸的方法 |
| `const w: number = this.contentWidth > 0 ? this.contentWidth : 360;` | 如果内容宽度有效就使用它，否则使用 360vp 默认值 |
| `const h: number = this.contentHeight > 0 ? this.contentHeight : 640;` | 如果内容高度有效就使用它，否则使用 640vp 默认值 |
| `this.pageLandscape = w > h;` | 根据内容区域判断当前是否横屏 |
| `this.screenWidth = w;` | 将转盘画布宽度设置为内容宽度 |
| `this.screenHeight = Math.max(this.pageLandscape ? 220 : 320, h);` | 横屏最小高度 220vp，竖屏最小高度 320vp，避免画布过小 |
| `}` | 结束方法 |

### 3. 横竖屏切换时直接用窗口尺寸重新计算

代码：

```ts
updateWheelSizeFromWindow(fullW: number, fullH: number): void {
  const minDim: number = Math.min(fullW, fullH);
  const smallScreen: boolean = minDim < 600;
  const sidebarW: number = smallScreen ? 0 : 90;
  const bottomTabH: number = smallScreen ? (fullW > fullH ? 50 : 64) : 0;
  const w: number = fullW - sidebarW;
  const h: number = fullH - bottomTabH;
  this.pageLandscape = w > h;
  this.screenWidth = w;
  this.screenHeight = Math.max(this.pageLandscape ? 220 : 320, h);
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `updateWheelSizeFromWindow(fullW: number, fullH: number): void {` | 定义根据窗口完整宽高更新转盘尺寸的方法 |
| `const minDim: number = Math.min(fullW, fullH);` | 取窗口短边，用于判断手机还是平板 |
| `const smallScreen: boolean = minDim < 600;` | 短边小于 600vp 视为手机布局 |
| `const sidebarW: number = smallScreen ? 0 : 90;` | 手机没有侧边栏，平板扣除 90vp 侧边 Tab |
| `const bottomTabH: number = smallScreen ? (fullW > fullH ? 50 : 64) : 0;` | 手机扣除底部 Tab 高度，横屏扣 50vp，竖屏扣 64vp |
| `const w: number = fullW - sidebarW;` | 计算转盘可用宽度 |
| `const h: number = fullH - bottomTabH;` | 计算转盘可用高度 |
| `this.pageLandscape = w > h;` | 根据可用区域判断横竖屏 |
| `this.screenWidth = w;` | 更新转盘画布宽度 |
| `this.screenHeight = Math.max(this.pageLandscape ? 220 : 320, h);` | 更新转盘画布高度，并保留最小高度 |
| `}` | 结束方法 |

这个方法解决横竖屏切换时 `AppStorage` 更新慢一拍的问题。窗口变化时，转盘可以立即用最新窗口尺寸计算。

### 4. 页面出现时监听窗口变化

代码：

```ts
aboutToAppear(): void {
  this.updateWheelSize();
  window.getLastWindow(context)
    .then((wc) => {
      wc.setWindowLayoutFullScreen(true);
      const wp = wc.getWindowProperties();
      this.updateWheelSizeFromWindow(uiContext!.px2vp(wp.windowRect.width), uiContext!.px2vp(wp.windowRect.height));
      if (this.canvasDrawn) {
        this.drawModel.draw(this.canvasContext, this.screenWidth, this.screenHeight);
      }

      wc.on('windowSizeChange', (size: window.Size) => {
        this.updateWheelSizeFromWindow(uiContext!.px2vp(size.width), uiContext!.px2vp(size.height));
        if (this.canvasDrawn) {
          this.drawModel.draw(this.canvasContext, this.screenWidth, this.screenHeight);
        }
      });
    })
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `aboutToAppear(): void {` | 组件即将显示时执行 |
| `this.updateWheelSize();` | 先用父页面已经写入的内容尺寸初始化转盘 |
| `window.getLastWindow(context)` | 获取当前窗口对象 |
| `.then((wc) => {` | 获取窗口成功后执行回调 |
| `wc.setWindowLayoutFullScreen(true);` | 设置窗口全屏布局 |
| `const wp = wc.getWindowProperties();` | 获取当前窗口属性 |
| `this.updateWheelSizeFromWindow(...);` | 用窗口实际宽高再次校准转盘尺寸 |
| `if (this.canvasDrawn) {` | 判断 Canvas 是否已经绘制过 |
| `this.drawModel.draw(this.canvasContext, this.screenWidth, this.screenHeight);` | 如果已经绘制过，就用新尺寸重画转盘 |
| `}` | 结束绘制判断 |
| `wc.on('windowSizeChange', (size: window.Size) => {` | 监听横竖屏或窗口大小变化 |
| `this.updateWheelSizeFromWindow(...);` | 窗口变化后重新计算转盘尺寸 |
| `if (this.canvasDrawn) {` | 判断 Canvas 是否可重绘 |
| `this.drawModel.draw(...);` | 使用新宽高重绘转盘 |
| `}` | 结束重绘判断 |
| `});` | 结束窗口变化监听 |
| `})` | 结束窗口获取成功回调 |
| `}` | 结束 `aboutToAppear` 方法 |

### 5. Canvas、旋转中心、GO 按钮共用同一套尺寸

代码：

```ts
Stack({ alignContent: Alignment.Center }) {
  Canvas(this.canvasContext)
    .width(this.screenWidth)
    .height(this.screenHeight)
    .onReady(() => {
      this.canvasDrawn = true;
      this.drawModel.draw(this.canvasContext, this.screenWidth, this.screenHeight);
    })
    .rotate({
      x: 0, y: 0, z: 1, angle: this.rotateDegree,
      centerX: this.screenWidth / CommonConstants.TWO,
      centerY: this.screenHeight / CommonConstants.TWO,
    })

  Canvas(this.overlayContext)
    .width(this.screenWidth)
    .height(this.screenHeight)
    .hitTestBehavior(HitTestMode.None)

  Button('GO')
    .fontSize(Math.min(this.screenWidth, this.screenHeight) * 0.055)
    .width(Math.min(this.screenWidth, this.screenHeight) * 0.14)
    .height(Math.min(this.screenWidth, this.screenHeight) * 0.14)
}
.width(this.screenWidth)
.height(this.screenHeight)
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `Stack({ alignContent: Alignment.Center }) {` | 创建层叠容器，并让子元素默认居中 |
| `Canvas(this.canvasContext)` | 创建主 Canvas，用于绘制转盘 |
| `.width(this.screenWidth)` | Canvas 宽度使用适配后的内容宽度 |
| `.height(this.screenHeight)` | Canvas 高度使用适配后的内容高度 |
| `.onReady(() => {` | Canvas 准备完成后执行 |
| `this.canvasDrawn = true;` | 标记 Canvas 已经可以重绘 |
| `this.drawModel.draw(...);` | 按当前宽高绘制转盘 |
| `})` | 结束 Canvas ready 回调 |
| `.rotate({` | 给 Canvas 添加旋转变换 |
| `x: 0, y: 0, z: 1, angle: this.rotateDegree,` | 设置绕 Z 轴旋转，旋转角度为 `rotateDegree` |
| `centerX: this.screenWidth / CommonConstants.TWO,` | 旋转中心 X 设置为画布宽度的一半 |
| `centerY: this.screenHeight / CommonConstants.TWO,` | 旋转中心 Y 设置为画布高度的一半 |
| `})` | 结束旋转配置 |
| `Canvas(this.overlayContext)` | 创建覆盖层 Canvas，用于绘制指针、高光等固定元素 |
| `.width(this.screenWidth)` | 覆盖层宽度与主 Canvas 一致 |
| `.height(this.screenHeight)` | 覆盖层高度与主 Canvas 一致 |
| `.hitTestBehavior(HitTestMode.None)` | 覆盖层不拦截点击事件 |
| `Button('GO')` | 创建中心 GO 按钮 |
| `.fontSize(Math.min(...) * 0.055)` | 按较短边计算按钮字体大小 |
| `.width(Math.min(...) * 0.14)` | 按较短边计算按钮宽度 |
| `.height(Math.min(...) * 0.14)` | 按较短边计算按钮高度 |
| `}` | 结束 Stack 内容 |
| `.width(this.screenWidth)` | Stack 宽度与 Canvas 一致 |
| `.height(this.screenHeight)` | Stack 高度与 Canvas 一致 |

这段代码解决了 GO 按钮偏离中心的问题。主 Canvas、覆盖 Canvas、旋转中心、Stack 尺寸全部使用 `screenWidth/screenHeight`，因此视觉中心一致。

## 四、ScratchCardView 的多端适配代码

`ScratchCardView` 负责刮刮乐。它的适配目标是：

1. 平板竖屏初始涂层不出屏。
2. 手机竖屏不被底部 Tab 遮挡。
3. 手机横屏改成横向刮刮卡。
4. 横竖屏切换后立即重算 Canvas 尺寸。

### 1. 读取内容尺寸并维护本地横屏状态

代码：

```ts
@State scaleFactor: number = 1.0;
@StorageProp('contentWidth') contentWidth: number = 360;
@StorageProp('contentHeight') contentHeight: number = 640;
@State pageLandscape: boolean = false;
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `@State scaleFactor: number = 1.0;` | 当前页面缩放系数，用于字体、边距、刮擦半径等 |
| `@StorageProp('contentWidth') contentWidth: number = 360;` | 从全局存储读取业务内容宽度 |
| `@StorageProp('contentHeight') contentHeight: number = 640;` | 从全局存储读取业务内容高度 |
| `@State pageLandscape: boolean = false;` | 记录当前刮刮乐内容区域是否横屏 |

### 2. 页面出现时初始化并监听窗口变化

代码：

```ts
aboutToAppear(): void {
  this.updateCanvasSize();
  if (this.canvasInitialized) {
    this.drawCard();
  }
  window.getLastWindow(uiContext!.getHostContext()!)
    .then((windowClass: window.Window) => {
      const wp = windowClass.getWindowProperties();
      this.updateCanvasSizeFromWindow(uiContext!.px2vp(wp.windowRect.width), uiContext!.px2vp(wp.windowRect.height));
      if (this.canvasInitialized) {
        this.drawCard();
      }
      windowClass.on('windowSizeChange', (size: window.Size) => {
        this.updateCanvasSizeFromWindow(uiContext!.px2vp(size.width), uiContext!.px2vp(size.height));
        if (this.canvasInitialized) {
          this.drawCard();
        }
      });
    })
    .catch(() => {});
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `aboutToAppear(): void {` | 组件即将显示时执行 |
| `this.updateCanvasSize();` | 先用父页面提供的内容宽高计算 Canvas 区域 |
| `if (this.canvasInitialized) {` | 如果 Canvas 已经初始化过 |
| `this.drawCard();` | 立即按新尺寸重绘刮刮卡 |
| `}` | 结束初始化判断 |
| `window.getLastWindow(uiContext!.getHostContext()!)` | 获取当前窗口 |
| `.then((windowClass: window.Window) => {` | 获取窗口成功后执行 |
| `const wp = windowClass.getWindowProperties();` | 获取窗口属性 |
| `this.updateCanvasSizeFromWindow(...);` | 用实际窗口尺寸重新计算 Canvas 区域 |
| `if (this.canvasInitialized) {` | 判断 Canvas 是否已经可用 |
| `this.drawCard();` | 如果可用就重绘卡片 |
| `}` | 结束判断 |
| `windowClass.on('windowSizeChange', (size: window.Size) => {` | 监听横竖屏切换 |
| `this.updateCanvasSizeFromWindow(...);` | 尺寸变化后重新计算 Canvas 区域 |
| `if (this.canvasInitialized) {` | 判断是否可以重绘 |
| `this.drawCard();` | 按新尺寸重绘刮刮卡 |
| `}` | 结束重绘判断 |
| `});` | 结束窗口变化监听 |
| `})` | 结束窗口获取成功回调 |
| `.catch(() => {});` | 获取窗口失败时静默处理，避免页面崩溃 |
| `}` | 结束 `aboutToAppear` 方法 |

### 3. 从父页面内容尺寸计算 Canvas

代码：

```ts
updateCanvasSize(): void {
  const fullW: number = this.contentWidth > 0 ? this.contentWidth : 360;
  const fullH: number = this.contentHeight > 0 ? this.contentHeight : 640;
  this.applyCanvasSize(fullW, fullH);
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `updateCanvasSize(): void {` | 定义使用父页面内容尺寸更新 Canvas 的方法 |
| `const fullW: number = this.contentWidth > 0 ? this.contentWidth : 360;` | 内容宽度有效则使用内容宽度，否则使用默认 360vp |
| `const fullH: number = this.contentHeight > 0 ? this.contentHeight : 640;` | 内容高度有效则使用内容高度，否则使用默认 640vp |
| `this.applyCanvasSize(fullW, fullH);` | 将宽高交给统一计算方法处理 |
| `}` | 结束方法 |

### 4. 从窗口尺寸计算 Canvas

代码：

```ts
updateCanvasSizeFromWindow(fullW: number, fullH: number): void {
  const minDim: number = Math.min(fullW, fullH);
  const smallScreen: boolean = minDim < 600;
  const sidebarW: number = smallScreen ? 0 : 90;
  const bottomTabH: number = smallScreen ? (fullW > fullH ? 50 : 64) : 0;
  this.applyCanvasSize(fullW - sidebarW, fullH - bottomTabH);
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `updateCanvasSizeFromWindow(fullW: number, fullH: number): void {` | 定义使用窗口完整宽高更新 Canvas 的方法 |
| `const minDim: number = Math.min(fullW, fullH);` | 取窗口短边判断设备类型 |
| `const smallScreen: boolean = minDim < 600;` | 短边小于 600vp 判定为手机 |
| `const sidebarW: number = smallScreen ? 0 : 90;` | 手机没有侧边栏，平板扣除 90vp 侧边 Tab |
| `const bottomTabH: number = smallScreen ? (fullW > fullH ? 50 : 64) : 0;` | 手机扣除底部 Tab 高度，横屏 50vp，竖屏 64vp |
| `this.applyCanvasSize(fullW - sidebarW, fullH - bottomTabH);` | 将扣除导航后的内容区域交给统一计算方法 |
| `}` | 结束方法 |

### 5. 统一计算刮刮乐 Canvas 区域

代码：

```ts
applyCanvasSize(fullW: number, fullH: number): void {
  const minDim: number = Math.min(fullW, fullH);
  this.pageLandscape = fullW > fullH;
  const compactLandscape: boolean = this.pageLandscape && fullH < 480;

  this.scaleFactor = Math.max(0.75, Math.min(minDim / 360, 1.35));
  this.screenWidth = fullW;

  const titleArea: number = compactLandscape ? 48 * this.scaleFactor : 86 * this.scaleFactor;
  const bottomArea: number = compactLandscape ? 24 * this.scaleFactor : 40 * this.scaleFactor;
  const safePadding: number = compactLandscape ? 8 * this.scaleFactor : 14 * this.scaleFactor;
  this.screenHeight = Math.max(160, fullH - titleArea - bottomArea - safePadding);
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `applyCanvasSize(fullW: number, fullH: number): void {` | 定义统一的 Canvas 尺寸计算方法 |
| `const minDim: number = Math.min(fullW, fullH);` | 取内容区域短边，用于计算缩放比例 |
| `this.pageLandscape = fullW > fullH;` | 根据内容宽高判断是否横屏 |
| `const compactLandscape: boolean = this.pageLandscape && fullH < 480;` | 横屏且高度小于 480vp 时启用紧凑横屏布局 |
| `this.scaleFactor = Math.max(0.75, Math.min(minDim / 360, 1.35));` | 根据短边计算缩放系数，并限制在 0.75 到 1.35 之间 |
| `this.screenWidth = fullW;` | Canvas 宽度使用内容宽度 |
| `const titleArea: number = compactLandscape ? 48 * this.scaleFactor : 86 * this.scaleFactor;` | 估算标题区域高度，手机横屏更小 |
| `const bottomArea: number = compactLandscape ? 24 * this.scaleFactor : 40 * this.scaleFactor;` | 估算底部进度区域高度，手机横屏更小 |
| `const safePadding: number = compactLandscape ? 8 * this.scaleFactor : 14 * this.scaleFactor;` | 预留安全边距，避免贴边 |
| `this.screenHeight = Math.max(160, fullH - titleArea - bottomArea - safePadding);` | 计算 Canvas 可绘制高度，最小不低于 160vp |
| `}` | 结束方法 |

这一段解决了刮刮乐初始涂层出屏的问题。卡片不再按照整屏高度居中，而是在扣除标题、底部进度、Tab 后的 Canvas 区域内居中。

### 6. 根据横竖屏决定刮刮卡比例

代码：

```ts
drawCard(): void {
  const ctx = this.canvasContext;
  let cw: number;
  let ch: number;
  if (this.compactLandscape) {
    ch = Math.min(this.screenHeight * 0.76, 220);
    cw = Math.min(ch * 2.05, this.screenWidth * 0.78);
  } else if (this.pageLandscape) {
    ch = Math.min(this.screenHeight * 0.72, 320);
    cw = Math.min(ch * 1.7, this.screenWidth * 0.82);
  } else {
    cw = Math.min(this.screenWidth * 0.78, 420);
    ch = Math.min(cw * 1.18, this.screenHeight * 0.82);
  }
  this.cardX = (this.screenWidth - cw) / 2;
  this.cardY = (this.screenHeight - ch) / 2;
  this.cardW = cw;
  this.cardH = ch;
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `drawCard(): void {` | 定义绘制刮刮卡的方法 |
| `const ctx = this.canvasContext;` | 获取 Canvas 绘图上下文 |
| `let cw: number;` | 声明卡片宽度变量 |
| `let ch: number;` | 声明卡片高度变量 |
| `if (this.compactLandscape) {` | 判断是否是手机横屏紧凑布局 |
| `ch = Math.min(this.screenHeight * 0.76, 220);` | 手机横屏下卡片高度最多 220vp，占 Canvas 高度 76% |
| `cw = Math.min(ch * 2.05, this.screenWidth * 0.78);` | 手机横屏下卡片宽度约为高度的 2.05 倍，形成横向卡片 |
| `} else if (this.pageLandscape) {` | 如果不是紧凑横屏，但仍然是横屏 |
| `ch = Math.min(this.screenHeight * 0.72, 320);` | 普通横屏下卡片高度最多 320vp |
| `cw = Math.min(ch * 1.7, this.screenWidth * 0.82);` | 普通横屏下卡片宽度为高度的 1.7 倍 |
| `} else {` | 竖屏布局 |
| `cw = Math.min(this.screenWidth * 0.78, 420);` | 竖屏下卡片宽度占屏幕 78%，最大 420vp |
| `ch = Math.min(cw * 1.18, this.screenHeight * 0.82);` | 竖屏下卡片高度略高于宽度，但不超过 Canvas 高度 82% |
| `}` | 结束横竖屏判断 |
| `this.cardX = (this.screenWidth - cw) / 2;` | 让卡片在 Canvas 中水平居中 |
| `this.cardY = (this.screenHeight - ch) / 2;` | 让卡片在 Canvas 中垂直居中 |
| `this.cardW = cw;` | 保存卡片宽度，供触摸和绘制使用 |
| `this.cardH = ch;` | 保存卡片高度，供触摸和绘制使用 |
| `}` | 结束绘制方法 |

### 7. 紧凑横屏判断

代码：

```ts
private get compactLandscape(): boolean {
  return this.pageLandscape && this.screenHeight < 360;
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `private get compactLandscape(): boolean {` | 定义只在组件内部使用的计算属性 |
| `return this.pageLandscape && this.screenHeight < 360;` | 当前是横屏且 Canvas 高度小于 360vp 时，使用紧凑横屏布局 |
| `}` | 结束计算属性 |

### 8. 横屏时压缩标题区域

代码：

```ts
Text('刮刮乐')
  .fontSize((this.compactLandscape ? 18 : 24) * this.scaleFactor)
  .margin({
    top: (this.compactLandscape ? 6 : 12) * this.scaleFactor,
    bottom: (this.compactLandscape ? 4 : 8) * this.scaleFactor
  })

if (!this.compactLandscape) {
  Text(this.isRevealed ? '恭喜中奖！' : '手指刮开涂层看看手气')
    .fontSize(14 * this.scaleFactor)
    .margin({ bottom: 16 * this.scaleFactor })
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `Text('刮刮乐')` | 显示刮刮乐标题 |
| `.fontSize((this.compactLandscape ? 18 : 24) * this.scaleFactor)` | 横屏紧凑模式下标题字体变小 |
| `.margin({` | 开始设置标题外边距 |
| `top: (this.compactLandscape ? 6 : 12) * this.scaleFactor,` | 横屏紧凑模式下减小顶部间距 |
| `bottom: (this.compactLandscape ? 4 : 8) * this.scaleFactor` | 横屏紧凑模式下减小底部间距 |
| `})` | 结束标题边距设置 |
| `if (!this.compactLandscape) {` | 如果不是手机横屏紧凑布局 |
| `Text(this.isRevealed ? '恭喜中奖！' : '手指刮开涂层看看手气')` | 显示副标题 |
| `.fontSize(14 * this.scaleFactor)` | 副标题字体按比例缩放 |
| `.margin({ bottom: 16 * this.scaleFactor })` | 设置副标题底部间距 |
| `}` | 手机横屏紧凑模式下不显示副标题，节省高度 |

### 9. Canvas 容器使用真实绘制尺寸

代码：

```ts
Stack()
  .width(this.screenWidth)
  .height(this.screenHeight) {
  Canvas(this.canvasContext)
    .width(this.screenWidth)
    .height(this.screenHeight)
    .onReady(() => {
      this.updateCanvasSize();
      if (!this.canvasInitialized) {
        this.canvasInitialized = true;
        this.initCard();
      } else {
        this.drawCard();
      }
    })

  Canvas(this.sparkleContext)
    .width(this.screenWidth)
    .height(this.screenHeight)
    .hitTestBehavior(HitTestMode.None)
}
```

逐行解释：

| 代码 | 作用 |
| --- | --- |
| `Stack()` | 创建刮刮卡和粒子层的叠放容器 |
| `.width(this.screenWidth)` | 容器宽度等于计算后的 Canvas 宽度 |
| `.height(this.screenHeight) {` | 容器高度等于计算后的 Canvas 高度 |
| `Canvas(this.canvasContext)` | 创建主 Canvas，用于绘制刮刮卡 |
| `.width(this.screenWidth)` | 主 Canvas 宽度和容器一致 |
| `.height(this.screenHeight)` | 主 Canvas 高度和容器一致 |
| `.onReady(() => {` | Canvas 准备完成后执行 |
| `this.updateCanvasSize();` | 再次确保 Canvas 尺寸是最新值 |
| `if (!this.canvasInitialized) {` | 如果 Canvas 第一次初始化 |
| `this.canvasInitialized = true;` | 标记 Canvas 已初始化 |
| `this.initCard();` | 初始化并绘制第一张刮刮卡 |
| `} else {` | 如果 Canvas 已经初始化过 |
| `this.drawCard();` | 直接按当前尺寸重绘 |
| `}` | 结束初始化判断 |
| `})` | 结束 Canvas ready 回调 |
| `Canvas(this.sparkleContext)` | 创建粒子 Canvas，用于刮擦时的火花效果 |
| `.width(this.screenWidth)` | 粒子 Canvas 宽度和主 Canvas 一致 |
| `.height(this.screenHeight)` | 粒子 Canvas 高度和主 Canvas 一致 |
| `.hitTestBehavior(HitTestMode.None)` | 粒子层不拦截触摸事件 |
| `}` | 结束 Stack 容器 |

这段代码保证了“布局区域”和“绘制坐标区域”一致。之前刮刮卡出屏，就是因为 Canvas 显示区域和绘制区域不是同一套高度。

## 五、不同设备上的显示策略

| 场景 | Tab 位置 | 转盘策略 | 刮刮乐策略 |
| --- | --- | --- | --- |
| 手机竖屏 | 底部 Tab | 扣除底部 Tab 后绘制，GO 居中 | 竖向卡片，扣除标题和底部进度 |
| 手机横屏 | 底部 Tab | 扣除底部 Tab，高度压缩，转盘缩小 | 横向卡片，隐藏副标题，压缩上下间距 |
| 平板竖屏 | 左侧 Tab | 扣除左侧 90vp 后绘制 | 竖向卡片，居中显示 |
| 平板横屏 | 左侧 Tab | 扣除左侧 90vp 后绘制 | 横向/宽屏卡片，内容居中 |

## 六、为什么这样可以解决问题

### 1. 解决底部 Tab 超出屏幕

手机模式下：

```ts
const bottomTabH = isSmallScreen ? (fullW > fullH ? 50 : 64) : 0;
const ch = fullH - bottomTabH;
```

这两行会提前把底部 Tab 的高度扣掉。子页面拿到的 `contentHeight` 已经不是整屏高度，而是真正可用高度。

### 2. 解决 GO 按钮不在转盘中心

转盘中：

```ts
centerX: this.screenWidth / CommonConstants.TWO,
centerY: this.screenHeight / CommonConstants.TWO,
```

同时：

```ts
Stack({ alignContent: Alignment.Center })
.width(this.screenWidth)
.height(this.screenHeight)
```

旋转中心、Canvas 尺寸、Stack 尺寸全部统一，所以 GO 按钮会落在转盘中心。

### 3. 解决手机横屏转盘过大

手机横屏时：

```ts
const bottomTabH: number = smallScreen ? (fullW > fullH ? 50 : 64) : 0;
const h: number = fullH - bottomTabH;
this.screenHeight = Math.max(this.pageLandscape ? 220 : 320, h);
```

这会把横屏手机可用高度压到合理范围，转盘的基准尺寸也会随之变小。

### 4. 解决手机横屏刮刮乐超出屏幕

手机横屏时：

```ts
if (this.compactLandscape) {
  ch = Math.min(this.screenHeight * 0.76, 220);
  cw = Math.min(ch * 2.05, this.screenWidth * 0.78);
}
```

卡片高度被限制，宽度按高度放大，所以显示为横向卡片，不再使用竖屏那种高卡片比例。

## 七、后续维护建议

1. 新增页面时，优先读取 `contentWidth` 和 `contentHeight`，不要直接使用窗口完整宽高。
2. 新增 Canvas 组件时，Canvas 的 `.width()`、`.height()`、绘图 `clearRect()`、中心点计算要使用同一套尺寸。
3. 手机横屏高度很小，尽量隐藏说明性副标题，保留核心交互。
4. 平板布局不要使用底部 Tab 占位，应该通过侧边栏宽度扣除内容区。
5. 所有横竖屏切换都建议监听 `windowSizeChange` 后主动重绘 Canvas。

