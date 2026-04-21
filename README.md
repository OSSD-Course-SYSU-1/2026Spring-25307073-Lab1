# Canvas抽奖转盘项目 - 完整代码功能解析文档

## 目录
1. [项目概述](#项目概述)
2. [项目架构](#项目架构)
3. [核心模块详解](#核心模块详解)
4. [数据模型详解](#数据模型详解)
5. [工具类详解](#工具类详解)
6. [常量配置详解](#常量配置详解)
7. [资源文件详解](#资源文件详解)
8. [功能流程分析](#功能流程分析)

---

## 项目概述

### 项目名称
基于Canvas实现抽奖转盘功能

### 项目简介
本项目是一个基于HarmonyOS平台开发的抽奖转盘应用，使用Canvas画布组件实现自定义绘制抽奖转盘，支持点击抽奖、转盘旋转动画、中奖结果展示等完整功能。

### 技术栈
- **开发平台**: HarmonyOS 5.0.5 Release及以上
- **开发语言**: ArkTS (TypeScript扩展)
- **UI框架**: ArkUI声明式开发范式
- **核心组件**: Canvas画布组件
- **动画**: 显式动画animateTo
- **国际化**: 支持中英文切换

---

## 项目架构

### 目录结构
```
entry/src/main/ets/
├── common/                    # 公共模块
│   ├── constants/            # 常量定义
│   │   ├── ColorConstants.ets      # 颜色常量
│   │   ├── CommonConstants.ets     # 通用常量
│   │   └── StyleConstants.ets      # 样式常量
│   └── utils/                # 工具类
│       ├── CheckEmptyUtils.ets     # 空值检查工具
│       └── Logger.ets              # 日志工具
├── entryability/             # 应用入口
│   └── EntryAbility.ts             # Ability生命周期
├── pages/                    # 页面
│   └── CanvasPage.ets              # 主页面
├── view/                     # 视图组件
│   └── PrizeDialog.ets             # 中奖弹窗
└── viewmodel/                # 数据模型
    ├── DrawModel.ets               # 绘图逻辑
    ├── FillArcData.ets             # 圆弧数据
    └── PrizeData.ets               # 奖品数据
```

### 架构设计模式
项目采用MVVM架构模式：
- **Model**: PrizeData、FillArcData数据模型
- **View**: CanvasPage页面、PrizeDialog弹窗
- **ViewModel**: DrawModel绘图逻辑处理

---

## 核心模块详解

### 1. EntryAbility.ts - 应用入口类

**文件路径**: `entry/src/main/ets/entryability/EntryAbility.ts`

#### 功能说明
EntryAbility是应用的入口类，继承自UIAbility，负责应用的生命周期管理和窗口初始化。

#### 代码详解

##### 1.1 onCreate生命周期
```typescript
onCreate(want, launchParam) {
  hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
}
```
**功能**: 应用创建时调用
**实现方式**: 
- 使用hilog记录应用创建日志
- 参数want包含启动信息，launchParam包含启动参数

##### 1.2 onWindowStageCreate生命周期
```typescript
onWindowStageCreate(windowStage: window.WindowStage) {
  hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
  
  windowStage.loadContent('pages/CanvasPage', (err, data) => {
    if (err.code) {
      hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
      return;
    }
    hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    AppStorage.setOrCreate('uiContext', windowStage.getMainWindowSync().getUIContext());
  });
}
```
**功能**: 窗口阶段创建时加载主页面
**实现步骤**:
1. 记录窗口创建日志
2. 调用windowStage.loadContent加载CanvasPage页面
3. 错误处理：如果加载失败，记录错误日志并返回
4. 成功处理：记录成功日志
5. **关键操作**: 将UIContext存储到AppStorage中，供全局使用
   - `windowStage.getMainWindowSync()` 获取主窗口
   - `getUIContext()` 获取UI上下文
   - `AppStorage.setOrCreate()` 存储到应用全局存储

##### 1.3 其他生命周期方法
- **onDestroy**: 应用销毁时调用
- **onWindowStageDestroy**: 窗口阶段销毁时调用
- **onForeground**: 应用进入前台时调用
- **onBackground**: 应用进入后台时调用

---

### 2. CanvasPage.ets - 主页面

**文件路径**: `entry/src/main/ets/pages/CanvasPage.ets`

#### 功能说明
CanvasPage是应用的主页面，负责展示抽奖转盘、处理用户交互、控制转盘旋转动画、显示中奖结果。

#### 代码详解

##### 2.1 全局上下文获取
```typescript
const uiContext: UIContext | undefined = AppStorage.get('uiContext');
let context: Context = uiContext!.getHostContext()!;
```
**功能**: 获取全局UI上下文和应用上下文
**实现方式**: 
- 从AppStorage获取之前存储的uiContext
- 通过getHostContext()获取宿主上下文，用于访问资源管理器等系统服务

##### 2.2 组件状态定义
```typescript
@Entry
@Component
struct CanvasPage {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  @State drawModel: DrawModel = new DrawModel();
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State rotateDegree: number = 0;
  @State enableFlag: boolean = true;
  @State prizeData: PrizeData = new PrizeData();
  // ...
}
```
**状态变量说明**:
- **settings**: 渲染上下文设置，参数true表示开启抗锯齿
- **canvasContext**: Canvas 2D渲染上下文，用于绑定Canvas组件并执行绘图操作
- **drawModel**: 绘图模型实例，封装所有绘图逻辑
- **screenWidth/screenHeight**: 屏幕宽高，用于自适应布局
- **rotateDegree**: 转盘旋转角度，用于动画控制
- **enableFlag**: 启用标志，控制按钮是否可点击，防止重复抽奖
- **prizeData**: 中奖数据，存储中奖信息

##### 2.3 自定义弹窗控制器
```typescript
dialogController: CustomDialogController = new CustomDialogController({
  builder: PrizeDialog({
    prizeData: $prizeData,
    enableFlag: $enableFlag
  }),
  autoCancel: false,
  alignment: DialogAlignment.Center,
  cancel: () => {
    this.enableFlag = !this.enableFlag;
  }
});
```
**功能**: 创建中奖弹窗控制器
**参数说明**:
- **builder**: 弹窗构建器，使用PrizeDialog组件
- **prizeData/enableFlag**: 使用$语法进行双向绑定
- **autoCancel**: false表示点击遮罩不关闭弹窗
- **alignment**: 弹窗居中显示
- **cancel**: 取消回调，切换enableFlag状态

##### 2.4 语言切换监听
```typescript
private currentLang: string = 'zh-Hans';
private lastLang: string = 'zh-Hans';
private subscriber: commonEventManager.CommonEventSubscriber | null = null;

aboutToAppear() {
  // ... 窗口尺寸获取代码 ...
  
  let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: [commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED]
  };
  commonEventManager.createSubscriber(subscribeInfo)
    .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
      this.subscriber = commonEventSubscriber;
      commonEventManager.subscribe(this.subscriber, (err) => {
        if (err) {
          Logger.error(`Failed to subscribe common event. errorCode=${err.code}, errorMessage=${err.message}`);
          return;
        }
        this.currentLang = i18n.System.getSystemLanguage();
      });
    })
    .catch((err: BusinessError) => {
      Logger.error(`CreateSubscriber failed, errorCode=${err.code}, errorMessage=${err.message}}`);
    })
}
```
**功能**: 监听系统语言切换事件，实现国际化
**实现步骤**:
1. 创建订阅信息，订阅语言变更事件COMMON_EVENT_LOCALE_CHANGED
2. 创建订阅者subscriber
3. 订阅事件，当语言变更时更新currentLang
4. 错误处理：记录订阅失败日志

##### 2.5 窗口尺寸获取
```typescript
aboutToAppear() {
  window.getLastWindow(context)
    .then((windowClass: window.Window) => {
      windowClass.setWindowLayoutFullScreen(true);
      let windowProperties = windowClass.getWindowProperties();
      this.screenWidth = this.getUIContext().px2vp(windowProperties.windowRect.width);
      this.screenHeight = this.getUIContext().px2vp(windowProperties.windowRect.height);
    })
    .catch((error: Error) => {
      Logger.error('Failed to obtain the window size. Cause: ' + JSON.stringify(error));
    })
}
```
**功能**: 获取屏幕尺寸并设置全屏显示
**实现步骤**:
1. 获取最后一个窗口实例
2. 设置窗口全屏显示setWindowLayoutFullScreen(true)
3. 获取窗口属性
4. 将像素值转换为vp单位（px2vp）
5. 存储屏幕宽高到状态变量

##### 2.6 页面显示与隐藏
```typescript
onPageShow(): void {
  if (this.lastLang != this.currentLang) {
    this.drawModel.draw(this.canvasContext, this.screenWidth, this.screenHeight);
  }
}

onPageHide(): void {
  this.lastLang = i18n.System.getSystemLanguage();
}
```
**功能**: 处理页面显示隐藏时的语言切换
**实现逻辑**:
- onPageShow: 如果语言发生变化，重新绘制转盘（更新文本）
- onPageHide: 记录当前语言，用于下次比较

##### 2.7 组件销毁
```typescript
aboutToDisappear(): void {
  if (this.subscriber) {
    commonEventManager.unsubscribe(this.subscriber, (err: BusinessError) => {
      if (!err) {
        this.subscriber = null;
      }
    })
  }
}
```
**功能**: 组件销毁时取消事件订阅，防止内存泄漏

##### 2.8 UI构建
```typescript
build() {
  Stack({ alignContent: Alignment.Center }) {
    Canvas(this.canvasContext)
      .width(StyleConstants.FULL_PERCENT)
      .height(StyleConstants.FULL_PERCENT)
      .onReady(() => {
        this.drawModel.draw(this.canvasContext, this.screenWidth, this.screenHeight);
      })
      .rotate({
        x: 0,
        y: 0,
        z: 1,
        angle: this.rotateDegree,
        centerX: this.screenWidth / CommonConstants.TWO,
        centerY: this.screenHeight / CommonConstants.TWO
      })

    Image($r('app.media.ic_center'))
      .width(StyleConstants.CENTER_IMAGE_WIDTH)
      .height(StyleConstants.CENTER_IMAGE_HEIGHT)
      .enabled(this.enableFlag)
      .onClick(() => {
        this.enableFlag = !this.enableFlag;
        this.startAnimator();
      })
  }
  .width(StyleConstants.FULL_PERCENT)
  .height(StyleConstants.FULL_PERCENT)
  .backgroundImage($r('app.media.ic_background'), ImageRepeat.NoRepeat)
  .backgroundImageSize({
    width: StyleConstants.FULL_PERCENT,
    height: StyleConstants.BACKGROUND_IMAGE_SIZE
  })
}
```
**UI结构说明**:
1. **Stack容器**: 堆叠布局，子组件居中对齐
2. **Canvas组件**: 
   - 绑定canvasContext渲染上下文
   - 设置宽高为100%
   - onReady回调：Canvas准备就绪时绘制转盘
   - rotate属性：根据rotateDegree旋转转盘
3. **中心图片**: 
   - 显示"开始"按钮图片
   - enabled绑定enableFlag，控制是否可点击
   - onClick：点击时禁用按钮并启动动画
4. **Stack背景**: 设置背景图片

##### 2.9 启动动画
```typescript
startAnimator() {
  let randomAngle = Math.round(Math.random() * CommonConstants.CIRCLE);
  this.prizeData = this.drawModel.showPrizeData(randomAngle);

  this.getUIContext().animateTo({
    duration: CommonConstants.DURATION,
    curve: Curve.Ease,
    delay: 0,
    iterations: 1,
    playMode: PlayMode.Normal,
    onFinish: () => {
      this.rotateDegree = CommonConstants.ANGLE - randomAngle;
      this.dialogController.open();
    }
  }, () => {
    this.rotateDegree = CommonConstants.CIRCLE * CommonConstants.FIVE +
    CommonConstants.ANGLE - randomAngle;
  })
}
```
**功能**: 启动转盘旋转动画
**实现步骤**:
1. **生成随机角度**: Math.random() * 360，决定中奖结果
2. **获取中奖数据**: 调用drawModel.showPrizeData()根据角度获取奖品信息
3. **启动显式动画**:
   - duration: 4000ms动画时长
   - curve: Ease缓动曲线
   - iterations: 1次播放
   - playMode: Normal正常播放
   - onFinish: 动画结束回调
4. **动画闭包**: 
   - 计算旋转角度：5圈(1800度) + 270度 - 随机角度
   - 实现转盘旋转5圈后停在指定位置
5. **动画结束**:
   - 设置最终角度
   - 打开中奖弹窗

---

### 3. DrawModel.ets - 绘图逻辑类

**文件路径**: `entry/src/main/ets/viewmodel/DrawModel.ets`

#### 功能说明
DrawModel是核心绘图类，封装了所有Canvas绑定的绘图逻辑，负责绘制转盘的各个组成部分。

#### 代码详解

##### 3.1 类属性定义
```typescript
export default class DrawModel {
  private startAngle: number = 0;
  private avgAngle: number = CommonConstants.CIRCLE / CommonConstants.COUNT;
  private screenWidth: number = 0;
  private canvasContext?: CanvasRenderingContext2D;
}
```
**属性说明**:
- **startAngle**: 起始角度，用于绘制扇形
- **avgAngle**: 平均角度，360度/6个扇区 = 60度
- **screenWidth**: 屏幕宽度，用于计算比例
- **canvasContext**: Canvas渲染上下文

##### 3.2 主绘制方法
```typescript
draw(canvasContext: CanvasRenderingContext2D, screenWidth: number, screenHeight: number) {
  if (CheckEmptyUtils.isEmptyObj(canvasContext)) {
    Logger.error('[DrawModel][draw] canvasContext is empty.');
    return;
  }
  this.canvasContext = canvasContext;
  this.screenWidth = screenWidth;
  
  // 清空画布
  this.canvasContext.clearRect(0, 0, this.screenWidth, screenHeight);
  
  // 平移坐标系到中心
  this.canvasContext.translate(this.screenWidth / CommonConstants.TWO,
    screenHeight / CommonConstants.TWO);
  
  // 绘制各部分
  this.drawFlower();        // 绘制外圈花瓣
  this.drawOutCircle();     // 绘制外圈和小圆点
  this.drawInnerCircle();   // 绘制内圈
  this.drawInnerArc();      // 绘制扇形抽奖区
  this.drawArcText();       // 绘制扇形文字
  this.drawImage();         // 绘制奖品图片
  
  // 恢复坐标系
  this.canvasContext.translate(-this.screenWidth / CommonConstants.TWO,
    -screenHeight / CommonConstants.TWO);
}
```
**绘制流程**:
1. **参数校验**: 检查canvasContext是否为空
2. **清空画布**: clearRect清除之前的内容
3. **坐标系变换**: translate将原点移到屏幕中心，便于绘制
4. **分层绘制**: 按照从外到内的顺序绘制各层
5. **恢复坐标系**: 平移回原点

##### 3.3 绘制圆弧方法
```typescript
fillArc(fillArcData: FillArcData, fillColor: string) {
  if (CheckEmptyUtils.isEmptyObj(fillArcData) || CheckEmptyUtils.isEmptyStr(fillColor)) {
    Logger.error('[DrawModel][fillArc] fillArcData or fillColor is empty.');
    return;
  }
  if (this.canvasContext !== undefined) {
    this.canvasContext.beginPath();
    this.canvasContext.fillStyle = fillColor;
    this.canvasContext.arc(fillArcData.x, fillArcData.y, fillArcData.radius,
      fillArcData.startAngle, fillArcData.endAngle);
    this.canvasContext.fill();
  }
}
```
**功能**: 绘制填充圆弧
**实现步骤**:
1. 参数校验
2. beginPath开始新路径
3. 设置填充颜色
4. arc绘制圆弧
5. fill填充

##### 3.4 绘制外圈花瓣
```typescript
drawFlower() {
  let beginAngle = this.startAngle + this.avgAngle;
  const pointY = this.screenWidth * CommonConstants.FLOWER_POINT_Y_RATIOS;
  const radius = this.screenWidth * CommonConstants.FLOWER_RADIUS_RATIOS;
  const innerRadius = this.screenWidth * CommonConstants.FLOWER_INNER_RATIOS;
  
  for (let i = 0; i < CommonConstants.COUNT; i++) {
    this.canvasContext?.save();
    this.canvasContext?.rotate(beginAngle * Math.PI / CommonConstants.HALF_CIRCLE);
    
    // 绘制外花瓣
    this.fillArc(new FillArcData(0, -pointY, radius, 0, Math.PI * CommonConstants.TWO),
      ColorConstants.FLOWER_OUT_COLOR);
    
    // 绘制内花瓣
    this.fillArc(new FillArcData(0, -pointY, innerRadius, 0, Math.PI * CommonConstants.TWO),
      ColorConstants.FLOWER_INNER_COLOR);
    
    beginAngle += this.avgAngle;
    this.canvasContext?.restore();
  }
}
```
**功能**: 绘制转盘外圈的装饰花瓣
**实现步骤**:
1. 计算花瓣位置参数（基于屏幕宽度的比例）
2. 循环6次，每次绘制一个花瓣
3. save保存当前状态
4. rotate旋转坐标系到指定角度
5. 绘制外层花瓣（橙色）
6. 绘制内层花瓣（黄色）
7. restore恢复状态

##### 3.5 绘制外圈和小圆点
```typescript
drawOutCircle() {
  // 绘制外圈
  this.fillArc(new FillArcData(0, 0, this.screenWidth * CommonConstants.OUT_CIRCLE_RATIOS, 0,
    Math.PI * CommonConstants.TWO), ColorConstants.OUT_CIRCLE_COLOR);

  let beginAngle = this.startAngle;
  // 绘制小圆点
  for (let i = 0; i < CommonConstants.SMALL_CIRCLE_COUNT; i++) {
    this.canvasContext?.save();
    this.canvasContext?.rotate(beginAngle * Math.PI / CommonConstants.HALF_CIRCLE);
    this.fillArc(new FillArcData(this.screenWidth * CommonConstants.SMALL_CIRCLE_RATIOS, 0,
      CommonConstants.SMALL_CIRCLE_RADIUS, 0, Math.PI * CommonConstants.TWO),
      ColorConstants.WHITE_COLOR);
    beginAngle = beginAngle + CommonConstants.CIRCLE / CommonConstants.SMALL_CIRCLE_COUNT;
    this.canvasContext?.restore();
  }
}
```
**功能**: 绘制转盘外圈和装饰小圆点
**实现步骤**:
1. 绘制外圈大圆（黄色）
2. 循环8次，绘制8个小圆点
3. 每个小圆点间隔45度（360/8）
4. 小圆点为白色，半径4.1

##### 3.6 绘制内圈
```typescript
drawInnerCircle() {
  // 绘制内圈底色
  this.fillArc(new FillArcData(0, 0, this.screenWidth * CommonConstants.INNER_CIRCLE_RATIOS, 0,
    Math.PI * CommonConstants.TWO), ColorConstants.INNER_CIRCLE_COLOR);
  
  // 绘制内圈白色
  this.fillArc(new FillArcData(0, 0, this.screenWidth * CommonConstants.INNER_WHITE_CIRCLE_RATIOS, 0,
    Math.PI * CommonConstants.TWO), ColorConstants.WHITE_COLOR);
}
```
**功能**: 绘制转盘内圈（中心圆盘）

##### 3.7 绘制扇形抽奖区
```typescript
drawInnerArc() {
  let colors = [
    ColorConstants.ARC_PINK_COLOR, ColorConstants.ARC_YELLOW_COLOR,
    ColorConstants.ARC_GREEN_COLOR, ColorConstants.ARC_PINK_COLOR,
    ColorConstants.ARC_YELLOW_COLOR, ColorConstants.ARC_GREEN_COLOR
  ];
  let radius = this.screenWidth * CommonConstants.INNER_ARC_RATIOS;
  
  for (let i = 0; i < CommonConstants.COUNT; i++) {
    this.fillArc(new FillArcData(0, 0, radius, 
      this.startAngle * Math.PI / CommonConstants.HALF_CIRCLE,
      (this.startAngle + this.avgAngle) * Math.PI / CommonConstants.HALF_CIRCLE), 
      colors[i]);
    this.canvasContext?.lineTo(0, 0);
    this.canvasContext?.fill();
    this.startAngle += this.avgAngle;
  }
}
```
**功能**: 绘制6个扇形抽奖区域
**实现步骤**:
1. 定义颜色数组（粉、黄、绿交替）
2. 循环6次，每次绘制一个扇形
3. 使用fillArc绘制扇形
4. lineTo(0,0)连接到中心点，形成扇形
5. fill填充

##### 3.8 绘制扇形文字
```typescript
drawArcText() {
  if (this.canvasContext !== undefined) {
    this.canvasContext.textAlign = CommonConstants.TEXT_ALIGN;
    this.canvasContext.textBaseline = CommonConstants.TEXT_BASE_LINE;
    this.canvasContext.fillStyle = ColorConstants.TEXT_COLOR;
    this.canvasContext.font = StyleConstants.ARC_TEXT_SIZE + CommonConstants.CANVAS_FONT;
  }
  
  let textArrays = [
    $r('app.string.text_smile'),
    $r('app.string.text_hamburger'),
    $r('app.string.text_cake'),
    $r('app.string.text_smile'),
    $r('app.string.text_hamburger'),
    $r('app.string.text_watermelon')
  ];
  
  let arcTextStartAngle = CommonConstants.ARC_START_ANGLE;
  let arcTextEndAngle = CommonConstants.ARC_END_ANGLE;
  
  for (let i = 0; i < CommonConstants.COUNT; i++) {
    this.drawCircularText(this.getResourceString(textArrays[i]),
      (this.startAngle + arcTextStartAngle) * Math.PI / CommonConstants.HALF_CIRCLE,
      (this.startAngle + arcTextEndAngle) * Math.PI / CommonConstants.HALF_CIRCLE);
    this.startAngle += this.avgAngle;
  }
}
```
**功能**: 在扇形区域绘制弧形文字
**实现步骤**:
1. 设置文本样式（对齐、基线、颜色、字体）
2. 定义文字资源数组（支持国际化）
3. 循环6次，在每个扇形绘制弧形文字
4. 调用drawCircularText绘制弧形文字

##### 3.9 获取资源字符串
```typescript
getResourceString(resource: Resource): string {
  if (CheckEmptyUtils.isEmptyObj(resource)) {
    Logger.error('[DrawModel][getResourceString] resource is empty.')
    return '';
  }
  let resourceString: string = '';
  try {
    resourceString = uiContext!.getHostContext()!.resourceManager.getStringSync(resource.id);
  } catch (error) {
    Logger.error(`[DrawModel][getResourceString]getStringSync failed, error : ${JSON.stringify(error)}.`);
  }
  return resourceString;
}
```
**功能**: 根据资源ID获取字符串（支持国际化）
**实现方式**: 使用resourceManager.getStringSync同步获取字符串资源

##### 3.10 绘制弧形文字
```typescript
drawCircularText(textString: string, startAngle: number, endAngle: number) {
  if (CheckEmptyUtils.isEmptyStr(textString)) {
    Logger.error('[DrawModel][drawCircularText] textString is empty.')
    return;
  }

  class CircleText {
    x: number = 0;
    y: number = 0;
    radius: number = 0;
  }

  let circleText: CircleText = {
    x: 0,
    y: 0,
    radius: this.screenWidth * CommonConstants.INNER_ARC_RATIOS
  };
  
  let radius = circleText.radius - circleText.radius / CommonConstants.COUNT;
  let angleDecrement = (startAngle - endAngle) / (textString.length - 1);
  let angle = startAngle;
  let index = 0;
  let character: string;

  while (index < textString.length) {
    character = textString.charAt(index);
    this.canvasContext?.save();
    this.canvasContext?.beginPath();
    this.canvasContext?.translate(circleText.x + Math.cos(angle) * radius,
      circleText.y - Math.sin(angle) * radius);
    this.canvasContext?.rotate(Math.PI / CommonConstants.TWO - angle);
    this.canvasContext?.fillText(character, 0, 0);
    angle -= angleDecrement;
    index++;
    this.canvasContext?.restore();
  }
}
```
**功能**: 绘制沿圆弧排列的文字
**实现原理**:
1. 计算每个字符占据的角度
2. 循环每个字符：
   - 计算字符位置（使用三角函数）
   - 平移到该位置
   - 旋转字符使其沿圆弧方向
   - 绘制字符
3. 实现文字沿圆弧排列效果

##### 3.11 绘制奖品图片
```typescript
drawImage() {
  let beginAngle = this.startAngle;
  let imageSrc = [
    CommonConstants.WATERMELON_IMAGE_URL, CommonConstants.HAMBURG_IMAGE_URL,
    CommonConstants.SMILE_IMAGE_URL, CommonConstants.CAKE_IMAGE_URL,
    CommonConstants.HAMBURG_IMAGE_URL, CommonConstants.SMILE_IMAGE_URL
  ];
  
  for (let i = 0; i < CommonConstants.COUNT; i++) {
    let image = new ImageBitmap(imageSrc[i]);
    this.canvasContext?.save();
    this.canvasContext?.rotate(beginAngle * Math.PI / CommonConstants.HALF_CIRCLE);
    this.canvasContext?.drawImage(image, 
      this.screenWidth * CommonConstants.IMAGE_DX_RATIOS,
      this.screenWidth * CommonConstants.IMAGE_DY_RATIOS, 
      CommonConstants.IMAGE_SIZE,
      CommonConstants.IMAGE_SIZE);
    beginAngle += this.avgAngle;
    this.canvasContext?.restore();
  }
}
```
**功能**: 在每个扇形区域绘制奖品图片
**实现步骤**:
1. 定义图片路径数组
2. 循环6次，每次：
   - 创建ImageBitmap对象
   - 旋转坐标系到对应扇形
   - drawImage绘制图片
   - 恢复坐标系

##### 3.12 显示中奖数据
```typescript
showPrizeData(randomAngle: number): PrizeData {
  for (let i = 1; i <= CommonConstants.COUNT; i++) {
    if (randomAngle <= i * this.avgAngle) {
      return this.getPrizeData(i);
    }
  }
  return new PrizeData();
}
```
**功能**: 根据随机角度确定中奖奖品
**实现逻辑**: 
- 遍历6个扇区
- 判断随机角度落在哪个扇区
- 返回对应的奖品数据

##### 3.13 获取奖品数据
```typescript
getPrizeData(scopeNum: number): PrizeData {
  let prizeData: PrizeData = new PrizeData();
  switch (scopeNum) {
    case EnumeratedValue.ONE:
      prizeData.message = $r('app.string.prize_text_watermelon');
      prizeData.imageSrc = CommonConstants.WATERMELON_IMAGE_URL;
      break;
    case EnumeratedValue.THREE:
      prizeData.message = $r('app.string.prize_text_smile');
      prizeData.imageSrc = CommonConstants.SMILE_IMAGE_URL;
      break;
    case EnumeratedValue.FOUR:
      prizeData.message = $r('app.string.prize_text_cake');
      prizeData.imageSrc = CommonConstants.CAKE_IMAGE_URL;
      break;
    case EnumeratedValue.TWO:
    case EnumeratedValue.FIVE:
      prizeData.message = $r('app.string.prize_text_hamburger');
      prizeData.imageSrc = CommonConstants.HAMBURG_IMAGE_URL;
      break;
    case EnumeratedValue.SIX:
      prizeData.message = $r('app.string.prize_text_smile');
      prizeData.imageSrc = CommonConstants.SMILE_IMAGE_URL;
      break;
    default:
      break;
  }
  return prizeData;
}
```
**功能**: 根据扇区编号获取具体奖品信息
**奖品对应关系**:
- 扇区1: 西瓜
- 扇区2: 汉堡
- 扇区3: 笑脸
- 扇区4: 蛋糕
- 扇区5: 汉堡
- 扇区6: 笑脸

---

### 4. PrizeDialog.ets - 中奖弹窗

**文件路径**: `entry/src/main/ets/view/PrizeDialog.ets`

#### 功能说明
PrizeDialog是自定义弹窗组件，用于展示中奖结果。

#### 代码详解

##### 4.1 组件定义
```typescript
@CustomDialog
export default struct PrizeDialog {
  @Link prizeData: PrizeData;
  @Link enableFlag: boolean;
  private controller?: CustomDialogController;
}
```
**装饰器说明**:
- **@CustomDialog**: 标记为自定义弹窗组件
- **@Link**: 双向绑定父组件数据
- **controller**: 弹窗控制器，用于关闭弹窗

##### 4.2 UI构建
```typescript
build() {
  Column() {
    // 奖品图片
    Image(this.prizeData.imageSrc !== undefined ? this.prizeData.imageSrc : '')
      .width($r('app.float.dialog_image_size'))
      .height($r('app.float.dialog_image_size'))
      .margin({
        top: $r('app.float.dialog_image_top'),
        bottom: $r('app.float.dialog_image_bottom')
      })
      .rotate({
        x: 0,
        y: 0,
        z: 1,
        angle: CommonConstants.TRANSFORM_ANGLE
      })

    // 奖品文字
    Text(this.prizeData.message)
      .fontSize($r('app.float.dialog_font_size'))
      .textAlign(TextAlign.Center)
      .margin({ bottom: $r('app.float.dialog_message_bottom') })

    // 确认按钮
    Text($r('app.string.text_confirm'))
      .fontColor($r('app.color.text_font_color'))
      .fontWeight(StyleConstants.FONT_WEIGHT)
      .fontSize($r('app.float.dialog_font_size'))
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.controller?.close();
        this.enableFlag = !this.enableFlag;
      })
  }
  .backgroundColor($r('app.color.dialog_background'))
  .width(StyleConstants.FULL_PERCENT)
  .height($r('app.float.dialog_height'))
}
```
**UI结构**:
1. **Column容器**: 垂直布局
2. **奖品图片**: 
   - 显示中奖奖品图片
   - 旋转-120度（装饰效果）
3. **奖品文字**: 显示中奖信息
4. **确认按钮**: 
   - 点击关闭弹窗
   - 恢复按钮可点击状态

---

## 数据模型详解

### 1. PrizeData.ets - 奖品数据模型

**文件路径**: `entry/src/main/ets/viewmodel/PrizeData.ets`

```typescript
export default class PrizeData {
  message?: Resource;    // 奖品消息（支持国际化）
  imageSrc?: string;     // 奖品图片路径
}
```
**功能**: 存储中奖奖品信息
**属性说明**:
- **message**: 奖品描述文字，类型为Resource支持多语言
- **imageSrc**: 奖品图片路径

---

### 2. FillArcData.ets - 圆弧数据模型

**文件路径**: `entry/src/main/ets/viewmodel/FillArcData.ets`

```typescript
export default class FillArcData {
  x: number;           // 圆心X坐标
  y: number;           // 圆心Y坐标
  radius: number;      // 半径
  startAngle: number;  // 起始角度（弧度）
  endAngle: number;    // 结束角度（弧度）

  constructor(x: number, y: number, radius: number, startAngle: number, endAngle: number) {
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.startAngle = startAngle;
    this.endAngle = endAngle;
  }
}
```
**功能**: 封装绘制圆弧所需的数据
**使用场景**: 在DrawModel的fillArc方法中使用

---

## 工具类详解

### 1. Logger.ets - 日志工具类

**文件路径**: `entry/src/main/ets/common/utils/Logger.ets`

```typescript
class Logger {
  private domain: number;
  private prefix: string;
  private format: string = '%{public}s, %{public}s';

  constructor(prefix: string = 'MyApp', domain: number = 0xFF00) {
    this.prefix = prefix;
    this.domain = domain;
  }

  debug(...args: string[]): void {
    hilog.debug(this.domain, this.prefix, this.format, args);
  }

  info(...args: string[]): void {
    hilog.info(this.domain, this.prefix, this.format, args);
  }

  warn(...args: string[]): void {
    hilog.warn(this.domain, this.prefix, this.format, args);
  }

  error(...args: string[]): void {
    hilog.error(this.domain, this.prefix, this.format, args);
  }
}

export default new Logger('[CanvasComponent]', 0xFF00)
```
**功能**: 封装hilog日志接口
**实现方式**:
- 使用单例模式，导出一个预配置的Logger实例
- prefix设置为'[CanvasComponent]'
- domain设置为0xFF00
- 提供debug、info、warn、error四个日志级别

---

### 2. CheckEmptyUtils.ets - 空值检查工具类

**文件路径**: `entry/src/main/ets/common/utils/CheckEmptyUtils.ets`

```typescript
class CheckEmptyUtils {
  isEmptyObj(obj: object | string) {
    return (typeof obj === 'undefined' || obj === null || obj === '');
  }

  isEmptyStr(str: string) {
    return str.trim().length === 0;
  }

  isEmptyArr(arr: Array<string>) {
    return arr.length === 0;
  }
}

export default new CheckEmptyUtils();
```
**功能**: 提供数据空值检查方法
**方法说明**:
- **isEmptyObj**: 检查对象是否为空（undefined、null、空字符串）
- **isEmptyStr**: 检查字符串是否为空（去除空格后长度为0）
- **isEmptyArr**: 检查数组是否为空

---

## 常量配置详解

### 1. CommonConstants.ets - 通用常量类

**文件路径**: `entry/src/main/ets/common/constants/CommonConstants.ets`

#### 图片路径常量
```typescript
static readonly WATERMELON_IMAGE_URL: string = 'resources/base/media/ic_watermelon.png';
static readonly HAMBURG_IMAGE_URL: string = 'resources/base/media/ic_hamburg.png';
static readonly CAKE_IMAGE_URL: string = 'resources/base/media/ic_cake.png';
static readonly SMILE_IMAGE_URL: string = 'resources/base/media/ic_smile.png';
```

#### 角度与数量常量
```typescript
static readonly CIRCLE: number = 360;              // 圆周角度
static readonly HALF_CIRCLE: number = 180;         // 半圆角度
static readonly COUNT: number = 6;                 // 扇区数量
static readonly SMALL_CIRCLE_COUNT: number = 8;    // 小圆点数量
static readonly ANGLE: number = 270;               // 奖品角度基准
static readonly DURATION: number = 4000;           // 动画时长(ms)
```

#### 比例常量（用于自适应布局）
```typescript
static readonly FLOWER_POINT_Y_RATIOS: number = 0.255;      // 花瓣Y坐标比例
static readonly FLOWER_RADIUS_RATIOS: number = 0.217;       // 花瓣外半径比例
static readonly FLOWER_INNER_RATIOS: number = 0.193;        // 花瓣内半径比例
static readonly OUT_CIRCLE_RATIOS: number = 0.4;            // 外圈半径比例
static readonly SMALL_CIRCLE_RATIOS: number = 0.378;        // 小圆点位置比例
static readonly SMALL_CIRCLE_RADIUS: number = 4.1;          // 小圆点半径
static readonly INNER_CIRCLE_RATIOS: number = 0.356;        // 内圈半径比例
static readonly INNER_WHITE_CIRCLE_RATIOS: number = 0.339;  // 内圈白色半径比例
static readonly INNER_ARC_RATIOS: number = 0.336;           // 扇形半径比例
static readonly IMAGE_DX_RATIOS: number = 0.114;            // 图片X偏移比例
static readonly IMAGE_DY_RATIOS: number = 0.052;            // 图片Y偏移比例
```

#### 文本样式常量
```typescript
static readonly TEXT_ALIGN: CanvasTextAlign = 'center';
static readonly TEXT_BASE_LINE: CanvasTextBaseline = 'middle';
static readonly CANVAS_FONT: string = 'px sans-serif';
```

#### 枚举值
```typescript
export enum EnumeratedValue {
  ONE = 1,
  TWO = 2,
  THREE = 3,
  FOUR = 4,
  FIVE = 5,
  SIX = 6
}
```

---

### 2. ColorConstants.ets - 颜色常量类

**文件路径**: `entry/src/main/ets/common/constants/ColorConstants.ets`

```typescript
export default class ColorConstants {
  static readonly FLOWER_OUT_COLOR: string = '#ED6E21';      // 花瓣外层颜色（橙色）
  static readonly FLOWER_INNER_COLOR: string = '#F8A01E';    // 花瓣内层颜色（黄色）
  static readonly OUT_CIRCLE_COLOR: string = '#F7CD03';      // 外圈颜色（亮黄色）
  static readonly WHITE_COLOR: string = '#FFFFFF';           // 白色
  static readonly INNER_CIRCLE_COLOR: string = '#F8A01E';    // 内圈颜色（黄色）
  static readonly ARC_PINK_COLOR: string = '#FFC6BD';        // 扇形粉色
  static readonly ARC_YELLOW_COLOR: string = '#FFEC90';      // 扇形黄色
  static readonly ARC_GREEN_COLOR: string = '#ECF9C7'        // 扇形绿色
  static readonly TEXT_COLOR: string = '#ED6E21';            // 文字颜色（橙色）
}
```

---

### 3. StyleConstants.ets - 样式常量类

**文件路径**: `entry/src/main/ets/common/constants/StyleConstants.ets`

```typescript
const uiContext: UIContext | undefined = AppStorage.get('uiContext');

export default class StyleConstants {
  static readonly FONT_WEIGHT: number = 500;                      // 字体粗细
  static readonly FULL_PERCENT: string = '100%';                  // 百分之百
  static readonly BACKGROUND_IMAGE_SIZE: string = '38.7%';        // 背景图片高度
  static readonly CENTER_IMAGE_WIDTH: string = '19.3%';           // 中心图片宽度
  static readonly CENTER_IMAGE_HEIGHT: string = '10.6%';          // 中心图片高度
  static readonly ARC_TEXT_SIZE: number = uiContext!.fp2px(14);   // 弧形文字大小（fp转px）
}
```

---

## 资源文件详解

### 1. 字符串资源

#### base/element/string.json（默认）
```json
{
  "string": [
    { "name": "text_smile", "value": "Smile" },
    { "name": "text_hamburger", "value": "Hamburger" },
    { "name": "text_cake", "value": "Cake" },
    { "name": "text_watermelon", "value": "Watermelon" },
    { "name": "prize_text_watermelon", "value": "Congratulations on winning the watermelon" },
    { "name": "prize_text_smile", "value": "Congratulations on winning the smile" },
    { "name": "prize_text_cake", "value": "Congratulations on winning the cake" },
    { "name": "prize_text_hamburger", "value": "Congratulations on winning the hamburger" },
    { "name": "text_confirm", "value": "Confirm" }
  ]
}
```

#### zh_CN/element/string.json（中文）
```json
{
  "string": [
    { "name": "text_smile", "value": "笑脸" },
    { "name": "text_hamburger", "value": "汉堡" },
    { "name": "text_cake", "value": "蛋糕" },
    { "name": "text_watermelon", "value": "西瓜" },
    { "name": "prize_text_watermelon", "value": "恭喜中奖西瓜" },
    { "name": "prize_text_smile", "value": "恭喜中奖笑脸" },
    { "name": "prize_text_cake", "value": "恭喜中奖蛋糕" },
    { "name": "prize_text_hamburger", "value": "恭喜中奖汉堡" },
    { "name": "text_confirm", "value": "确认" }
  ]
}
```

### 2. 图片资源
- **ic_background.png**: 背景图片
- **ic_center.png**: 中心"开始"按钮图片
- **ic_cake.png**: 蛋糕奖品图片
- **ic_hamburg.png**: 汉堡奖品图片
- **ic_smile.png**: 笑脸奖品图片
- **ic_watermelon.png**: 西瓜奖品图片

---

## 功能流程分析

### 1. 应用启动流程
```
EntryAbility.onCreate()
    ↓
EntryAbility.onWindowStageCreate()
    ↓
windowStage.loadContent('pages/CanvasPage')
    ↓
AppStorage.setOrCreate('uiContext', ...)
    ↓
CanvasPage.aboutToAppear()
    ↓
获取屏幕尺寸
    ↓
订阅语言切换事件
    ↓
CanvasPage.build()
    ↓
Canvas.onReady()
    ↓
DrawModel.draw() 绘制转盘
```

### 2. 抽奖流程
```
用户点击中心按钮
    ↓
enableFlag = false（禁用按钮）
    ↓
startAnimator()
    ↓
生成随机角度 randomAngle
    ↓
获取中奖数据 prizeData
    ↓
启动动画 animateTo
    ↓
转盘旋转5圈 + 停止角度
    ↓
动画结束 onFinish
    ↓
打开中奖弹窗 dialogController.open()
    ↓
用户点击确认
    ↓
关闭弹窗
    ↓
enableFlag = true（恢复按钮）
```

### 3. 绘制流程
```
DrawModel.draw()
    ↓
清空画布 clearRect
    ↓
平移坐标系到中心 translate
    ↓
绘制外圈花瓣 drawFlower
    ↓
绘制外圈和小圆点 drawOutCircle
    ↓
绘制内圈 drawInnerCircle
    ↓
绘制扇形抽奖区 drawInnerArc
    ↓
绘制扇形文字 drawArcText
    ↓
绘制奖品图片 drawImage
    ↓
恢复坐标系 translate
```

### 4. 国际化流程
```
系统语言切换
    ↓
触发 COMMON_EVENT_LOCALE_CHANGED 事件
    ↓
更新 currentLang
    ↓
onPageShow 检测语言变化
    ↓
重新绘制转盘（更新文字）
```

---

## 技术亮点

### 1. Canvas自定义绘图
- 使用CanvasRenderingContext2D进行自定义绘制
- 分层绘制，从外到内依次绘制各层
- 使用坐标系变换（translate、rotate）简化绘制逻辑

### 2. 弧形文字绘制
- 通过三角函数计算每个字符的位置
- 旋转字符使其沿圆弧方向排列
- 实现美观的弧形文字效果

### 3. 显式动画
- 使用animateTo实现转盘旋转动画
- 支持自定义时长、缓动曲线、播放模式
- 通过闭包修改状态驱动动画

### 4. 自适应布局
- 所有尺寸使用屏幕宽度的比例计算
- 支持不同屏幕尺寸的自适应
- 使用px2vp、fp2px进行单位转换

### 5. 国际化支持
- 使用Resource类型引用字符串资源
- 监听系统语言切换事件
- 动态更新界面文字

### 6. 状态管理
- 使用@State、@Link进行状态管理
- 双向绑定实现父子组件通信
- 状态驱动UI更新

---

## 总结

本项目是一个完整的HarmonyOS应用示例，展示了以下技术要点：

1. **Canvas自定义绘图**: 使用Canvas组件绘制复杂的抽奖转盘
2. **动画系统**: 使用显式动画实现流畅的转盘旋转效果
3. **自定义弹窗**: 使用CustomDialogController实现中奖结果展示
4. **国际化**: 支持中英文切换，动态更新界面
5. **状态管理**: 使用ArkUI的状态管理机制实现数据驱动
6. **自适应布局**: 使用比例计算实现不同屏幕尺寸的适配

项目代码结构清晰，分层合理，是学习HarmonyOS应用开发的优秀示例。
