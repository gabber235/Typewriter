package com.typewritermc.playtest.wire;

import com.typewritermc.playtest.wire.Message.AimAtBlockStep;
import com.typewritermc.playtest.wire.Message.AimAtEntityStep;
import com.typewritermc.playtest.wire.Message.BarrierSeen;
import com.typewritermc.playtest.wire.Message.Block;
import com.typewritermc.playtest.wire.Message.BlockPos;
import com.typewritermc.playtest.wire.Message.ButtonStep;
import com.typewritermc.playtest.wire.Message.Camera;
import com.typewritermc.playtest.wire.Message.ChatLine;
import com.typewritermc.playtest.wire.Message.Claim;
import com.typewritermc.playtest.wire.Message.Claimed;
import com.typewritermc.playtest.wire.Message.Connect;
import com.typewritermc.playtest.wire.Message.Declined;
import com.typewritermc.playtest.wire.Message.End;
import com.typewritermc.playtest.wire.Message.Ended;
import com.typewritermc.playtest.wire.Message.Entity;
import com.typewritermc.playtest.wire.Message.Hello;
import com.typewritermc.playtest.wire.Message.Input;
import com.typewritermc.playtest.wire.Message.InputDone;
import com.typewritermc.playtest.wire.Message.InputStep;
import com.typewritermc.playtest.wire.Message.Item;
import com.typewritermc.playtest.wire.Message.Joined;
import com.typewritermc.playtest.wire.Message.Key;
import com.typewritermc.playtest.wire.Message.KeyStep;
import com.typewritermc.playtest.wire.Message.Lease;
import com.typewritermc.playtest.wire.Message.Perceived;
import com.typewritermc.playtest.wire.Message.Perception;
import com.typewritermc.playtest.wire.Message.Player;
import com.typewritermc.playtest.wire.Message.PointAtSlotStep;
import com.typewritermc.playtest.wire.Message.Probe;
import com.typewritermc.playtest.wire.Message.ProbeAction;
import com.typewritermc.playtest.wire.Message.ProbeCancelBreaking;
import com.typewritermc.playtest.wire.Message.ProbeChat;
import com.typewritermc.playtest.wire.Message.ProbeCommand;
import com.typewritermc.playtest.wire.Message.ProbeDone;
import com.typewritermc.playtest.wire.Message.ProbeFill;
import com.typewritermc.playtest.wire.Message.ProbeGameMode;
import com.typewritermc.playtest.wire.Message.ProbeGive;
import com.typewritermc.playtest.wire.Message.ProbePacketEntity;
import com.typewritermc.playtest.wire.Message.ProbeSelectSlot;
import com.typewritermc.playtest.wire.Message.ProbeSpawn;
import com.typewritermc.playtest.wire.Message.ProbeTeleport;
import com.typewritermc.playtest.wire.Message.Ready;
import com.typewritermc.playtest.wire.Message.Refused;
import com.typewritermc.playtest.wire.Message.Region;
import com.typewritermc.playtest.wire.Message.Release;
import com.typewritermc.playtest.wire.Message.Reset;
import com.typewritermc.playtest.wire.Message.ResetDone;
import com.typewritermc.playtest.wire.Message.Result;
import com.typewritermc.playtest.wire.Message.Role;
import com.typewritermc.playtest.wire.Message.ScrollStep;
import com.typewritermc.playtest.wire.Message.StepUntil;
import com.typewritermc.playtest.wire.Message.Stepping;
import com.typewritermc.playtest.wire.Message.StopStepping;
import com.typewritermc.playtest.wire.Message.Submit;
import com.typewritermc.playtest.wire.Message.Text;
import com.typewritermc.playtest.wire.Message.TypeInChatStep;
import com.typewritermc.playtest.wire.Message.WaitStep;
import com.typewritermc.playtest.wire.Message.WalkToStep;
import com.typewritermc.playtest.wire.Message.Watch;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.EOFException;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * The framing of every connection: one frame is an int length, a type byte and the message's body,
 * where the length counts the type byte and the body. Every part ships from one build, so the type
 * table needs no version. Strings are an int byte count and UTF-8, so a text of any length fits;
 * lists are an int count and their items; an absent string is a false boolean.
 */
