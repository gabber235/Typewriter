package probe.mod.nodraw;

import com.mojang.blaze3d.systems.RenderSystem;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.GameRenderer;
import net.minecraft.client.renderer.LevelRenderer;
import net.minecraft.client.renderer.SubmitNodeStorage;
import net.minecraft.client.renderer.chunk.SectionRenderDispatcher;
import net.minecraft.client.renderer.state.GameRenderState;
import net.minecraft.client.renderer.state.WindowRenderState;
import net.minecraft.client.renderer.state.level.CameraRenderState;
import net.minecraft.client.renderer.state.level.LevelRenderState;
import net.minecraft.util.Util;
import probe.mod.nodraw.mixin.GameRendererInvoker;
import probe.mod.nodraw.mixin.LevelRendererInvoker;

/**
 * Perceive without drawing: GameRenderer.render with every GPU step cut. Runs after GameRenderer.extract
 * (the GUI render state, entity and block entity states, section visibility) on a frame whose swapchain
 * texture was never acquired, so blit and present already skip themselves.
 *
 * Kept, because A2 or a later drawn frame reads their result:
 *   LevelRenderer.repositionCamera   view area follows the camera; compile sorts from the camera
 *   LevelRenderer.submitFeatures     entity, block entity, name tag and world text submits (A2 seams)
 *   SubmitNodeStorage drain          the submits are dropped instead of prepared into vertices
 *   LevelRenderer.compileSections    meshes of dirty sections (sync nearby, async otherwise)
 *   uploadTerrainBuffersToGpu        compiled meshes reach their buffers, so a later draw is current
 *   SectionOcclusionGraph.update     the visible section list the next extract culls with
 *   window resize                    targets follow the window
 *
 * Cut: clear, global uniforms, lightmap, post effects, fog buffer, frame graph setup and execution (sky,
 * terrain, entities, translucency, outline), FeatureRenderDispatcher.prepareFrame (sort, vertex building,
 * glyph and vertex upload), the first person hand, GuiRenderer.render (GUI vertices, item atlas, draw),
 * the per frame end calls of the GUI, render buffers and the transient target pool.
 */
public final class Nodraw {
    public static long frames, nanos, submitNanos, compileNanos, occlusionNanos;

    private Nodraw() {}

    public static void render(Minecraft mc) {
        long t0 = System.nanoTime();
        GameRenderer gr = mc.gameRenderer;
        GameRenderState state = gr.gameRenderState();
        WindowRenderState window = state.windowRenderState;
        if (window.width != gr.mainRenderTarget().width || window.height != gr.mainRenderTarget().height) {
            gr.resize(window.width, window.height);
        }
        if (state.shouldRenderLevel) {
            LevelRenderer lr = mc.levelRenderer;
            LevelRendererInvoker inv = (LevelRendererInvoker) lr;
            CameraRenderState camera = state.levelRenderState.cameraRenderState;
            LevelRenderState levelState = inv.probe$levelRenderState();
            RenderSystem.isRenderingLevel = true;
            try {
                inv.probe$repositionCamera(camera);
                SubmitNodeStorage storage = inv.probe$submitNodeStorage();
                storage.setUseImprovedTransparency(gr.useImprovedTransparency());
                inv.probe$submitFeatures(levelState, storage, ((GameRendererInvoker) gr).probe$shouldRenderBlockOutline());
                storage.drainPhases(phase -> phase.sortInto((submit, ordered) -> {}));
                long t1 = System.nanoTime();
                submitNanos += t1 - t0;
                inv.probe$compileSections(camera);
                SectionRenderDispatcher dispatcher = inv.probe$sectionRenderDispatcher();
                if (dispatcher != null) {
                    dispatcher.lock();
                    try {
                        dispatcher.uploadTerrainBuffersToGpu();
                    } finally {
                        dispatcher.unlock();
                    }
                }
                long t2 = System.nanoTime();
                compileNanos += t2 - t1;
                lr.sectionOcclusionGraph().update(camera, inv.probe$optionsRenderState().fov, levelState.chunkLoadingRenderState);
                Runnable compiled = levelState.playerCompiledSectionCallback;
                if (compiled != null && lr.isSectionCompiledAndVisible(camera.blockPos, Util.toMillis(inv.probe$optionsRenderState().chunkSectionFadeInTime))) {
                    compiled.run();
                }
                occlusionNanos += System.nanoTime() - t2;
            } finally {
                RenderSystem.isRenderingLevel = false;
            }
        }
        frames++;
        nanos += System.nanoTime() - t0;
    }

    public static String stats() {
        return "{\"frames\":" + frames + ",\"nanos\":" + nanos + ",\"submitNanos\":" + submitNanos + ",\"compileNanos\":" + compileNanos + ",\"occlusionNanos\":" + occlusionNanos + "}";
    }
}
