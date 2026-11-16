package com.typewritermc.playtest.wire;

import com.typewritermc.playtest.wire.Message.BlockPos;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.EOFException;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * The payloads Paper and the client send each other on the game connection itself, beside the game's
 * own packets, so they keep their order with them. Each names its channel; Paper and the client write
 * and read a body only through its payload here.
 */
public final class Payload {
    private Payload() {}

    /**
     * Paper to client: from now on every record also carries these blocks and entities, which a probe
     * puts in front of the player. Paper sends it ahead of the packets that show them, so the client
     * handles it first. A reset ends every watch.
     */
    public record Watch(List<BlockPos> blocks, List<UUID> entities) {
        public static final String CHANNEL = "playtest:watch";

        public byte[] body() {
            return write(out -> {
                out.writeInt(blocks.size());
                for (BlockPos at : blocks) {
                    out.writeInt(at.x());
                    out.writeInt(at.y());
                    out.writeInt(at.z());
                }
                out.writeInt(entities.size());
                for (UUID entity : entities) {
                    out.writeLong(entity.getMostSignificantBits());
                    out.writeLong(entity.getLeastSignificantBits());
                }
            });
        }

        public static Watch read(byte[] body) throws WireException {
            return Payload.read(body, in -> {
                int blockCount = count(in);
                var blocks = new ArrayList<BlockPos>(blockCount);
                for (int i = 0; i < blockCount; i++) blocks.add(new BlockPos(in.readInt(), in.readInt(), in.readInt()));
                int entityCount = count(in);
                var entities = new ArrayList<UUID>(entityCount);
                for (int i = 0; i < entityCount; i++) entities.add(new UUID(in.readLong(), in.readLong()));
                return new Watch(List.copyOf(blocks), List.copyOf(entities));
            });
        }
    }

    /**
     * Client to Paper: the client ran and perceived server tick {@code tick}; {@code busy} while an input
     * waits to start or runs and needs further ticks, so Paper keeps stepping.
     */
    public record StepAck(int tick, boolean busy) {
        public static final String CHANNEL = "playtest:step";

        public byte[] body() {
            return write(out -> {
                out.writeInt(tick);
                out.writeBoolean(busy);
            });
        }

        public static StepAck read(byte[] body) throws WireException {
            return Payload.read(body, in -> new StepAck(in.readInt(), in.readBoolean()));
        }
    }

    private interface Writer {
        void write(DataOutputStream out) throws IOException;
    }

    private interface Reader<T> {
        T read(DataInputStream in) throws IOException;
    }

    private static byte[] write(Writer writer) {
        var bytes = new ByteArrayOutputStream();
        try (var out = new DataOutputStream(bytes)) {
            writer.write(out);
        } catch (IOException unreachable) {
            throw new UncheckedIOException("an in-memory stream failed", unreachable);
        }
        return bytes.toByteArray();
    }

    /** Reads the whole of {@code body}: a body that ends early or carries more is refused. */
    private static <T> T read(byte[] body, Reader<T> reader) throws WireException {
        var in = new DataInputStream(new ByteArrayInputStream(body));
        try {
            T payload = reader.read(in);
            int left = in.available();
            if (left > 0) throw new WireException("a payload body carries " + left + " bytes beyond its payload");
            return payload;
        } catch (EOFException cut) {
            throw new WireException("a payload body ends inside its payload");
        } catch (WireException refused) {
            throw refused;
        } catch (IOException unreachable) {
            throw new UncheckedIOException("an in-memory stream failed", unreachable);
        }
    }

    private static int count(DataInputStream in) throws IOException {
        int count = in.readInt();
        if (count < 0) throw new WireException("a payload body counts " + count + " entries");
        return count;
    }
}
