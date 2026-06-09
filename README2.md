# Canvas抽奖应用 - 新增功能完整代码解析文档

## 目录
1. [新增功能概览](#新增功能概览)
2. [刮刮乐 (ScratchCardView)](#1-刮刮乐-scratchcardviewets)
3. [抽奖记录 (HistoryView)](#2-抽奖记录-historyviewets)
4. [彩纸庆祝动画 (ConfettiEffect)](#3-彩纸庆祝动画-confettieffectets)
5. [星空粒子背景 (StarParticle)](#4-星空粒子背景-starparticleets)
6. [转盘改进 (WheelView)](#5-转盘改进-wheelviewets)
7. [中奖弹窗改进 (PrizeDialog)](#6-中奖弹窗改进-prizedialogets)
8. [绘图逻辑改进 (DrawModel)](#7-绘图逻辑改进-drawmodelets)
9. [主页面改进 (CanvasPage)](#8-主页面改进-canvaspageets)
10. [常量配置改进](#9-常量配置改进)
11. [功能流程分析](#10-功能流程分析)

---

## 新增功能概览

### 与第一版相比新增的功能

| 功能 | 文件 | 说明 |
|------|------|------|
| 🎫 **刮刮乐** | `ScratchCardView.ets` | 手指在涂层上滑动刮开，露出下方奖品，支持连续刮卡 |
| 📊 **抽奖记录** | `HistoryView.ets` | 自动记录每次抽奖结果，统计中奖率，按时间倒序展示 |
| 🎊 **彩纸庆祝** | `ConfettiEffect.ets` | 中奖时全屏飘落彩色粒子（圆形+矩形），增强仪式感 |
| ⭐ **星空粒子** | `StarParticle.ets` | 页面背景动态闪烁的星星，营造沉浸氛围 |
| 🎡 **转盘增强** | `WheelView.ets` | 新增连抽模式（3/5连抽）、按钮呼吸动效、语言切换监听 |
| 🏆 **弹窗升级** | `PrizeDialog.ets` | Emoji替代图片、入场缩放淡入动画 |
| 🎨 **绘图升级** | `DrawModel.ets` | 径向渐变扇区、金色装饰环、外圈辉光、内圈光晕、emoji绘制 |
| 📅 **签到系统** | `CanvasPage.ets` | 每日签到、连续天数统计、签到状态持久化 |
| 🌌 **视觉主题** | `ColorConstants.ets` | 全新暗色渐变背景 + 霓虹光效色彩体系 |

---

## 1. 刮刮乐 (ScratchCardView.ets)

**文件路径**: `entry/src/main/ets/view/ScratchCardView.ets`

### 功能说明

刮刮乐是新增的互动抽奖玩法。用户用手指在金色涂层上滑动刮开，露出下方随机奖品，刮开面积达到45%后自动彻底揭开涂层，显示中奖结果并保存记录。

### 代码详解

#### 1.1 导入模块
```typescript
import Logger from '../common/utils/Logger';
import StyleConstants from '../common/constants/StyleConstants';
import CommonConstants from '../common/constants/CommonConstants';
import ColorConstants from '../common/constants/ColorConstants';
import { window } from '@kit.ArkUI';
import { Context } from '@kit.AbilityKit';
```
**功能**: 导入日志工具、样式常量、通用常量、颜色常量、窗口API和应用上下文。

#### 1.2 全局上下文获取
```typescript
const uiContext: UIContext | undefined = AppStorage.get('uiContext');
let context: Context = uiContext!.getHostContext()!;
```
**功能**: 从AppStorage获取UI上下文，再获取Ability上下文，用于窗口操作和资源读取。

#### 1.3 奖品数据类型定义
```typescript
interface ScratchPrize {
  message: Resource;
  imageSrc: string;
}
```
**功能**: 定义刮刮乐奖品的数据结构，包含奖品的国际化文字资源(message)和图片路径(imageSrc)。

#### 1.4 组件定义与状态变量
```typescript
@Component
export default struct ScratchCardView {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  @State screenWidth: number = 360;
  @State screenHeight: number = 640;
  @State scratchPercent: number = 0;
  @State isRevealed: boolean = false;
  @State hasNewCard: boolean = true;
  private cardX: number = 0;
  private cardY: number = 0;
  private cardW: number = 0;
  private cardH: number = 0;
  private scratchedPixels: number = 0;
  private totalPixels: number = 0;
  private isScratching: boolean = false;
  private canvasInitialized: boolean = false;
  // ...
}
```
**说明**:
- **settings**: 渲染上下文设置，`true`表示开启抗锯齿
- **canvasContext**: Canvas 2D渲染上下文，用于在Canvas组件上绘制涂层和奖品
- **screenWidth/screenHeight**: 屏幕宽高，用于自适应布局（@State装饰保证更新时重新渲染）
- **scratchPercent**: 已刮开的百分比，用于UI反馈显示
- **isRevealed**: 是否已揭开涂层，控制中奖庆祝界面显隐
- **hasNewCard**: 是否有新卡片，控制初始化
- **cardX/cardY/cardW/cardH**: 卡片在画布上的位置和尺寸
- **scratchedPixels/totalPixels**: 已刮像素数 / 总像素数，用于计算百分比
- **isScratching**: 是否正在刮擦，防止触摸移出后继续刮擦
- **canvasInitialized**: Canvas是否已初始化完成，防止组件重建时重复初始化
- **currentPrize**: 当前卡片的中奖奖品
- **allPrizes**: 所有可选奖品池，随机从中选取

#### 1.5 初始化奖品池
```typescript
private currentPrize: ScratchPrize = {
  message: $r('app.string.prize_text_smile'),
  imageSrc: CommonConstants.SMILE_IMAGE_URL
};
private allPrizes: ScratchPrize[] = [
  { message: $r('app.string.prize_text_watermelon'), imageSrc: CommonConstants.WATERMELON_IMAGE_URL },
  { message: $r('app.string.prize_text_hamburger'), imageSrc: CommonConstants.HAMBURG_IMAGE_URL },
  { message: $r('app.string.prize_text_cake'), imageSrc: CommonConstants.CAKE_IMAGE_URL },
  { message: $r('app.string.prize_text_smile'), imageSrc: CommonConstants.SMILE_IMAGE_URL },
];
```
**功能**: 定义4种可选奖品（西瓜、汉堡、蛋糕、笑脸），`currentPrize`默认笑脸，会在初始化时随机选择。

#### 1.6 aboutToAppear - 获取窗口尺寸
```typescript
aboutToAppear(): void {
  window.getLastWindow(context)
    .then((windowClass: window.Window) => {
      const wp = windowClass.getWindowProperties();
      this.screenWidth = this.getUIContext().px2vp(wp.windowRect.width);
      this.screenHeight = this.getUIContext().px2vp(wp.windowRect.height);
    })
    .catch((error: Error) => {
      Logger.error('Failed window size: ' + JSON.stringify(error));
    });
}
```
**功能**: 页面即将显示时获取窗口实际尺寸，将像素值转换为vp（虚拟像素）单位，确保在不同设备上显示一致。

#### 1.7 initCard - 初始化卡片
```typescript
initCard(): void {
  this.isRevealed = false;
  this.scratchedPixels = 0;
  this.scratchPercent = 0;
  this.isScratching = false;
  this.hasNewCard = true;
  this.pickPrize();
  this.drawCard();
}
```
**功能**: 重置所有刮卡状态，随机选取奖品，重新绘制卡片。每次"再来一张"时调用此方法。

#### 1.8 pickPrize - 随机选奖
```typescript
pickPrize(): void {
  const idx = Math.floor(Math.random() * this.allPrizes.length);
  this.currentPrize = this.allPrizes[idx];
}
```
**功能**: 从4种奖品中随机选取一个，`Math.random()`生成[0,1)随机数，乘以数组长度后向下取整。

#### 1.9 drawCard - 绘制刮刮卡
```typescript
drawCard(): void {
  const ctx = this.canvasContext;
  const cw = this.screenWidth * 0.8;
  const ch = cw * 1.2;
  this.cardX = (this.screenWidth - cw) / 2;
  this.cardY = (this.screenHeight - ch) / 2 - 20;
  this.cardW = cw;
  this.cardH = ch;
  this.totalPixels = cw * ch;
```
**功能**: 计算卡片尺寸和位置。卡片宽度为屏幕宽的80%，高度为宽度的1.2倍，居中显示（水平偏移20vp）。`totalPixels`记录卡片总面积用于计算刮开百分比。

```typescript
  // Clear
  ctx.clearRect(0, 0, this.screenWidth, this.screenHeight);
```
**功能**: 清空整个画布，准备重新绘制。

```typescript
  // --- Layer 1: Prize content ---
  // Card background
  ctx.save();
  this.roundRect(ctx, this.cardX, this.cardY, cw, ch, 16);
  ctx.fillStyle = '#1E1E3F';
  ctx.fill();
  ctx.restore();
```
**功能**: 绘制第一层（奖品底层）。`save()`保存画布状态，`roundRect()`绘制圆角矩形路径（圆角半径16），填充深蓝紫色作为卡片背景，`restore()`恢复画布状态。

```typescript
  // Decorative border
  ctx.save();
  this.roundRect(ctx, this.cardX, this.cardY, cw, ch, 16);
  ctx.strokeStyle = '#FFD700';
  ctx.lineWidth = 2;
  ctx.stroke();
  ctx.restore();
```
**功能**: 绘制金色边框。使用同样的圆角路径，`strokeStyle`设置金色，`lineWidth`设置线宽2px，`stroke()`描边。

```typescript
  // Prize text
  ctx.save();
  ctx.fillStyle = '#FFD700';
  ctx.font = '22px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  const prizeStr = this.getPrizeString();
  ctx.fillText(prizeStr, this.screenWidth / 2, this.cardY + ch * 0.35);
  ctx.restore();
```
**功能**: 绘制奖品文字。金色22px字体，水平居中，垂直位于卡片35%位置处。文字内容通过`getPrizeString()`获取中文字符串。

```typescript
  // Prize image (emoji)
  const imgSize = 80;
  ctx.save();
  ctx.font = '64px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillStyle = '#FFFFFF';
  ctx.shadowColor = 'rgba(0,0,0,0.5)';
  ctx.shadowBlur = 6;
  ctx.fillText(this.getPrizeEmoji(), this.screenWidth / 2, this.cardY + ch * 0.45 + imgSize / 2);
  ctx.restore();
```
**功能**: 绘制奖品Emoji。64px超大字体，白色加黑色阴影（模糊6px），位于卡片垂直45%+40px处，确保在文字下方居中显示。

```typescript
  // Hint text
  ctx.save();
  ctx.fillStyle = 'rgba(255,255,255,0.3)';
  ctx.font = '14px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('刮开涂层查看奖品', this.screenWidth / 2, this.cardY + ch * 0.78);
  ctx.restore();
```
**功能**: 在卡片底部绘制半透明提示文字"刮开涂层查看奖品"，引导用户操作。

```typescript
  // --- Layer 2: Gold coating ---
  ctx.save();
  this.roundRect(ctx, this.cardX, this.cardY, cw, ch, 16);
  ctx.clip();
```
**功能**: 开始绘制第二层（金色涂层）。先绘制圆角矩形路径，然后`clip()`裁剪画布，使后续所有绘制只在此圆角范围内显示。

```typescript
  const gradient = ctx.createLinearGradient(this.cardX, this.cardY, this.cardX + cw, this.cardY + ch);
  gradient.addColorStop(0, ColorConstants.SCRATCH_COAT_COLOR2);
  gradient.addColorStop(0.5, ColorConstants.SCRATCH_COAT_COLOR1);
  gradient.addColorStop(1, ColorConstants.SCRATCH_COAT_COLOR2);
  ctx.fillStyle = gradient;
  ctx.fillRect(this.cardX, this.cardY, cw, ch);
```
**功能**: 创建线性渐变（从卡片左上到右下），使用金色系颜色（橙色→金色→橙色），填充整个卡片区域形成华丽的金色涂层。

```typescript
  // Scratch hint text on coating
  ctx.fillStyle = 'rgba(255,255,255,0.5)';
  ctx.font = '16px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('👆 用手指刮开', this.screenWidth / 2, this.cardY + ch / 2);
  ctx.restore();
```
**功能**: 在金色涂层上绘制半透明白色提示"👆 用手指刮开"，在涂层正中央显示。

#### 1.10 roundRect - 绘制圆角矩形
```typescript
roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number): void {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.arcTo(x + w, y, x + w, y + r, r);
  ctx.lineTo(x + w, y + h - r);
  ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
  ctx.lineTo(x + r, y + h);
  ctx.arcTo(x, y + h, x, y + h - r, r);
  ctx.lineTo(x, y + r);
  ctx.arcTo(x, y, x + r, y, r);
  ctx.closePath();
}
```
**功能**: 手动绘制圆角矩形路径。从左上角开始顺时针绘制，使用`arcTo`在每个角绘制圆弧，`r`参数控制圆角大小。Canvas原生没有圆角矩形API，所以手动实现。

#### 1.11 getPrizeEmoji 和 getPrizeString
```typescript
getPrizeEmoji(): string {
  if (this.currentPrize.imageSrc === CommonConstants.WATERMELON_IMAGE_URL) return '🍉';
  if (this.currentPrize.imageSrc === CommonConstants.HAMBURG_IMAGE_URL) return '🍔';
  if (this.currentPrize.imageSrc === CommonConstants.CAKE_IMAGE_URL) return '🎂';
  return '😊';
}

getPrizeString(): string {
  const resources = [
    $r('app.string.prize_text_watermelon'),
    $r('app.string.prize_text_hamburger'),
    $r('app.string.prize_text_cake'),
    $r('app.string.prize_text_smile'),
  ];
  const resStr = this.currentPrize.message!;
  try {
    return uiContext!.getHostContext()!.resourceManager.getStringSync(resStr.id);
  } catch (_e) {
    return '🎉 Prize!';
  }
}
```
**功能**: 
- `getPrizeEmoji()`: 根据imageSrc路径判断奖品类型，返回对应Emoji字符
- `getPrizeString()`: 从资源管理器中同步获取当前奖品的中文描述文字，失败时返回默认文本

#### 1.12 onTouchHandler - 触摸事件处理
```typescript
onTouchHandler(event: TouchEvent): void {
  if (this.isRevealed) return;

  if (event.type === TouchType.Down) {
    this.isScratching = true;
  }

  if (event.type === TouchType.Move && this.isScratching) {
    const touch = event.touches[0];
    if (!touch) return;
    this.scratchAt(touch.x, touch.y);
  }

  if (event.type === TouchType.Up) {
    this.isScratching = false;
  }
}
```
**功能**: 处理触摸事件的三阶段：
- **Down**: 手指按下，设置`isScratching = true`开始刮擦
- **Move**: 手指移动且正在刮擦，获取触摸点坐标，调用`scratchAt()`擦除涂层
- **Up**: 手指抬起，设置`isScratching = false`停止刮擦

#### 1.13 scratchAt - 刮擦涂层
```typescript
scratchAt(x: number, y: number): void {
  const ctx = this.canvasContext;
  ctx.save();
  ctx.globalCompositeOperation = 'destination-out';
  ctx.beginPath();
  ctx.arc(x, y, 24, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
```
**功能**: 在触摸点位置擦除涂层。核心是`globalCompositeOperation = 'destination-out'`——这是Canvas合成模式，意思是"只保留目标图像中与源图像不重叠的部分"，即在涂层上"挖"出一个圆形透明区域。圆半径24px模拟手指大小。

```typescript
  this.scratchedPixels += Math.PI * 24 * 24;
  this.scratchPercent = Math.min(100, Math.round((this.scratchedPixels / this.totalPixels) * 100));

  if (this.scratchPercent >= 45 && !this.isRevealed) {
    this.revealCard();
  }
}
```
**功能**: 
- 计算已刮像素数（累加每次刮擦圆的面积），计算百分比
- 当刮开面积≥45%时触发`revealCard()`自动揭开整张卡片（注意：存在重复计算重叠面积的问题，但作为游戏来说可接受）

#### 1.14 revealCard - 揭开卡片
```typescript
revealCard(): void {
  this.isRevealed = true;
  // Clear remaining coating
  const ctx = this.canvasContext;
  ctx.save();
  ctx.globalCompositeOperation = 'destination-out';
  ctx.fillRect(0, 0, this.screenWidth, this.screenHeight);
  ctx.restore();
  this.saveHistory();
}
```
**功能**: 设置`isRevealed = true`显示中奖庆祝界面。并用`destination-out`全屏擦除剩余涂层，让奖品完全露出。同时调用`saveHistory()`记录中奖结果。

#### 1.15 saveHistory - 保存历史记录
```typescript
saveHistory(): void {
  const key: string = 'wheel_history';
  const raw: string = AppStorage.get<string>(key) || '';
  const img: string = this.currentPrize.imageSrc || '';
  const entry: string = '' + new Date().getTime() + '|' + img;
  let newVal: string = raw.length > 0 ? raw + ',' + entry : entry;
  const parts: string[] = newVal.split(',');
  if (parts.length > 100) {
    let trimmed: string = '';
    for (let i = parts.length - 100; i < parts.length; i++) {
      if (trimmed.length > 0) trimmed = trimmed + ',';
      trimmed = trimmed + parts[i];
    }
    newVal = trimmed;
  }
  AppStorage.set(key, newVal);
}
```
**功能**: 将中奖记录保存到AppStorage（应用级持久化存储）。格式为`时间戳|图片路径`，多条用逗号分隔。最多保留100条，超出时删除最早的记录。这样转盘和刮刮乐共用同一份历史记录。

#### 1.16 newCard - 再来一张
```typescript
newCard(): void {
  this.initCard();
}
```
**功能**: 点击"再来一张"按钮时重新初始化卡片。

#### 1.17 build - UI构建
```typescript
build() {
  Column() {
    // Title
    Text('🎫 刮刮乐')
      .fontSize(24)
      .fontColor('#FFFFFF')
      .fontWeight(700)
      .margin({ top: 12, bottom: 8 })

    Text(this.isRevealed ? '恭喜中奖！' : '手指刮开涂层看看手气')
      .fontSize(14)
      .fontColor('rgba(255,255,255,0.5)')
      .margin({ bottom: 16 })
```
**功能**: 页面标题"🎫 刮刮乐"（白色大字号加粗），副标题根据是否揭开发化（未刮开显示"手指刮开涂层看看手气"，已揭开显示"恭喜中奖！"）。

```typescript
    // Card Canvas
    Canvas(this.canvasContext)
      .layoutWeight(1)
      .width('100%')
      .onReady(() => {
        if (!this.canvasInitialized) {
          this.canvasInitialized = true;
          this.initCard();
        } else {
          this.drawCard();
        }
      })
      .onTouch((event: TouchEvent) => {
        this.onTouchHandler(event);
      })
```
**功能**: 
- Canvas组件绑定canvasContext，宽度100%，`layoutWeight(1)`占满剩余空间
- `onReady`: Canvas组件首次初始化时调用`initCard()`，后续触发的onReady（如切换Tab回来）只调用`drawCard()`防止状态丢失。`canvasInitialized`标志位防止重复初始化。
- `onTouch`: 将触摸事件交给`onTouchHandler`处理刮擦逻辑

```typescript
    // Celebration overlay
    if (this.isRevealed) {
      Column() {
        Text('🎉 恭喜中奖 🎉')
          .fontSize(24)
          .fontColor('#FFD700')
          .fontWeight(700)
          .margin({ bottom: 8 })
        Text(this.getPrizeEmoji())
          .fontSize(64)
          .margin({ bottom: 8 })
        Text(this.getPrizeString())
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(600)
        Text('✨ 🌟 ✨')
          .fontSize(20)
          .margin({ top: 8 })
      }
      .width('70%')
      .padding(20)
      .backgroundColor('rgba(30,30,63,0.92)')
      .borderRadius(16)
      .border({ width: 1, color: 'rgba(255,215,0,0.4)' })
      .hitTestBehavior(HitTestMode.None)
      .alignItems(HorizontalAlign.Center)
      .position({ x: '15%', y: '30%' })
    }
```
**功能**: 揭开后显示的庆祝浮层。半透明深色背景、金色边框、圆角。显示"🎉 恭喜中奖 🎉"、奖品Emoji（64px）、奖品文字、装饰星星。使用`position`绝对定位在屏幕中央区域，`hitTestBehavior(HitTestMode.None)`让触摸事件穿透到下层。

```typescript
    // Bottom area
    if (this.isRevealed) {
      Button('再来一张')
        .width(200)
        .height(44)
        .backgroundColor('#FFD700')
        .fontColor('#1A1A2E')
        .fontWeight(700)
        .borderRadius(22)
        .margin({ bottom: 16 })
        .onClick(() => {
          this.newCard();
        })
    } else {
      Text(`已刮 ${this.scratchPercent}%`)
        .fontSize(13)
        .fontColor('rgba(255,255,255,0.3)')
        .margin({ bottom: 16 })
    }
  }
  .width(StyleConstants.FULL_PERCENT)
  .height(StyleConstants.FULL_PERCENT)
}
```
**功能**: 底部区域：未揭开时显示"已刮 X%"进度文字；揭开后显示金色"再来一张"按钮（圆角胶囊形），点击重新开始新一轮刮卡。

---

## 2. 抽奖记录 (HistoryView.ets)

**文件路径**: `entry/src/main/ets/view/HistoryView.ets`

### 功能说明

自动记录所有抽奖和刮刮乐的结果。以时间倒序列表展示每次结果（Emoji + 中奖状态 + 时间），统计总次数和中奖率，支持清空记录。

### 代码详解

#### 2.1 导入模块与类型定义
```typescript
import Logger from '../common/utils/Logger';
import StyleConstants from '../common/constants/StyleConstants';
import CommonConstants from '../common/constants/CommonConstants';

interface HistoryRow {
  emoji: string;
  isWin: boolean;
  timeText: string;
}
```
**功能**: `HistoryRow`定义一条历史记录的数据结构：Emoji图标、是否中奖、时间字符串。

#### 2.2 工具函数
```typescript
function getEmoji(img: string): string {
  if (img === CommonConstants.WATERMELON_IMAGE_URL) return '🍉';
  if (img === CommonConstants.HAMBURG_IMAGE_URL) return '🍔';
  if (img === CommonConstants.CAKE_IMAGE_URL) return '🎂';
  if (img === CommonConstants.SMILE_IMAGE_URL) return '😊';
  return '🎁';
}

function isWin(img: string): boolean {
  return img !== CommonConstants.SMILE_IMAGE_URL;
}

function formatTime(ts: string): string {
  try {
    const num: number = parseInt(ts, 10);
    const d: Date = new Date(num);
    const h: string = ('0' + d.getHours()).slice(-2);
    const m: string = ('0' + d.getMinutes()).slice(-2);
    return h + ':' + m;
  } catch (_e) {
    return ts;
  }
}
```
**功能**:
- **getEmoji**: 根据图片路径返回对应Emoji字符
- **isWin**: 判断是否中奖——笑脸(SMILE)视为"未中奖"，其他奖品视为"中奖"
- **formatTime**: 将时间戳字符串格式化为"时:分"格式（两位数补零），解析失败时返回原始字符串

#### 2.3 组件定义
```typescript
@Component
export default struct HistoryView {
  @State records: HistoryRow[] = [];
  @State statsText: string = '';
```
**功能**: 两个@State变量驱动UI更新：`records`存储历史记录数组，`statsText`存储统计文字。

#### 2.4 aboutToAppear / onPageShow
```typescript
aboutToAppear(): void {
  this.loadHistory();
}

onPageShow(): void {
  this.loadHistory();
}
```
**功能**: 组件首次创建时和每次页面显示时都加载历史记录。`onPageShow`保证从其他Tab切换回来时数据是最新的。

#### 2.5 loadHistory - 加载历史记录
```typescript
loadHistory(): void {
  this.records = [];
  let total: number = 0;
  let wins: number = 0;

  const raw: string = AppStorage.get<string>('wheel_history') || '';
  if (raw.length > 0) {
    const parts: string[] = raw.split(',');
    for (let i = parts.length - 1; i >= 0; i--) {
      const entry: string[] = parts[i].split('|');
      if (entry.length >= 2) {
        const ts: string = entry[0];
        const img: string = entry[1];
        const row: HistoryRow = {
          emoji: getEmoji(img),
          isWin: isWin(img),
          timeText: formatTime(ts),
        };
        this.records.push(row);
        total++;
        if (isWin(img)) wins++;
      }
    }
  }

  const winRate: number = total > 0 ? Math.round((wins / total) * 100) : 0;
  this.statsText = '共 ' + total + ' 次 · 中奖率 ' + winRate + '%';
}
```
**功能**: 
1. 从AppStorage读取`wheel_history`（格式：`时间戳|图片路径,时间戳|图片路径,...`）
2. 用逗号分割每条记录，用竖线分割时间和图片
3. **倒序遍历**实现时间倒序排列（最新的在前面）
4. 统计总次数和中奖次数，计算中奖率（百分比取整）
5. 拼接统计文字如"共 10 次 · 中奖率 60%"

#### 2.6 clearHistory - 清空记录
```typescript
clearHistory(): void {
  AppStorage.set('wheel_history', '');
  this.records = [];
  this.statsText = '暂无记录';
}
```
**功能**: 清空AppStorage中的记录，重置UI状态。

#### 2.7 build - UI构建
```typescript
build() {
  Column() {
    Text('📊 抽奖记录')
      .fontSize(22).fontColor('#FFFFFF').fontWeight(700)
      .margin({ top: 24, bottom: 4 })

    Text(this.statsText)
      .fontSize(14).fontColor('rgba(255,255,255,0.5)')
      .margin({ bottom: 16 })
```
**功能**: 页面标题"📊 抽奖记录" + 统计文字（白色半透明）。

```typescript
    if (this.records.length === 0) {
      Column() {
        Text('🎯').fontSize(48).margin({ bottom: 12 })
        Text('还没有抽奖记录').fontSize(16).fontColor('rgba(255,255,255,0.4)')
        Text('去转盘或老虎机试试手气吧！').fontSize(14).fontColor('rgba(255,255,255,0.3)')
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
```
**功能**: 没有记录时显示空状态：大号Emoji + 提示文字，垂直水平居中。

```typescript
    } else {
      List({ space: 8 }) {
        ForEach(this.records, (item: HistoryRow) => {
          ListItem() {
            Row({ space: 12 }) {
              Text(item.emoji).fontSize(32)

              Column({ space: 4 }) {
                Text(item.isWin ? '🎉 中奖' : '😅 未中奖')
                  .fontSize(15)
                  .fontColor(item.isWin ? '#FFD700' : 'rgba(255,255,255,0.6)')
                  .fontWeight(600)
                Text(item.timeText).fontSize(12).fontColor('rgba(255,255,255,0.3)')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              if (item.isWin) {
                Text('✨').fontSize(16)
              }
            }
            .padding(12)
            .backgroundColor('rgba(255,255,255,0.05)')
            .borderRadius(10)
          }
        }, (item: HistoryRow) => item.timeText + item.emoji)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 16, right: 16 })
```
**功能**: 有记录时显示List列表，每条记录是一个ListItem：
- 左侧：奖品Emoji（32px）
- 中间：中奖状态（金色"🎉 中奖"或灰色"😅 未中奖"）+ 时间
- 右侧：中奖时显示"✨"装饰
- 列表项有半透明背景和圆角
- `ForEach`的第三个参数是key生成器，用`timeText+emoji`作为唯一标识

```typescript
      Button('清空记录')
        .width(160).height(40)
        .backgroundColor('rgba(255,255,255,0.1)')
        .fontColor('rgba(255,255,255,0.5)')
        .borderRadius(20)
        .margin({ bottom: 20 })
        .onClick(() => { this.clearHistory(); })
    }
  }
  .width(StyleConstants.FULL_PERCENT)
  .height(StyleConstants.FULL_PERCENT)
}
```
**功能**: 底部"清空记录"按钮（半透明白色胶囊形），点击后清除所有历史记录。

---

## 3. 彩纸庆祝动画 (ConfettiEffect.ets)

**文件路径**: `entry/src/main/ets/view/ConfettiEffect.ets`

### 功能说明

中奖时全屏播放彩色粒子庆祝动画。生成80个随机彩色粒子（圆形+矩形混合），从屏幕中央向四周飞散，受"重力"影响下落，逐渐淡出消失。

### 代码详解

#### 3.1 Particle接口
```typescript
interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  size: number;
  color: string;
  life: number;
  maxLife: number;
  rotation: number;
  rotSpeed: number;
  isRect: boolean;
}
```
**功能**: 粒子数据结构定义：
- **x/y**: 当前位置坐标
- **vx/vy**: 水平和垂直速度
- **size**: 粒子尺寸
- **color**: 颜色
- **life/maxLife**: 当前生命值 / 最大生命值，用于淡出效果
- **rotation/rotSpeed**: 旋转角度 / 旋转速度（只有矩形会旋转）
- **isRect**: true为矩形，false为圆形

#### 3.2 组件定义
```typescript
@Component
export default struct ConfettiEffect {
  private particleContext: CanvasRenderingContext2D = new CanvasRenderingContext2D();
  private particles: Particle[] = [];
  private animTimer: number = -1;
  private canvasWidth: number = 500;
  private canvasHeight: number = 800;

  private colors: string[] = [
    '#FF6B9D', '#C44AFF', '#FFD93D', '#FF9A56',
    '#00D2FF', '#3A7BD5', '#FFD700', '#FF4500',
    '#00FF7F', '#FF1493'
  ];
```
**功能**: 10种鲜艳颜色（粉、紫、黄、橙、蓝、金、红、绿），canvas默认宽高500x800。

#### 3.3 trigger - 触发彩纸
```typescript
trigger(): void {
  this.particles = [];
  for (let i = 0; i < 80; i++) {
    const angle: number = Math.random() * Math.PI * 2;
    const speed: number = Math.random() * 8 + 3;
    const p: Particle = {
      x: this.canvasWidth / 2 + (Math.random() - 0.5) * 100,
      y: this.canvasHeight / 2,
      vx: Math.cos(angle) * speed * (0.5 + Math.random()),
      vy: Math.sin(angle) * speed * (0.5 + Math.random()) - 3,
      size: Math.random() * 8 + 4,
      color: this.colors[Math.floor(Math.random() * this.colors.length)],
      life: 1,
      maxLife: Math.random() * 60 + 60,
      rotation: Math.random() * 360,
      rotSpeed: (Math.random() - 0.5) * 10,
      isRect: Math.random() > 0.5,
    };
    this.particles.push(p);
  }
  if (this.animTimer > 0) clearTimeout(this.animTimer);
  this.animate();
}
```
**功能**: 生成80个粒子：
- 位置从屏幕中央附近随机偏移（x偏移±50px）
- 方向：`angle = random * 2π`，向360°任意方向飞散
- 速度：基础速度3-11，每个方向分量再乘`(0.5 + random)`增加随机性
- **vy减3**：整体向上偏移，形成"爆发"效果
- 形状：50%概率矩形，50%概率圆形
- 生命期：60-120帧（约1-2秒）
- 清除之前正在播放的动画定时器后启动动画

#### 3.4 animate - 动画循环
```typescript
animate(): void {
  const ctx: CanvasRenderingContext2D = this.particleContext;
  let frame: number = 0;

  const loop = (): void => {
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    frame++;
    let alive: boolean = false;
```
**功能**: 使用`setTimeout`模拟动画循环（ArkTS不支持requestAnimationFrame）。`frame`控制最大帧数200（约3.2秒），`alive`跟踪是否还有存活粒子。

```typescript
    for (let i = 0; i < this.particles.length; i++) {
      const p: Particle = this.particles[i];
      if (p.life <= 0) continue;
      alive = true;
      p.x += p.vx;
      p.vy += 0.15;     // 重力
      p.y += p.vy;
      p.rotation += p.rotSpeed;
      p.life -= 1 / p.maxLife;
      const alpha: number = Math.max(0, p.life);
```
**功能**: 每帧更新每个粒子：
- `p.x += p.vx`: 水平移动
- `p.vy += 0.15`: 模拟重力，使垂直速度逐渐增加（向下加速）
- `p.y += p.vy`: 垂直移动
- `p.rotation += p.rotSpeed`: 旋转
- `p.life -= 1/maxLife`: 生命值递减
- `alpha = max(0, life)`: 透明度随生命值降低

```typescript
      ctx.save();
      ctx.globalAlpha = alpha;
      ctx.translate(p.x, p.y);
      ctx.rotate((p.rotation * Math.PI) / 180);
      ctx.fillStyle = p.color;

      if (p.isRect) {
        ctx.fillRect(-p.size / 2, -p.size / 4, p.size, p.size / 2);
      } else {
        ctx.beginPath();
        ctx.arc(0, 0, p.size / 2, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    }
```
**功能**: 绘制每个粒子：
- 保存画布状态
- 设置全局透明度实现淡出
- 平移到粒子位置并旋转
- 矩形粒子：绘制扁平矩形（宽高比2:1）
- 圆形粒子：绘制完整圆形
- 恢复画布状态

```typescript
    ctx.globalAlpha = 1;

    if (alive && frame < 200) {
      this.animTimer = setTimeout(loop, 16);
    } else {
      ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    }
  };

  this.animTimer = setTimeout(loop, 16);
}
```
**功能**: 如果还有存活粒子且未超过200帧，继续下一帧（16ms间隔≈60fps）。否则清除画布结束动画。

#### 3.5 生命周期与UI
```typescript
aboutToDisappear(): void {
  if (this.animTimer > 0) clearTimeout(this.animTimer);
}

build() {
  Canvas(this.particleContext)
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
}
```
**功能**: 组件销毁时清除定时器防止内存泄漏。Canvas全屏覆盖且`hitTestBehavior(None)`让触摸事件穿透。

---

## 4. 星空粒子背景 (StarParticle.ets)

**文件路径**: `entry/src/main/ets/view/StarParticle.ets`

### 功能说明

在页面背景层动态绘制闪烁的星星粒子。40颗星星以不同速度、不同频率呼吸闪烁，营造星空沉浸效果。

### 代码详解

#### 4.1 Star接口与组件
```typescript
interface Star {
  x: number;
  y: number;
  size: number;
  alpha: number;
  speed: number;
  phase: number;
}
```
**功能**: 星星数据结构：位置、大小、基础透明度、闪烁速度、相位偏移。

#### 4.2 aboutToAppear - 初始化并启动
```typescript
aboutToAppear(): void {
  this.initStars();
  this.startAnimation();
}
```
**功能**: 组件创建时初始化星星并启动动画。

#### 4.3 initStars - 初始化星星
```typescript
initStars(): void {
  this.stars = [];
  for (let i = 0; i < 40; i++) {
    const s: Star = {
      x: Math.random() * 500,
      y: Math.random() * 800,
      size: Math.random() * 2.5 + 0.5,
      alpha: Math.random() * 0.6 + 0.2,
      speed: Math.random() * 0.2 + 0.05,
      phase: Math.random() * Math.PI * 2,
    };
    this.stars.push(s);
  }
}
```
**功能**: 生成40颗星星：
- 位置：在500×800范围内随机分布
- 大小：0.5-3.0（小星星更自然）
- 基础透明度：0.2-0.8
- 速度：0.05-0.25（控制闪烁频率）
- 相位：0-2π，让星星不同步闪烁

#### 4.4 startAnimation - 动画循环
```typescript
startAnimation(): void {
  const animate = (): void => {
    const ctx: CanvasRenderingContext2D = this.starCanvasContext;
    const now: number = Date.now() / 1000;

    ctx.clearRect(0, 0, 500, 800);

    for (let i = 0; i < this.stars.length; i++) {
      const star: Star = this.stars[i];
      const pulse: number = Math.sin(now * star.speed + star.phase) * 0.3 + 0.7;
      const a: number = star.alpha * pulse;
      ctx.globalAlpha = a;
      ctx.fillStyle = ColorConstants.STAR_COLOR;
      ctx.beginPath();
      ctx.arc(star.x, star.y, star.size, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;

    this.animTimer = setTimeout(animate, 33);
  };

  this.animTimer = setTimeout(animate, 33);
}
```
**功能**: 
- 用`Date.now()/1000`获取当前秒数作为时间基准
- `Math.sin(now * speed + phase) * 0.3 + 0.7`：正弦波生成0.4-1.0的脉冲因子，使星星柔和闪烁
- 最终透明度 = 基础透明度 × 脉冲因子
- 以33ms间隔（≈30fps）持续运行，永不停止

#### 4.5 UI
```typescript
build() {
  Canvas(this.starCanvasContext)
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
}
```
**功能**: 全屏Canvas覆盖层，触摸穿透，作为背景装饰。

---

## 5. 转盘改进 (WheelView.ets)

**文件路径**: `entry/src/main/ets/view/WheelView.ets`

### 功能说明

由原来CanvasPage中的内联代码重构为独立组件。新增连抽模式（3次/5次）、按钮呼吸动效、语言切换监听、中奖记录保存、彩纸庆祝触发等功能。

### 代码详解

#### 5.1 getEmoji工具函数
```typescript
function getEmoji(img: string): string {
  if (img === CommonConstants.WATERMELON_IMAGE_URL) return '🍉';
  if (img === CommonConstants.HAMBURG_IMAGE_URL) return '🍔';
  if (img === CommonConstants.CAKE_IMAGE_URL) return '🎂';
  if (img === CommonConstants.SMILE_IMAGE_URL) return '😊';
  return '🎁';
}
```
**功能**: 根据奖品图片路径返回对应Emoji，用于连抽结果汇总展示。

#### 5.2 组件状态
```typescript
@Component
export default struct WheelView {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private drawModel: DrawModel = new DrawModel();
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State rotateDegree: number = 0;
  @State enableFlag: boolean = true;
  @State prizeData: PrizeData = new PrizeData();
  @State confettiKey: number = 0;
  @State btnScale: number = 1.0;
  @State multiMode: number = 0;
  @State multiRemaining: number = 0;
  @State multiResults: string[] = [];
  @State showSummary: boolean = false;
  @State summaryText: string = '';
```
**新增状态说明**:
- **confettiKey**: 彩纸触发器key，每次变化重新创建ConfettiEffect组件
- **btnScale**: 按钮缩放比例（1.0→1.08→0.95循环），用于呼吸动效
- **multiMode/multiRemaining**: 连抽模式（3或5）和剩余次数
- **multiResults**: 连抽结果数组
- **showSummary/summaryText**: 连抽汇总弹窗显隐和内容

#### 5.3 aboutToAppear - 初始化和语言监听
```typescript
aboutToAppear(): void {
  window.getLastWindow(context)
    .then((windowClass: window.Window) => {
      windowClass.setWindowLayoutFullScreen(true);
      const wp = windowClass.getWindowProperties();
      this.screenWidth = this.getUIContext().px2vp(wp.windowRect.width);
      this.screenHeight = this.getUIContext().px2vp(wp.windowRect.height);
    })
    .catch((error: Error) => {
      Logger.error('Failed window size: ' + JSON.stringify(error));
    });

  const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: [commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED]
  };
  commonEventManager.createSubscriber(subscribeInfo)
    .then((sub) => {
      this.subscriber = sub;
      commonEventManager.subscribe(this.subscriber, (err) => {
        if (err) { Logger.error(`Locale error: ${err.code}`); return; }
        this.currentLang = i18n.System.getSystemLanguage();
      });
    })
    .catch((err: BusinessError) => {
      Logger.error(`CreateSubscriber failed: ${err.code}`);
    });

  this.startBreathing();
}
```
**功能**: 
1. 获取屏幕尺寸并设置全屏
2. 订阅系统语言切换事件（COMMON_EVENT_LOCALE_CHANGED），语言变化时重新绘制转盘更新文字
3. 启动按钮呼吸动画

#### 5.4 startBreathing - 按钮呼吸动效
```typescript
startBreathing(): void {
  const animate = (): void => {
    const ctx = this.getUIContext();
    if (!ctx) { this.breatheTimer = setTimeout(animate, 200); return; }
    ctx.animateTo({ duration: 1000, curve: Curve.EaseInOut }, () => { this.btnScale = 1.08; });
    setTimeout(() => {
      ctx.animateTo({ duration: 1000, curve: Curve.EaseInOut }, () => { this.btnScale = 0.95; });
    }, 1000);
    this.breatheTimer = setTimeout(animate, 2100);
  };
  animate();
}
```
**功能**: 使用`animateTo`显式动画让中心按钮在"放大1.08倍→缩小0.95倍"之间循环，每个周期2.1秒。EaseInOut曲线使缩放更自然柔和。

#### 5.5 页面显示/隐藏
```typescript
onPageShow(): void {
  if (this.lastLang !== this.currentLang) {
    this.drawModel.draw(this.canvasContext, this.screenWidth, this.screenHeight);
  }
}
onPageHide(): void { this.lastLang = i18n.System.getSystemLanguage(); }
```
**功能**: 页面显示时检测语言是否变化，变化则重新绘制转盘。隐藏时记录当前语言。

#### 5.6 spinOnce - 单次抽奖
```typescript
spinOnce(): PrizeData {
  const angle = Math.round(Math.random() * CommonConstants.CIRCLE);
  this.prizeData = this.drawModel.showPrizeData(angle);

  this.getUIContext().animateTo({
    duration: CommonConstants.DURATION,
    curve: Curve.Ease,
    onFinish: () => {
      this.rotateDegree = CommonConstants.ANGLE - angle;
      this.onSpinFinished();
    }
  }, () => {
    this.rotateDegree = CommonConstants.CIRCLE * CommonConstants.FIVE
      + CommonConstants.ANGLE - angle;
  });
  return this.prizeData;
}
```
**功能**: 
1. 生成0-360随机角度，根据角度确定奖品
2. 启动animateTo动画：转盘旋转5整圈（1800°）+ 270° - 随机角度
3. `Curve.Ease`缓动曲线：开始和结束慢、中间快
4. `onFinish`回调：记录最终角度、调用`onSpinFinished()`处理结果

#### 5.7 onSpinFinished - 抽奖结束处理
```typescript
onSpinFinished(): void {
  this.addHistory(this.prizeData);

  if (this.multiMode > 0 && this.multiRemaining > 0) {
    this.multiRemaining--;
    this.multiResults.push(this.prizeData.imageSrc || '');
    if (this.multiRemaining <= 0) {
      this.showMultiSummary();
      return;
    }
    setTimeout(() => {
      this.enableFlag = false;
      this.spinOnce();
    }, 800);
  } else {
    this.multiResults.push(this.prizeData.imageSrc || '');
    this.triggerConfetti();
    this.dialogController.open();
    this.enableFlag = true;
  }
}
```
**功能**: 抽奖结束时的分支逻辑：
- **连抽模式**: 减少剩余次数、记录结果；如果还有剩余次数，800ms后自动开始下一次旋转；全部完成则显示汇总
- **单次模式**: 触发彩纸庆祝、打开中奖弹窗、恢复按钮可点击

#### 5.8 showMultiSummary - 连抽汇总
```typescript
showMultiSummary(): void {
  const imgKeys: string[] = [];
  const imgCounts: number[] = [];
  const imgEmojis: string[] = [];

  for (let i = 0; i < this.multiResults.length; i++) {
    const img = this.multiResults[i];
    let found = -1;
    for (let j = 0; j < imgKeys.length; j++) {
      if (imgKeys[j] === img) {
        found = j;
        break;
      }
    }
    if (found >= 0) {
      imgCounts[found]++;
    } else {
      imgKeys.push(img);
      imgCounts.push(1);
      imgEmojis.push(getEmoji(img));
    }
  }

  let text: string = '🎉 抽奖 ' + this.multiMode + ' 次结果\n';
  for (let i = 0; i < imgKeys.length; i++) {
    text = text + imgEmojis[i] + ' × ' + imgCounts[i] + '\n';
  }
  this.summaryText = text;
  this.showSummary = true;
  this.enableFlag = true;
  this.multiResults = [];
  this.triggerConfetti();
}
```
**功能**: 使用并行数组（imgKeys/imgCounts/imgEmojis）手动统计每种奖品出现次数（ArkTS不支持Map对象）。拼接汇总文字如"🎉 抽奖 3 次结果\n🍉 × 1\n🍔 × 2"，显示汇总弹窗并触发彩纸。

#### 5.9 addHistory - 保存历史记录
```typescript
addHistory(prize: PrizeData): void {
  const key: string = 'wheel_history';
  const raw: string = AppStorage.get<string>(key) || '';
  const img: string = prize.imageSrc || '';
  const entry: string = '' + new Date().getTime() + '|' + img;
  let newVal: string = entry;
  if (raw.length > 0) {
    newVal = raw + ',' + entry;
  }
  // Keep only last 100 entries
  const parts: string[] = newVal.split(',');
  if (parts.length > 100) {
    let trimmed: string = '';
    for (let i = parts.length - 100; i < parts.length; i++) {
      if (trimmed.length > 0) trimmed = trimmed + ',';
      trimmed = trimmed + parts[i];
    }
    newVal = trimmed;
  }
  AppStorage.set(key, newVal);
}
```
**功能**: 与ScratchCardView相同的历史记录保存逻辑，共用`wheel_history`键，格式一致。保留最近100条记录。

#### 5.10 build - UI构建
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
        x: 0, y: 0, z: 1, angle: this.rotateDegree,
        centerX: this.screenWidth / CommonConstants.TWO,
        centerY: this.screenHeight / CommonConstants.TWO,
      })
```
**功能**: Canvas转盘，`rotate`属性绑定`rotateDegree`驱动旋转动画，旋转中心为屏幕中心。

```typescript
    Image($r('app.media.ic_center'))
      .width(StyleConstants.CENTER_IMAGE_WIDTH)
      .height(StyleConstants.CENTER_IMAGE_HEIGHT)
      .scale({ x: this.btnScale, y: this.btnScale })
      .enabled(this.enableFlag)
      .onClick(() => { this.startSingle(); })
```
**功能**: 中心按钮图片，`scale`绑定`btnScale`实现呼吸缩放动效，`enabled`绑定`enableFlag`防止重复点击。

```typescript
    if (this.enableFlag && !this.showSummary) {
      Row({ space: 12 }) {
        Button('抽 1 次')
          .fontColor('#FFFFFF').backgroundColor('rgba(255,255,255,0.15)')
          .onClick(() => { this.startSingle(); })
        Button('连抽 3 次')
          .fontColor('#FFFFFF').backgroundColor('rgba(255,215,0,0.2)')
          .onClick(() => { this.startMulti(3); })
        Button('连抽 5 次')
          .fontColor('#FFFFFF').backgroundColor('rgba(255,215,0,0.2)')
          .onClick(() => { this.startMulti(5); })
      }
      .position({ x: 0, y: this.screenHeight - 200 })
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
```
**功能**: 底部按钮栏固定在屏幕底部上方200px处。三个按钮：抽1次（灰色）、连抽3次（金色半透明）、连抽5次（金色半透明）。抽奖过程中隐藏。

```typescript
    if (this.multiMode > 0 && !this.showSummary) {
      Text(`连抽中... (${this.multiMode - this.multiRemaining}/${this.multiMode})`)
        .fontSize(13).fontColor('rgba(255,255,255,0.5)')
        .position({ x: 0, y: this.screenHeight - 235 })
        .width('100%').textAlign(TextAlign.Center)
    }
```
**功能**: 连抽进行中的进度提示，如"连抽中... (2/3)"。

```typescript
    if (this.showSummary) {
      Column() {
        Text(this.summaryText)
          .fontSize(18).fontColor('#FFD700').fontWeight(700)
          .textAlign(TextAlign.Center).lineHeight(30)
          .margin({ bottom: 20 })
        Button('知道了')
          .width(160).height(40)
          .backgroundColor('#FFD700').fontColor('#1A1A2E')
          .borderRadius(20).fontWeight(700)
          .onClick(() => { this.showSummary = false; })
      }
      .padding(24)
      .backgroundColor('rgba(30,30,63,0.95)')
      .borderRadius(16)
      .border({ width: 1, color: 'rgba(255,215,0,0.3)' })
    }
```
**功能**: 连抽汇总弹窗，深色半透明背景、金色边框，显示每种奖品的中奖次数。

```typescript
    if (this.confettiKey > 0) {
      ConfettiEffect()
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.FULL_PERCENT)
        .hitTestBehavior(HitTestMode.None)
    }
  }
  .width(StyleConstants.FULL_PERCENT)
  .height(StyleConstants.FULL_PERCENT)
  .clip(false)
}
```
**功能**: `confettiKey > 0`时渲染CelebrationEffect组件，每次key变化重新创建实例触发新动画。`clip(false)`防止转盘旋转时被父容器裁切。

---

## 6. 中奖弹窗改进 (PrizeDialog.ets)

**文件路径**: `entry/src/main/ets/view/PrizeDialog.ets`

### 功能说明

与第一版相比，改用Emoji替代图片资源加载（更可靠），新增入场缩放+淡入动画，优化视觉样式。

### 代码详解

#### 6.1 工具函数
```typescript
function getPrizeEmoji(img: string): string {
  if (img === CommonConstants.WATERMELON_IMAGE_URL) return '🍉';
  if (img === CommonConstants.HAMBURG_IMAGE_URL) return '🍔';
  if (img === CommonConstants.CAKE_IMAGE_URL) return '🎂';
  return '😊';
}

function getPrizeMessage(msg: Resource | undefined): string {
  if (msg === undefined) return '🎉 恭喜中奖！';
  const ctx: UIContext | undefined = AppStorage.get('uiContext');
  if (ctx === undefined) return '🎉 恭喜中奖！';
  try {
    return ctx.getHostContext()!.resourceManager.getStringSync(msg.id);
  } catch (_e) {
    return '🎉 恭喜中奖！';
  }
}
```
**功能**: 
- `getPrizeEmoji`: 根据图片路径返回对应Emoji
- `getPrizeMessage`: 从资源管理器获取奖品的本地化描述文字，多层防御性编程防止空指针

#### 6.2 组件定义与入场动画
```typescript
@CustomDialog
export default struct PrizeDialog {
  @Link prizeData: PrizeData;
  @Link enableFlag: boolean;
  private controller?: CustomDialogController;
  @State animScale: number = 0;
  @State animOpacity: number = 0;

  aboutToAppear(): void {
    this.animScale = 0;
    this.animOpacity = 0;
    setTimeout(() => {
      this.getUIContext()?.animateTo({
        duration: 400,
        curve: Curve.Friction,
      }, () => {
        this.animScale = 1;
        this.animOpacity = 1;
      });
    }, 50);
  }
```
**功能**: 入场时动画（延迟50ms启动）：
- 初始状态：`scale=0`（不可见）、`opacity=0`（透明）
- 动画目标：`scale=1`、`opacity=1`
- `Curve.Friction`摩擦力曲线：开始时快速弹出，结束时摩擦减速，模拟弹性效果

#### 6.3 UI构建
```typescript
build() {
  Column() {
    // Prize emoji (replaces Image for reliable rendering)
    Text(getPrizeEmoji(this.prizeData.imageSrc !== undefined ? this.prizeData.imageSrc : ''))
      .fontSize(72)
      .margin({ top: 20, bottom: 8 })

    // Prize message
    Text(getPrizeMessage(this.prizeData.message))
      .fontSize(22)
      .fontColor('#FFD700')
      .fontWeight(700)
      .textAlign(TextAlign.Center)
      .margin({ bottom: 8 })

    // Sparkle divider
    Text('✨ ✨ ✨')
      .fontSize(16)
      .margin({ bottom: 12 })

    // Confirm button
    Text($r('app.string.text_confirm'))
      .fontColor($r('app.color.text_font_color'))
      .fontWeight(StyleConstants.FONT_WEIGHT)
      .fontSize(18)
      .textAlign(TextAlign.Center)
      .padding({ left: 40, right: 40, top: 10, bottom: 10 })
      .borderRadius(20)
      .border({ width: 1, color: '#FFD700' })
      .onClick(() => {
        this.controller?.close();
        this.enableFlag = true;
      })
      .margin({ bottom: 16 })
  }
  .backgroundColor('#1E1E3F')
  .borderRadius(20)
  .border({ width: 1, color: 'rgba(255,215,0,0.3)' })
  .width(280)
  .scale({ x: this.animScale, y: this.animScale })
  .opacity(this.animOpacity)
}
```
**功能**: 
- **奖品Emoji**: 72px超大字体替代图片（更可靠，无需加载资源）
- **奖品文字**: 金色22px加粗
- **装饰分隔线**: "✨ ✨ ✨"增加视觉层次
- **确认按钮**: 圆角文字按钮，金色边框，点击关闭弹窗并恢复转盘可点击状态
- **弹窗容器**: 深色背景、圆角、金色边框、280px宽。`scale`和`opacity`绑定动画状态变量

---

## 7. 绘图逻辑改进 (DrawModel.ets)

**文件路径**: `entry/src/main/ets/viewmodel/DrawModel.ets`

### 功能说明

与第一版相比完全重写。删除花瓣和外圈小圆点，新增：径向渐变扇形（取代纯色）、外圈发光环、金色装饰旋转环、内圈辉光、中心按钮光晕、Emoji绘制（替代ImageBitmap）。布局全部重调适配暗色主题。

### 代码详解

#### 7.1 draw - 主绘制方法
```typescript
draw(canvasContext: CanvasRenderingContext2D, screenWidth: number, screenHeight: number): void {
  if (CheckEmptyUtils.isEmptyObj(canvasContext)) {
    Logger.error('[DrawModel][draw] canvasContext is empty.');
    return;
  }
  this.canvasContext = canvasContext;
  this.screenWidth = screenWidth;
  this.canvasContext.clearRect(0, 0, this.screenWidth, screenHeight);
  this.canvasContext.translate(this.screenWidth / CommonConstants.TWO,
    screenHeight / CommonConstants.TWO);

  this.drawInnerArc();       // Gradient fan sectors (full wheel)
  this.drawArcText();        // White text with shadow
  this.drawImage();          // Prize emoji

  this.canvasContext.translate(-this.screenWidth / CommonConstants.TWO,
    -screenHeight / CommonConstants.TWO);
}
```
**功能**: 绘制流程简化，始终绘制：渐变扇形→弧形文字→奖品Emoji。注意：调用前需要先调用`drawOuterRing()`、`drawDecoRing()`、`drawInnerCircle()`、`drawCenterGlow()`（由外部在适当时机调用）。

#### 7.2 fillGradientArc - 渐变扇形绘制（新增）
```typescript
fillGradientArc(fillArcData: FillArcData, color1: string, color2: string): void {
  if (CheckEmptyUtils.isEmptyObj(fillArcData)) return;
  const ctx = this.canvasContext;
  if (ctx === undefined) return;
  ctx.beginPath();
  ctx.arc(fillArcData.x, fillArcData.y, fillArcData.radius,
    fillArcData.startAngle, fillArcData.endAngle);
  const gradient = ctx.createRadialGradient(0, 0, 0, 0, 0, fillArcData.radius);
  gradient.addColorStop(0, color1);
  gradient.addColorStop(1, color2);
  ctx.fillStyle = gradient;
  ctx.fill();
}
```
**功能**: 第一版使用纯色填充，现在使用`createRadialGradient`创建径向渐变（从中心辐射）。每个扇区从color1渐变到color2，使转盘更有立体感。

#### 7.3 drawOuterRing - 外圈辉光环（新增）
```typescript
drawOuterRing(): void {
  const radius = this.screenWidth * CommonConstants.OUTER_RING_RATIOS;
  // Glow layer
  ctx.save();
  ctx.shadowColor = ColorConstants.OUTER_RING_GLOW;
  ctx.shadowBlur = CommonConstants.GLOW_BLUR;
  this.fillArc(new FillArcData(0, 0, radius, 0, Math.PI * CommonConstants.TWO),
    ColorConstants.OUTER_RING_COLOR);
  ctx.restore();
  // Main ring
  this.fillArc(new FillArcData(0, 0, radius, 0, Math.PI * CommonConstants.TWO),
    ColorConstants.OUTER_RING_COLOR);
}
```
**功能**: 绘制外圈深蓝色环（带紫色辉光发光效果）。先绘制一层带`shadowBlur=20`的发光层，再绘制主环。`GLOW_BLUR=20`控制辉光扩散范围。

#### 7.4 drawDecoRing - 金色装饰环（新增）
```typescript
drawDecoRing(): void {
  const radius = this.screenWidth * CommonConstants.DECO_RING_RATIOS;
  // Golden ring line
  ctx.save();
  ctx.beginPath();
  ctx.strokeStyle = ColorConstants.DECO_RING_COLOR;
  ctx.lineWidth = 1.5;
  ctx.shadowColor = ColorConstants.DECO_RING_COLOR;
  ctx.shadowBlur = 8;
  ctx.arc(0, 0, radius, 0, Math.PI * CommonConstants.TWO);
  ctx.stroke();
  ctx.restore();
```
**功能**: 在外圈内部绘制金色细圆环，带金色发光效果。`lineWidth=1.5`细线更精致。

```typescript
  // Dots around the ring
  let angle = 0;
  const dotRadius = CommonConstants.DECO_DOT_RADIUS;
  for (let i = 0; i < CommonConstants.DECO_RING_DOT_COUNT; i++) {
    const rad = (angle * Math.PI) / CommonConstants.HALF_CIRCLE;
    const dx = Math.cos(rad) * radius;
    const dy = Math.sin(rad) * radius;
    ctx.save();
    ctx.shadowColor = ColorConstants.DECO_RING_DOT_COLOR;
    ctx.shadowBlur = 6;
    this.fillArc(new FillArcData(dx, dy, dotRadius, 0, Math.PI * CommonConstants.TWO),
      i % 2 === 0 ? ColorConstants.DECO_RING_COLOR : ColorConstants.DECO_RING_DOT_COLOR);
    ctx.restore();
    angle += CommonConstants.CIRCLE / CommonConstants.DECO_RING_DOT_COUNT;
  }
}
```
**功能**: 在装饰环上均匀分布12个金色/橙色交替的小圆点，带辉光效果。通过`cos/sin`三角函数计算点在圆周上的位置。

#### 7.5 drawInnerArc - 渐变扇形（改进）
```typescript
drawInnerArc(): void {
  const radius = this.screenWidth * CommonConstants.INNER_ARC_RATIOS;
  const colors1 = ColorConstants.SECTOR_COLOR1;
  const colors2 = ColorConstants.SECTOR_COLOR2;
  for (let i = 0; i < CommonConstants.COUNT; i++) {
    this.fillGradientArc(
      new FillArcData(0, 0, radius,
        this.startAngle * Math.PI / CommonConstants.HALF_CIRCLE,
        (this.startAngle + this.avgAngle) * Math.PI / CommonConstants.HALF_CIRCLE),
      colors1[i], colors2[i]);
    this.canvasContext?.lineTo(0, 0);
    this.canvasContext?.fill();
    this.startAngle += this.avgAngle;
  }
}
```
**功能**: 绘制6个扇形，使用径向渐变代替纯色。颜色从SECTOR_COLOR1渐变到SECTOR_COLOR2，每对颜色不同（粉色系→紫色系、橙色系→黄色系、蓝色系→青色系交替）。`lineTo(0,0)`确保扇形闭合到中心。

#### 7.6 drawArcText / drawCircularText - 弧形文字（改进）
```typescript
drawArcText(): void {
  const ctx = this.canvasContext;
  ctx.textAlign = CommonConstants.TEXT_ALIGN;
  ctx.textBaseline = CommonConstants.TEXT_BASE_LINE;
  ctx.fillStyle = ColorConstants.TEXT_COLOR;
  ctx.font = StyleConstants.ARC_TEXT_SIZE + CommonConstants.CANVAS_FONT;
  ctx.shadowColor = ColorConstants.TEXT_SHADOW;
  ctx.shadowBlur = CommonConstants.TEXT_SHADOW_BLUR;

  const textArrays = [
    $r('app.string.text_smile'), $r('app.string.text_hamburger'),
    $r('app.string.text_cake'), $r('app.string.text_smile'),
    $r('app.string.text_hamburger'), $r('app.string.text_watermelon')
  ];
  for (let i = 0; i < CommonConstants.COUNT; i++) {
    this.drawCircularText(this.getResourceString(textArrays[i]),
      (this.startAngle + CommonConstants.ARC_START_ANGLE) * Math.PI / CommonConstants.HALF_CIRCLE,
      (this.startAngle + CommonConstants.ARC_END_ANGLE) * Math.PI / CommonConstants.HALF_CIRCLE);
    this.startAngle += this.avgAngle;
  }
  ctx.shadowBlur = 0;
}
```
**功能**: 在扇区外侧绘制白色文字，带黑色阴影增强可读性。文字沿圆弧排列（`drawCircularText`），逐字符计算位置。

```typescript
drawCircularText(textString: string, startAngle: number, endAngle: number): void {
  const radius = this.screenWidth * CommonConstants.INNER_ARC_RATIOS
    - this.screenWidth * CommonConstants.INNER_ARC_RATIOS / CommonConstants.COUNT;
  const angleDecrement = (startAngle - endAngle) / (textString.length - 1);
  let angle = startAngle;
  let index = 0;

  while (index < textString.length) {
    const character = textString.charAt(index);
    ctx.save();
    ctx.beginPath();
    ctx.translate(Math.cos(angle) * radius, -Math.sin(angle) * radius);
    ctx.rotate(Math.PI / CommonConstants.TWO - angle);
    ctx.fillText(character, 0, 0);
    angle -= angleDecrement;
    index++;
    ctx.restore();
  }
}
```
**功能**: 将文字绘制在扇形外沿的弧形上。每个字符通过三角函数计算位置，逐个绘制并旋转使其沿弧线排列。半径位置在扇区外沿（`radius - radius/6`），确保文字在扇区外部不被裁剪。

#### 7.7 drawImage - Emoji绘制（改进）
```typescript
drawImage(): void {
  const ctx = this.canvasContext;
  if (ctx === undefined) return;
  let beginAngle = this.startAngle;
  const emojis: string[] = ['🍉', '🍔', '😊', '🎂', '🍔', '😊'];
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.font = '110px sans-serif';
  ctx.shadowColor = ColorConstants.TEXT_SHADOW;
  ctx.shadowBlur = CommonConstants.TEXT_SHADOW_BLUR;
  for (let i = 0; i < CommonConstants.COUNT; i++) {
    ctx.save();
    ctx.rotate(beginAngle * Math.PI / CommonConstants.HALF_CIRCLE);
    ctx.fillText(emojis[i],
      this.screenWidth * CommonConstants.IMAGE_DX_RATIOS + CommonConstants.IMAGE_SIZE / 2,
      this.screenWidth * CommonConstants.IMAGE_DY_RATIOS + CommonConstants.IMAGE_SIZE / 2);
    beginAngle += this.avgAngle;
    ctx.restore();
  }
}
```
**功能**: 
- 第一版使用`ImageBitmap`加载图片文件，可能因资源加载问题导致显示失败
- 改用**Emoji字符**通过`fillText`绘制（110px超大字体），永远可靠显示
- Emoji位置在扇区内侧（靠近圆心），与外侧的文字不重叠
- 坐标计算：`screenWidth * IMAGE_DX_RATIOS + IMAGE_SIZE/2`，通过比例常量控制偏移

#### 7.8 drawInnerCircle - 内圈辉光（改进）
```typescript
drawInnerCircle(): void {
  // Glow
  ctx.save();
  ctx.shadowColor = ColorConstants.INNER_GLOW_COLOR;
  ctx.shadowBlur = CommonConstants.GLOW_BLUR;
  this.fillArc(new FillArcData(0, 0, this.screenWidth * CommonConstants.INNER_CIRCLE_RATIOS, 0,
    Math.PI * CommonConstants.TWO), ColorConstants.INNER_CIRCLE_COLOR);
  ctx.restore();
  // Main circle
  this.fillArc(new FillArcData(0, 0, this.screenWidth * CommonConstants.INNER_CIRCLE_RATIOS, 0,
    Math.PI * CommonConstants.TWO), ColorConstants.INNER_CIRCLE_COLOR);
  // Inner dot
  this.fillArc(new FillArcData(0, 0, this.screenWidth * CommonConstants.INNER_DOT_RATIOS, 0,
    Math.PI * CommonConstants.TWO), ColorConstants.OUTER_RING_COLOR);
}
```
**功能**: 绘制转盘中心三层圆：紫色辉光层→深蓝色主圆→最中心深色小圆点。辉光营造霓虹灯效果。

#### 7.9 drawCenterGlow - 中心金环（新增）
```typescript
drawCenterGlow(): void {
  ctx.save();
  ctx.shadowColor = ColorConstants.CENTER_BUTTON_GLOW;
  ctx.shadowBlur = 25;
  ctx.beginPath();
  ctx.arc(0, 0, this.screenWidth * CommonConstants.INNER_DOT_RATIOS + 6, 0,
    Math.PI * CommonConstants.TWO);
  ctx.strokeStyle = ColorConstants.CENTER_BUTTON_GLOW;
  ctx.lineWidth = 2;
  ctx.stroke();
  ctx.restore();
}
```
**功能**: 在中心按钮周围绘制金色发光圆环，`shadowBlur=25`制造强烈的辉光扩散效果，突出中心按钮的交互性。

#### 7.10 showPrizeData / getPrizeData
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
**功能**: 与第一版相同的奖品判定逻辑。随机角度除以60°（360°/6）确定落在哪个扇区。

---

## 8. 主页面改进 (CanvasPage.ets)

**文件路径**: `entry/src/main/ets/pages/CanvasPage.ets`

### 功能说明

与第一版相比，从单一转盘页面升级为多Tab应用。新增：Tab导航（转盘/刮刮乐/记录）、签到系统（每日签到、连续天数统计）、渐变背景、星空粒子层。

### 代码详解

#### 8.1 组件定义
```typescript
import WheelView from '../view/WheelView';
import ScratchCardView from '../view/ScratchCardView';
import HistoryView from '../view/HistoryView';
import StarParticle from '../view/StarParticle';
```
**功能**: 导入三个独立视图组件（转盘、刮刮乐、记录、星空粒子）。

```typescript
@Component
struct CanvasPage {
  @State currentIndex: number = 0;
  @State checkedIn: boolean = false;
  @State checkInDays: number = 0;
  @State currentBreakpoint: string = 'sm';
```
**功能**: 
- `currentIndex`: 当前Tab索引（0=转盘，1=刮刮乐，2=记录）
- `checkedIn`: 今天是否已签到
- `checkInDays`: 连续签到天数
- `currentBreakpoint`: 当前断点（'sm'=手机底部Tab，'md'/'lg'等=平板侧边栏）

#### 8.2 aboutToAppear

```typescript
aboutToAppear(): void {
  window.getLastWindow(context)
    .then((wc) => {
      wc.setWindowLayoutFullScreen(true);

      // 断点检测
      const wp = wc.getWindowProperties();
      const vpW = uiContext!.px2vp(wp.windowRect.width);
      const vpH = uiContext!.px2vp(wp.windowRect.height);
      this.currentBreakpoint = Math.min(vpW, vpH) >= 600 ? 'md' : 'sm';

      // 监听窗口变化
      wc.on('windowSizeChange', (size: window.Size) => {
        const w = uiContext!.px2vp(size.width);
        const h = uiContext!.px2vp(size.height);
        this.currentBreakpoint = Math.min(w, h) >= 600 ? 'md' : 'sm';
      });
    })
    .catch((e: Error) => { Logger.error('Fullscreen error: ' + JSON.stringify(e)); });
  this.checkDaily();
}
```
**功能**: 设置全屏 + 检测初始断点（短边≥600vp为平板模式）+ 监听窗口大小变化自动切换布局 + 检查今日签到状态。

#### 8.3 checkDaily - 签到检查
```typescript
checkDaily(): void {
  const today = new Date().toDateString();
  const lastCheckIn = AppStorage.get<string>('last_checkin') || '';
  const streak = AppStorage.get<number>('checkin_streak') || 0;

  if (lastCheckIn === today) {
    this.checkedIn = true;
    this.checkInDays = streak;
  } else {
    this.checkedIn = false;
    this.checkInDays = streak;
  }
}
```
**功能**: 读取AppStorage中的最后签到日期和连续天数。如果最后签到日期是今天，标记已签到；否则标记未签到（但仍保留连续天数，待签到后确认是否连续）。

#### 8.4 doCheckIn - 执行签到
```typescript
doCheckIn(): void {
  const today = new Date().toDateString();
  const lastCheckIn = AppStorage.get<string>('last_checkin') || '';
  let streak = AppStorage.get<number>('checkin_streak') || 0;

  // Check if consecutive day
  const yesterday = new Date(Date.now() - 86400000).toDateString();
  if (lastCheckIn === yesterday) {
    streak++;
  } else if (lastCheckIn !== today) {
    streak = 1;
  }

  AppStorage.set('last_checkin', today);
  AppStorage.set('checkin_streak', streak);
  this.checkedIn = true;
  this.checkInDays = streak;
}
```
**功能**: 签到逻辑：
- 如果昨天签过到（`lastCheckIn === yesterday`）：连续天数+1
- 如果今天还没签到且昨天也没签：重置为1天
- 更新AppStorage中的签到日期和连续天数
- `yesterday`通过`Date.now() - 86400000`（24小时毫秒数）计算

#### 8.5 build - UI构建
```typescript
build() {
  Stack() {
    // Gradient background
    Column()
      .width(StyleConstants.FULL_PERCENT)
      .height(StyleConstants.FULL_PERCENT)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [
          [ColorConstants.BG_COLOR_TOP, 0],
          [ColorConstants.BG_COLOR_MID, 0.5],
          [ColorConstants.BG_COLOR_BOTTOM, 1],
        ]
      })
```
**功能**: 三层渐变背景（深紫→紫蓝→深蓝），替代第一版的背景图片。

```typescript
    // Star particle overlay
    StarParticle()
```
**功能**: 在背景上覆盖星空粒子层，营造沉浸氛围。

```typescript
    // Main content column (to fit Tabs + check-in badge)
    Column() {
      // Check-in badge (top-right corner, only on first tab)
      if (this.currentIndex === 0) {
        Row() {
          if (this.checkedIn) {
            Text(`✅ 已签到 ${this.checkInDays} 天`)
              .fontSize(11).fontColor('rgba(255,215,0,0.6)')
          } else {
            Text('📅 签到')
              .fontSize(12).fontColor('#FFD700').fontWeight(600)
              .onClick(() => { this.doCheckIn(); })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .padding({ right: 16, top: 8 })
      }
```
**功能**: 
- 仅在第一Tab（转盘页）右上角显示签到按钮
- 未签到：金色"📅 签到"文字，点击执行签到
- 已签到：半透明金色"✅ 已签到 X 天"

```typescript
      // Tabs (响应式: 手机底部Tab / 平板左侧侧边栏)
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
**功能**: 
- `Tabs`组件：`barPosition`在手机端为`End`(底部)，平板端为`Start`(左侧)
- `.vertical()`控制Tab方向，平板端为竖向侧边栏
- `.barWidth()`平板端90vp侧边栏宽度
- `.onChange`监听Tab切换更新`currentIndex`

#### 8.6 tabBuilder - 自定义标签栏（已更新为响应式）

```typescript
@Builder
tabBuilder(index: number) {
  const isTablet: boolean = this.currentBreakpoint !== 'sm';
  const isActive: boolean = index === this.currentIndex;
  Column() {
    if (index === 0) {
      Text('🎡').fontSize(isTablet ? 26 : 18).margin({ bottom: isTablet ? 6 : 1 })
      Text('转盘').fontSize(isTablet ? 13 : 10).fontColor('#FFFFFF')
        .fontWeight(isActive ? 700 : 400)
    } else if (index === 1) {
      Text('🎫').fontSize(isTablet ? 26 : 18).margin({ bottom: isTablet ? 6 : 1 })
      Text('刮刮乐').fontSize(isTablet ? 13 : 10).fontColor('#FFFFFF')
        .fontWeight(isActive ? 700 : 400)
    } else {
      Text('📊').fontSize(isTablet ? 26 : 18).margin({ bottom: isTablet ? 6 : 1 })
      Text('记录').fontSize(isTablet ? 13 : 10).fontColor('#FFFFFF')
        .fontWeight(isActive ? 700 : 400)
    }
  }
  .padding(isTablet ? { top: 20, bottom: 20 } : { top: 6, bottom: 10 })
  .width(isTablet ? '100%' : 72)
  .backgroundColor(isTablet && isActive ? 'rgba(255,215,0,0.12)' : 'transparent')
  .borderRadius(isTablet ? 8 : 0)
  .border({
    width: (isTablet && isActive) ? { left: 3 } : {},
    color: (isTablet && isActive) ? { left: '#FFD700' } : {}
  })
}
```
**功能**: 
- **手机模式(sm)**：底部水平Tab，图标18px、文字10px、宽度72vp，选中项字体加粗
- **平板模式(md+)**：左侧竖向Tab侧边栏，图标26px、文字13px、宽度100%填充90vp侧边栏，选中项有金色半透明背景 + 左侧3px金色指示条 + 8px圆角

### 8.7 一次开发多端部署 — 响应式布局

#### 8.7.1 设计目标

| 断点 | 短边宽度 | 典型设备 | 导航方式 |
|------|---------|---------|---------|
| sm | [320, 600)vp | 手机（竖屏+横屏） | 底部 Tab |
| md+ | [600, +∞)vp | 平板（竖屏+横屏） | 左侧竖向 Tab 侧边栏 |

手机横屏时短边仍 < 600vp，自动归入 sm 断点保持底部 Tab。

#### 8.7.2 核心思路：Tabs 组件原生响应式

参考 ArkUI 官方"一次开发多端部署"方案，利用 `Tabs` 组件自身的 `vertical` + `barPosition` 属性配合断点系统，**无需手写两套布局**。同一套 `TabContent` + `tabBar` Builder，仅根据断点切换 3 个属性：

```
sm 断点:
  Tabs({ barPosition: BarPosition.End })
  .vertical(false)      → 底部水平 Tab

md+ 断点:
  Tabs({ barPosition: BarPosition.Start })
  .vertical(true)       → 左侧竖向 Tab（等于侧边栏）
  .barWidth(90)         → 侧边栏宽度
```

#### 8.7.3 新增状态变量

```typescript
@State currentBreakpoint: string = 'sm';
```

#### 8.7.4 aboutToAppear — 断点检测与监听

```typescript
aboutToAppear(): void {
  window.getLastWindow(context)
    .then((wc) => {
      wc.setWindowLayoutFullScreen(true);

      // 获取初始窗口尺寸，计算断点
      const wp = wc.getWindowProperties();
      const vpW = uiContext!.px2vp(wp.windowRect.width);
      const vpH = uiContext!.px2vp(wp.windowRect.height);
      this.currentBreakpoint = Math.min(vpW, vpH) >= 600 ? 'md' : 'sm';

      // 监听窗口尺寸变化（折叠屏展开/关闭、分屏等场景）
      wc.on('windowSizeChange', (size: window.Size) => {
        const w = uiContext!.px2vp(size.width);
        const h = uiContext!.px2vp(size.height);
        this.currentBreakpoint = Math.min(w, h) >= 600 ? 'md' : 'sm';
      });
    })
    .catch((e: Error) => { Logger.error('Fullscreen error: ' + JSON.stringify(e)); });
  this.checkDaily();
}
```

**关键设计决策**：
- 使用 `Math.min(width, height)`（短边）而非宽度来判断，确保手机横屏不会被误判为平板
- 阈值 600vp 对应 ArkUI 断点系统中 sm → md 的分界线
- `windowSizeChange` 事件保证运行时窗口变化（如分屏、折叠屏展开）时自动切换布局

#### 8.7.5 Tabs 组件响应式属性

```typescript
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

**各属性断点对照表**：

| 属性 | sm (手机) | md+ (平板) |
|------|----------|-----------|
| `barPosition` | `End` | `Start` |
| `vertical` | `false` | `true` |
| `barWidth` | `'100%'` | `90`vp |
| `barHeight` | `undefined`（默认） | `'100%'` |

#### 8.7.6 子组件无需改动

三个 View 组件（`WheelView`、`ScratchCardView`、`HistoryView`）使用 `screenWidth * ratio` 比例自适应，在平板端自动等比例放大，无需任何修改。

#### 8.7.7 范围与限制

- **已实现**：手机底部Tab / 平板左侧侧边栏自适应切换
- **不涉及**：折叠屏展开/闭合适配、多HAP工程拆分、车机/电视/手表适配、SysCap能力检测

---

## 9. 常量配置改进

### 9.1 ColorConstants.ets (完全重写)

**文件路径**: `entry/src/main/ets/common/constants/ColorConstants.ets`

**对比第一版**：从暖色明亮主题（粉/黄/绿/橙色）改为暗色霓虹主题（深紫/蓝/金色发光）。

```typescript
export default class ColorConstants {
  /** Sector gradient color1 (6 sectors) */
  static readonly SECTOR_COLOR1: string[] = [
    '#FF6B9D', '#FF9A56', '#00D2FF',
    '#FF6B9D', '#FF9A56', '#00D2FF'
  ];

  /** Sector gradient color2 (6 sectors) */
  static readonly SECTOR_COLOR2: string[] = [
    '#C44AFF', '#FFD93D', '#3A7BD5',
    '#C44AFF', '#FFD93D', '#3A7BD5'
  ];
```
**功能**: 6个扇区的渐变颜色对：
- 扇区1/4：粉色→紫色渐变
- 扇区2/5：橙色→黄色渐变  
- 扇区3/6：青色→蓝色渐变

```typescript
  /** Outer ring */
  static readonly OUTER_RING_COLOR: string = '#1A1A2E';
  static readonly OUTER_RING_GLOW: string = '#4A4A8A';

  /** Decorative rotating ring */
  static readonly DECO_RING_COLOR: string = '#FFD700';
  static readonly DECO_RING_DOT_COLOR: string = '#FFA500';

  /** Inner circle */
  static readonly INNER_CIRCLE_COLOR: string = '#2D2D5E';
  static readonly INNER_GLOW_COLOR: string = '#6C6CFF';

  /** Center button */
  static readonly CENTER_BUTTON_GLOW: string = '#FFD700';
  static readonly CENTER_BUTTON_INNER: string = '#FFFFFF';

  /** Text */
  static readonly TEXT_COLOR: string = '#FFFFFF';
  static readonly TEXT_SHADOW: string = '#000000';

  /** Background */
  static readonly BG_COLOR_TOP: string = '#0F0C29';
  static readonly BG_COLOR_MID: string = '#302B63';
  static readonly BG_COLOR_BOTTOM: string = '#24243E';

  /** Star particle */
  static readonly STAR_COLOR: string = '#FFFFFF';

  /** Scratch card */
  static readonly SCRATCH_COAT_COLOR1: string = '#FFD700';
  static readonly SCRATCH_COAT_COLOR2: string = '#FFA500';
}
```
**功能**: 
- 外圈：深蓝色+紫色辉光
- 装饰环：金色+橙色圆点
- 内圈：蓝紫色+蓝色辉光
- 中心按钮：金色光晕
- 文字：白色带黑色阴影
- 背景：三段式渐变（深紫→紫蓝→深蓝）
- 刮刮乐涂层：金色渐变

### 9.2 CommonConstants.ets (重写)

**新增常量**：
```typescript
static readonly OUTER_RING_RATIOS: number = 0.42;      // 外圈半径比例
static readonly DECO_RING_RATIOS: number = 0.39;       // 装饰环半径比例
static readonly INNER_ARC_RATIOS: number = 0.45;       // 扇形半径比例（对比第一版0.336）
static readonly INNER_CIRCLE_RATIOS: number = 0.30;    // 内圈半径比例（对比第一版0.356）
static readonly INNER_DOT_RATIOS: number = 0.26;       // 内圈中心点半径比例
static readonly DECO_DOT_RADIUS: number = 3;           // 装饰圆点半径
static readonly DECO_RING_DOT_COUNT: number = 12;      // 装饰圆点数量

static readonly IMAGE_SIZE: number = 40;               // 奖品图片尺寸
static readonly IMAGE_DX_RATIOS: number = 0.10;        // Emoji X偏移比例（对比第一版0.114）
static readonly IMAGE_DY_RATIOS: number = 0.05;        // Emoji Y偏移比例（对比第一版0.052）

// 弧文字设置
static readonly ARC_START_ANGLE: number = 40;          // 弧形文字起始偏移角度
static readonly ARC_END_ANGLE: number = 20;            // 弧形文字结束偏移角度

// 辉光效果
static readonly GLOW_BLUR: number = 20;                // 辉光模糊半径
static readonly TEXT_SHADOW_BLUR: number = 4;          // 文字阴影模糊半径
```
**功能**: 所有布局比例调整适配新的暗色主题设计。`INNER_ARC_RATIOS`从0.336增加到0.45使扇形占据更大面积。

### 9.3 StyleConstants.ets (更新)

```typescript
static readonly CENTER_IMAGE_WIDTH: string = '19.3%';   // 中心按钮宽度
static readonly CENTER_IMAGE_HEIGHT: string = '10.6%';  // 中心按钮高度
static readonly ARC_TEXT_SIZE: number = uiContext!.fp2px(22);  // 弧文字大小（从14fp改为22fp）
```
**功能**: 弧文字从14fp增大到22fp，提升可读性。新增中心按钮尺寸常量。

---

## 10. 功能流程分析

### 10.1 应用启动流程
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
设置全屏 → 检查签到状态
    ↓
CanvasPage.build()
    ↓
StarParticle 星空粒子开始动画
    ↓
WheelView.aboutToAppear()
    ↓
获取屏幕尺寸 → 订阅语言事件 → 开始按钮呼吸动效
    ↓
### (画布就绪后)
Canvas.onReady()
    ↓
DrawModel.drawOuterRing()      外圈辉光环
DrawModel.drawDecoRing()       金色装饰环+圆点
DrawModel.drawInnerCircle()    内圈辉光+中心圆
DrawModel.drawInnerArc()       6个渐变扇形
DrawModel.drawArcText()        弧形奖品文字
DrawModel.drawImage()          奖品Emoji
DrawModel.drawCenterGlow()     中心按钮光晕
```

### 10.2 刮刮乐流程
```
用户切换到"刮刮乐"Tab
    ↓
ScratchCardView.onReady()
    ↓
initCard() → pickPrize()随机选奖 → drawCard()绘制卡片
    ↓
--- 涂层绘制 ---
roundRect()绘制圆角卡片路径
绘制奖品文字+Emoji在底层
绘制金色线性渐变涂层在上层
    ↓
用户手指滑动刮擦
    ↓
onTouchHandler (Down/Move/Up)
    ↓
scratchAt(x, y)
    ↓
globalCompositeOperation = 'destination-out' 擦除涂层
    ↓
计算刮开百分比
    ↓
≥45%? → revealCard()
    ↓
清除所有涂层 → 显示庆祝界面 → 保存历史记录
    ↓
用户点击"再来一张"
    ↓
重新 initCard()
```

### 10.3 连抽流程
```
用户点击"连抽 3 次"或"连抽 5 次"
    ↓
startMulti(n)
    ↓
enableFlag = false → 禁用所有按钮
    ↓
spinOnce() → 旋转动画(4秒)
    ↓
onSpinFinished()
    ↓
multiRemaining-- → 记录此次结果
    ↓
还有剩余次数? → 800ms后自动 spinOnce()
    ↓
无剩余次数? → showMultiSummary()
    ↓
统计每种奖品出现次数 → 显示汇总弹窗 → 触发彩纸
```

### 10.4 签到流程
```
页面加载 → checkDaily()
    ↓
AppStorage读取 last_checkin 和 checkin_streak
    ↓
已签到? → 显示"✅ 已签到 X 天"
未签到? → 显示"📅 签到"按钮
    ↓
用户点击"📅 签到"
    ↓
doCheckIn()
    ↓
检查昨天是否签到 → 连续天数+1或重置为1
    ↓
AppStorage持久化 → UI更新
```

### 10.5 彩纸庆祝流程
```
中奖触发 → triggerConfetti()
    ↓
confettiKey++ → 重新创建ConfettiEffect组件
    ↓
aboutToAppear → trigger()
    ↓
生成80个随机粒子（位置/速度/颜色/形状）
    ↓
animate() 循环 (16ms/帧)
    ↓
每帧：更新位置(+速度+重力) → 降低透明度 → 绘制粒子
    ↓
粒子全部消失或达到200帧 → 清除画布停止
```

### 10.6 历史记录数据流
```
抽奖完成 / 刮奖揭晓
    ↓
addHistory() / saveHistory()
    ↓
格式: "timestamp|imageUrl"
存储: AppStorage('wheel_history')
    ↓
切换到"记录"Tab
    ↓
HistoryView.onPageShow() → loadHistory()
    ↓
解析: split(',') → split('|')
    ↓
倒序显示 → 统计中奖率
    ↓
List组件展示
```

---

## 总结

与第一版相比，本项目从单一转盘抽奖应用升级为集**转盘抽奖、刮刮乐、历史记录**三大功能于一体的综合性抽奖应用。新增以下技术亮点：

1. **Canvas图层擦除技术**：使用`globalCompositeOperation = 'destination-out'`实现刮刮乐涂层擦除
2. **粒子系统**：彩纸庆祝粒子（重力、淡出、旋转）和星空呼吸粒子（正弦波脉冲）
3. **多Tab导航**：ArkUI Tabs组件实现页面切换
4. **连抽机制**：自动连续抽奖 + 结果汇总统计
5. **签到系统**：基于AppStorage的每日签到 + 连续天数持久化
6. **视觉升级**：径向渐变扇形、多层辉光效果、渐变星空背景、弹跳入场动画
7. **响应式交互**：按钮呼吸动效、页面切换自动刷新、语言切换实时更新
