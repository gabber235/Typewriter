package com.typewritermc.playtest.client;

import com.typewritermc.playtest.client.mixin.GuiTextRenderStateAccessor;
import com.typewritermc.playtest.wire.Message.Block;
import com.typewritermc.playtest.wire.Message.Camera;
import com.typewritermc.playtest.wire.Message.ChatLine;
import com.typewritermc.playtest.wire.Message.Entity;
import com.typewritermc.playtest.wire.Message.Perceived;
import com.typewritermc.playtest.wire.Message.Perception;
import com.typewritermc.playtest.wire.Message.ResetDone;
import com.typewritermc.playtest.wire.Message.Watch;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.navigation.ScreenRectangle;
import net.minecraft.client.renderer.chunk.CompiledSectionMesh;
import net.minecraft.client.renderer.chunk.SectionMesh;
import net.minecraft.client.renderer.entity.state.EntityRenderState;
import net.minecraft.client.renderer.entity.state.LivingEntityRenderState;
import net.minecraft.client.renderer.state.gui.BlitRenderState;
import net.minecraft.client.renderer.state.gui.ColoredRectangleRenderState;
import net.minecraft.client.renderer.state.gui.GuiElementRenderState;
import net.minecraft.client.renderer.state.gui.GuiItemRenderState;
import net.minecraft.client.renderer.state.gui.GuiTextRenderState;
import net.minecraft.client.renderer.state.level.CameraRenderState;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.phys.AABB;

/**
 * What the player perceives, built from what each frame's extract hands the GUI and the world renderer,
 * and the stream of records to the pool: a record is sent whole after a perceived frame, and only when
 * it changed. Render thread only.
 */
final class Perceiver {
    private static final int MAX_DEPTH = 16;

    /** A watched block's last change: the tick it came in, and the section mesh that did not show it yet. */
    private record Change(int tick, SectionMesh before) {}

    private static final String[] elements = new String[MAX_DEPTH];
    private static final List<ChatLine> chat = new ArrayList<>();
    private static final Set<BlockPos> watchedBlocks = new LinkedHashSet<>();
    private static final Set<UUID> watchedEntities = new LinkedHashSet<>();
    private static final Map<BlockPos, Change> changes = new HashMap<>();
    private static final Map<UUID, Entity> drawnEntities = new LinkedHashMap<>();
    private static int depth;
    private static GuiFrame frame = new GuiFrame(0, 0);
    private static String itemElement;
    private static int itemSlot = -1;
    private static ItemStack itemStack;
    private static boolean selectionFrame;
    private static boolean scoped;
    private static Perception lastSent;
    private static boolean forced;
    private static boolean resetPending;

    private Perceiver() {}

    /**
     * A new attempt: forget the chat, the toasts and the watches so far and send a fresh record, then
     * confirm the reset. A toast lasts seconds of real time, such as the one joining shows, so without
     * this it would cover the start of the next attempts.
     */
    static void reset(Minecraft mc) {
        mc.gui.hud.getChat().clearMessages(false);
        mc.gui.toastManager().clear();
        chat.clear();
        watchedBlocks.clear();
        watchedEntities.clear();
        changes.clear();
        forced = true;
        resetPending = true;
    }

    /** From now on every record also carries these blocks and entities. */
    static void watch(Watch watch) {
        watch.blocks().forEach(at -> watchedBlocks.add(new BlockPos(at.x(), at.y(), at.z())));
        watchedEntities.addAll(watch.entities());
        forced = true;
    }

    static boolean forced() {
        return forced;
    }

    static void beginFrame(Minecraft mc) {
        frame = new GuiFrame(mc.getWindow().getGuiScaledWidth(), mc.getWindow().getGuiScaledHeight());
        drawnEntities.clear();
        scoped = false;
    }

    /** After a frame's extract and render ran: sends the record of {@code tick} when it changed or is forced. */
    static void endFrame(Minecraft mc, int tick) {
        var perception = new Perception(tick, frame.legibleTexts(), List.copyOf(chat), camera(mc), frame.visibleItems(), blocks(mc), entities());
        if (forced || lastSent == null || !sameContent(perception, lastSent)) {
            PlaytestClient.send(new Perceived(PlaytestClient.player(), perception));
            lastSent = perception;
        }
        forced = false;
        if (resetPending) {
            resetPending = false;
            PlaytestClient.send(new ResetDone());
        }
    }

    private static boolean sameContent(Perception a, Perception b) {
        return a.texts().equals(b.texts())
                && a.chat().equals(b.chat())
                && Objects.equals(a.camera(), b.camera())
                && a.items().equals(b.items())
                && a.blocks().equals(b.blocks())
                && a.entities().equals(b.entities());
    }

