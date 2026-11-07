package probe.mod.observe;

/**
 * Stream prototype: which HUD element is extracting right now. Mixins on the extract methods push
 * a name at HEAD and pop it at RETURN; GuiRenderState.addText reads the innermost name, since GUI
 * text is added synchronously inside the element's own extract call. Render thread only.
 */
public final class Tag {
    private static final String[] stack = new String[32];
    private static int depth;

    private Tag() {}

    public static void push(String t) {
        if (depth < stack.length) stack[depth] = t;
        depth++;
    }

    public static void pop() {
        if (depth > 0) depth--;
    }

    public static String current() {
        return depth == 0 ? null : stack[Math.min(depth, stack.length) - 1];
    }

    /** Head of Hud.extractRenderState: a stack left unbalanced by an exception must not leak into the next frame. */
    public static void reset() {
        depth = 0;
    }
}
