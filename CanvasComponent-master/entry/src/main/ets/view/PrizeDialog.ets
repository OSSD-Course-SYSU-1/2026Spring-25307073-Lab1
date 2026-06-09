import { matrix4, display } from '@kit.ArkUI';
import PrizeData from '../viewmodel/PrizeData';
import StyleConstants from '../common/constants/StyleConstants';
import CommonConstants from '../common/constants/CommonConstants';

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

@CustomDialog
export default struct PrizeDialog {
  @Link prizeData: PrizeData;
  @Link enableFlag: boolean;
  private controller?: CustomDialogController;
  @State animScale: number = 0;
  @State animOpacity: number = 0;
  private scaleFactor: number = 1.0;

  aboutToAppear(): void {
    this.animScale = 0;
    this.animOpacity = 0;
    try {
      const d = display.getDefaultDisplaySync();
      const uiCtx: UIContext | undefined = AppStorage.get('uiContext');
      if (uiCtx !== undefined) {
        const w = uiCtx.px2vp(d.width);
        const h = uiCtx.px2vp(d.height);
        this.scaleFactor = Math.min(w, h) / 360;
      }
    } catch (_e) {}
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

  build() {
    Column() {
      Text(getPrizeEmoji(this.prizeData.imageSrc !== undefined ? this.prizeData.imageSrc : ''))
        .fontSize(Math.min(72 * this.scaleFactor, 120))
        .margin({ top: Math.min(20 * this.scaleFactor, 30), bottom: Math.min(8 * this.scaleFactor, 12) })

      Text(getPrizeMessage(this.prizeData.message))
        .fontSize(Math.min(22 * this.scaleFactor, 36))
        .fontColor('#FFD700')
        .fontWeight(700)
        .textAlign(TextAlign.Center)
        .margin({ bottom: Math.min(8 * this.scaleFactor, 12) })

      Text('✨ ✨ ✨')
        .fontSize(Math.min(16 * this.scaleFactor, 24))
        .margin({ bottom: Math.min(12 * this.scaleFactor, 18) })

      Text($r('app.string.text_confirm'))
        .fontColor($r('app.color.text_font_color'))
        .fontWeight(StyleConstants.FONT_WEIGHT)
        .fontSize(Math.min(18 * this.scaleFactor, 28))
        .textAlign(TextAlign.Center)
        .padding({ left: 40, right: 40, top: 10, bottom: 10 })
        .borderRadius(20)
        .border({ width: 1, color: '#FFD700' })
        .onClick(() => {
          this.controller?.close();
          this.enableFlag = true;
        })
        .margin({ bottom: Math.min(16 * this.scaleFactor, 24) })
    }
    .backgroundColor('#1E1E3F')
    .borderRadius(20)
    .border({ width: 1, color: 'rgba(255,215,0,0.3)' })
    .width(Math.min(280 * this.scaleFactor, 420))
    .scale({ x: this.animScale, y: this.animScale })
    .opacity(this.animOpacity)
  }
}