    /** The view the frame was drawn from, rounded so that a still view gives the same record every frame. */
    private static Camera camera(Minecraft mc) {
        if (mc.level == null) return null;
        CameraRenderState view = mc.gameRenderer.gameRenderState().levelRenderState.cameraRenderState;
        if (!view.initialized) return null;
        float fov = (float) Math.toDegrees(2 * Math.atan(1 / view.projectionMatrix.m11()));
        return new Camera(round(view.pos.x, 100), round(view.pos.y, 100), round(view.pos.z, 100), (float) round(view.yRot, 10), (float) round(view.xRot, 10), (float) round(fov, 10), scoped);
    }

    private static double round(double value, int steps) {
        return Math.round(value * steps) / (double) steps;
    }

    private static List<Block> blocks(Minecraft mc) {
        if (mc.level == null) return List.of();
        var blocks = new ArrayList<Block>();
        for (BlockPos at : watchedBlocks) {
            String id = BuiltInRegistries.BLOCK.getKey(mc.level.getBlockState(at).getBlock()).toString();
            Change change = changes.get(at);
            blocks.add(new Block(new com.typewritermc.playtest.wire.Message.BlockPos(at.getX(), at.getY(), at.getZ()), id, seen(mc, at, change), change == null ? -1 : change.tick()));
        }
        return blocks;
    }

    /**
     * Whether the frame shows the block as it is: blocks have no draw of their own, so its section must be
     * compiled since the block last changed, among the sections the frame draws, and the block inside the
     * view.
     */
    private static boolean seen(Minecraft mc, BlockPos at, Change change) {
        var area = mc.levelRenderer.viewArea();
        var section = area == null ? null : area.getRenderSectionAt(at);
        if (section == null) return false;
        SectionMesh mesh = section.getSectionMesh();
        if (mesh == CompiledSectionMesh.UNCOMPILED) return false;
        if (change != null && mesh == change.before()) return false;
        if (!mc.levelRenderer.visibleSections().contains(section)) return false;
        return mc.gameRenderer.gameRenderState().levelRenderState.cameraRenderState.cullFrustum.isVisible(new AABB(at));
    }

    private static List<Entity> entities() {
        var entities = new ArrayList<Entity>();
        for (UUID uuid : watchedEntities) {
            Entity drawn = drawnEntities.get(uuid);
            if (drawn != null) entities.add(drawn);
        }
        return entities;
    }

    static void onChat(String text) {
        chat.add(new ChatLine(Stepper.arrivalTick(), text));
    }

    /** A block changed in the client's world, from the server or the client's own prediction. */
    static void onBlockChanged(BlockPos pos) {
        if (!watchedBlocks.contains(pos)) return;
        var area = Minecraft.getInstance().levelRenderer.viewArea();
        var section = area == null ? null : area.getRenderSectionAt(pos);
        changes.put(pos.immutable(), new Change(Stepper.currentTick(), section == null ? null : section.getSectionMesh()));
    }

    /** The frame draws {@code entity} after culling, as {@code state}. */
    static void onEntity(net.minecraft.world.entity.Entity entity, EntityRenderState state) {
        if (!watchedEntities.contains(entity.getUUID())) return;
        boolean hurt = state instanceof LivingEntityRenderState living && living.hasRedOverlay;
        String name = state.nameTag == null ? null : state.nameTag.getString();
        drawnEntities.put(entity.getUUID(), new Entity(entity.getUUID(), hurt, name));
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
        if (selectionFrame) frame.selection(box.left(), box.top(), box.right(), box.bottom());
        switch (state) {
            case ColoredRectangleRenderState fill -> frame.element(GuiFrame.Kind.FILL, box.left(), box.top(), box.right(), box.bottom(), fill.col1());
            case BlitRenderState blit -> frame.element(GuiFrame.Kind.IMAGE, box.left(), box.top(), box.right(), box.bottom(), blit.color());
            default -> frame.element(GuiFrame.Kind.IMAGE, box.left(), box.top(), box.right(), box.bottom(), -1);
        }
    }

    /** The GUI starts drawing {@code stack} as an item; its render state follows. */
    static void onItemStack(ItemStack stack) {
        itemStack = stack;
    }

    static void onItem(GuiItemRenderState state) {
        ItemStack stack = itemStack;
        itemStack = null;
        ScreenRectangle box = state.bounds();
        if (stack == null || box == null) return;
        String id = BuiltInRegistries.ITEM.getKey(stack.getItem()).toString();
        String element = itemElement == null ? "other" : itemElement;
        frame.item(element, itemSlot, id, stack.getCount(), box.left(), box.top(), box.right(), box.bottom());
    }

    /** The items drawn from now on stand in {@code slot} of {@code element}; null ends it. */
    static void itemSlot(String element, int slot) {
        itemElement = element;
        itemSlot = slot;
    }

    /** The hotbar's selection frame is being drawn. */
    static void selectionFrame(boolean drawing) {
        selectionFrame = drawing;
    }

    static void onSpyglass() {
        scoped = true;
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