public final class Wire {
    /** A perception record is a few hundred bytes; a frame this large is a fault, not a message. */
    public static final int MAX_FRAME = 16 << 20;

    private Wire() {}

    /** Writes one frame and flushes it. */
    public static void write(DataOutputStream out, Message message) throws IOException {
        var bytes = new ByteArrayOutputStream();
        var body = new DataOutputStream(bytes);
        body.writeByte(type(message));
        switch (message) {
            case Hello hello -> {
                body.writeByte(hello.role().ordinal());
                string(body, hello.name());
            }
            case Refused refused -> string(body, refused.reason());
            case Submit submit -> {
                body.writeLong(submit.submission());
                string(body, submit.testId());
                string(body, submit.requirement());
                body.writeInt(submit.players());
            }
            case Declined declined -> {
                body.writeLong(declined.submission());
                string(body, declined.reason());
            }
            case Lease lease -> {
                body.writeLong(lease.submission());
                body.writeInt(lease.players().size());
                for (Player player : lease.players()) {
                    string(body, player.name());
                    uuid(body, player.uuid());
                }
                region(body, lease.region());
            }
            case Result result -> {
                body.writeLong(result.submission());
                body.writeLong(result.durationMillis());
                optional(body, result.failure());
                optional(body, result.firstBroken());
            }
            case End end -> {
                string(body, end.run());
                string(body, end.testRunFile());
            }
            case Probe probe -> {
                body.writeLong(probe.request());
                uuids(body, probe.players());
                action(body, probe.action());
            }
            case Claim claim -> {
                body.writeLong(claim.attempt());
                uuids(body, claim.players());
                region(body, claim.region());
            }
            case Claimed claimed -> {
                body.writeLong(claimed.attempt());
                optional(body, claimed.failure());
            }
            case Release release -> body.writeLong(release.attempt());
            case ProbeDone done -> {
                body.writeLong(done.request());
                body.writeInt(done.tick());
                optional(body, done.failure());
            }
            case Input input -> {
                body.writeLong(input.request());
                uuid(body, input.player());
                body.writeInt(input.steps().size());
                for (InputStep step : input.steps()) step(body, step);
            }
            case InputDone done -> {
                body.writeLong(done.request());
                body.writeInt(done.tick());
                optional(body, done.failure());
            }
            case Watch watch -> {
                uuid(body, watch.player());
                body.writeInt(watch.blocks().size());
                for (BlockPos block : watch.blocks()) blockPos(body, block);
                body.writeInt(watch.entities().size());
                for (UUID entity : watch.entities()) uuid(body, entity);
            }
            case StepUntil step -> {
                uuid(body, step.player());
                body.writeInt(step.tick());
                body.writeInt(step.barrier());
            }
            case StopStepping stop -> uuid(body, stop.player());
            case Connect connect -> {
                string(body, connect.host());
                body.writeInt(connect.port());
            }
            case Perceived perceived -> {
                string(body, perceived.player());
                perception(body, perceived.perception());
            }
            case BarrierSeen seen -> {
                string(body, seen.player());
                body.writeInt(seen.barrier());
            }
            case Ended ended -> {}
            case Joined joined -> {}
            case Stepping stepping -> {}
            case Ready ready -> {}
            case Reset reset -> {}
            case ResetDone done -> {}
        }
        if (bytes.size() > MAX_FRAME) throw new WireException("a " + message.getClass().getSimpleName() + " of " + bytes.size() + " bytes is over the frame limit");
        out.writeInt(bytes.size());
        bytes.writeTo(out);
        out.flush();
    }

