import Logger from '../common/utils/Logger';
import StyleConstants from '../common/constants/StyleConstants';
import CommonConstants from '../common/constants/CommonConstants';
import { window } from '@kit.ArkUI';
import { Context } from '@kit.AbilityKit';

const uiContext: UIContext | undefined = AppStorage.get('uiContext');
let context: Context = uiContext!.getHostContext()!;

interface ReelState {
  currentOffset: number;
  speed: number;
  stopped: boolean;
  finalIndex: number;
  stopDelay: number;
  stopping: boolean;
  stopStart: number;
  stopTarget: number;
  stopDistance: number;
}

@Component
export default struct SlotMachineView {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  @State screenWidth: number = 360;
  @State screenHeight: number = 640;
  @State isSpinning: boolean = false;
  @State resultText: string = '';
  @State showResult: boolean = false;
  @State resultEmojis: string[] = ['', '', ''];
  @State winType: number = 0;

  private reelCount: number = 3;
  private visibleItems: number = 3;
  private itemHeight: number = 70;
  private reelWidth: number = 0;
  private reelGap: number = 4;
  private reels: ReelState[] = [];
  private animTimer: number = -1;
  private symbols: string[] = [
    CommonConstants.WATERMELON_IMAGE_URL,
    CommonConstants.HAMBURG_IMAGE_URL,
    CommonConstants.CAKE_IMAGE_URL,
    CommonConstants.SMILE_IMAGE_URL,
  ];
  private symbolEmoji: string[] = ['🍉', '🍔', '🎂', '😊'];
  private finalSymbols: number[] = [0, 0, 0];

  aboutToAppear(): void {
    window.getLastWindow(context)
      .then((windowClass: window.Window) => {
        const wp = windowClass.getWindowProperties();
        this.screenWidth = this.getUIContext().px2vp(wp.windowRect.width);
        this.screenHeight = this.getUIContext().px2vp(wp.windowRect.height);
        this.calculateLayout();
        this.resetReels();
      })
      .catch(() => {});
  }

  aboutToDisappear(): void {
    if (this.animTimer > 0) clearTimeout(this.animTimer);
  }

  calculateLayout(): void {
    const totalReelWidth: number = this.screenWidth * 0.92;
    this.reelWidth = (totalReelWidth - this.reelGap * (this.reelCount - 1)) / this.reelCount;
    this.itemHeight = this.reelWidth * 1.6;
  }

  resetReels(): void {
    this.reels = [];
    for (let i = 0; i < this.reelCount; i++) {
      this.reels.push({
        currentOffset: 0,
        speed: 0,
        stopped: true,
        finalIndex: 0,
        stopDelay: 0,
        stopping: false,
        stopStart: 0,
        stopTarget: 0,
        stopDistance: 0,
      });
    }
    this.isSpinning = false;
    this.showResult = false;
    this.resultText = '';
    this.resultEmojis = ['', '', ''];
    this.winType = 0;
    this.drawStatic();
  }

  drawStatic(): void {
    const ctx: CanvasRenderingContext2D = this.canvasContext;
    ctx.clearRect(0, 0, this.screenWidth, this.screenHeight);

    const startY: number = this.screenHeight * 0.15;
    const totalReelWidth: number = this.reelWidth * this.reelCount + this.reelGap * (this.reelCount - 1);
    const reelAreaX: number = (this.screenWidth - totalReelWidth) / 2;

    for (let r = 0; r < this.reelCount; r++) {
      const rx: number = reelAreaX + r * (this.reelWidth + this.reelGap);
      this.drawReelFrame(ctx, rx, startY);

      ctx.save();
      ctx.font = '130px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillStyle = '#FFFFFF';
      ctx.fillText('🍉', rx + this.reelWidth / 2, startY + this.itemHeight * 1.5);
      ctx.restore();
    }
  }

