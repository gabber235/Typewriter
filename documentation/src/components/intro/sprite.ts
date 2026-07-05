// All geometry and timing below is measured frame-by-frame from the source
// video (design/Banner/TW-Banner-Animated.mp4, 1920x1080 @ 29.97fps).
// Coordinates are in the 1920x1080 design space of the animation stage.

export const FRAME_MS = 1000 / 29.97;

// title text box: left/top of the first glyph, glyph height in stage px
export const TITLE_LEFT = 716;
export const TITLE_TOP = 470;
export const TITLE_SIZE = 135.5;
// first letter lands on frame 35, one letter every 2 frames, ~2-frame fade
export const TITLE_DELAY_MS = 34 * FRAME_MS;
export const TITLE_STAGGER_MS = 2 * FRAME_MS;
export const TITLE_FADE_MS = 80;

// subtitle text box
export const SUB_LEFT = 734;
export const SUB_TOP = 620;
export const SUB_SIZE = 50.6;
// typing starts on frame 51, ~1.4 frames per glyph, ~2-frame fade
export const SUB_DELAY_MS = 50 * FRAME_MS;
export const SUB_STAGGER_MS = 1.4 * FRAME_MS;
export const SUB_FADE_MS = 67;

// Logo settled box, measured from the video's final frame.
export const LOGO_BOX = { left: 108, top: 290, w: 532, h: 512 };
// pops in on frame 2 at ~1.1x scale, squashes to ~0.9x (impact bounce),
// slides left while scaling back to 1x, overshoots, settles by frame 36
export const LOGO_POP_MS = FRAME_MS;
export const LOGO_MOVE_MS = 34 * FRAME_MS;