    /**
     * Reads one frame. Throws {@link EOFException} when the stream ends between frames and
     * {@link WireException} when a frame is malformed or ends early.
     */
    public static Message read(DataInputStream in) throws IOException {
        int first = in.read();
        if (first < 0) throw new EOFException("the stream ended between frames");
        int length;
        try {
            length = first << 24 | in.readUnsignedByte() << 16 | in.readUnsignedByte() << 8 | in.readUnsignedByte();
        } catch (EOFException cut) {
            throw new WireException("the stream ended inside a frame's length");
        }
        if (length < 1 || length > MAX_FRAME) throw new WireException("a frame of " + length + " bytes is outside 1 to " + MAX_FRAME + " bytes");
        var frame = new byte[length];
        try {
            in.readFully(frame);
        } catch (EOFException cut) {
            throw new WireException("the stream ended inside a frame of " + length + " bytes");
        }
        var body = new DataInputStream(new ByteArrayInputStream(frame));
        Message message;
        try {
            message = message(body.readUnsignedByte(), body);
        } catch (EOFException cut) {
            throw new WireException("a frame of " + length + " bytes ended inside its message");
        }
        int left = body.available();
        if (left > 0) throw new WireException("a " + message.getClass().getSimpleName() + " frame has " + left + " bytes after its message");
        return message;
    }

    private static int type(Message message) {
        return switch (message) {
            case Hello m -> 0;
            case Refused m -> 1;
            case Submit m -> 2;
            case Lease m -> 3;
            case Result m -> 4;
            case End m -> 5;
            case Ended m -> 6;
            case Probe m -> 7;
            case ProbeDone m -> 8;
            case StepUntil m -> 9;
            case StopStepping m -> 10;
            case Stepping m -> 11;
            case Connect m -> 12;
            case Ready m -> 13;
            case Reset m -> 14;
            case ResetDone m -> 15;
            case Perceived m -> 16;
            case BarrierSeen m -> 17;
            case Joined m -> 18;
            case Input m -> 19;
            case InputDone m -> 20;
            case Watch m -> 21;
            case Claim m -> 22;
            case Claimed m -> 23;
            case Release m -> 24;
            case Declined m -> 25;
        };
    }

    private static Message message(int type, DataInputStream in) throws IOException {
        return switch (type) {
            case 0 -> new Hello(role(in.readUnsignedByte()), string(in));
            case 1 -> new Refused(string(in));
            case 2 -> new Submit(in.readLong(), string(in), string(in), in.readInt());
            case 3 -> {
                long submission = in.readLong();
                int count = count(in);
                var players = new ArrayList<Player>(count);
                for (int i = 0; i < count; i++) players.add(new Player(string(in), uuid(in)));
                yield new Lease(submission, List.copyOf(players), region(in));
            }
            case 4 -> new Result(in.readLong(), in.readLong(), optional(in), optional(in));
            case 5 -> new End(string(in), string(in));
            case 6 -> new Ended();
            case 7 -> new Probe(in.readLong(), uuids(in), action(in));
            case 8 -> new ProbeDone(in.readLong(), in.readInt(), optional(in));
            case 9 -> new StepUntil(uuid(in), in.readInt(), in.readInt());
            case 10 -> new StopStepping(uuid(in));
            case 11 -> new Stepping();
            case 12 -> new Connect(string(in), in.readInt());
            case 13 -> new Ready();
            case 14 -> new Reset();
            case 15 -> new ResetDone();
            case 16 -> new Perceived(string(in), perception(in));
            case 17 -> new BarrierSeen(string(in), in.readInt());
            case 18 -> new Joined();
            case 19 -> {
                long request = in.readLong();
                UUID player = uuid(in);
                int count = count(in);
                var steps = new ArrayList<InputStep>(count);
                for (int i = 0; i < count; i++) steps.add(step(in));
                yield new Input(request, player, List.copyOf(steps));
            }
            case 20 -> new InputDone(in.readLong(), in.readInt(), optional(in));
            case 21 -> {
                UUID player = uuid(in);
                int blockCount = count(in);
                var blocks = new ArrayList<BlockPos>(blockCount);
                for (int i = 0; i < blockCount; i++) blocks.add(blockPos(in));
                int entityCount = count(in);
                var entities = new ArrayList<UUID>(entityCount);
                for (int i = 0; i < entityCount; i++) entities.add(uuid(in));
                yield new Watch(player, List.copyOf(blocks), List.copyOf(entities));
            }
            case 22 -> new Claim(in.readLong(), uuids(in), region(in));
            case 23 -> new Claimed(in.readLong(), optional(in));
            case 24 -> new Release(in.readLong());
            case 25 -> new Declined(in.readLong(), string(in));
            default -> throw new WireException("a frame of type " + type + " is no message this build knows");
        };
    }

