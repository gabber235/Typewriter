package com.typewritermc.playtest.client.mixin;

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

/** The CPU stages of {@code LevelRenderer.render}, callable without its frame graph. */
@Mixin(LevelRenderer.class)
public interface LevelRendererInvoker {
    @Invoker("repositionCamera")
    void playtest$repositionCamera(CameraRenderState camera);

    @Invoker("submitFeatures")
    void playtest$submitFeatures(LevelRenderState state, SubmitNodeCollector output, boolean renderOutline);

    @Invoker("compileSections")
    void playtest$compileSections(CameraRenderState camera);

    @Accessor("submitNodeStorage")
    SubmitNodeStorage playtest$submitNodeStorage();

    @Accessor("levelRenderState")
    LevelRenderState playtest$levelRenderState();

    @Accessor("optionsRenderState")
    OptionsRenderState playtest$optionsRenderState();

    @Accessor("sectionRenderDispatcher")
    SectionRenderDispatcher playtest$sectionRenderDispatcher();
}
