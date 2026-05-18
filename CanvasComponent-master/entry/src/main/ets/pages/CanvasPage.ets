import { window } from '@kit.ArkUI';
import Logger from '../common/utils/Logger';
import WheelView from '../view/WheelView';
import ScratchCardView from '../view/ScratchCardView';
import HistoryView from '../view/HistoryView';
import StarParticle from '../view/StarParticle';
import StyleConstants from '../common/constants/StyleConstants';
import ColorConstants from '../common/constants/ColorConstants';
import { Context } from '@kit.AbilityKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

const uiContext: UIContext | undefined = AppStorage.get('uiContext');
let context: Context = uiContext!.getHostContext()!;

@Entry
@Component
struct CanvasPage {
  @State currentIndex: number = 0;
  @State checkedIn: boolean = false;
  @State checkInDays: number = 0;

  aboutToAppear(): void {
    window.getLastWindow(context)
      .then((wc) => { wc.setWindowLayoutFullScreen(true); })
      .catch((e: Error) => { Logger.error('Fullscreen error: ' + JSON.stringify(e)); });

    this.checkDaily();
  }

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

      // Star particle overlay
      StarParticle()

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

        // Tabs
        Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
          TabContent() { WheelView() }
            .tabBar(this.tabBuilder(0))
          TabContent() { ScratchCardView() }
            .tabBar(this.tabBuilder(1))
          TabContent() { HistoryView() }
            .tabBar(this.tabBuilder(2))
        }
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.FULL_PERCENT)
        .onChange((idx: number) => { this.currentIndex = idx; })
      }
      .width(StyleConstants.FULL_PERCENT)
      .height(StyleConstants.FULL_PERCENT)
    }
    .width(StyleConstants.FULL_PERCENT)
    .height(StyleConstants.FULL_PERCENT)
  }

  @Builder
  tabBuilder(index: number) {
    Column() {
      if (index === 0) {
        Text('🎡').fontSize(18).margin({ bottom: 1 })
        Text('转盘').fontSize(10).fontColor('#FFFFFF')
          .fontWeight(index === this.currentIndex ? 700 : 400)
      } else if (index === 1) {
        Text('🎫').fontSize(18).margin({ bottom: 1 })
        Text('刮刮乐').fontSize(10).fontColor('#FFFFFF')
          .fontWeight(index === this.currentIndex ? 700 : 400)
      } else {
        Text('📊').fontSize(18).margin({ bottom: 1 })
        Text('记录').fontSize(10).fontColor('#FFFFFF')
          .fontWeight(index === this.currentIndex ? 700 : 400)
      }
    }
    .padding({ top: 6, bottom: 10 })
    .width(72)
  }
}
