interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  size: number;
  color: string;
  life: number;
  maxLife: number;
  rotation: number;
  rotSpeed: number;
  isRect: boolean;
}

@Component
export default struct ConfettiEffect {
  private particleContext: CanvasRenderingContext2D = new CanvasRenderingContext2D();
  private particles: Particle[] = [];
  private animTimer: number = -1;
  private canvasWidth: number = 500;
  private canvasHeight: number = 800;

  private colors: string[] = [
    '#FF6B9D', '#C44AFF', '#FFD93D', '#FF9A56',
    '#00D2FF', '#3A7BD5', '#FFD700', '#FF4500',
    '#00FF7F', '#FF1493'
  ];

  trigger(): void {
    this.particles = [];
    for (let i = 0; i < 80; i++) {
      const angle: number = Math.random() * Math.PI * 2;
      const speed: number = Math.random() * 8 + 3;
      const p: Particle = {
        x: this.canvasWidth / 2 + (Math.random() - 0.5) * 100,
        y: this.canvasHeight / 2,
        vx: Math.cos(angle) * speed * (0.5 + Math.random()),
        vy: Math.sin(angle) * speed * (0.5 + Math.random()) - 3,
        size: Math.random() * 8 + 4,
        color: this.colors[Math.floor(Math.random() * this.colors.length)],
        life: 1,
        maxLife: Math.random() * 60 + 60,
        rotation: Math.random() * 360,
        rotSpeed: (Math.random() - 0.5) * 10,
        isRect: Math.random() > 0.5,
      };
      this.particles.push(p);
    }
    if (this.animTimer > 0) clearTimeout(this.animTimer);
    this.animate();
  }

  animate(): void {
    const ctx: CanvasRenderingContext2D = this.particleContext;
    let frame: number = 0;

    const loop = (): void => {
      ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
      frame++;
      let alive: boolean = false;

      for (let i = 0; i < this.particles.length; i++) {
        const p: Particle = this.particles[i];
        if (p.life <= 0) continue;
        alive = true;
        p.x += p.vx;
        p.vy += 0.15;
        p.y += p.vy;
        p.rotation += p.rotSpeed;
        p.life -= 1 / p.maxLife;
        const alpha: number = Math.max(0, p.life);

        ctx.save();
        ctx.globalAlpha = alpha;
        ctx.translate(p.x, p.y);
        ctx.rotate((p.rotation * Math.PI) / 180);
        ctx.fillStyle = p.color;

        if (p.isRect) {
          ctx.fillRect(-p.size / 2, -p.size / 4, p.size, p.size / 2);
        } else {
          ctx.beginPath();
          ctx.arc(0, 0, p.size / 2, 0, Math.PI * 2);
          ctx.fill();
        }
        ctx.restore();
      }
      ctx.globalAlpha = 1;

      if (alive && frame < 200) {
        this.animTimer = setTimeout(loop, 16);
      } else {
        ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
      }
    };

    this.animTimer = setTimeout(loop, 16);
  }

  aboutToDisappear(): void {
    if (this.animTimer > 0) clearTimeout(this.animTimer);
  }

  build() {
    Canvas(this.particleContext)
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)
  }
}
