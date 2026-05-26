import CommonConstants from '../common/constants/CommonConstants';
import { EnumeratedValue } from '../common/constants/CommonConstants';
import ColorConstants from '../common/constants/ColorConstants';
import StyleConstants from '../common/constants/StyleConstants';
import PrizeData from './PrizeData';
import FillArcData from './FillArcData';
import Logger from '../common/utils/Logger';
import CheckEmptyUtils from '../common/utils/CheckEmptyUtils';
const uiContext: UIContext | undefined = AppStorage.get('uiContext');

export default class DrawModel {
  private startAngle: number = 0;
  private avgAngle: number = CommonConstants.CIRCLE / CommonConstants.COUNT;
  private screenWidth: number = 0;
  private canvasContext?: CanvasRenderingContext2D;

  draw(canvasContext: CanvasRenderingContext2D, screenWidth: number, screenHeight: number,
    timeMs?: number, glowIntensity?: number): void {
    if (CheckEmptyUtils.isEmptyObj(canvasContext)) {
      Logger.error('[DrawModel][draw] canvasContext is empty.');
      return;
    }
    this.canvasContext = canvasContext;
    this.screenWidth = screenWidth;
    this.startAngle = 0;
    this.canvasContext.clearRect(0, 0, this.screenWidth, screenHeight);
    this.canvasContext.translate(this.screenWidth / CommonConstants.TWO,
      screenHeight / CommonConstants.TWO);

    this.drawOuterRing(glowIntensity);
    this.drawDecoRing();
    this.drawInnerCircle();
    this.drawInnerArc();       // Gradient fan sectors (full wheel)
    if (timeMs !== undefined) {
      this.drawShimmer(timeMs);
    }
    this.drawArcText();        // White text with shadow
    this.drawImage();          // Prize emoji
    this.drawCenterGlow();

    this.canvasContext.translate(-this.screenWidth / CommonConstants.TWO,
      -screenHeight / CommonConstants.TWO);
  }

  fillArc(fillArcData: FillArcData, fillColor: string): void {
    if (CheckEmptyUtils.isEmptyObj(fillArcData) || CheckEmptyUtils.isEmptyStr(fillColor)) {
      return;
    }
    if (this.canvasContext !== undefined) {
      this.canvasContext.beginPath();
      this.canvasContext.fillStyle = fillColor;
      this.canvasContext.arc(fillArcData.x, fillArcData.y, fillArcData.radius,
        fillArcData.startAngle, fillArcData.endAngle);
      this.canvasContext.fill();
    }
  }

  /** Draw an arc with radial gradient fill */
  fillGradientArc(fillArcData: FillArcData, color1: string, color2: string): void {
    if (CheckEmptyUtils.isEmptyObj(fillArcData)) return;
    const ctx = this.canvasContext;
    if (ctx === undefined) return;
    ctx.beginPath();
    ctx.arc(fillArcData.x, fillArcData.y, fillArcData.radius,
      fillArcData.startAngle, fillArcData.endAngle);
    const gradient = ctx.createRadialGradient(0, 0, 0, 0, 0, fillArcData.radius);
    gradient.addColorStop(0, color1);
    gradient.addColorStop(1, color2);
    ctx.fillStyle = gradient;
    ctx.fill();
  }

  /** Outer ring with glow shadow */
  drawOuterRing(glowIntensity?: number): void {
    const ctx = this.canvasContext;
    if (ctx === undefined) return;
    const radius = this.screenWidth * CommonConstants.OUTER_RING_RATIOS;

    // Glow layer
    ctx.save();
    ctx.shadowColor = ColorConstants.OUTER_RING_GLOW;
    ctx.shadowBlur = glowIntensity !== undefined ? glowIntensity : CommonConstants.GLOW_BLUR;
    this.fillArc(new FillArcData(0, 0, radius, 0, Math.PI * CommonConstants.TWO),
      ColorConstants.OUTER_RING_COLOR);
    ctx.restore();

    // Main ring
    this.fillArc(new FillArcData(0, 0, radius, 0, Math.PI * CommonConstants.TWO),
      ColorConstants.OUTER_RING_COLOR);
  }

