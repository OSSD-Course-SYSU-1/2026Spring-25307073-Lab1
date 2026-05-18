import { window } from '@kit.ArkUI';
import Logger from '../common/utils/Logger';
import DrawModel from '../viewmodel/DrawModel';
import PrizeDialog from '../view/PrizeDialog';
import PrizeData from '../viewmodel/PrizeData';
import ConfettiEffect from '../view/ConfettiEffect';
import StyleConstants from '../common/constants/StyleConstants';
import CommonConstants from '../common/constants/CommonConstants';
import { Context } from '@kit.AbilityKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

const uiContext: UIContext | undefined = AppStorage.get('uiContext');
let context: Context = uiContext!.getHostContext()!;

function getEmoji(img: string): string {
  if (img === CommonConstants.WATERMELON_IMAGE_URL) return '🍉';
  if (img === CommonConstants.HAMBURG_IMAGE_URL) return '🍔';
  if (img === CommonConstants.CAKE_IMAGE_URL) return '🎂';
  if (img === CommonConstants.SMILE_IMAGE_URL) return '😊';
  return '🎁';
}

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
  private currentLang: string = 'zh-Hans';
  private lastLang: string = 'zh-Hans';
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;
  private breatheTimer: number = -1;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: PrizeDialog({ prizeData: $prizeData, enableFlag: $enableFlag }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    cancel: () => { this.enableFlag = true; }
  });

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

  onPageShow(): void {
    if (this.lastLang !== this.currentLang) {
      this.drawModel.draw(this.canvasContext, this.screenWidth, this.screenHeight);
    }
  }
  onPageHide(): void { this.lastLang = i18n.System.getSystemLanguage(); }

  aboutToDisappear(): void {
    if (this.subscriber) { commonEventManager.unsubscribe(this.subscriber, () => {}); }
    if (this.breatheTimer > 0) clearTimeout(this.breatheTimer);
  }

  vibrate(_duration: number): void {
    // Vibration requires @ohos.vibrator; skipped for ArkTS strict mode
  }

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

  showMultiSummary(): void {
    // Count results using parallel arrays
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

  triggerConfetti(): void {
    this.confettiKey++;
  }

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

  startSingle(): void { this.enableFlag = false; this.multiMode = 0; this.spinOnce(); }

  startMulti(n: number): void {
    this.enableFlag = false;
    this.multiMode = n;
    this.multiRemaining = n;
    this.multiResults = [];
    this.showSummary = false;
    this.spinOnce();
  }

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

      Image($r('app.media.ic_center'))
        .width(StyleConstants.CENTER_IMAGE_WIDTH)
        .height(StyleConstants.CENTER_IMAGE_HEIGHT)
        .scale({ x: this.btnScale, y: this.btnScale })
        .enabled(this.enableFlag)
        .onClick(() => { this.startSingle(); })

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

      if (this.multiMode > 0 && !this.showSummary) {
        Text(`连抽中... (${this.multiMode - this.multiRemaining}/${this.multiMode})`)
          .fontSize(13).fontColor('rgba(255,255,255,0.5)')
          .position({ x: 0, y: this.screenHeight - 235 })
          .width('100%').textAlign(TextAlign.Center)
      }

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
}
