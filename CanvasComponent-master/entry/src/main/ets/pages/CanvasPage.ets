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
  @StorageLink('currentIndex') currentIndex: number = 0;
  @State checkedIn: boolean = false;
  @State checkInDays: number = 0;
  @State currentBreakpoint: string = 'sm';

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

      // Main content column
      Column() {
        // Tabs
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
      }
      .width(StyleConstants.FULL_PERCENT)
      .height(StyleConstants.FULL_PERCENT)

      // Check-in badge floats above content and does not push Tabs off screen.
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
    }
    .width(StyleConstants.FULL_PERCENT)
    .height(StyleConstants.FULL_PERCENT)
  }

  @Builder
  tabBuilder(index: number) {
    Column() {
      if (index === 0) {
        Text('🎡').fontSize(this.currentBreakpoint !== 'sm' ? 26 : 18)
          .margin({ bottom: this.currentBreakpoint !== 'sm' ? 6 : 1 })
        Text('转盘').fontSize(this.currentBreakpoint !== 'sm' ? 13 : 10).fontColor('#FFFFFF')
          .fontWeight(index === this.currentIndex ? 700 : 400)
      } else if (index === 1) {
        Text('🎫').fontSize(this.currentBreakpoint !== 'sm' ? 26 : 18)
          .margin({ bottom: this.currentBreakpoint !== 'sm' ? 6 : 1 })
        Text('刮刮乐').fontSize(this.currentBreakpoint !== 'sm' ? 13 : 10).fontColor('#FFFFFF')
          .fontWeight(index === this.currentIndex ? 700 : 400)
      } else {
        Text('📊').fontSize(this.currentBreakpoint !== 'sm' ? 26 : 18)
          .margin({ bottom: this.currentBreakpoint !== 'sm' ? 6 : 1 })
        Text('记录').fontSize(this.currentBreakpoint !== 'sm' ? 13 : 10).fontColor('#FFFFFF')
          .fontWeight(index === this.currentIndex ? 700 : 400)
      }
    }
    .padding(this.currentBreakpoint !== 'sm' ? { top: 20, bottom: 20 } : { top: 6, bottom: 10 })
    .width(this.currentBreakpoint !== 'sm' ? '100%' : 72)
    .backgroundColor(this.currentBreakpoint !== 'sm' && index === this.currentIndex ? 'rgba(255,215,0,0.12)' : 'transparent')
    .borderRadius(this.currentBreakpoint !== 'sm' ? 8 : 0)
    .border({
      width: (this.currentBreakpoint !== 'sm' && index === this.currentIndex) ? { left: 3 } : {},
      color: (this.currentBreakpoint !== 'sm' && index === this.currentIndex) ? { left: '#FFD700' } : {}
    })
  }
}
