package probe.mod.observe;

import net.minecraft.network.chat.TextColor;
import net.minecraft.util.FormattedCharSequence;

/** Small JSON and text helpers. */
final class J {
    private J() {}

    static String q(String s) {
        if (s == null) return "null";
        StringBuilder b = new StringBuilder(s.length() + 2).append('"');
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '"' -> b.append("\\\"");
                case '\\' -> b.append("\\\\");
                case '\n' -> b.append("\\n");
                case '\r' -> b.append("\\r");
                case '\t' -> b.append("\\t");
                default -> {
                    if (c < 0x20 || c == 0x7f) b.append(String.format("\\u%04x", (int) c));
                    else b.append(c);
                }
            }
        }
        return b.append('"').toString();
    }

    static String str(FormattedCharSequence text) {
        StringBuilder b = new StringBuilder();
        text.accept((pos, style, cp) -> {
            b.appendCodePoint(cp);
            return true;
        });
        return b.toString();
    }

    /** First explicit style colour in the run, or -1 when the run uses the state's own colour. */
    static int styleColor(FormattedCharSequence text) {
        int[] c = {-1};
        text.accept((pos, style, cp) -> {
            TextColor col = style.getColor();
            if (col != null) {
                c[0] = col.getValue();
                return false;
            }
            return true;
        });
        return c[0];
    }
}
