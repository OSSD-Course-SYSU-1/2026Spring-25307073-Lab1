import StyleConstants from '../common/constants/StyleConstants';
import CommonConstants from '../common/constants/CommonConstants';
import ColorConstants from '../common/constants/ColorConstants';
import { window } from '@kit.ArkUI';

const uiContext: UIContext | undefined = AppStorage.get('uiContext');

interface ScratchPrize {
  message: Resource;
  imageSrc: string;
}

interface SparkleParticle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  size: number;
  color: string;
  life: number;
  maxLife: number;
}

@Component
export default struct ScratchCardView {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  @State screenWidth: number = 360;
  @State screenHeight: number = 640;
  @State scratchPercent: number = 0;
  @State isRevealed: boolean = false;
  @State hasNewCard: boolean = true;
  @State scaleFactor: number = 1.0;
  @StorageProp('contentWidth') contentWidth: number = 360;
  @StorageProp('contentHeight') contentHeight: number = 640;
  @State pageLandscape: boolean = false;
  private cardX: number = 0;
  private cardY: number = 0;
  private cardW: number = 0;
  private cardH: number = 0;
  private scratchedPixels: number = 0;
  private totalPixels: number = 0;
  private isScratching: boolean = false;
  private canvasInitialized: boolean = false;
  private sparkleContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private sparkles: SparkleParticle[] = [];
  private sparkleTimer: number = -1;
  private sparkleColors: string[] = ['#FFD700', '#FFFFFF', '#FFA500', '#FFE4B5'];
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

  aboutToDisappear(): void {
    if (this.sparkleTimer > 0) clearTimeout(this.sparkleTimer);
  }

  updateCanvasSize(): void {
    const fullW: number = this.contentWidth > 0 ? this.contentWidth : 360;
    const fullH: number = this.contentHeight > 0 ? this.contentHeight : 640;
    this.applyCanvasSize(fullW, fullH);
  }

  updateCanvasSizeFromWindow(fullW: number, fullH: number): void {
    const minDim: number = Math.min(fullW, fullH);
    const smallScreen: boolean = minDim < 600;
    const sidebarW: number = smallScreen ? 0 : 90;
    const bottomTabH: number = smallScreen ? (fullW > fullH ? 50 : 64) : 0;
    this.applyCanvasSize(fullW - sidebarW, fullH - bottomTabH);
  }

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

  initCard(): void {
    this.isRevealed = false;
    this.scratchedPixels = 0;
    this.scratchPercent = 0;
    this.isScratching = false;
    this.hasNewCard = true;
    this.pickPrize();
    this.drawCard();
  }

  pickPrize(): void {
    const idx = Math.floor(Math.random() * this.allPrizes.length);
    this.currentPrize = this.allPrizes[idx];
  }

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
    this.totalPixels = cw * ch;

    // Clear
    ctx.clearRect(0, 0, this.screenWidth, this.screenHeight);

    // --- Layer 1: Prize content ---
    // Card background
    ctx.save();
    this.roundRect(ctx, this.cardX, this.cardY, cw, ch, 16);
    ctx.fillStyle = '#1E1E3F';
    ctx.fill();
    ctx.restore();

    // Decorative border
    ctx.save();
    this.roundRect(ctx, this.cardX, this.cardY, cw, ch, 16);
    ctx.strokeStyle = '#FFD700';
    ctx.lineWidth = 2 * this.scaleFactor;
    ctx.stroke();
    ctx.restore();

    // Prize text
    ctx.save();
    ctx.fillStyle = '#FFD700';
    ctx.font = `${22 * this.scaleFactor}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    const prizeStr = this.getPrizeString();
    ctx.fillText(prizeStr, this.screenWidth / 2, this.cardY + ch * 0.35);
    ctx.restore();

    // Prize image (emoji)
    const imgSize = 80 * this.scaleFactor;
    ctx.save();
    ctx.font = `${64 * this.scaleFactor}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillStyle = '#FFFFFF';
    ctx.shadowColor = 'rgba(0,0,0,0.5)';
    ctx.shadowBlur = 6;
    ctx.fillText(this.getPrizeEmoji(), this.screenWidth / 2, this.cardY + ch * 0.45 + imgSize / 2);
    ctx.restore();

    // Hint text
    ctx.save();
    ctx.fillStyle = 'rgba(255,255,255,0.3)';
    ctx.font = `${14 * this.scaleFactor}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.fillText('刮开涂层查看奖品', this.screenWidth / 2, this.cardY + ch * 0.78);
    ctx.restore();

    // --- Layer 2: Gold coating ---
    ctx.save();
    this.roundRect(ctx, this.cardX, this.cardY, cw, ch, 16);
    ctx.clip();

    const gradient = ctx.createLinearGradient(this.cardX, this.cardY, this.cardX + cw, this.cardY + ch);
    gradient.addColorStop(0, ColorConstants.SCRATCH_COAT_COLOR2);
    gradient.addColorStop(0.5, ColorConstants.SCRATCH_COAT_COLOR1);
    gradient.addColorStop(1, ColorConstants.SCRATCH_COAT_COLOR2);
    ctx.fillStyle = gradient;
    ctx.fillRect(this.cardX, this.cardY, cw, ch);

    // Scratch hint text on coating
    ctx.fillStyle = 'rgba(255,255,255,0.5)';
    ctx.font = `${16 * this.scaleFactor}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.fillText('👆 用手指刮开', this.screenWidth / 2, this.cardY + ch / 2);
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