  drawReelFrame(ctx: CanvasRenderingContext2D, x: number, y: number): void {
    const totalH: number = this.itemHeight * this.visibleItems;
    ctx.save();
    ctx.fillStyle = '#1A1A2E';
    ctx.shadowColor = '#4A4A8A';
    ctx.shadowBlur = 10;
    this.roundRect(ctx, x, y, this.reelWidth, totalH, 8);
    ctx.fill();
    ctx.restore();

    ctx.save();
    this.roundRect(ctx, x, y, this.reelWidth, totalH, 8);
    ctx.strokeStyle = '#FFD700';
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.restore();

    for (let i = 1; i < this.visibleItems; i++) {
      ctx.save();
      ctx.strokeStyle = 'rgba(255,215,0,0.2)';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(x + 4, y + this.itemHeight * i);
      ctx.lineTo(x + this.reelWidth - 4, y + this.itemHeight * i);
      ctx.stroke();
      ctx.restore();
    }

    ctx.save();
    ctx.fillStyle = 'rgba(255,215,0,0.08)';
    ctx.fillRect(x + 2, y + this.itemHeight, this.reelWidth - 4, this.itemHeight);
    ctx.restore();
  }

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

  spin(): void {
    if (this.isSpinning) return;
    this.isSpinning = true;
    this.showResult = false;
    this.resultText = '';
    this.resultEmojis = ['', '', ''];
    this.winType = 0;
    this.calculateLayout();

    const now: number = Date.now();
    for (let i = 0; i < this.reelCount; i++) {
      this.reels[i] = {
        currentOffset: i * 200,
        speed: 65 + Math.random() * 25,
        stopped: false,
        finalIndex: 0,
        stopDelay: 800 + i * 400,
        stopping: false,
        stopStart: 0,
        stopTarget: 0,
        stopDistance: 0,
      };
    }

    this.animateReels();
  }

  animateReels(): void {
    const ctx: CanvasRenderingContext2D = this.canvasContext;
    const now: number = Date.now();
    let allStopped: boolean = true;

    ctx.clearRect(0, 0, this.screenWidth, this.screenHeight);

    const startY: number = this.screenHeight * 0.15;
    const totalReelWidth: number = this.reelWidth * this.reelCount + this.reelGap * (this.reelCount - 1);
    const reelAreaX: number = (this.screenWidth - totalReelWidth) / 2;
    const totalSymbols: number = this.symbols.length;

    for (let r = 0; r < this.reelCount; r++) {
      const reel: ReelState = this.reels[r];
      const rx: number = reelAreaX + r * (this.reelWidth + this.reelGap);

      if (!reel.stopped) {
        if (now > reel.stopDelay && !reel.stopping) {
          // Start stopping: calculate the next symbol boundary
          reel.stopping = true;
          reel.stopStart = reel.currentOffset;
          const N: number = Math.ceil(reel.currentOffset / this.itemHeight);
          reel.stopTarget = N * this.itemHeight;
          reel.stopDistance = reel.stopTarget - reel.stopStart;
          // Ensure minimum movement distance for smooth deceleration
          if (reel.stopDistance < this.itemHeight * 0.3) {
            reel.stopTarget += this.itemHeight;
            reel.stopDistance = reel.stopTarget - reel.stopStart;
          }
        }

        if (reel.stopping) {
          const remaining: number = reel.stopTarget - reel.currentOffset;
          if (remaining <= 0.5) {
            reel.currentOffset = reel.stopTarget;
            const N: number = Math.round(reel.stopTarget / this.itemHeight);
            reel.finalIndex = ((N + 1) % totalSymbols + totalSymbols) % totalSymbols;
            reel.stopped = true;
          } else {
            // Fast deceleration: use proportion of remaining distance with ease-out
            const progress: number = 1 - (remaining / reel.stopDistance);
            const t: number = 1 - Math.pow(1 - progress, 2);
            reel.currentOffset = reel.stopStart + t * reel.stopDistance;
          }
        } else {
          // Constant high speed
          reel.currentOffset += reel.speed;
        }
      }

      if (!reel.stopped) allStopped = false;

      this.drawReelFrame(ctx, rx, startY);

      ctx.save();
      ctx.beginPath();
      ctx.rect(rx + 2, startY + 2, this.reelWidth - 4, this.itemHeight * this.visibleItems - 4);
      ctx.clip();

      const baseIdx: number = Math.floor(reel.currentOffset / this.itemHeight) % totalSymbols;
      const yOffset: number = -(reel.currentOffset % this.itemHeight);

      for (let i = -1; i < this.visibleItems + 1; i++) {
        let idx: number = ((baseIdx + i) % totalSymbols + totalSymbols) % totalSymbols;
        const iy: number = startY + i * this.itemHeight + yOffset;
        ctx.save();
        ctx.font = '130px sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillStyle = '#FFFFFF';
        ctx.fillText(this.symbolEmoji[idx], rx + this.reelWidth / 2, iy + this.itemHeight / 2);
        ctx.restore();
      }
      ctx.restore();
    }

    if (!allStopped) {
      this.animTimer = setTimeout(() => { this.animateReels(); }, 16);
    } else {
      this.isSpinning = false;
      this.finalSymbols = [
        this.reels[0].finalIndex,
        this.reels[1].finalIndex,
        this.reels[2].finalIndex,
      ];
      this.checkResult();
    }
  }

