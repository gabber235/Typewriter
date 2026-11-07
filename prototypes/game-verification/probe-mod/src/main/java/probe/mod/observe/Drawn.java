package probe.mod.observe;

import com.mojang.blaze3d.vertex.PoseStack;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.Font;
import net.minecraft.client.gui.navigation.ScreenRectangle;
import net.minecraft.client.renderer.ViewArea;
import net.minecraft.client.renderer.blockentity.state.BlockEntityRenderState;
import net.minecraft.client.renderer.chunk.SectionRenderDispatcher;
import net.minecraft.client.renderer.entity.state.EntityRenderState;
import net.minecraft.client.renderer.state.gui.BlitRenderState;
import net.minecraft.client.renderer.state.gui.ColoredRectangleRenderState;
import net.minecraft.client.renderer.state.gui.GuiElementRenderState;
import net.minecraft.client.renderer.state.gui.GuiItemRenderState;
import net.minecraft.client.renderer.state.gui.GuiTextRenderState;
import net.minecraft.client.renderer.state.level.CameraRenderState;
import net.minecraft.client.renderer.state.level.LevelRenderState;
import net.minecraft.client.resources.sounds.Sound;
import net.minecraft.client.resources.sounds.SoundInstance;
import net.minecraft.client.sounds.SoundManager;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.network.chat.Component;
import net.minecraft.sounds.SoundSource;
import net.minecraft.util.FormattedCharSequence;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.Vec3;
import org.joml.Matrix4f;
import org.joml.Vector4f;
import probe.mod.observe.mixin.GuiTextAccessor;
import probe.mod.observe.mixin.LevelRendererAccessor;

/**
 * A2: what really reached the draw path in the last rendered frame. Also the A4 suppression switches:
 * the hooks that record a thing are the same hooks that can leave it out of one frame.
 */
public final class Drawn {
    public static volatile boolean on = true;
    public static volatile int[] overdraw;
    public static volatile int hideEntity = Integer.MIN_VALUE;
    public static volatile String hideText;
    public static volatile String hideItem;
    public static volatile boolean pinning;
    public static volatile float pinned = Float.NaN;
    public static volatile long ticks;
    public static volatile long hideHits;
    public static long hookNanos;
    public static long framesCounted;

    record GuiEl(char kind, Object ref, int[] box, int color, String extra, String tag) {}
    static final class Ent {
        int id; String type; String name; boolean invisible; int geo; double x, y, z; final List<String> text = new ArrayList<>();
    }
    record WorldText(String text, int color, int bg, int style, float[] screen, double area, String mode, int entity) {}
    record Snd(long seq, long at, String id, String src, double x, double y, double z, float vol, float pitch, String att, float range, double dist, float cat, float master, double effective, boolean relative) {}

    static final class Frame {
        long no; String screen; boolean hudHidden; int blurAt = -1; int fbW, fbH, guiW, guiH;
        final List<GuiEl> gui = new ArrayList<>();
        final List<Ent> ents = new ArrayList<>();
        final List<WorldText> world = new ArrayList<>();
        final List<String> blockEnts = new ArrayList<>();
    }

    private static Frame cur = new Frame();
    public static volatile Frame last = new Frame();
    private static final IdentityHashMap<EntityRenderState, Ent> byState = new IdentityHashMap<>();
    private static Ent submitting;
    private static String lastBackground;
    private static int lastBgColor;
    private static long frameNo;
    private static final Map<Long, Object> meshAtChange = new HashMap<>();
    private static final List<Snd> sounds = new ArrayList<>();
    private static long soundSeq;

    private Drawn() {}

    // ---- GUI ----
    private static int[] box(ScreenRectangle r) {
        return r == null ? null : new int[] {r.left(), r.top(), r.right(), r.bottom()};
    }

