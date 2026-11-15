package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Message.Disconnected;
import com.typewritermc.playtest.wire.Message.Joined;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.screens.ConnectScreen;
import net.minecraft.client.gui.screens.DisconnectedScreen;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.client.gui.screens.TitleScreen;
import net.minecraft.client.gui.screens.multiplayer.JoinMultiplayerScreen;
import net.minecraft.client.multiplayer.ServerData;
import net.minecraft.client.multiplayer.resolver.ServerAddress;
import net.minecraft.network.chat.Component;

/**
 * Joining the Paper the pool names, leaving it again, and telling the pool once the player is in the
 * world. A client the pool sends to another Paper leaves the one it is on the way the pause menu
 * leaves. A client that loses its Paper without being told to leave, or cannot join, tells the pool and
 * draws nothing until the pool names a Paper again: a killed Paper boots while its clients stay quiet.
 * Render thread only.
 */
final class Session {
    private static String host;
    private static int port;
    private static String connectingTo;
    private static boolean leaving;
    private static boolean joined;
    private static boolean everJoined;

    private Session() {}

    /** Whether the player is in the world and the pool heard so. */
    static boolean joined() {
        return joined;
    }

    /** Whether the client lost its Paper and waits for the pool to name one; it draws nothing meanwhile. */
    static boolean waiting() {
        return host == null && everJoined;
    }

    /** The pool names the Paper to join; a client in another Paper's world leaves it first. */
    static void connect(Minecraft mc, String host, int port) {
        Session.host = host;
        Session.port = port;
        if (mc.getConnection() != null) {
            leaving = true;
            mc.disconnectFromWorld(Component.literal("The game pool moves this player to another Paper"));
        }
    }

    /**
     * Head of {@code Minecraft.disconnect}, which every way out of a Paper's world runs through: leaving
     * on purpose and a dropped connection alike. Without a connection there is nothing to leave.
     */
    static void leavingWorld(Minecraft mc) {
        if (mc.getConnection() == null) return;
        joined = false;
        connectingTo = null;
        Stepper.leftPaper();
        Perceiver.leftPaper();
        if (leaving) {
            leaving = false;
            return;
        }
        lost(port, "its connection to the Paper at " + host + ":" + port + " dropped");
    }

    /** After every client tick: joins the named Paper once nothing covers an idle screen, and reports once the player is in the world. */
    static void afterTick(Minecraft mc) {
        if (host == null || joined) return;
        boolean clear = mc.gui.overlay() == null;
        Screen screen = mc.gui.screen();
        var address = host + ":" + port;
        if (connectingTo != null) {
            if (screen instanceof DisconnectedScreen) {
                // A join the pool replaced with another target meanwhile simply starts over.
                boolean same = connectingTo.equals(address);
                connectingTo = null;
                if (same) lost(port, "it could not join the Paper at " + address);
            } else if (mc.player != null && mc.level != null && clear && screen == null) {
                // The pool named another Paper while this join ran: this world is the wrong one.
                if (!connectingTo.equals(address)) {
                    leaving = true;
                    mc.disconnectFromWorld(Component.literal("The game pool moves this player to another Paper"));
                    return;
                }
                joined = true;
                everJoined = true;
                PlaytestClient.send(new Joined());
            }
            return;
        }
        if (clear && (screen instanceof TitleScreen || screen instanceof JoinMultiplayerScreen || screen instanceof DisconnectedScreen)) {
            connectingTo = address;
            ConnectScreen.startConnecting(screen, mc, new ServerAddress(host, port), new ServerData("playtest", address, ServerData.Type.OTHER), false, null);
        }
    }

    /** The client lost the Paper on [lostPort] for [reason] without being told to leave: it tells the pool and waits. */
    private static void lost(int lostPort, String reason) {
        host = null;
        everJoined = true;
        PlaytestClient.send(new Disconnected(lostPort, reason));
    }
}