  /** Decorative ring with golden dots */
  drawDecoRing(): void {
    const ctx = this.canvasContext;
    if (ctx === undefined) return;
    const radius = this.screenWidth * CommonConstants.DECO_RING_RATIOS;

    // Golden ring line
    ctx.save();
    ctx.beginPath();
    ctx.strokeStyle = ColorConstants.DECO_RING_COLOR;
    ctx.lineWidth = 1.5;
    ctx.shadowColor = ColorConstants.DECO_RING_COLOR;
    ctx.shadowBlur = 8;
    ctx.arc(0, 0, radius, 0, Math.PI * CommonConstants.TWO);
    ctx.stroke();
    ctx.restore();

    // Dots around the ring
    let angle = 0;
    const dotRadius = CommonConstants.DECO_DOT_RADIUS;
    for (let i = 0; i < CommonConstants.DECO_RING_DOT_COUNT; i++) {
      const rad = (angle * Math.PI) / CommonConstants.HALF_CIRCLE;
      const dx = Math.cos(rad) * radius;
      const dy = Math.sin(rad) * radius;
      ctx.save();
      ctx.shadowColor = ColorConstants.DECO_RING_DOT_COLOR;
      ctx.shadowBlur = 6;
      this.fillArc(new FillArcData(dx, dy, dotRadius, 0, Math.PI * CommonConstants.TWO),
        i % 2 === 0 ? ColorConstants.DECO_RING_COLOR : ColorConstants.DECO_RING_DOT_COLOR);
      ctx.restore();
      angle += CommonConstants.CIRCLE / CommonConstants.DECO_RING_DOT_COUNT;
    }
  }

  /** Gradient fan sectors */
  drawInnerArc(): void {
    const radius = this.screenWidth * CommonConstants.INNER_ARC_RATIOS;
    const colors1 = ColorConstants.SECTOR_COLOR1;
    const colors2 = ColorConstants.SECTOR_COLOR2;
    for (let i = 0; i < CommonConstants.COUNT; i++) {
      this.fillGradientArc(
        new FillArcData(0, 0, radius,
          this.startAngle * Math.PI / CommonConstants.HALF_CIRCLE,
          (this.startAngle + this.avgAngle) * Math.PI / CommonConstants.HALF_CIRCLE),
        colors1[i], colors2[i]);
      this.canvasContext?.lineTo(0, 0);
      this.canvasContext?.fill();
      this.startAngle += this.avgAngle;
    }
  }

  /** White text with dark shadow on arcs */
  drawArcText(): void {
    const ctx = this.canvasContext;
    if (ctx === undefined) return;
    ctx.textAlign = CommonConstants.TEXT_ALIGN;
    ctx.textBaseline = CommonConstants.TEXT_BASE_LINE;
    ctx.fillStyle = ColorConstants.TEXT_COLOR;
    ctx.font = StyleConstants.ARC_TEXT_SIZE + CommonConstants.CANVAS_FONT;
    ctx.shadowColor = ColorConstants.TEXT_SHADOW;
    ctx.shadowBlur = CommonConstants.TEXT_SHADOW_BLUR;

    const textArrays = [
      $r('app.string.text_smile'), $r('app.string.text_hamburger'),
      $r('app.string.text_cake'), $r('app.string.text_smile'),
      $r('app.string.text_hamburger'), $r('app.string.text_watermelon')
    ];
    for (let i = 0; i < CommonConstants.COUNT; i++) {
      this.drawCircularText(this.getResourceString(textArrays[i]),
        (this.startAngle + CommonConstants.ARC_START_ANGLE) * Math.PI / CommonConstants.HALF_CIRCLE,
        (this.startAngle + CommonConstants.ARC_END_ANGLE) * Math.PI / CommonConstants.HALF_CIRCLE);
      this.startAngle += this.avgAngle;
    }
    ctx.shadowBlur = 0;
  }

  getResourceString(resource: Resource): string {
    if (CheckEmptyUtils.isEmptyObj(resource)) return '';
    try {
      return uiContext!.getHostContext()!.resourceManager.getStringSync(resource.id);
    } catch (error) {
      Logger.error('[DrawModel][getResourceString] failed: ' + JSON.stringify(error));
      return '';
    }
  }

  drawCircularText(textString: string, startAngle: number, endAngle: number): void {
    if (CheckEmptyUtils.isEmptyStr(textString)) return;
    const ctx = this.canvasContext;
    if (ctx === undefined) return;

    const radius = this.screenWidth * CommonConstants.INNER_ARC_RATIOS
      - this.screenWidth * CommonConstants.INNER_ARC_RATIOS / CommonConstants.COUNT;
    const angleDecrement = (startAngle - endAngle) / (textString.length - 1);
    let angle = startAngle;
    let index = 0;

    while (index < textString.length) {
      const character = textString.charAt(index);
      ctx.save();
      ctx.beginPath();
      ctx.translate(Math.cos(angle) * radius, -Math.sin(angle) * radius);
      ctx.rotate(Math.PI / CommonConstants.TWO - angle);
      ctx.fillText(character, 0, 0);
      angle -= angleDecrement;
      index++;
      ctx.restore();
    }
  }

