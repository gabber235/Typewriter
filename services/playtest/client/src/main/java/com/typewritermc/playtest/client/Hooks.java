package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Message.BarrierSeen;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.GameRenderer;
import net.minecraft.client.renderer.entity.state.EntityRenderState;
import net.minecraft.client.renderer.state.gui.GuiElementRenderState;
import net.minecraft.client.renderer.state.gui.GuiItemRenderState;
import net.minecraft.client.renderer.state.gui.GuiTextRenderState;
import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.item.ItemStack;

/** The one door from the mixins into the client: every game hook lands here and is handed on. */
public final class Hooks {
    private Hooks() {}

    public static void beforeRunTick(Minecraft mc) {
        Stepper.beforeRunTick(mc);
    }

    public static void afterTick(Minecraft mc) {
        Stepper.afterTick(mc);
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

    public static boolean pretendsFocus() {
        return Inputs.pretendsFocus();
    }

    public static void itemStack(ItemStack stack) {
        Perceiver.onItemStack(stack);
    }

    public static void guiItem(GuiItemRenderState state) {
        Perceiver.onItem(state);
    }

    public static void itemSlot(String element, int slot) {
        Perceiver.itemSlot(element, slot);
    }

    public static void itemSlotDone() {
        Perceiver.itemSlot(null, -1);
    }

    public static void selectionFrame(boolean drawing) {
        Perceiver.selectionFrame(drawing);
    }

    public static void scoped() {
        Perceiver.onSpyglass();
    }

    public static void blockChanged(BlockPos pos) {
        Perceiver.onBlockChanged(pos);
    }

    public static void entityDrawn(Entity entity, EntityRenderState state) {
        Perceiver.onEntity(entity, state);
    }
}
