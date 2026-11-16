package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Payload.Watch;
import com.typewritermc.playtest.wire.WireException;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.ByteBufUtil;
import io.netty.handler.codec.DecoderException;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.resources.Identifier;

/** A {@link Watch} on the game connection, as Paper sends it; its body is the wire's. */
record WatchPayload(Watch watch) implements CustomPacketPayload {
    static final Type<WatchPayload> TYPE = new Type<>(Identifier.parse(Watch.CHANNEL));
    static final StreamCodec<ByteBuf, WatchPayload> CODEC = StreamCodec.of(
            (buf, payload) -> buf.writeBytes(payload.watch.body()),
            buf -> {
                try {
                    return new WatchPayload(Watch.read(ByteBufUtil.getBytes(buf, buf.readerIndex(), buf.readableBytes())));
                } catch (WireException broken) {
                    throw new DecoderException(broken);
                } finally {
                    buf.skipBytes(buf.readableBytes());
                }
            });

    @Override
    public Type<WatchPayload> type() {
        return TYPE;
    }
}
