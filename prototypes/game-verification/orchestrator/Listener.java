import java.io.BufferedInputStream;
import java.io.BufferedWriter;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.EOFException;
import java.io.IOException;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Stream prototype, the test process end: a separate JVM that accepts the client's stream, stamps each
 * frame's arrival with System.nanoTime (one monotonic clock for every process on the machine), decodes it,
 * prices what a diff against the previous record would have cost, and writes one JSON line per frame.
 *
 *   java Listener.java <port file> <out.jsonl>
 */
public class Listener {
    static final List<String> SECTIONS = List.of("runs", "chat", "suggestions", "ents", "blocks", "facts");

    public static void main(String[] a) throws Exception {
        try (ServerSocket server = new ServerSocket(0, 4, InetAddress.getLoopbackAddress());
             BufferedWriter out = Files.newBufferedWriter(Path.of(a[1]), StandardCharsets.UTF_8)) {
            Files.writeString(Path.of(a[0]), Integer.toString(server.getLocalPort()));
            while (true) {
                try (Socket s = server.accept()) {
                    s.setTcpNoDelay(true);
                    serve(new DataInputStream(new BufferedInputStream(s.getInputStream(), 1 << 16)), out);
                }
            }
        }
    }

    static void serve(DataInputStream in, BufferedWriter out) throws IOException {
        List<List<byte[]>> prev = null;
        while (true) {
            int len;
            try {
                len = in.readInt();
            } catch (EOFException e) {
                out.flush();
                return;
            }
            byte[] f = new byte[len];
            in.readFully(f);
            long recv = System.nanoTime();
            byte type = f[0];
            DataInputStream b = new DataInputStream(new ByteArrayInputStream(f, 1, len - 1));
            StringBuilder j = new StringBuilder(256);
            j.append("{\"type\":").append(type).append(",\"recv\":").append(recv).append(",\"wire\":").append(4 + len);
            if (type == 1) {
                j.append(",\"seq\":").append(b.readLong()).append(",\"tick\":").append(b.readInt()).append(",\"clientTick\":").append(b.readLong())
                    .append(",\"frame\":").append(b.readLong()).append(",\"tickEnd\":").append(b.readLong()).append(",\"frameStart\":").append(b.readLong())
                    .append(",\"frameEnd\":").append(b.readLong()).append(",\"build\":").append(b.readLong()).append(",\"a4\":").append(b.readLong())
                    .append(",\"enq\":").append(b.readLong());
                int headerLen = 8 + 4 + 8 * 8;
                byte[] content = Arrays.copyOfRange(f, 1 + headerLen, len);
                List<List<byte[]>> secs = new ArrayList<>();
                String decoded = decode(content, secs);
                j.append(",\"content\":").append(content.length).append(",\"diff\":").append(prev == null ? -1 : diffCost(prev, secs));
                j.append(",\"changed\":").append(changed(prev, secs)).append(',').append(decoded);
                prev = secs;
            } else if (type == 2) {
                j.append(",\"id\":").append(b.readInt()).append(",\"handled\":").append(b.readLong()).append(",\"echo\":").append(b.readLong())
                    .append(",\"afterSeq\":").append(b.readLong());
            } else if (type == 3) {
                j.append(",\"name\":").append(q(b.readUTF())).append(",\"at\":").append(b.readLong());
                prev = null;
            }
            out.write(j.append("}\n").toString());
            if (in.available() == 0) out.flush();
        }
    }

    /** Diff wire cost: 5 framing + 8 tick and frame + 1 bitmap; per changed section 4 counts, 2 per removed index, 2 plus the bytes per added item. */
    static int diffCost(List<List<byte[]>> a, List<List<byte[]>> b) {
        int cost = 5 + 8 + 1;
        for (int s = 0; s < a.size(); s++) {
            List<byte[]> x = a.get(s), y = b.get(s);
            Map<String, Integer> have = new HashMap<>();
            for (byte[] v : x) have.merge(Arrays.toString(v), 1, Integer::sum);
            int added = 0, addedBytes = 0;
            for (byte[] v : y) {
                String k = Arrays.toString(v);
                Integer n = have.get(k);
                if (n != null && n > 0) have.put(k, n - 1);
                else {
                    added++;
                    addedBytes += v.length;
                }
            }
            int removed = 0;
            for (int n : have.values()) removed += n;
            if (added == 0 && removed == 0 && x.size() == y.size()) continue;
            cost += 4 + 2 * removed + 2 * added + addedBytes;
        }
        return cost;
    }