    public static boolean onGuiText(GuiTextRenderState state) {
        long t = System.nanoTime();
        try {
            String h = hideText;
            if (h != null && J.str(((GuiTextAccessor) (Object) state).probe$text()).contains(h)) {
                hideHits++;
                return true;
            }
            if (!on) return false;
            ScreenRectangle b = state.bounds();
            if (b != null) cur.gui.add(new GuiEl('T', state, box(b), ((GuiTextAccessor) (Object) state).probe$color(), null, Tag.current()));
            return false;
        } finally {
            hookNanos += System.nanoTime() - t;
        }
    }

    public static void onGuiElement(GuiElementRenderState state) {
        if (!on) return;
        long t = System.nanoTime();
        ScreenRectangle b = state.bounds();
        if (b != null) {
            char kind = 'B';
            int color = -1;
            if (state instanceof ColoredRectangleRenderState r) {
                kind = 'R';
                color = r.col1();
            } else if (state instanceof BlitRenderState blit) {
                color = blit.color();
            }
            cur.gui.add(new GuiEl(kind, null, box(b), color, null, Tag.current()));
        }
        hookNanos += System.nanoTime() - t;
    }

    private static String pendingItem;

    public static boolean onGuiItem(ItemStack stack, int x, int y) {
        if (stack.isEmpty()) return false;
        String id = BuiltInRegistries.ITEM.getKey(stack.getItem()).toString();
        String h = hideItem;
        if (h != null && id.equals(h)) {
            hideHits++;
            return true;
        }
        pendingItem = id + "*" + stack.getCount();
        return false;
    }

    public static void onGuiItemBounds(GuiItemRenderState state) {
        if (!on) return;
        ScreenRectangle b = state.bounds();
        if (b != null) cur.gui.add(new GuiEl('I', null, box(b), -1, pendingItem, Tag.current()));
    }

    public static void onBlur() {
        cur.blurAt = cur.gui.size();
    }

    // ---- Entities and world text ----
    public static void onEntityExtract(Entity entity, EntityRenderState state) {
        if (!on && hideEntity == Integer.MIN_VALUE) return;
        Ent e = new Ent();
        e.id = entity.getId();
        e.type = BuiltInRegistries.ENTITY_TYPE.getKey(entity.getType()).toString();
        Component name = entity.getCustomName();
        e.name = name == null ? null : name.getString();
        e.invisible = state.isInvisible;
        e.x = state.x;
        e.y = state.y;
        e.z = state.z;
        byState.put(state, e);
    }

    public static void afterEntities(LevelRenderState output) {
        long t = System.nanoTime();
        int h = hideEntity;
        if (h != Integer.MIN_VALUE) {
            output.entityRenderStates.removeIf(s -> {
                Ent e = byState.get(s);
                boolean hit = e != null && e.id == h;
                if (hit) hideHits++;
                return hit;
            });
        }
        if (on) {
            for (EntityRenderState s : output.entityRenderStates) {
                Ent e = byState.get(s);
                if (e != null) cur.ents.add(e);
            }
        }
        hookNanos += System.nanoTime() - t;
    }

    public static void afterBlockEntities(LevelRenderState output) {
        if (!on) return;
        for (BlockEntityRenderState s : output.blockEntityRenderStates) cur.blockEnts.add(s.blockPos.toShortString());
    }

    public static void beginEntitySubmit(EntityRenderState state) {
        submitting = byState.get(state);
    }

    public static void endEntitySubmit() {
        submitting = null;
    }

    public static void onGeometry() {
        if (submitting != null) submitting.geo++;
    }

    public static void onWorldTextBackground(int color) {
        lastBgColor = color;
        if (submitting != null) submitting.geo++;
    }

