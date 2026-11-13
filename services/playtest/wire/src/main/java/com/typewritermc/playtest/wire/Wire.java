package com.typewritermc.playtest.wire;

import com.typewritermc.playtest.wire.Message.BarrierSeen;
import com.typewritermc.playtest.wire.Message.ChatLine;
import com.typewritermc.playtest.wire.Message.Connect;
import com.typewritermc.playtest.wire.Message.End;
import com.typewritermc.playtest.wire.Message.Ended;
import com.typewritermc.playtest.wire.Message.Hello;
import com.typewritermc.playtest.wire.Message.Joined;
import com.typewritermc.playtest.wire.Message.Lease;
import com.typewritermc.playtest.wire.Message.Perceived;
import com.typewritermc.playtest.wire.Message.Perception;
import com.typewritermc.playtest.wire.Message.Player;
import com.typewritermc.playtest.wire.Message.ProbeChat;
import com.typewritermc.playtest.wire.Message.ProbeDone;
import com.typewritermc.playtest.wire.Message.Ready;
import com.typewritermc.playtest.wire.Message.Refused;
import com.typewritermc.playtest.wire.Message.Reset;
import com.typewritermc.playtest.wire.Message.ResetDone;
import com.typewritermc.playtest.wire.Message.Result;
import com.typewritermc.playtest.wire.Message.Role;
import com.typewritermc.playtest.wire.Message.StepUntil;
import com.typewritermc.playtest.wire.Message.Stepping;
import com.typewritermc.playtest.wire.Message.StopStepping;
import com.typewritermc.playtest.wire.Message.Submit;
import com.typewritermc.playtest.wire.Message.Text;
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
            }
            case Lease lease -> {
                body.writeLong(lease.submission());
                body.writeInt(lease.players().size());
                for (Player player : lease.players()) {
                    string(body, player.name());
                    uuid(body, player.uuid());
                }
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
            case ProbeChat probe -> {
                body.writeLong(probe.request());
                uuid(body, probe.player());
                string(body, probe.text());
            }
            case ProbeDone done -> {
                body.writeLong(done.request());
                body.writeInt(done.tick());
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
                body.writeInt(perceived.perception().tick());
                body.writeInt(perceived.perception().texts().size());
                for (Text text : perceived.perception().texts()) {
                    string(body, text.element());
                    string(body, text.text());
                }
                body.writeInt(perceived.perception().chat().size());
                for (ChatLine line : perceived.perception().chat()) {
                    body.writeInt(line.tick());
                    string(body, line.text());
                }
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
            case ProbeChat m -> 7;
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
        };
    }

    private static Message message(int type, DataInputStream in) throws IOException {
        return switch (type) {
            case 0 -> new Hello(role(in.readUnsignedByte()), string(in));
            case 1 -> new Refused(string(in));
            case 2 -> new Submit(in.readLong(), string(in), string(in));
            case 3 -> {
                long submission = in.readLong();
                int count = count(in);
                var players = new ArrayList<Player>(count);
                for (int i = 0; i < count; i++) players.add(new Player(string(in), uuid(in)));
                yield new Lease(submission, List.copyOf(players));
            }
            case 4 -> new Result(in.readLong(), in.readLong(), optional(in), optional(in));
            case 5 -> new End(string(in), string(in));
            case 6 -> new Ended();
            case 7 -> new ProbeChat(in.readLong(), uuid(in), string(in));
            case 8 -> new ProbeDone(in.readLong(), in.readInt());
            case 9 -> new StepUntil(uuid(in), in.readInt(), in.readInt());
            case 10 -> new StopStepping(uuid(in));
            case 11 -> new Stepping();
            case 12 -> new Connect(string(in), in.readInt());
            case 13 -> new Ready();
            case 14 -> new Reset();
            case 15 -> new ResetDone();
            case 16 -> {
                String player = string(in);
                int tick = in.readInt();
                int count = count(in);
                var texts = new ArrayList<Text>(count);
                for (int i = 0; i < count; i++) texts.add(new Text(string(in), string(in)));
                int lines = count(in);
                var chat = new ArrayList<ChatLine>(lines);
                for (int i = 0; i < lines; i++) chat.add(new ChatLine(in.readInt(), string(in)));
                yield new Perceived(player, new Perception(tick, List.copyOf(texts), List.copyOf(chat)));
            }
            case 17 -> new BarrierSeen(string(in), in.readInt());
            case 18 -> new Joined();
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