    static String changed(List<List<byte[]>> a, List<List<byte[]>> b) {
        StringBuilder s = new StringBuilder("[");
        boolean first = true;
        for (int i = 0; i < b.size(); i++) {
            boolean same = a != null && a.get(i).size() == b.get(i).size();
            if (same) for (int k = 0; k < b.get(i).size(); k++) if (!Arrays.equals(a.get(i).get(k), b.get(i).get(k))) same = false;
            if (!same) {
                if (!first) s.append(',');
                s.append(q(SECTIONS.get(i)));
                first = false;
            }
        }
        return s.append(']').toString();
    }

    /** Decodes content into JSON fields and fills secs with each section's items as encoded bytes. */
    static String decode(byte[] c, List<List<byte[]>> secs) throws IOException {
        Reader r = new Reader(c);
        StringBuilder j = new StringBuilder();
        List<byte[]> runs = new ArrayList<>();
        j.append("\"runs\":[");
        int n = r.in.readShort();
        for (int i = 0; i < n; i++) {
            int p = r.pos();
            String tag = r.in.readUTF(), text = r.in.readUTF();
            runs.add(r.since(p));
            if (i > 0) j.append(',');
            j.append('[').append(q(tag)).append(',').append(q(text)).append(']');
        }
        secs.add(runs);
        List<byte[]> chat = new ArrayList<>();
        n = r.in.readShort();
        String last = null;
        for (int i = 0; i < n; i++) {
            int p = r.pos();
            last = r.in.readUTF();
            chat.add(r.since(p));
        }
        secs.add(chat);
        j.append("],\"chat\":").append(n).append(",\"chatLast\":").append(last == null ? "null" : q(last));
        List<byte[]> sug = new ArrayList<>();
        j.append(",\"suggestions\":[");
        n = r.in.readShort();
        for (int i = 0; i < n; i++) {
            int p = r.pos();
            String t = r.in.readUTF();
            sug.add(r.since(p));
            if (i > 0) j.append(',');
            j.append(q(t));
        }
        secs.add(sug);
        List<byte[]> ents = new ArrayList<>();
        j.append("],\"ents\":[");
        n = r.in.readShort();
        for (int i = 0; i < n; i++) {
            int p = r.pos();
            int id = r.in.readInt();
            boolean drawn = r.in.readBoolean();
            int px = r.in.readInt();
            ents.add(r.since(p));
            if (i > 0) j.append(',');
            j.append('[').append(id).append(',').append(drawn).append(',').append(px).append(']');
        }
        secs.add(ents);
        List<byte[]> blocks = new ArrayList<>();
        j.append("],\"blocks\":[");
        n = r.in.readShort();
        for (int i = 0; i < n; i++) {
            int p = r.pos();
            int x = r.in.readInt(), y = r.in.readInt(), z = r.in.readInt();
            String st = r.in.readUTF();
            boolean vis = r.in.readBoolean();
            blocks.add(r.since(p));
            if (i > 0) j.append(',');
            j.append("[\"").append(x).append(':').append(y).append(':').append(z).append("\",").append(q(st)).append(',').append(vis).append(']');
        }
        secs.add(blocks);
        int p = r.pos();
        String screen = r.in.readUTF();
        boolean hud = r.in.readBoolean();
        int x = r.in.readInt(), y = r.in.readInt(), z = r.in.readInt();
        j.append("],\"facts\":{\"screen\":").append(q(screen)).append(",\"hudHidden\":").append(hud).append(",\"at\":[").append(x).append(',').append(y).append(',').append(z).append("],\"boss\":[");
        n = r.in.readShort();
        for (int i = 0; i < n; i++) {
            if (i > 0) j.append(',');
            j.append('[').append(q(r.in.readUTF())).append(',').append(r.in.readByte()).append(']');
        }
        j.append("],\"health\":").append(r.in.readFloat());
        if (r.in.available() > 0) j.append(",\"vx\":").append(r.in.readUTF());
        j.append('}');
        secs.add(List.of(r.since(p)));
        return j.toString();
    }

    static final class Reader {
        final byte[] c;
        final Counting cin;
        final DataInputStream in;

        Reader(byte[] c) {
            this.c = c;
            this.cin = new Counting(c);
            this.in = new DataInputStream(cin);
        }

        int pos() {
            return cin.position();
        }

        byte[] since(int p) {
            return Arrays.copyOfRange(c, p, pos());
        }
    }

    static final class Counting extends ByteArrayInputStream {
        Counting(byte[] b) {
            super(b);
        }

        int position() {
            return pos;
        }
    }

    static String q(String s) {
        StringBuilder b = new StringBuilder("\"");
        for (char ch : s.toCharArray()) {
            switch (ch) {
                case '"' -> b.append("\\\"");
                case '\\' -> b.append("\\\\");
                case '\n' -> b.append("\\n");
                default -> {
                    if (ch < 32) b.append(String.format("\\u%04x", (int) ch));
                    else b.append(ch);
                }
            }
        }
        return b.append('"').toString();
    }
}