    private static Role role(int ordinal) throws WireException {
        var roles = Role.values();
        if (ordinal >= roles.length) throw new WireException("role " + ordinal + " is no role this build knows");
        return roles[ordinal];
    }

    /** A count read from a frame cannot exceed the frame's own bytes, so a broken one fails before it allocates. */
    private static int count(DataInputStream in) throws IOException {
        int count = in.readInt();
        if (count < 0 || count > in.available()) throw new WireException("a list of " + count + " items does not fit its frame");
        return count;
    }

    private static void action(DataOutputStream out, ProbeAction action) throws IOException {
        switch (action) {
            case ProbeChat chat -> {
                out.writeByte(0);
                string(out, chat.text());
            }
            case ProbeGameMode mode -> {
                out.writeByte(1);
                string(out, mode.mode());
            }
            case ProbeTeleport teleport -> {
                out.writeByte(2);
                out.writeDouble(teleport.x());
                out.writeDouble(teleport.y());
                out.writeDouble(teleport.z());
                out.writeFloat(teleport.yaw());
                out.writeFloat(teleport.pitch());
            }
            case ProbeGive give -> {
                out.writeByte(3);
                out.writeInt(give.slot());
                string(out, give.item());
                out.writeInt(give.count());
            }
            case ProbeSelectSlot select -> {
                out.writeByte(4);
                out.writeInt(select.slot());
            }
            case ProbeFill fill -> {
                out.writeByte(5);
                blockPos(out, fill.from());
                blockPos(out, fill.to());
                string(out, fill.block());
            }
            case ProbeSpawn spawn -> {
                out.writeByte(6);
                uuid(out, spawn.uuid());
                string(out, spawn.type());
                out.writeDouble(spawn.x());
                out.writeDouble(spawn.y());
                out.writeDouble(spawn.z());
                out.writeFloat(spawn.yaw());
                optional(out, spawn.onHit());
                optional(out, spawn.onClick());
            }
            case ProbePacketEntity entity -> {
                out.writeByte(9);
                uuid(out, entity.uuid());
                string(out, entity.type());
                out.writeDouble(entity.x());
                out.writeDouble(entity.y());
                out.writeDouble(entity.z());
                out.writeFloat(entity.yaw());
                optional(out, entity.onHit());
                optional(out, entity.onClick());
            }
            case ProbeCancelBreaking cancel -> {
                out.writeByte(7);
                blockPos(out, cancel.at());
            }
            case ProbeCommand command -> {
                out.writeByte(8);
                string(out, command.name());
                strings(out, command.suggestions());
                string(out, command.answer());
            }
        }
    }

    private static ProbeAction action(DataInputStream in) throws IOException {
        int kind = in.readUnsignedByte();
        return switch (kind) {
            case 0 -> new ProbeChat(string(in));
            case 1 -> new ProbeGameMode(string(in));
            case 2 -> new ProbeTeleport(in.readDouble(), in.readDouble(), in.readDouble(), in.readFloat(), in.readFloat());
            case 3 -> new ProbeGive(in.readInt(), string(in), in.readInt());
            case 4 -> new ProbeSelectSlot(in.readInt());
            case 5 -> new ProbeFill(blockPos(in), blockPos(in), string(in));
            case 6 -> new ProbeSpawn(uuid(in), string(in), in.readDouble(), in.readDouble(), in.readDouble(), in.readFloat(), optional(in), optional(in));
            case 7 -> new ProbeCancelBreaking(blockPos(in));
            case 8 -> new ProbeCommand(string(in), strings(in), string(in));
            case 9 -> new ProbePacketEntity(uuid(in), string(in), in.readDouble(), in.readDouble(), in.readDouble(), in.readFloat(), optional(in), optional(in));
            default -> throw new WireException("probe action " + kind + " is no action this build knows");
        };
    }

