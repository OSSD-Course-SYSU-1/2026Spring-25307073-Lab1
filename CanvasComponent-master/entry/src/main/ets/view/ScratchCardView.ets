import Logger from '../common/utils/Logger';
import StyleConstants from '../common/constants/StyleConstants';
import CommonConstants from '../common/constants/CommonConstants';
import ColorConstants from '../common/constants/ColorConstants';
import { window } from '@kit.ArkUI';
import { Context } from '@kit.AbilityKit';

const uiContext: UIContext | undefined = AppStorage.get('uiContext');
let context: Context = uiContext!.getHostContext()!;

interface ScratchPrize {
  message: Resource;
  imageSrc: string;
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
  private cardX: number = 0;
  private cardY: number = 0;
  private cardW: number = 0;
  private cardH: number = 0;
  private scratchedPixels: number = 0;
  private totalPixels: number = 0;
  private isScratching: boolean = false;
  private canvasInitialized: boolean = false;
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
    const cw = this.screenWidth * 0.8;
    const ch = cw * 1.2;
    this.cardX = (this.screenWidth - cw) / 2;
    this.cardY = (this.screenHeight - ch) / 2 - 20;
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
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.restore();

    // Prize text
    ctx.save();
    ctx.fillStyle = '#FFD700';
    ctx.font = '22px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    const prizeStr = this.getPrizeString();
    ctx.fillText(prizeStr, this.screenWidth / 2, this.cardY + ch * 0.35);
    ctx.restore();

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

    // Hint text
    ctx.save();
    ctx.fillStyle = 'rgba(255,255,255,0.3)';
    ctx.font = '14px sans-serif';
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
    ctx.font = '16px sans-serif';
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
    ctx.arc(x, y, 24, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();

    this.scratchedPixels += Math.PI * 24 * 24;
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
    this.initCard();
  }

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
}