  /** Draw prize emoji inside sectors (replaces ImageBitmap for reliable rendering) */
  drawImage(): void {
    const ctx = this.canvasContext;
    if (ctx === undefined) return;
    let beginAngle = this.startAngle;
    const emojis: string[] = ['🍉', '🍔', '😊', '🎂', '🍔', '😊'];
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.font = '110px sans-serif';
    ctx.shadowColor = ColorConstants.TEXT_SHADOW;
    ctx.shadowBlur = CommonConstants.TEXT_SHADOW_BLUR;
    for (let i = 0; i < CommonConstants.COUNT; i++) {
      ctx.save();
      ctx.rotate(beginAngle * Math.PI / CommonConstants.HALF_CIRCLE);
      ctx.fillText(emojis[i],
        this.screenWidth * CommonConstants.IMAGE_DX_RATIOS + CommonConstants.IMAGE_SIZE / 2,
        this.screenWidth * CommonConstants.IMAGE_DY_RATIOS + CommonConstants.IMAGE_SIZE / 2);
      beginAngle += this.avgAngle;
      ctx.restore();
    }
  }

  /** Inner circle with glow */
  drawInnerCircle(): void {
    const ctx = this.canvasContext;
    if (ctx === undefined) return;

    // Glow
    ctx.save();
    ctx.shadowColor = ColorConstants.INNER_GLOW_COLOR;
    ctx.shadowBlur = CommonConstants.GLOW_BLUR;
    this.fillArc(new FillArcData(0, 0, this.screenWidth * CommonConstants.INNER_CIRCLE_RATIOS, 0,
      Math.PI * CommonConstants.TWO), ColorConstants.INNER_CIRCLE_COLOR);
    ctx.restore();

    // Main circle
    this.fillArc(new FillArcData(0, 0, this.screenWidth * CommonConstants.INNER_CIRCLE_RATIOS, 0,
      Math.PI * CommonConstants.TWO), ColorConstants.INNER_CIRCLE_COLOR);

    // Inner dot
    this.fillArc(new FillArcData(0, 0, this.screenWidth * CommonConstants.INNER_DOT_RATIOS, 0,
      Math.PI * CommonConstants.TWO), ColorConstants.OUTER_RING_COLOR);
  }

  /** Draw a rotating shimmer highlight sweeping across sectors */
  drawShimmer(timeMs: number): void {
    const ctx = this.canvasContext;
    if (ctx === undefined) return;

    const radius = this.screenWidth * CommonConstants.INNER_ARC_RATIOS;
    const offset = ((timeMs * 0.05) % CommonConstants.CIRCLE) * Math.PI / CommonConstants.HALF_CIRCLE;

    ctx.save();
    ctx.globalAlpha = 0.12;

    // Draw a 45° wedge from center with radial gradient
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.arc(0, 0, radius, offset, offset + Math.PI / 4);
    ctx.closePath();

    const gradient = ctx.createRadialGradient(0, 0, 0, 0, 0, radius);
    gradient.addColorStop(0, 'rgba(255,255,255,0.25)');
    gradient.addColorStop(0.5, 'rgba(255,255,255,0.08)');
    gradient.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = gradient;
    ctx.fill();

    ctx.restore();
  }

  /** Golden glow ring around center */
  drawCenterGlow(): void {
    const ctx = this.canvasContext;
    if (ctx === undefined) return;
    ctx.save();
    ctx.shadowColor = ColorConstants.CENTER_BUTTON_GLOW;
    ctx.shadowBlur = 25;
    ctx.beginPath();
    ctx.arc(0, 0, this.screenWidth * CommonConstants.INNER_DOT_RATIOS + 6, 0,
      Math.PI * CommonConstants.TWO);
    ctx.strokeStyle = ColorConstants.CENTER_BUTTON_GLOW;
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.restore();
  }

  /** Determine prize based on random angle */
  showPrizeData(randomAngle: number): PrizeData {
    for (let i = 1; i <= CommonConstants.COUNT; i++) {
      if (randomAngle <= i * this.avgAngle) {
        return this.getPrizeData(i);
      }
    }
    return new PrizeData();
  }

  getPrizeData(scopeNum: number): PrizeData {
    const prizeData: PrizeData = new PrizeData();
    switch (scopeNum) {
      case EnumeratedValue.ONE:
        prizeData.message = $r('app.string.prize_text_watermelon');
        prizeData.imageSrc = CommonConstants.WATERMELON_IMAGE_URL;
        break;
      case EnumeratedValue.THREE:
        prizeData.message = $r('app.string.prize_text_smile');
        prizeData.imageSrc = CommonConstants.SMILE_IMAGE_URL;
        break;
      case EnumeratedValue.FOUR:
        prizeData.message = $r('app.string.prize_text_cake');
        prizeData.imageSrc = CommonConstants.CAKE_IMAGE_URL;
        break;
      case EnumeratedValue.TWO:
      case EnumeratedValue.FIVE:
        prizeData.message = $r('app.string.prize_text_hamburger');
        prizeData.imageSrc = CommonConstants.HAMBURG_IMAGE_URL;
        break;
      case EnumeratedValue.SIX:
        prizeData.message = $r('app.string.prize_text_smile');
        prizeData.imageSrc = CommonConstants.SMILE_IMAGE_URL;
        break;
      default: break;
    }
    return prizeData;
  }
}