    private static void step(DataOutputStream out, InputStep step) throws IOException {
        switch (step) {
            case KeyStep key -> {
                out.writeByte(0);
                out.writeByte(key.key().ordinal());
                out.writeBoolean(key.down());
            }
            case ButtonStep button -> {
                out.writeByte(1);
                out.writeInt(button.button());
                out.writeBoolean(button.down());
            }
            case ScrollStep scroll -> {
                out.writeByte(2);
                out.writeInt(scroll.amount());
            }
            case TypeInChatStep type -> {
                out.writeByte(3);
                string(out, type.text());
            }
            case WaitStep wait -> {
                out.writeByte(4);
                out.writeInt(wait.ticks());
            }
            case AimAtEntityStep aim -> {
                out.writeByte(5);
                uuid(out, aim.entity());
            }
            case AimAtBlockStep aim -> {
                out.writeByte(6);
                blockPos(out, aim.block());
            }
            case PointAtSlotStep point -> {
                out.writeByte(7);
                out.writeInt(point.slot());
            }
            case WalkToStep walk -> {
                out.writeByte(8);
                out.writeDouble(walk.x());
                out.writeDouble(walk.z());
                out.writeInt(walk.maxTicks());
            }
        }
    }

    private static InputStep step(DataInputStream in) throws IOException {
        int kind = in.readUnsignedByte();
        return switch (kind) {
            case 0 -> new KeyStep(key(in.readUnsignedByte()), in.readBoolean());
            case 1 -> new ButtonStep(in.readInt(), in.readBoolean());
            case 2 -> new ScrollStep(in.readInt());
            case 3 -> new TypeInChatStep(string(in));
            case 4 -> new WaitStep(in.readInt());
            case 5 -> new AimAtEntityStep(uuid(in));
            case 6 -> new AimAtBlockStep(blockPos(in));
            case 7 -> new PointAtSlotStep(in.readInt());
            case 8 -> new WalkToStep(in.readDouble(), in.readDouble(), in.readInt());
            default -> throw new WireException("input step " + kind + " is no step this build knows");
        };
    }

    private static Key key(int ordinal) throws WireException {
        var keys = Key.values();
        if (ordinal >= keys.length) throw new WireException("key " + ordinal + " is no key this build knows");
        return keys[ordinal];
    }

    private static void perception(DataOutputStream out, Perception perception) throws IOException {
        out.writeInt(perception.tick());
        out.writeInt(perception.texts().size());
        for (Text text : perception.texts()) {
            string(out, text.element());
            string(out, text.text());
        }
        out.writeInt(perception.chat().size());
        for (ChatLine line : perception.chat()) {
            out.writeInt(line.tick());
            string(out, line.text());
        }
        Camera camera = perception.camera();
        out.writeBoolean(camera != null);
        if (camera != null) {
            out.writeDouble(camera.x());
            out.writeDouble(camera.y());
            out.writeDouble(camera.z());
            out.writeFloat(camera.yaw());
            out.writeFloat(camera.pitch());
            out.writeFloat(camera.fov());
            out.writeBoolean(camera.scoped());
        }
        out.writeInt(perception.items().size());
        for (Item item : perception.items()) {
            string(out, item.element());
            out.writeInt(item.slot());
            out.writeBoolean(item.selected());
            string(out, item.item());
            out.writeInt(item.count());
        }
        out.writeInt(perception.blocks().size());
        for (Block block : perception.blocks()) {
            blockPos(out, block.at());
            string(out, block.block());
            out.writeBoolean(block.seen());
            out.writeInt(block.changed());
        }
        out.writeInt(perception.entities().size());
        for (Entity entity : perception.entities()) {
            uuid(out, entity.uuid());
            out.writeBoolean(entity.hurt());
            optional(out, entity.name());
        }
    }

