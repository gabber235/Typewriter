package com.typewritermc.playtest.client;

import com.mojang.blaze3d.systems.RenderSystem;
import com.typewritermc.playtest.client.mixin.GameRendererInvoker;
import com.typewritermc.playtest.client.mixin.LevelRendererInvoker;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.GameRenderer;
import net.minecraft.client.renderer.SubmitNodeStorage;
import net.minecraft.client.renderer.chunk.SectionRenderDispatcher;
import net.minecraft.client.renderer.state.GameRenderState;
import net.minecraft.client.renderer.state.level.CameraRenderState;
import net.minecraft.client.renderer.state.level.LevelRenderState;
import net.minecraft.util.Util;

/**
 * {@code GameRenderer.render} with every GPU step cut, run after extract on a frame that acquired no
 * window texture. It keeps the CPU work whose result a later drawn frame or the next extract reads: the
 * view area follows the camera, the world's submits run and are dropped, dirty sections compile and
 * upload, and the occlusion graph updates the visible sections the next extract culls with.
 */
final class NoDraw {
    private NoDraw() {}

    static void render(Minecraft mc) {
        GameRenderer renderer = mc.gameRenderer;
        GameRenderState state = renderer.gameRenderState();
        var window = state.windowRenderState;
        if (window.width != renderer.mainRenderTarget().width || window.height != renderer.mainRenderTarget().height) {
            renderer.resize(window.width, window.height);
        }
        if (!state.shouldRenderLevel) return;
        var level = (LevelRendererInvoker) mc.levelRenderer;
        CameraRenderState camera = state.levelRenderState.cameraRenderState;
        LevelRenderState levelState = level.playtest$levelRenderState();
        RenderSystem.isRenderingLevel = true;
        try {
            level.playtest$repositionCamera(camera);
            SubmitNodeStorage storage = level.playtest$submitNodeStorage();
            storage.setUseImprovedTransparency(renderer.useImprovedTransparency());
            level.playtest$submitFeatures(levelState, storage, ((GameRendererInvoker) renderer).playtest$shouldRenderBlockOutline());
            storage.drainPhases(phase -> phase.sortInto((submit, ordered) -> {}));
            level.playtest$compileSections(camera);
            SectionRenderDispatcher sections = level.playtest$sectionRenderDispatcher();
            if (sections != null) {
                sections.lock();
                try {
                    sections.uploadTerrainBuffersToGpu();
                } finally {
                    sections.unlock();
                }
            }
            var options = level.playtest$optionsRenderState();
            mc.levelRenderer.sectionOcclusionGraph().update(camera, options.fov, levelState.chunkLoadingRenderState);
            Runnable compiled = levelState.playerCompiledSectionCallback;
            if (compiled != null && mc.levelRenderer.isSectionCompiledAndVisible(camera.blockPos, Util.toMillis(options.chunkSectionFadeInTime))) {
                compiled.run();
            }
        } finally {
            RenderSystem.isRenderingLevel = false;
        }
    }
}
