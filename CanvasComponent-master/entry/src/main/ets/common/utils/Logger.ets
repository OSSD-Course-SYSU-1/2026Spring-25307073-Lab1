import { hilog } from '@kit.PerformanceAnalysisKit';

class Logger {
  private domain: number;
  private prefix: string;

  constructor(prefix: string = 'MyApp', domain: number = 0xFF00) {
    this.prefix = prefix;
    this.domain = domain;
  }

  debug(msg: string): void {
    hilog.debug(this.domain, this.prefix, '%{public}s', msg);
  }

  info(msg: string): void {
    hilog.info(this.domain, this.prefix, '%{public}s', msg);
  }

  warn(msg: string): void {
    hilog.warn(this.domain, this.prefix, '%{public}s', msg);
  }

  error(msg: string): void {
    hilog.error(this.domain, this.prefix, '%{public}s', msg);
  }
}

export default new Logger('[CanvasComponent]', 0xFF00);