  checkResult(): void {
    const s0: number = this.finalSymbols[0];
    const s1: number = this.finalSymbols[1];
    const s2: number = this.finalSymbols[2];

    this.resultEmojis = [
      this.symbolEmoji[s0],
      this.symbolEmoji[s1],
      this.symbolEmoji[s2],
    ];

    if (s0 === s1 && s1 === s2) {
      this.resultText = this.symbolEmoji[s0] + ' × 3  大奖！🎉';
      this.winType = 2;
    } else if (s0 === s1 || s1 === s2 || s0 === s2) {
      this.resultText = '👏 两个相同，小奖！';
      this.winType = 1;
    } else {
      this.resultText = '😅 没中奖，再试一次！';
      this.winType = 0;
    }
    this.saveHistory();
    this.showResult = true;
  }

  saveHistory(): void {
    const key: string = 'wheel_history';
    const raw: string = AppStorage.get<string>(key) || '';
    const img: string = this.symbols[this.finalSymbols[0]] || '';
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

  build() {
    Column() {
      Text('🎰 老虎机')
        .fontSize(24)
        .fontColor('#FFFFFF')
        .fontWeight(700)
        .margin({ top: 12, bottom: 4 })

      Text('三连相同即中大奖！')
        .fontSize(14)
        .fontColor('rgba(255,255,255,0.5)')
        .margin({ bottom: 8 })

      Canvas(this.canvasContext)
        .layoutWeight(1)
        .width('100%')
        .onReady(() => {
          if (this.screenWidth > 100) {
            this.calculateLayout();
            this.resetReels();
          }
        })

      if (this.showResult) {
        Column() {
          Text(this.resultEmojis[0] + '  ' + this.resultEmojis[1] + '  ' + this.resultEmojis[2])
            .fontSize(40)
            .fontColor('#FFFFFF')
            .fontWeight(700)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 4 })
          Text(this.resultText)
            .fontSize(this.winType === 2 ? 24 : 18)
            .fontColor(this.winType === 2 ? '#FF6B6B' : '#FFD700')
            .fontWeight(700)
            .textAlign(TextAlign.Center)
            .lineHeight(28)
        }
        .margin({ bottom: 12 })
      }

      Button(this.isSpinning ? '🎰 旋转中...' : '🎰 开始旋转')
        .width(220).height(50)
        .backgroundColor(this.isSpinning ? '#555' : '#FFD700')
        .fontColor('#1A1A2E').fontWeight(700)
        .borderRadius(25).fontSize(18)
        .enabled(!this.isSpinning)
        .margin({ bottom: 20 })
        .onClick(() => { this.spin(); })
    }
    .width(StyleConstants.FULL_PERCENT)
    .height(StyleConstants.FULL_PERCENT)
  }
}