  scratchAt(x: number, y: number): void {
    const ctx = this.canvasContext;
    ctx.save();
    ctx.globalCompositeOperation = 'destination-out';
    ctx.beginPath();
    const sr = 24 * this.scaleFactor;
    ctx.arc(x, y, sr, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();

    this.spawnSparkles(x, y);

    this.scratchedPixels += Math.PI * sr * sr;
    this.scratchPercent = Math.min(100, Math.round((this.scratchedPixels / this.totalPixels) * 100));

    if (this.scratchPercent >= 45 && !this.isRevealed) {
      this.revealCard();
    }
  }

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

  newCard(): void {
    this.sparkles = [];
    if (this.sparkleTimer > 0) clearTimeout(this.sparkleTimer);
    this.sparkleTimer = -1;
    this.initCard();
  }

  spawnSparkles(x: number, y: number): void {
    for (let i = 0; i < 4; i++) {
      const angle: number = Math.random() * Math.PI * CommonConstants.TWO;
      const speed: number = Math.random() * 3 + 1;
      this.sparkles.push({
        x: x, y: y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - 1,
        size: Math.random() * 4 + 2,
        color: this.sparkleColors[Math.floor(Math.random() * this.sparkleColors.length)],
        life: 1,
        maxLife: Math.random() * 15 + 15,
      });
    }
    this.startSparkleTimer();
  }

  startSparkleTimer(): void {
    if (this.sparkleTimer > 0) return;
    const animate = (): void => {
      const ctx = this.sparkleContext;
      ctx.clearRect(0, 0, this.screenWidth, this.screenHeight);
      let alive: boolean = false;

      for (let i = 0; i < this.sparkles.length; i++) {
        const p: SparkleParticle = this.sparkles[i];
        if (p.life <= 0) continue;
        alive = true;
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.05;
        p.life -= 1 / p.maxLife;

        ctx.save();
        ctx.globalAlpha = Math.max(0, p.life);
        ctx.fillStyle = p.color;
        ctx.shadowColor = p.color;
        ctx.shadowBlur = 4;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * CommonConstants.TWO);
        ctx.fill();
        ctx.restore();
      }

      if (alive) {
        this.sparkleTimer = setTimeout(animate, 16);
      } else {
        this.sparkleTimer = -1;
        ctx.clearRect(0, 0, this.screenWidth, this.screenHeight);
      }
    };
    this.sparkleTimer = setTimeout(animate, 16);
  }

  private get compactLandscape(): boolean {
    return this.pageLandscape && this.screenHeight < 360;
  }

  build() {
    Column() {
      // Title
      Text('🎫 刮刮乐')
        .fontSize((this.compactLandscape ? 18 : 24) * this.scaleFactor)
        .fontColor('#FFFFFF')
        .fontWeight(700)
        .margin({
          top: (this.compactLandscape ? 6 : 12) * this.scaleFactor,
          bottom: (this.compactLandscape ? 4 : 8) * this.scaleFactor
        })

      if (!this.compactLandscape) {
        Text(this.isRevealed ? '恭喜中奖！' : '手指刮开涂层看看手气')
          .fontSize(14 * this.scaleFactor)
          .fontColor('rgba(255,255,255,0.5)')
          .margin({ bottom: 16 * this.scaleFactor })
      }

      // Card Canvas + Sparkles overlay
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
          .onTouch((event: TouchEvent) => {
            this.onTouchHandler(event);
          })

        // Sparkle particle overlay
        Canvas(this.sparkleContext)
          .width(this.screenWidth)
          .height(this.screenHeight)
          .hitTestBehavior(HitTestMode.None)
      }

      // Celebration overlay with new-card button
      if (this.isRevealed) {
        Column() {
          Text('🎉 恭喜中奖 🎉')
            .fontSize(24 * this.scaleFactor)
            .fontColor('#FFD700')
            .fontWeight(700)
            .margin({ bottom: 8 * this.scaleFactor })
          Text(this.getPrizeEmoji())
            .fontSize(64 * this.scaleFactor)
            .margin({ bottom: 8 * this.scaleFactor })
          Text(this.getPrizeString())
            .fontSize(16 * this.scaleFactor)
            .fontColor('#FFFFFF')
            .fontWeight(600)
          Text('✨ 🌟 ✨')
            .fontSize(20 * this.scaleFactor)
            .margin({ top: 8 * this.scaleFactor })
          Button('再来一张')
            .width(160 * this.scaleFactor)
            .height(40 * this.scaleFactor)
            .backgroundColor('#FFD700')
            .fontColor('#1A1A2E')
            .fontWeight(700)
            .borderRadius(20 * this.scaleFactor)
            .margin({ top: 16 * this.scaleFactor })
            .onClick(() => {
              this.newCard();
            })
        }
        .width('70%')
        .padding(20 * this.scaleFactor)
        .backgroundColor('rgba(30,30,63,0.92)')
        .borderRadius(16 * this.scaleFactor)
        .border({ width: 1, color: 'rgba(255,215,0,0.4)' })
        .hitTestBehavior(HitTestMode.None)
        .alignItems(HorizontalAlign.Center)
        .position({ x: '15%', y: '30%' })
      }

      // Bottom area
      if (!this.isRevealed) {
        Text(`已刮 ${this.scratchPercent}%`)
          .fontSize(13 * this.scaleFactor)
          .fontColor('rgba(255,255,255,0.3)')
          .margin({ bottom: (this.compactLandscape ? 4 : 16) * this.scaleFactor })
      }
    }
    .width(StyleConstants.FULL_PERCENT)
    .height(StyleConstants.FULL_PERCENT)
  }
}
