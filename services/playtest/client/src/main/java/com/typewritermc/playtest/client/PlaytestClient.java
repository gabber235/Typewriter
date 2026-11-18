package com.typewritermc.playtest.client;

import build.skir.internal.MustNameArguments;
import com.typewritermc.playtest.wire.Link;
import java.io.IOException;
import java.io.UncheckedIOException;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.fabricmc.fabric.api.networking.v1.PayloadTypeRegistry;
import net.minecraft.client.Minecraft;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import skirout.harness.v1.wire.Ask;
import skirout.harness.v1.wire.ClientTask;
import skirout.harness.v1.wire.Hello;
import skirout.harness.v1.wire.Message;
import skirout.harness.v1.wire.Request;
import skirout.harness.v1.wire.Role;

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
        PayloadTypeRegistry.serverboundPlay().register(StepAckPayload.TYPE, StepAckPayload.CODEC);
        PayloadTypeRegistry.clientboundPlay().register(WatchPayload.TYPE, WatchPayload.CODEC);
        // Fabric hands a payload over on the thread that handles packets, in order with the game's own.
        ClientPlayNetworking.registerGlobalReceiver(WatchPayload.TYPE, (payload, context) -> Perceiver.watch(payload.watch()));
        player = System.getProperty("playtest.player");
        Integer port = Integer.getInteger("playtest.pool.port");
        if (player == null || port == null) throw new IllegalStateException("playtest.player and playtest.pool.port are not set: only the game pool runs this client");
        try {
            pool = Link.open(port, new Hello(MustNameArguments.INSTANCE, Role.CLIENT.INSTANCE, player, null), PlaytestClient::receive, PlaytestClient::poolLost);
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
            case Message.ConnectWrapper connect -> {
                var to = connect.getValue();
                mc.execute(() -> Session.connect(mc, to.getHost(), to.getPort()));
            }
            case Message.LEAVE leave -> mc.execute(() -> Session.leave(mc));
            case Message.RESET reset -> mc.execute(() -> {
                Inputs.reset(mc);
                Looks.reset();
                Clips.reset();
                Blends.reset(mc);
                Cooldowns.reset(mc);
                Perceiver.reset(mc);
            });
            case Message.RequestWrapper request when request.getValue().getAsk() instanceof Ask.ClientWrapper client ->
                    receive(mc, request.getValue().getId(), client.getValue().getTask());
            default -> LOG.error("The game pool sent {}, which the client never receives", message);
        }
        Stepper.wake();
    }

    /** The session's request {@code request} for this client's player: {@code task}. */
    private static void receive(Minecraft mc, long request, ClientTask task) {
        switch (task) {
            case ClientTask.CaptureWrapper capture -> mc.execute(() -> {
                Looks.capture(request, capture.getValue());
                Perceiver.force();
            });
            case ClientTask.StartClipWrapper start -> mc.execute(() -> Clips.start(request, start.getValue()));
            case ClientTask.STOP_CLIP stop -> mc.execute(() -> Clips.stop(request));
            case ClientTask.InputWrapper input -> Inputs.arrive(request, input.getValue());
            default -> LOG.error("The game pool sent request {} for {}, which the client never serves", request, task);
        }
    }

    /** Without the pool this client serves nobody and holds nothing worth saving. */
    private static void poolLost(IOException cause) {
        LOG.error("Lost the game pool ({}); exiting.", cause.getMessage());
        Runtime.getRuntime().halt(1);
    }
}