    /** Projected corners in framebuffer pixels; the sign of the signed area tells facing. */
    private static float[] project(Matrix4f pose, float x0, float y0, float x1, float y1) {
        Minecraft mc = Minecraft.getInstance();
        CameraRenderState cam = mc.gameRenderer.gameRenderState().levelRenderState.cameraRenderState;
        Matrix4f m = new Matrix4f(cam.projectionMatrix).mul(cam.viewRotationMatrix).mul(pose);
        float[] out = new float[8];
        float[][] c = {{x0, y0}, {x1, y0}, {x1, y1}, {x0, y1}};
        int w = mc.getWindow().getWidth(), h = mc.getWindow().getHeight();
        for (int i = 0; i < 4; i++) {
            Vector4f v = m.transform(new Vector4f(c[i][0], c[i][1], 0, 1));
            if (v.w <= 0) return null;
            out[i * 2] = (v.x / v.w * 0.5f + 0.5f) * w;
            out[i * 2 + 1] = (0.5f - v.y / v.w * 0.5f) * h;
        }
        return out;
    }

    private static double signedArea(float[] p) {
        if (p == null) return 0;
        double a = 0;
        for (int i = 0; i < 4; i++) {
            int j = (i + 1) % 4;
            a += p[i * 2] * p[j * 2 + 1] - p[j * 2] * p[i * 2 + 1];
        }
        return a / 2;
    }

    public static boolean onWorldText(PoseStack pose, float x, float y, FormattedCharSequence text, int color, int bg, Font.DisplayMode mode) {
        long t = System.nanoTime();
        try {
            String s = null;
            String h = hideText;
            if (h != null) {
                s = J.str(text);
                if (s.contains(h)) {
                    hideHits++;
                    return true;
                }
            }
            if (submitting != null) submitting.geo++;
            if (!on) return false;
            if (s == null) s = J.str(text);
            if (submitting != null) submitting.text.add(s);
            int width = Minecraft.getInstance().font.width(text);
            float[] screen = project(pose.last().pose(), x, y, x + width, y + 8);
            int effectiveBg = bg != 0 ? bg : lastBgColor;
            cur.world.add(new WorldText(s, color, effectiveBg, J.styleColor(text), screen, signedArea(screen), mode.name(), submitting == null ? -1 : submitting.id));
            lastBgColor = 0;
            return false;
        } finally {
            hookNanos += System.nanoTime() - t;
        }
    }

    public static boolean onNameTag(PoseStack pose, Vec3 at, Component name) {
        String s = name.getString();
        String h = hideText;
        if (h != null && s.contains(h)) {
            hideHits++;
            return true;
        }
        if (submitting != null) submitting.geo++;
        if (!on || at == null) return false;
        pose.pushPose();
        pose.translate(at.x, at.y + 0.5, at.z);
        Matrix4f m = new Matrix4f(pose.last().pose());
        pose.popPose();
        Minecraft mc = Minecraft.getInstance();
        CameraRenderState cam = mc.gameRenderer.gameRenderState().levelRenderState.cameraRenderState;
        Vector4f v = new Matrix4f(cam.projectionMatrix).mul(cam.viewRotationMatrix).mul(m).transform(new Vector4f(0, 0, 0, 1));
        float[] p = v.w <= 0 ? null : new float[] {(v.x / v.w * 0.5f + 0.5f) * mc.getWindow().getWidth(), (0.5f - v.y / v.w * 0.5f) * mc.getWindow().getHeight()};
        cur.world.add(new WorldText(s, -1, 0, -1, p, 0, "NAMETAG", submitting == null ? -1 : submitting.id));
        return false;
    }

    // ---- Blocks: meshes are per section, so the per block fact is "a new mesh since the change" ----
    public static void onBlockDirty(BlockPos pos) {
        Minecraft mc = Minecraft.getInstance();
        ViewArea area = ((LevelRendererAccessor) mc.levelRenderer).probe$viewArea();
        if (area == null) return;
        SectionRenderDispatcher.RenderSection s = area.getRenderSectionAt(pos);
        if (s != null) meshAtChange.put(pos.asLong(), s.sectionMesh.get());
    }

