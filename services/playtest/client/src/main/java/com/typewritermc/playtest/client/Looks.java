package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Message.Look;
import com.typewritermc.playtest.wire.Message.Looked;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.GameRenderer;

/**
 * The entities a check asked about: how many pixels each owns, whenever a perceived frame draws it.
 * Only then does a stepped client draw for real: once with every entity, then once without each asked
 * entity the frame draws, and an entity owns the pixels that show another colour without it. The
 * perceive step's section compiles and occlusion update run first, so every draw sees the same world.
 * Render thread only.
 */
final class Looks {
    private static final Set<UUID> asked = new LinkedHashSet<>();
    private static UUID hidden;
    private static Long answer;

    private Looks() {}

    /** From now on records measure what {@code look} names; the answer goes out after the next record. */
    static void ask(Look look) {
        asked.clear();
        asked.addAll(look.entities());
        answer = look.request();
    }

    /** A new attempt: no check asks any more. */
    static void reset() {
        asked.clear();
        hidden = null;
        answer = null;
    }

    /** After a record went out: a look waiting for one is answered. */
    static void recordSent() {
        if (answer == null) return;
        PlaytestClient.send(new Looked(answer));
        answer = null;
    }

    /** Whether the frame extracting now leaves {@code entity} out, to draw the frame without it. */
    static boolean hides(UUID entity) {
        return entity.equals(hidden);
    }

    /**
     * The perceive step of a frame whose extract ran: perceives as {@link NoDraw} does, and when the
     * frame draws an asked entity, draws it for real and counts pixels. The world's submits consume
     * what the extract handed them, so each drawn frame extracts afresh, muted: once with every entity,
     * then once without each asked entity the frame draws.
     */
    static void perceive(Minecraft mc, GameRenderer renderer) {
        List<UUID> drawn = asked.stream().filter(Perceiver::draws).toList();
        NoDraw.render(mc);
        if (drawn.isEmpty()) return;
        var copies = new ArrayList<Grab.Copy>(drawn.size() + 1);
        copies.add(drawWithout(mc, renderer, null));
        for (UUID entity : drawn) copies.add(drawWithout(mc, renderer, entity));
        List<Pixels> frames = Grab.read(copies);
        for (int index = 0; index < drawn.size(); index++) {
            Perceiver.owns(drawn.get(index), frames.getFirst().differences(frames.get(index + 1)));
        }
    }

    /** Extracts and draws the frame again, leaving {@code entity} out unless it is null, and queues a copy of it. */
    private static Grab.Copy drawWithout(Minecraft mc, GameRenderer renderer, UUID entity) {
        hidden = entity;
        Perceiver.mute(true);
        try {
            renderer.extract(mc.getDeltaTracker(), true);
            renderer.render();
        } finally {
            Perceiver.mute(false);
            hidden = null;
        }
        return Grab.copy(renderer.mainRenderTarget());
    }
}
