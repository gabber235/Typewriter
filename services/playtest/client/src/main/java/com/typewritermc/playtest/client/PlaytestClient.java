package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Link;
import com.typewritermc.playtest.wire.Message;
import com.typewritermc.playtest.wire.Message.Connect;
import com.typewritermc.playtest.wire.Message.Hello;
import com.typewritermc.playtest.wire.Message.Input;
import com.typewritermc.playtest.wire.Message.Reset;
import com.typewritermc.playtest.wire.Message.Role;
import com.typewritermc.playtest.wire.Message.Watch;
import java.io.IOException;
import java.io.UncheckedIOException;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.networking.v1.PayloadTypeRegistry;
import net.minecraft.client.Minecraft;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Entry point of the verification client. The game pool launches it with {@code playtest.pool.port}
 * and {@code playtest.player}; it connects to the pool before the game window opens.
 */
public final class PlaytestClient implements ClientModInitializer {
    static final Logger LOG = LoggerFactory.getLogger("playtest");

    private static String player;
    private static Link pool;

    @Override
    public void onInitializeClient() {
        PayloadTypeRegistry.serverboundPlay().register(StepAck.TYPE, StepAck.CODEC);
        player = System.getProperty("playtest.player");
        Integer port = Integer.getInteger("playtest.pool.port");
        if (player == null || port == null) throw new IllegalStateException("playtest.player and playtest.pool.port are not set: only the game pool runs this client");
        try {
            pool = Link.open(port, new Hello(Role.CLIENT, player), PlaytestClient::receive, PlaytestClient::poolLost);
        } catch (IOException unreachable) {
            throw new UncheckedIOException("the game pool on port " + port + " is unreachable", unreachable);
        }
    }

    /** The player this client plays, as the pool named it. */
    static String player() {
        return player;
    }

    static void send(Message message) {
        pool.send(message);
    }

    private static void receive(Message message) {
        Minecraft mc = Minecraft.getInstance();
        switch (message) {
            case Connect connect -> mc.execute(() -> Session.connect(connect.host(), connect.port()));
            case Reset reset -> mc.execute(() -> {
                Inputs.reset(mc);
                Perceiver.reset(mc);
            });
            case Watch watch -> mc.execute(() -> Perceiver.watch(watch));
            case Input input -> Inputs.arrive(input);
            default -> LOG.error("The game pool sent {}, which the client never receives", message);
        }
        Stepper.wake();
    }

    /** Without the pool this client serves nobody and holds nothing worth saving. */
    private static void poolLost(IOException cause) {
        LOG.error("Lost the game pool ({}); exiting.", cause.getMessage());
        Runtime.getRuntime().halt(1);
    }
}
