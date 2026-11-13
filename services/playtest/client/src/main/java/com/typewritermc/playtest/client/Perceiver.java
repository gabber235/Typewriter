package com.typewritermc.playtest.client;

import com.typewritermc.playtest.client.mixin.GuiTextRenderStateAccessor;
import com.typewritermc.playtest.wire.Message.ChatLine;
import com.typewritermc.playtest.wire.Message.Perceived;
import com.typewritermc.playtest.wire.Message.Perception;
import com.typewritermc.playtest.wire.Message.ResetDone;
import java.util.ArrayList;
import java.util.List;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.navigation.ScreenRectangle;
import net.minecraft.client.renderer.state.gui.BlitRenderState;
import net.minecraft.client.renderer.state.gui.ColoredRectangleRenderState;
import net.minecraft.client.renderer.state.gui.GuiElementRenderState;
import net.minecraft.client.renderer.state.gui.GuiTextRenderState;

/**
 * What the player perceives, built from what each frame's extract hands the GUI, and the stream of
 * records to the pool: a record is sent whole after a perceived frame, and only when it changed.
 * Render thread only.
 */
final class Perceiver {
    private static final int MAX_DEPTH = 16;

    private static final String[] elements = new String[MAX_DEPTH];
    private static final List<ChatLine> chat = new ArrayList<>();
    private static int depth;
    private static GuiFrame frame = new GuiFrame(0, 0);
    private static Perception lastSent;
    private static boolean forced;
    private static boolean resetPending;

    private Perceiver() {}

    /** A new attempt: forget the chat so far and send a fresh record, then confirm the reset. */
    static void reset(Minecraft mc) {
        mc.gui.hud.getChat().clearMessages(false);
        chat.clear();
        forced = true;
        resetPending = true;
    }

    static boolean forced() {
        return forced;
    }

    static void beginFrame(Minecraft mc) {
        frame = new GuiFrame(mc.getWindow().getGuiScaledWidth(), mc.getWindow().getGuiScaledHeight());
    }

    /** After a frame's extract ran: sends the record of {@code tick} when it changed or is forced. */
    static void endFrame(int tick) {
        var perception = new Perception(tick, frame.legibleTexts(), List.copyOf(chat));
        boolean changed = lastSent == null || !perception.texts().equals(lastSent.texts()) || !perception.chat().equals(lastSent.chat());
        if (changed || forced) {
            PlaytestClient.send(new Perceived(PlaytestClient.player(), perception));
            lastSent = perception;
        }
        forced = false;
        if (resetPending) {
            resetPending = false;
            PlaytestClient.send(new ResetDone());
        }
    }

    static void onChat(String text) {
        chat.add(new ChatLine(Stepper.arrivalTick(), text));
    }

    static void onText(GuiTextRenderState state) {
        ScreenRectangle box = state.bounds();
        if (box == null) return;
        var text = (GuiTextRenderStateAccessor) (Object) state;
        var run = new StringBuilder();
        text.playtest$text().accept((index, style, codePoint) -> {
            run.appendCodePoint(codePoint);
            return true;
        });
        frame.text(element(), run.toString(), box.left(), box.top(), box.right(), box.bottom(), text.playtest$color());
    }

    static void onElement(GuiElementRenderState state) {
        ScreenRectangle box = state.bounds();
        if (box == null) return;
        switch (state) {
            case ColoredRectangleRenderState fill -> frame.element(GuiFrame.Kind.FILL, box.left(), box.top(), box.right(), box.bottom(), fill.col1());
            case BlitRenderState blit -> frame.element(GuiFrame.Kind.IMAGE, box.left(), box.top(), box.right(), box.bottom(), blit.color());
            default -> frame.element(GuiFrame.Kind.IMAGE, box.left(), box.top(), box.right(), box.bottom(), -1);
        }
    }

    static void onBlur() {
        frame.blur();
    }

    /** The HUD starts extracting; an element left open by an exception must not name the next frame's text. */
    static void beginHud() {
        depth = 0;
    }

    /** A named game element starts adding its text, for example {@code chat}. */
    static void enter(String element) {
        if (depth < MAX_DEPTH) elements[depth] = element;
        depth++;
    }

    static void leave() {
        if (depth > 0) depth--;
    }

    private static String element() {
        return depth == 0 ? null : elements[Math.min(depth, MAX_DEPTH) - 1];
    }
}
