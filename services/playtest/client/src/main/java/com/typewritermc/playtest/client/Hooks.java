package com.typewritermc.playtest.client;

import build.skir.internal.MustNameArguments;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.GameRenderer;
import net.minecraft.client.renderer.entity.state.EntityRenderState;
import net.minecraft.client.renderer.state.gui.GuiElementRenderState;
import net.minecraft.client.renderer.state.gui.GuiItemRenderState;
import net.minecraft.client.renderer.state.gui.GuiTextRenderState;
import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.item.ItemStack;
import org.lwjgl.sdl.SDLEvents;
import org.lwjgl.sdl.SDL_Event;
import skirout.harness.v1.wire.Message;
import skirout.harness.v1.wire.PlayerEvent;

/** The one door from the mixins into the client: every game hook lands here and is handed on. */
public final class Hooks {
    private Hooks() {}

    public static void processPackets(Minecraft mc) {
        Stepper.processPackets(mc);
    }

    public static void beforeRunTick(Minecraft mc) {
        Stepper.beforeRunTick(mc);
    }

    public static void leavingWorld(Minecraft mc) {
        Session.leavingWorld(mc);
    }

    public static void afterTick(Minecraft mc) {
        Stepper.afterTick(mc);
        Session.afterTick(mc);
    }

    /** Whether the frame acquires a window texture, that is, whether it draws. */
    public static boolean beginFrame(Minecraft mc) {
        return Frames.begin(mc) == Frames.Mode.DRAW;
    }

    public static boolean updatesGui() {
        return Stepper.updatesGui();
    }

    public static boolean extracts() {
        return Frames.mode() != Frames.Mode.SKIP;
    }

    public static void render(Minecraft mc, GameRenderer renderer) {
        switch (Frames.mode()) {
            case DRAW -> {
                renderer.render();
                Looks.drawn(renderer);
            }
            case PERCEIVE -> Looks.perceive(mc, renderer);
            case SKIP -> {}
        }
        Frames.end();
    }

    /** Whether the client sets how far past the last tick a frame draws: while it steps. */
    public static boolean stepsPartialTick() {
        return Stepper.stepping();
    }

    /** How far from the tick before to the last tick the frame draws: the tick's end, unless a clip draws between ticks. */
    public static float partialTick() {
        return Clips.partial();
    }

    public static void wake() {
        Stepper.wake();
    }

    public static void ping(int id) {
        if (id >= Stepper.STEP_BASE) Stepper.onStepPing(id - Stepper.STEP_BASE);
        else PlaytestClient.send(new Message.PlayerEventWrapper(new PlayerEvent(
                MustNameArguments.INSTANCE, PlaytestClient.player(), PlayerEvent.Happened.Companion.createBarrierSeen(MustNameArguments.INSTANCE, id), null)));
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

    private static final OwnInput EVENTS = new OwnInput(
            SDLEvents::SDL_PollEvent, () -> Inputs.device(Minecraft.getInstance()), Stepper::stepping, Stepper::currentTick, PlaytestClient.LOG::info);

    /** The game's event poll: only the playtest's own mouse and key events while the client steps. */
    public static boolean pollEvent(SDL_Event event) {
        return EVENTS.poll(event);
    }

    public static void inputFlushed() {
        Inputs.flushed();
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

    /** Whether the frame extracting now leaves {@code entity} out, as if it stood nowhere in view. */
    public static boolean hidden(Entity entity) {
        return Looks.hides(entity.getUUID());
    }
}