    private static Perception perception(DataInputStream in) throws IOException {
        int tick = in.readInt();
        int textCount = count(in);
        var texts = new ArrayList<Text>(textCount);
        for (int i = 0; i < textCount; i++) texts.add(new Text(string(in), string(in)));
        int lineCount = count(in);
        var chat = new ArrayList<ChatLine>(lineCount);
        for (int i = 0; i < lineCount; i++) chat.add(new ChatLine(in.readInt(), string(in)));
        Camera camera = in.readBoolean()
                ? new Camera(in.readDouble(), in.readDouble(), in.readDouble(), in.readFloat(), in.readFloat(), in.readFloat(), in.readBoolean())
                : null;
        int itemCount = count(in);
        var items = new ArrayList<Item>(itemCount);
        for (int i = 0; i < itemCount; i++) items.add(new Item(string(in), in.readInt(), in.readBoolean(), string(in), in.readInt()));
        int blockCount = count(in);
        var blocks = new ArrayList<Block>(blockCount);
        for (int i = 0; i < blockCount; i++) blocks.add(new Block(blockPos(in), string(in), in.readBoolean(), in.readInt()));
        int entityCount = count(in);
        var entities = new ArrayList<Entity>(entityCount);
        for (int i = 0; i < entityCount; i++) entities.add(new Entity(uuid(in), in.readBoolean(), optional(in)));
        return new Perception(tick, List.copyOf(texts), List.copyOf(chat), camera, List.copyOf(items), List.copyOf(blocks), List.copyOf(entities));
    }

    private static void blockPos(DataOutputStream out, BlockPos pos) throws IOException {
        out.writeInt(pos.x());
        out.writeInt(pos.y());
        out.writeInt(pos.z());
    }

    private static BlockPos blockPos(DataInputStream in) throws IOException {
        return new BlockPos(in.readInt(), in.readInt(), in.readInt());
    }

    private static void region(DataOutputStream out, Region region) throws IOException {
        out.writeInt(region.x());
        out.writeInt(region.z());
    }

    private static Region region(DataInputStream in) throws IOException {
        return new Region(in.readInt(), in.readInt());
    }

    private static void uuids(DataOutputStream out, List<UUID> values) throws IOException {
        out.writeInt(values.size());
        for (UUID value : values) uuid(out, value);
    }

    private static List<UUID> uuids(DataInputStream in) throws IOException {
        int count = count(in);
        var values = new ArrayList<UUID>(count);
        for (int i = 0; i < count; i++) values.add(uuid(in));
        return List.copyOf(values);
    }

    private static void strings(DataOutputStream out, List<String> values) throws IOException {
        out.writeInt(values.size());
        for (String value : values) string(out, value);
    }

    private static List<String> strings(DataInputStream in) throws IOException {
        int count = count(in);
        var values = new ArrayList<String>(count);
        for (int i = 0; i < count; i++) values.add(string(in));
        return List.copyOf(values);
    }

    private static void string(DataOutputStream out, String value) throws IOException {
        byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
        out.writeInt(bytes.length);
        out.write(bytes);
    }

    private static String string(DataInputStream in) throws IOException {
        int length = in.readInt();
        if (length < 0 || length > in.available()) throw new WireException("a string of " + length + " bytes does not fit its frame");
        var bytes = new byte[length];
        in.readFully(bytes);
        return new String(bytes, StandardCharsets.UTF_8);
    }

    private static void optional(DataOutputStream out, String value) throws IOException {
        out.writeBoolean(value != null);
        if (value != null) string(out, value);
    }

    private static String optional(DataInputStream in) throws IOException {
        return in.readBoolean() ? string(in) : null;
    }

    private static void uuid(DataOutputStream out, UUID value) throws IOException {
        out.writeLong(value.getMostSignificantBits());
        out.writeLong(value.getLeastSignificantBits());
    }

    private static UUID uuid(DataInputStream in) throws IOException {
        return new UUID(in.readLong(), in.readLong());
    }
}
