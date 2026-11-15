package com.typewritermc.playtest.client;

import com.typewritermc.playtest.client.mixin.SectionOcclusionGraphAccessor;
import java.util.concurrent.Future;
import net.minecraft.client.Minecraft;

/**
 * The client's own work a tick's record and ack wait for, as Paper's ticks wait for a player's counted
 * work: the events an input queued right after the tick, which the client handles in its next poll and
 * whose packets must reach Paper before the ack does, and the visible sections, which a move updates on
 * a background thread. While either runs, the client perceives the tick again in its next loop pass
 * instead of recording and acking it. Render thread only.
 */
final class ClientWork {
    private static boolean sectionsCurrent = true;

    private ClientWork() {}

    /**
     * After the perceive step updated the occlusion graph, or skipped it ({@code updated} false, with no
     * world to draw): whether the visible sections this frame extracted are the camera's current ones.
     */
    static void perceived(Minecraft mc, boolean updated) {
        sectionsCurrent = !updated || sectionsCurrent(mc);
    }

    /** Whether the frame perceived now may record and ack its tick. */
    static boolean done() {
        return sectionsCurrent && !Inputs.unpolled();
    }

    private static boolean sectionsCurrent(Minecraft mc) {
        var graph = (SectionOcclusionGraphAccessor) mc.levelRenderer.sectionOcclusionGraph();
        Future<?> update = graph.playtest$fullUpdateTask();
        return !graph.playtest$needsFullUpdate() && (update == null || update.isDone()) && !graph.playtest$needsFrustumUpdate().get();
    }
}
