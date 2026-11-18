package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Payload;
import com.typewritermc.playtest.wire.WireException;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.ByteBufUtil;
import io.netty.handler.codec.DecoderException;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.resources.Identifier;
import skirout.harness.v1.wire.StepAck;

/** A {@link StepAck} on the game connection, as Paper reads it; its body is the wire's. */
record StepAckPayload(StepAck ack) implements CustomPacketPayload {
    static final Type<StepAckPayload> TYPE = new Type<>(Identifier.parse(Payload.STEP_CHANNEL));
    static final StreamCodec<ByteBuf, StepAckPayload> CODEC = StreamCodec.of(
            (buf, payload) -> buf.writeBytes(Payload.body(payload.ack)),
            buf -> {
                try {
                    return new StepAckPayload(Payload.stepAck(ByteBufUtil.getBytes(buf, buf.readerIndex(), buf.readableBytes())));
                } catch (WireException broken) {
                    throw new DecoderException(broken);
                } finally {
                    buf.skipBytes(buf.readableBytes());
                }
            });

    @Override
    public Type<StepAckPayload> type() {
        return TYPE;
    }
}
