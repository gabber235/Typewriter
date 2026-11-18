package com.typewritermc.playtest.client;

import com.mojang.blaze3d.pipeline.RenderTarget;
import com.mojang.blaze3d.systems.RenderSystem;
import com.mojang.renderpearl.api.buffers.GpuBuffer;
import com.mojang.renderpearl.api.commands.GpuFence;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.List;

/**
 * Reads the colour of every pixel a draw left in a render target back from the GPU. Each copy is
 * queued right after its draw, so the next draw into the same target can follow; {@link #read} then
 * waits for all of them at once: a check that asks for pixels holds its tick until it has them.
 * Render thread only.
 */
final class Grab {
    private Grab() {}

    /** A copy of a target's pixels on its way to {@code buffer}. */
    record Copy(GpuBuffer buffer, int width, int height) {}

    /** Queues a copy of what {@code target} holds now. */
    static Copy copy(RenderTarget target) {
        var texture = target.getColorTexture();
        if (texture == null) throw new IllegalStateException("the render target holds no colour texture yet");
        var device = RenderSystem.getDevice();
        var buffer = device.createBuffer(
                () -> "playtest grab", GpuBuffer.USAGE_MAP_READ | GpuBuffer.USAGE_COPY_DST, (long) target.width * target.height * texture.getFormat().blockSize());
        device.createCommandEncoder().copyTextureToBuffer(texture, buffer, 0L, () -> {}, 0);
        return new Copy(buffer, target.width, target.height);
    }

    /** Waits until every copy reached its buffer and reads them, in order. */
    static List<Pixels> read(List<Copy> copies) {
        var encoder = RenderSystem.getDevice().createCommandEncoder();
        try (GpuFence copied = encoder.createFence()) {
            encoder.submit();
            copied.awaitCompletion(GpuFence.NO_TIMEOUT);
        }
        var read = new ArrayList<Pixels>(copies.size());
        for (Copy copy : copies) {
            GpuBuffer buffer = copy.buffer();
            try (buffer; var view = buffer.map(true, false)) {
                var rgba = new int[copy.width() * copy.height()];
                view.data().duplicate().order(ByteOrder.LITTLE_ENDIAN).asIntBuffer().get(rgba);
                read.add(new Pixels(copy.width(), copy.height(), rgba));
            }
        }
        return read;
    }
}
