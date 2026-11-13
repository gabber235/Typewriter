package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Message.BarrierSeen;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.GameRenderer;
import net.minecraft.client.renderer.state.gui.GuiElementRenderState;
import net.minecraft.client.renderer.state.gui.GuiTextRenderState;

/** The one door from the mixins into the client: every game hook lands here and is handed on. */
public final class Hooks {
    private Hooks() {}

    public static void beforeRunTick(Minecraft mc) {
        Stepper.beforeRunTick(mc);
    }

    public static void afterTick(Minecraft mc) {
        Stepper.afterTick();
        Session.afterTick(mc);
    }

    /** Whether the frame acquires a window texture, that is, whether it draws. */
    public static boolean beginFrame(Minecraft mc) {
        return Frames.begin(mc) == Frames.Mode.DRAW;
    }

    public static boolean extracts() {
        return Frames.mode() != Frames.Mode.SKIP;
    }

    public static void render(Minecraft mc, GameRenderer renderer) {
        switch (Frames.mode()) {
            case DRAW -> renderer.render();
            case PERCEIVE -> NoDraw.render(mc);
            case SKIP -> {}
        }
        Frames.end();
    }

    public static void wake() {
        Stepper.wake();
    }

    public static void ping(int id) {
        if (id >= Stepper.STEP_BASE) Stepper.onStepPing(id - Stepper.STEP_BASE);
        else PlaytestClient.send(new BarrierSeen(PlaytestClient.player(), id));
    }

    public static void chat(String text) {
        Perceiver.onChat(text);
    }

    public static void guiText(GuiTextRenderState state) {
        Perceiver.onText(state);
    }

    public static void guiElement(GuiElementRenderState state) {
        Perceiver.onElement(state);
    }

    public static void guiBlur() {
        Perceiver.onBlur();
    }

    public static void beginHud() {
        Perceiver.beginHud();
    }

    public static void enter(String element) {
        Perceiver.enter(element);
    }

    public static void leave() {
        Perceiver.leave();
    }
}