    public static void clearMeshes() {
        meshAtChange.clear();
    }

    /** Must run on the client thread. */
    public static String blockJson(Minecraft mc, BlockPos pos) {
        ViewArea area = ((LevelRendererAccessor) mc.levelRenderer).probe$viewArea();
        SectionRenderDispatcher.RenderSection s = area == null ? null : area.getRenderSectionAt(pos);
        boolean compiled = s != null && s.sectionMesh.get() != net.minecraft.client.renderer.chunk.CompiledSectionMesh.UNCOMPILED;
        boolean visible = s != null && mc.levelRenderer.visibleSections().contains(s);
        boolean inFrustum = mc.gameRenderer.gameRenderState().levelRenderState.cameraRenderState.cullFrustum.isVisible(new AABB(pos));
        Object at = meshAtChange.get(pos.asLong());
        boolean meshNew = at == null ? compiled : (s != null && s.sectionMesh.get() != at);
        String state = mc.level == null ? "?" : BuiltInRegistries.BLOCK.getKey(mc.level.getBlockState(pos).getBlock()).toString();
        return "{\"state\":" + J.q(state) + ",\"compiled\":" + compiled + ",\"sectionVisible\":" + visible + ",\"inFrustum\":" + inFrustum
            + ",\"meshNewSinceChange\":" + meshNew + ",\"tracked\":" + (at != null) + "}";
    }

    // ---- Sound ----
    public static void onSound(SoundInstance instance, SoundManager manager) {
        Minecraft mc = Minecraft.getInstance();
        try {
            if (instance.getOrResolve(manager) == null) return;
            Sound sound = instance.getSound();
            if (sound == null) return;
            SoundSource src = instance.getSource();
            float vol = instance.getVolume();
            float range = sound.getAttenuationDistance(vol);
            Vec3 l = mc.gameRenderer.mainCamera().position();
            double dx = instance.getX() - (instance.isRelative() ? 0 : l.x);
            double dy = instance.getY() - (instance.isRelative() ? 0 : l.y);
            double dz = instance.getZ() - (instance.isRelative() ? 0 : l.z);
            double dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
            boolean linear = instance.getAttenuation() == SoundInstance.Attenuation.LINEAR;
            double atten = linear ? Math.max(0, 1 - dist / range) : 1;
            float cat = mc.options.getSoundSourceVolume(src);
            float master = mc.options.getSoundSourceVolume(SoundSource.MASTER);
            // Master is forced to zero on the developer's machine, so "effective" leaves it out on purpose.
            double effective = Math.min(vol, 1f) * cat * atten;
            synchronized (sounds) {
                sounds.add(new Snd(++soundSeq, System.currentTimeMillis(), instance.getIdentifier().toString(), src.getName(), instance.getX(), instance.getY(), instance.getZ(), vol, instance.getPitch(),
                    instance.getAttenuation().name(), range, dist, cat, master, effective, instance.isRelative()));
                if (sounds.size() > 400) sounds.remove(0);
            }
        } catch (RuntimeException e) {
            e.printStackTrace();
        }
    }

    // ---- Frame boundary ----
    public static void endFrame(Minecraft mc, boolean rendered) {
        if (!rendered) {
            cur = new Frame();
            byState.clear();
            return;
        }
        Frame f = cur;
        f.no = ++frameNo;
        framesCounted++;
        var screen = mc.gui.screen();
        f.screen = screen == null ? "none" : screen.getClass().getSimpleName();
        f.hudHidden = mc.gui.hud.isHidden();
        f.fbW = mc.getWindow().getWidth();
        f.fbH = mc.getWindow().getHeight();
        f.guiW = mc.getWindow().getGuiScaledWidth();
        f.guiH = mc.getWindow().getGuiScaledHeight();
        last = f;
        cur = new Frame();
        byState.clear();
    }

