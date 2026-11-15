package com.typewritermc.playtest.client.mixin;

import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;
import net.minecraft.client.renderer.SectionOcclusionGraph;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

/**
 * Whether the visible sections are current: a move or a turn asks for a full update, which runs on a
 * background thread and hands its graph to the next extract through the frustum update.
 */
@Mixin(SectionOcclusionGraph.class)
public interface SectionOcclusionGraphAccessor {
    @Accessor("needsFullUpdate")
    boolean playtest$needsFullUpdate();

    @Accessor("fullUpdateTask")
    Future<?> playtest$fullUpdateTask();

    @Accessor("needsFrustumUpdate")
    AtomicBoolean playtest$needsFrustumUpdate();
}
