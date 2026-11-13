package com.typewritermc.playtest.client;

import io.netty.buffer.ByteBuf;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.resources.Identifier;

/** Client to Paper: the client ran and perceived server tick {@code tick}. The body is the bare int. */
record StepAck(int tick) implements CustomPacketPayload {
    static final Type<StepAck> TYPE = new Type<>(Identifier.parse("playtest:step"));
    static final StreamCodec<ByteBuf, StepAck> CODEC = StreamCodec.of((buf, ack) -> buf.writeInt(ack.tick), buf -> new StepAck(buf.readInt()));

    @Override
    public Type<StepAck> type() {
        return TYPE;
    }
}
