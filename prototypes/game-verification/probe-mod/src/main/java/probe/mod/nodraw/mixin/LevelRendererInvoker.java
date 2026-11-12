package probe.mod.nodraw.mixin;

import net.minecraft.client.renderer.LevelRenderer;
import net.minecraft.client.renderer.SubmitNodeCollector;
import net.minecraft.client.renderer.SubmitNodeStorage;
import net.minecraft.client.renderer.chunk.SectionRenderDispatcher;
import net.minecraft.client.renderer.state.OptionsRenderState;
import net.minecraft.client.renderer.state.level.CameraRenderState;
import net.minecraft.client.renderer.state.level.LevelRenderState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;
import org.spongepowered.asm.mixin.gen.Invoker;

/** The CPU stages of LevelRenderer.render, callable without the frame graph. */
@Mixin(LevelRenderer.class)
public interface LevelRendererInvoker {
    @Invoker("repositionCamera") void probe$repositionCamera(CameraRenderState camera);

    @Invoker("submitFeatures") void probe$submitFeatures(LevelRenderState state, SubmitNodeCollector out, boolean renderOutline);

    @Invoker("compileSections") void probe$compileSections(CameraRenderState camera);

    @Accessor("submitNodeStorage") SubmitNodeStorage probe$submitNodeStorage();

    @Accessor("levelRenderState") LevelRenderState probe$levelRenderState();

    @Accessor("optionsRenderState") OptionsRenderState probe$optionsRenderState();

    @Accessor("sectionRenderDispatcher") SectionRenderDispatcher probe$sectionRenderDispatcher();
}
