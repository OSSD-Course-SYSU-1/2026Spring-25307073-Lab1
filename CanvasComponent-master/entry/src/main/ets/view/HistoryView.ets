import { window } from '@kit.ArkUI';
import StyleConstants from '../common/constants/StyleConstants';
import CommonConstants from '../common/constants/CommonConstants';

const uiContext: UIContext | undefined = AppStorage.get('uiContext');

interface HistoryRow {
  emoji: string;
  isWin: boolean;
  timeText: string;
}

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

@Component
export default struct HistoryView {
  @StorageProp('wheel_history') historyRaw: string = '';
  @State scaleFactor: number = 1.0;

  aboutToAppear(): void {
    window.getLastWindow(uiContext!.getHostContext()!)
      .then((wc) => {
        const wp = wc.getWindowProperties();
        const vpW = uiContext!.px2vp(wp.windowRect.width);
        const vpH = uiContext!.px2vp(wp.windowRect.height);
        const minDim = Math.min(vpW, vpH);
        this.scaleFactor = minDim / 360;
      });
  }

  private getRecords(): HistoryRow[] {
    const result: HistoryRow[] = [];
    const raw: string = this.historyRaw;
    if (raw.length > 0) {
      const parts: string[] = raw.split(',');
      for (let i = parts.length - 1; i >= 0; i--) {
        const entry: string[] = parts[i].split('|');
        if (entry.length >= 2) {
          result.push({
            emoji: getEmoji(entry[1]),
            isWin: isWin(entry[1]),
            timeText: formatTime(entry[0]),
          });
        }
      }
    }
    return result;
  }

  private getStats(records: HistoryRow[]): string {
    let total: number = records.length;
    let wins: number = 0;
    for (let i = 0; i < records.length; i++) {
      if (records[i].isWin) wins++;
    }
    const winRate: number = total > 0 ? Math.round((wins / total) * 100) : 0;
    return '共 ' + total + ' 次 · 中奖率 ' + winRate + '%';
  }

  @Builder
  recordItem(item: HistoryRow) {
    Row({ space: 12 }) {
      Text(item.emoji).fontSize(32 * this.scaleFactor)

      Column({ space: 4 }) {
        Text(item.isWin ? '🎉 中奖' : '😅 未中奖')
          .fontSize(15 * this.scaleFactor)
          .fontColor(item.isWin ? '#FFD700' : 'rgba(255,255,255,0.6)')
          .fontWeight(600)
        Text(item.timeText).fontSize(12 * this.scaleFactor).fontColor('rgba(255,255,255,0.3)')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (item.isWin) {
        Text('✨').fontSize(16 * this.scaleFactor)
      }
    }
    .padding(12 * this.scaleFactor)
    .backgroundColor('rgba(255,255,255,0.05)')
    .borderRadius(10)
  }

  build() {
    Column() {
      Text('📊 抽奖记录')
        .fontSize(22 * this.scaleFactor).fontColor('#FFFFFF').fontWeight(700)
        .margin({ top: 24 * this.scaleFactor, bottom: 4 * this.scaleFactor })

      Text(this.getStatsText())
        .fontSize(14 * this.scaleFactor).fontColor('rgba(255,255,255,0.5)')
        .margin({ bottom: 8 * this.scaleFactor })

      if (this.getRecords().length === 0) {
        Column() {
          Text('🎯').fontSize(48 * this.scaleFactor).margin({ bottom: 12 * this.scaleFactor })
          Text('还没有抽奖记录').fontSize(16 * this.scaleFactor).fontColor('rgba(255,255,255,0.4)')
          Text('去转盘试试手气吧！').fontSize(14 * this.scaleFactor).fontColor('rgba(255,255,255,0.3)')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 8 * this.scaleFactor }) {
          ForEach(this.getRecords(), (item: HistoryRow) => {
            ListItem() {
              this.recordItem(item)
            }
          }, (item: HistoryRow) => item.timeText + item.emoji)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 16 * this.scaleFactor, right: 16 * this.scaleFactor })

        Button('清空记录')
          .width(160 * this.scaleFactor).height(40 * this.scaleFactor)
          .backgroundColor('rgba(255,255,255,0.1)')
          .fontColor('rgba(255,255,255,0.5)')
          .borderRadius(20 * this.scaleFactor)
          .margin({ bottom: 20 * this.scaleFactor })
          .onClick(() => {
            AppStorage.set('wheel_history', '');
          })
      }
    }
    .width(StyleConstants.FULL_PERCENT)
    .height(StyleConstants.FULL_PERCENT)
  }

  private getStatsText(): string {
    return this.getStats(this.getRecords());
  }
}
