package probe.mod.observe;

import java.util.List;
import java.util.Locale;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.components.LerpingBossEvent;
import net.minecraft.client.multiplayer.chat.GuiMessage;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.network.chat.Component;
import net.minecraft.network.chat.TextColor;
import net.minecraft.world.entity.Display;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.phys.Vec3;
import net.minecraft.world.scores.DisplaySlot;
import net.minecraft.world.scores.Objective;
import net.minecraft.world.scores.PlayerScoreEntry;
import net.minecraft.world.scores.Scoreboard;
import probe.mod.mixin.ChatAccessor;
import probe.mod.mixin.HudAccessor;
import probe.mod.observe.mixin.BossAccessor;

/** A1: what the client holds. Nothing here knows whether it reached the screen. */
final class Held {
    private Held() {}

    private static String comp(Component c) {
        return c == null ? "null" : J.q(c.getString());
    }

    private static int color(Component c) {
        if (c == null) return -1;
        TextColor col = c.getStyle().getColor();
        return col == null ? -1 : col.getValue();
    }

    /** Client thread. */
    static String json(Minecraft mc) {
        StringBuilder b = new StringBuilder(1024);
        HudAccessor hud = (HudAccessor) mc.gui.hud;
        b.append("{\"title\":").append(comp(hud.probe$title())).append(",\"titleColor\":").append(color(hud.probe$title()))
            .append(",\"sub\":").append(comp(hud.probe$subtitle())).append(",\"titleTime\":").append(hud.probe$titleTime())
            .append(",\"bar\":").append(comp(hud.probe$bar())).append(",\"barTime\":").append(hud.probe$barTime());
        b.append(",\"chat\":[");
        List<GuiMessage> all = ((ChatAccessor) mc.gui.hud.getChat()).probe$allMessages();
        for (int i = 0; i < all.size(); i++) {
            if (i > 0) b.append(',');
            b.append(J.q(all.get(i).content().getString()));
        }
        b.append("],\"ents\":[");
        boolean first = true;
        if (mc.level != null) {
            for (Entity e : mc.level.entitiesForRendering()) {
                if (e == mc.player) continue;
                if (!first) b.append(',');
                first = false;
                b.append("{\"id\":").append(e.getId()).append(",\"type\":").append(J.q(BuiltInRegistries.ENTITY_TYPE.getKey(e.getType()).toString()))
                    .append(",\"name\":").append(comp(e.getCustomName())).append(",\"invisible\":").append(e.isInvisible());
                if (e instanceof Display.TextDisplay d) b.append(",\"text\":").append(comp(d.getText()));
                b.append(String.format(Locale.ROOT, ",\"p\":[%.2f,%.2f,%.2f]}", e.getX(), e.getY(), e.getZ()));
            }
        }
        b.append("],\"inv\":[");
        if (mc.player != null) {
            first = true;
            for (int i = 0; i < mc.player.getInventory().getContainerSize(); i++) {
                ItemStack s = mc.player.getInventory().getItem(i);
                if (s.isEmpty()) continue;
                if (!first) b.append(',');
                first = false;
                b.append(J.q(BuiltInRegistries.ITEM.getKey(s.getItem()) + "*" + s.getCount()));
            }
        }
        var sc = mc.gui.screen();
        Vec3 cam = mc.gameRenderer.mainCamera().position();
        b.append("],\"screen\":").append(J.q(sc == null ? "none" : sc.getClass().getSimpleName()))
            .append(String.format(Locale.ROOT, ",\"cam\":[%.3f,%.3f,%.3f]", cam.x, cam.y, cam.z));
        boss(mc, b);
        sidebar(mc, b);
        return b.append('}').toString();
    }

    // FLEX-A1-BOSS begin
    private static void boss(Minecraft mc, StringBuilder b) {
        b.append(",\"boss\":[");
        boolean first = true;
        for (LerpingBossEvent e : ((BossAccessor) mc.gui.hud.getBossOverlay()).probe$events().values()) {
            if (!first) b.append(',');
            first = false;
            b.append("{\"name\":").append(comp(e.getName())).append(",\"progress\":").append(e.getProgress()).append('}');
        }
        b.append(']');
    }
    // FLEX-A1-BOSS end

    // FLEX-A1-SIDEBAR begin
    private static void sidebar(Minecraft mc, StringBuilder b) {
        b.append(",\"sidebar\":");
        Scoreboard board = mc.level == null ? null : mc.level.getScoreboard();
        Objective o = board == null ? null : board.getDisplayObjective(DisplaySlot.SIDEBAR);
        if (o == null) {
            b.append("null");
            return;
        }
        b.append("{\"title\":").append(comp(o.getDisplayName())).append(",\"lines\":[");
        boolean first = true;
        for (PlayerScoreEntry e : board.listPlayerScores(o)) {
            if (!first) b.append(',');
            first = false;
            b.append(J.q(e.ownerName().getString() + " " + e.value()));
        }
        b.append("]}");
    }
    // FLEX-A1-SIDEBAR end

    static String block(Minecraft mc, BlockPos pos) {
        return J.q(mc.level == null ? "?" : BuiltInRegistries.BLOCK.getKey(mc.level.getBlockState(pos).getBlock()).toString());
    }
}
