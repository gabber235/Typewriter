package probe.agent;

import java.io.File;
import java.lang.foreign.Arena;
import java.lang.foreign.FunctionDescriptor;
import java.lang.foreign.Linker;
import java.lang.foreign.ValueLayout;
import java.lang.invoke.MethodHandle;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * Restore prototype: a CRaC checkpoint at a chosen point of Paper's boot.
 *
 *   boot  Main, after Bootstrap.validate and before anything reads the server folder (Util.startTimerHackThread)
 *   data  Main, after the data packs and level.dat are loaded (MinecraftServer.spin)
 *   done  after Done, asked for by the probe plugin (checkpointNow)
 *
 * A restore runs `java -XX:CRaCRestoreFrom=img probe.agent.Restored dir=/new/server -Dk=v ...`; Restored.main runs
 * after the restore and before the checkpoint call returns, so the folder and properties are in place for the rest
 * of the boot.
 */
public final class Crac {
    static volatile String dir;
    public static volatile long restoredAtMillis;

    private Crac() {}

    public static void at(String point) {
        if (point.equals(System.getProperty("probe.crac.at"))) checkpointNow(point);
    }

    public static void checkpointNow(String point) {
        System.err.println("[crac] checkpoint at " + point + " wall=" + System.currentTimeMillis());
        try {
            Class.forName("jdk.crac.Core").getMethod("checkpointRestore").invoke(null);
        } catch (InvocationTargetException e) {
            Throwable c = e.getCause();
            System.err.println("[crac] checkpoint failed: " + c);
            for (Throwable s : c.getSuppressed()) System.err.println("[crac]   refused: " + s);
            c.printStackTrace();
            if (Boolean.getBoolean("probe.crac.haltOnFail")) Runtime.getRuntime().halt(3);
            return;
        } catch (ReflectiveOperationException e) {
            System.err.println("[crac] no jdk.crac: " + e);
            // Local check of the move without CRaC: continue as if restored into probe.crac.simulateDir.
            if (System.getProperty("probe.crac.simulateDir") == null) return;
            dir = System.getProperty("probe.crac.simulateDir");
        }
        restoredAtMillis = System.currentTimeMillis();
        System.err.println("[crac] restored at " + point + " wall=" + restoredAtMillis);
        afterRestore();
    }

    static void afterRestore() {
        String kernel = kernelCwd();
        System.err.println("[crac] cwd kernel=" + kernel + " user.dir=" + System.getProperty("user.dir") + " nio="
                + Path.of("").toAbsolutePath() + " io=" + new File("").getAbsolutePath() + " target=" + dir
                + " prop.probe.line.port=" + System.getProperty("probe.line.port")
                + " tlr=" + java.util.concurrent.ThreadLocalRandom.current().nextLong() + " uuid=" + java.util.UUID.randomUUID()
                + " random=" + new java.util.Random().nextLong());
        if (dir == null) return;
        try {
            if (!kernel.equals(dir)) chdir(dir);
            System.setProperty("user.dir", dir);
            setField(File.class, "fs", null, "userDir", dir);
            Object nio = FileSystems.getDefault();
            Field d = field(nio.getClass(), "defaultDirectory");
            d.set(nio, dir.getBytes(StandardCharsets.UTF_8));
            System.err.println("[crac] moved to " + kernelCwd() + " nio="
                    + Path.of("").toAbsolutePath() + " io=" + new File("").getAbsolutePath());
        } catch (Throwable t) {
            System.err.println("[crac] move failed: " + t);
            t.printStackTrace();
            Runtime.getRuntime().halt(4);
        }
    }

    static String kernelCwd() {
        try {
            return Files.readSymbolicLink(Path.of("/proc/self/cwd")).toString();
        } catch (Exception e) {
            return "?";
        }
    }

    private static void chdir(String to) throws Throwable {
        Linker l = Linker.nativeLinker();
        MethodHandle h = l.downcallHandle(l.defaultLookup().find("chdir").orElseThrow(),
                FunctionDescriptor.of(ValueLayout.JAVA_INT, ValueLayout.ADDRESS));
        try (Arena a = Arena.ofConfined()) {
            int rc = (int) h.invokeExact(a.allocateFrom(to));
            if (rc != 0) throw new IllegalStateException("chdir " + to + " = " + rc);
        }
    }

    /** owner.staticField.instanceField = value (java.io keeps user.dir in its file system object). */
    private static void setField(Class<?> owner, String staticField, Object unused, String instanceField, Object value) throws Exception {
        Field s;
        try {
            s = field(owner, staticField);
        } catch (NoSuchFieldException e) {
            s = field(owner, staticField.toUpperCase());
        }
        Object fs = s.get(null);
        try {
            field(fs.getClass(), instanceField).set(fs, value);
        } catch (NoSuchFieldException e) {
            System.err.println("[crac] " + fs.getClass().getName() + " has no " + instanceField + " (resolves through nio)");
        }
    }

    private static Field field(Class<?> c, String name) throws NoSuchFieldException {
        for (Class<?> k = c; k != null; k = k.getSuperclass()) {
            try {
                Field f = k.getDeclaredField(name);
                f.setAccessible(true);
                return f;
            } catch (NoSuchFieldException ignored) {
            }
        }
        throw new NoSuchFieldException(c + "." + name);
    }
}
