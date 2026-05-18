export default class CommonConstants {
  // --- Image URLs ---
  static readonly WATERMELON_IMAGE_URL: string = 'resources/base/media/ic_watermelon.png';
  static readonly HAMBURG_IMAGE_URL: string = 'resources/base/media/ic_hamburg.png';
  static readonly CAKE_IMAGE_URL: string = 'resources/base/media/ic_cake.png';
  static readonly SMILE_IMAGE_URL: string = 'resources/base/media/ic_smile.png';

  // --- Angle constants ---
  static readonly CIRCLE: number = 360;
  static readonly HALF_CIRCLE: number = 180;
  static readonly ANGLE: number = 270;

  // --- Counts ---
  static readonly COUNT: number = 6;
  static readonly DECO_RING_DOT_COUNT: number = 12;

  // --- Animation ---
  static readonly DURATION: number = 4000;
  static readonly TRANSFORM_ANGLE: number = -120;

  // --- Numbers ---
  static readonly ONE: number = 1;
  static readonly TWO: number = 2;
  static readonly THREE: number = 3;
  static readonly FOUR: number = 4;
  static readonly FIVE: number = 5;
  static readonly SIX: number = 6;

  // --- Layout ratios (relative to screenWidth) ---
  static readonly OUTER_RING_RATIOS: number = 0.42;
  static readonly DECO_RING_RATIOS: number = 0.39;
  static readonly INNER_ARC_RATIOS: number = 0.45;
  static readonly INNER_CIRCLE_RATIOS: number = 0.30;
  static readonly INNER_DOT_RATIOS: number = 0.26;
  static readonly DECO_DOT_RADIUS: number = 3;

  // --- Image ---
  static readonly IMAGE_SIZE: number = 40;
  static readonly IMAGE_DX_RATIOS: number = 0.10;
  static readonly IMAGE_DY_RATIOS: number = 0.05;

  // --- Arc text ---
  static readonly ARC_START_ANGLE: number = 40;
  static readonly ARC_END_ANGLE: number = 20;

  // --- Canvas text settings ---
  static readonly TEXT_ALIGN: CanvasTextAlign = 'center';
  static readonly TEXT_BASE_LINE: CanvasTextBaseline = 'middle';
  static readonly CANVAS_FONT: string = 'px sans-serif';

  // --- Glow ---
  static readonly GLOW_BLUR: number = 20;
  static readonly TEXT_SHADOW_BLUR: number = 4;
}

export enum EnumeratedValue {
  ONE = 1, TWO = 2, THREE = 3, FOUR = 4, FIVE = 5, SIX = 6
}
