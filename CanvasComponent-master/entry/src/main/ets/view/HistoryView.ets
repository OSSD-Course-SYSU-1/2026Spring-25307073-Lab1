import Logger from '../common/utils/Logger';
import StyleConstants from '../common/constants/StyleConstants';
import CommonConstants from '../common/constants/CommonConstants';

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
  @State records: HistoryRow[] = [];
  @State statsText: string = '';

  aboutToAppear(): void {
    this.loadHistory();
  }

  onPageShow(): void {
    this.loadHistory();
  }

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

  clearHistory(): void {
    AppStorage.set('wheel_history', '');
    this.records = [];
    this.statsText = '暂无记录';
  }

  build() {
    Column() {
      Text('📊 抽奖记录')
        .fontSize(22).fontColor('#FFFFFF').fontWeight(700)
        .margin({ top: 24, bottom: 4 })

      Text(this.statsText)
        .fontSize(14).fontColor('rgba(255,255,255,0.5)')
        .margin({ bottom: 16 })

      if (this.records.length === 0) {
        Column() {
          Text('🎯').fontSize(48).margin({ bottom: 12 })
          Text('还没有抽奖记录').fontSize(16).fontColor('rgba(255,255,255,0.4)')
          Text('去转盘或老虎机试试手气吧！').fontSize(14).fontColor('rgba(255,255,255,0.3)')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
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
}
