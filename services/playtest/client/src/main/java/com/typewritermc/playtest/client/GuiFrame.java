package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Message.Text;
import java.util.ArrayList;
import java.util.List;

/**
 * Everything the GUI added in one frame, in paint order, and which of its text a player can read.
 * Coordinates are GUI scaled pixels, {@code right} and {@code bottom} exclusive.
 */
final class GuiFrame {
    /** What a painted element that is not text does to text under it. */
    enum Kind {
        /** A coloured rectangle: hides text under it once nearly opaque. */
        FILL,
        /** A texture or any other drawn element: hides text under it. */
        IMAGE,
    }

    private record Painted(Kind kind, String element, String text, int left, int top, int right, int bottom, int color) {}

    private static final int MIN_TEXT_ALPHA = 8;
    private static final int MIN_OPAQUE_ALPHA = 240;

    private final int width;
    private final int height;
    private final List<Painted> painted = new ArrayList<>();
    private int blurAt = -1;

    GuiFrame(int width, int height) {
        this.width = width;
        this.height = height;
    }

    /** A run of text the element {@code element} drew, or null when no named element drew it. */
    void text(String element, String text, int left, int top, int right, int bottom, int color) {
        painted.add(new Painted(null, element, text, left, top, right, bottom, color));
    }

    void element(Kind kind, int left, int top, int right, int bottom, int color) {
        painted.add(new Painted(kind, null, null, left, top, right, bottom, color));
    }

    /** Everything painted so far sits behind a blur. */
    void blur() {
        blurAt = painted.size();
    }

    /**
     * Every run of text a player can read, in paint order: not blank, an alpha of at least 8, more than
     * half of it on screen, not behind a blur, and not 90 percent covered by an image or a nearly opaque
     * fill painted after it.
     */
    List<Text> legibleTexts() {
        var legible = new ArrayList<Text>();
        for (int index = 0; index < painted.size(); index++) {
            Painted text = painted.get(index);
            if (text.kind() != null || text.text().isBlank()) continue;
            if (alpha(text.color()) < MIN_TEXT_ALPHA || index < blurAt) continue;
            if (overlap(text, 0, 0, width, height) * 2 <= area(text)) continue;
            if (covered(text, index)) continue;
            legible.add(new Text(text.element() == null ? "other" : text.element(), text.text()));
        }
        return legible;
    }

    private boolean covered(Painted text, int index) {
        for (Painted later : painted.subList(index + 1, painted.size())) {
            boolean hides = later.kind() == Kind.IMAGE || (later.kind() == Kind.FILL && alpha(later.color()) >= MIN_OPAQUE_ALPHA);
            if (hides && overlap(text, later.left(), later.top(), later.right(), later.bottom()) * 10 >= area(text) * 9) return true;
        }
        return false;
    }

    private static long overlap(Painted text, int left, int top, int right, int bottom) {
        long wide = Math.max(0, Math.min(text.right(), right) - Math.max(text.left(), left));
        long high = Math.max(0, Math.min(text.bottom(), bottom) - Math.max(text.top(), top));
        return wide * high;
    }

    private static long area(Painted text) {
        return Math.max(1L, (long) (text.right() - text.left()) * (text.bottom() - text.top()));
    }

    private static int alpha(int color) {
        return color >>> 24;
    }
}
