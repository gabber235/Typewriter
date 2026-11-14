package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Message.Joined;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.screens.ConnectScreen;
import net.minecraft.client.gui.screens.DisconnectedScreen;
import net.minecraft.client.gui.screens.TitleScreen;
import net.minecraft.client.multiplayer.ServerData;
import net.minecraft.client.multiplayer.resolver.ServerAddress;

/** Joining the Paper the pool names and telling the pool once the player is in the world. Render thread only. */
final class Session {
    private static String host;
    private static int port;
    private static boolean connecting;
    private static boolean joined;

    private Session() {}

    /** Whether the player is in the world and the pool heard so. */
    static boolean joined() {
        return joined;
    }

    static void connect(String host, int port) {
        Session.host = host;
        Session.port = port;
    }

    /** After every client tick: joins once the title screen shows, and reports once the player is in the world. */
    static void afterTick(Minecraft mc) {
        if (host == null || joined) return;
        boolean clear = mc.gui.overlay() == null;
        if (!connecting && clear && mc.gui.screen() instanceof TitleScreen title) {
            connecting = true;
            var address = host + ":" + port;
            ConnectScreen.startConnecting(title, mc, new ServerAddress(host, port), new ServerData("playtest", address, ServerData.Type.OTHER), false, null);
            return;
        }
        if (mc.gui.screen() instanceof DisconnectedScreen) {
            PlaytestClient.LOG.error("Could not join the Paper at {}:{}; exiting.", host, port);
            Runtime.getRuntime().halt(1);
        }
        if (mc.player != null && mc.level != null && clear && mc.gui.screen() == null) {
            joined = true;
            PlaytestClient.send(new Joined());
        }
    }
}
