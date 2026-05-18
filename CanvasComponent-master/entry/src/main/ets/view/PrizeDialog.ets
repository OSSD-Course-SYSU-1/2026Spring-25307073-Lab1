import { matrix4 } from '@kit.ArkUI';
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
}