    // ---- JSON ----
    public static String frameJson() {
        Frame f = last;
        StringBuilder b = new StringBuilder(2048);
        b.append("{\"no\":").append(f.no).append(",\"screen\":").append(J.q(f.screen)).append(",\"hudHidden\":").append(f.hudHidden)
            .append(",\"blurAt\":").append(f.blurAt).append(",\"fb\":[").append(f.fbW).append(',').append(f.fbH).append("],\"gui\":[").append(f.guiW).append(',').append(f.guiH).append("],\"elems\":[");
        for (int i = 0; i < f.gui.size(); i++) {
            GuiEl e = f.gui.get(i);
            if (i > 0) b.append(',');
            b.append("{\"k\":\"").append(e.kind()).append("\",\"b\":[").append(e.box()[0]).append(',').append(e.box()[1]).append(',').append(e.box()[2]).append(',').append(e.box()[3])
                .append("],\"c\":").append(e.color());
            if (e.ref() instanceof GuiTextRenderState t) {
                FormattedCharSequence text = ((GuiTextAccessor) (Object) t).probe$text();
                b.append(",\"t\":").append(J.q(J.str(text))).append(",\"s\":").append(J.styleColor(text)).append(",\"bg\":").append(((GuiTextAccessor) (Object) t).probe$bg());
            } else if (e.extra() != null) {
                b.append(",\"t\":").append(J.q(e.extra()));
            }
            b.append('}');
        }
        b.append("],\"ents\":[");
        for (int i = 0; i < f.ents.size(); i++) {
            Ent e = f.ents.get(i);
            if (i > 0) b.append(',');
            b.append("{\"id\":").append(e.id).append(",\"type\":").append(J.q(e.type)).append(",\"name\":").append(J.q(e.name))
                .append(",\"inv\":").append(e.invisible).append(",\"geo\":").append(e.geo).append(String.format(Locale.ROOT, ",\"p\":[%.2f,%.2f,%.2f]", e.x, e.y, e.z)).append('}');
        }
        b.append("],\"world\":[");
        for (int i = 0; i < f.world.size(); i++) {
            WorldText w = f.world.get(i);
            if (i > 0) b.append(',');
            b.append("{\"t\":").append(J.q(w.text())).append(",\"c\":").append(w.color()).append(",\"bg\":").append(w.bg()).append(",\"s\":").append(w.style())
                .append(",\"area\":").append(String.format(Locale.ROOT, "%.1f", w.area())).append(",\"mode\":").append(J.q(w.mode())).append(",\"e\":").append(w.entity()).append(",\"p\":");
            if (w.screen() == null) b.append("null");
            else {
                b.append('[');
                for (int k = 0; k < w.screen().length; k++) {
                    if (k > 0) b.append(',');
                    b.append(String.format(Locale.ROOT, "%.0f", w.screen()[k]));
                }
                b.append(']');
            }
            b.append('}');
        }
        b.append("],\"blockEnts\":").append(f.blockEnts.size()).append('}');
        return b.toString();
    }

    public static String soundsJson(long since) {
        StringBuilder b = new StringBuilder("{\"seq\":");
        synchronized (sounds) {
            b.append(soundSeq).append(",\"sounds\":[");
            boolean first = true;
            for (Snd s : sounds) {
                if (s.seq() <= since) continue;
                if (!first) b.append(',');
                first = false;
                b.append("{\"seq\":").append(s.seq()).append(",\"id\":").append(J.q(s.id())).append(",\"src\":").append(J.q(s.src()))
                    .append(String.format(Locale.ROOT, ",\"vol\":%.3f,\"pitch\":%.3f,\"att\":\"%s\",\"range\":%.1f,\"dist\":%.1f,\"cat\":%.2f,\"master\":%.2f,\"effective\":%.4f", s.vol(), s.pitch(), s.att(), s.range(), s.dist(), s.cat(), s.master(), s.effective())).append('}');
            }
        }
        return b.append("]}").toString();
    }
}
