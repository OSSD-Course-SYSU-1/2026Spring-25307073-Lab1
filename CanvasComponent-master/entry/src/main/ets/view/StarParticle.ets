import ColorConstants from '../common/constants/ColorConstants';

interface Star {
  x: number;
  y: number;
  size: number;
  alpha: number;
  speed: number;
  phase: number;
}

@Component
export default struct StarParticle {
  private starCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D();
  private stars: Star[] = [];
  private animTimer: number = -1;

  aboutToAppear(): void {
    this.initStars();
    this.startAnimation();
  }

  aboutToDisappear(): void {
    if (this.animTimer > 0) clearTimeout(this.animTimer);
  }

  initStars(): void {
    this.stars = [];
    for (let i = 0; i < 40; i++) {
      const s: Star = {
        x: Math.random() * 500,
        y: Math.random() * 800,
        size: Math.random() * 2.5 + 0.5,
        alpha: Math.random() * 0.6 + 0.2,
        speed: Math.random() * 0.2 + 0.05,
        phase: Math.random() * Math.PI * 2,
      };
      this.stars.push(s);
    }
  }

  startAnimation(): void {
    const animate = (): void => {
      const ctx: CanvasRenderingContext2D = this.starCanvasContext;
      const now: number = Date.now() / 1000;

      ctx.clearRect(0, 0, 500, 800);

      for (let i = 0; i < this.stars.length; i++) {
        const star: Star = this.stars[i];
        const pulse: number = Math.sin(now * star.speed + star.phase) * 0.3 + 0.7;
        const a: number = star.alpha * pulse;
        ctx.globalAlpha = a;
        ctx.fillStyle = ColorConstants.STAR_COLOR;
        ctx.beginPath();
        ctx.arc(star.x, star.y, star.size, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.globalAlpha = 1;

      this.animTimer = setTimeout(animate, 33);
    };

    this.animTimer = setTimeout(animate, 33);
  }

  build() {
    Canvas(this.starCanvasContext)
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)
  }
}
