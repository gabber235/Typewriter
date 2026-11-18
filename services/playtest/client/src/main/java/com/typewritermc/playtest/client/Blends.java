package com.typewritermc.playtest.client;

import com.typewritermc.playtest.client.mixin.AtmosphericFogEnvironmentAccessor;
import com.typewritermc.playtest.client.mixin.CameraAccessor;
import com.typewritermc.playtest.client.mixin.FogRendererAccessor;
import net.minecraft.client.Camera;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.fog.environment.AtmosphericFogEnvironment;
import net.minecraft.client.renderer.fog.environment.FogEnvironment;

/**
 * What the client eases from tick to tick toward the world and the player, so that a frame would still
 * show what an earlier attempt left: the camera's environment probe (the sky, the fog colour and the
 * like, blended toward the camera's place and time), the fog rain thickens, and the field of view (a
 * spyglass narrows it). Paper's wipe resets the rain and thunder levels themselves; a new attempt starts
 * these from the world it finds, as a client that just joined does. Render thread only.
 */
final class Blends {
    private Blends() {}

    /** A new attempt: every blend starts afresh from what the next frame finds. */
    static void reset(Minecraft mc) {
        Camera camera = mc.gameRenderer.mainCamera();
        camera.attributeProbe().reset();
        // The factor of a player who looks through nothing; the client options keep flying and speed from changing it.
        ((CameraAccessor) camera).playtest$setFovModifier(1.0F);
        ((CameraAccessor) camera).playtest$setOldFovModifier(1.0F);
        for (FogEnvironment environment : FogRendererAccessor.playtest$environments()) {
            if (environment instanceof AtmosphericFogEnvironment) {
                ((AtmosphericFogEnvironmentAccessor) environment).playtest$setRainFogMultiplier(0.0F);
            }
        }
    }
}
