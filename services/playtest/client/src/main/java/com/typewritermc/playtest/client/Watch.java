package com.typewritermc.playtest.client;

import io.netty.buffer.ByteBuf;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import net.minecraft.core.BlockPos;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.resources.Identifier;

/**
 * Paper to client: from now on every record also carries these blocks and entities, which a probe puts
 * in front of the player. Paper sends it on the player's connection ahead of the packets that show
 * them, so the client handles it first. The body is the block count, each block's x, y and z ints, the
 * entity count, and each entity's two UUID halves. A reset ends every watch.
 */
record Watch(List<BlockPos> blocks, List<UUID> entities) implements CustomPacketPayload {
    static final Type<Watch> TYPE = new Type<>(Identifier.parse("playtest:watch"));
    static final StreamCodec<ByteBuf, Watch> CODEC = StreamCodec.of(
            (buf, watch) -> {
                buf.writeInt(watch.blocks.size());
                for (BlockPos at : watch.blocks) buf.writeInt(at.getX()).writeInt(at.getY()).writeInt(at.getZ());
                buf.writeInt(watch.entities.size());
                for (UUID entity : watch.entities) buf.writeLong(entity.getMostSignificantBits()).writeLong(entity.getLeastSignificantBits());
            },
            buf -> {
                int blockCount = buf.readInt();
                var blocks = new ArrayList<BlockPos>(blockCount);
                for (int i = 0; i < blockCount; i++) blocks.add(new BlockPos(buf.readInt(), buf.readInt(), buf.readInt()));
                int entityCount = buf.readInt();
                var entities = new ArrayList<UUID>(entityCount);
                for (int i = 0; i < entityCount; i++) entities.add(new UUID(buf.readLong(), buf.readLong()));
                return new Watch(List.copyOf(blocks), List.copyOf(entities));
            });

    @Override
    public Type<Watch> type() {
        return TYPE;
    }
}
