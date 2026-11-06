package probe.cov;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.stream.Stream;
import org.jacoco.core.analysis.Analyzer;
import org.jacoco.core.analysis.CoverageBuilder;
import org.jacoco.core.analysis.IClassCoverage;
import org.jacoco.core.data.ExecutionData;
import org.jacoco.core.data.ExecutionDataReader;
import org.jacoco.core.data.ExecutionDataStore;
import org.jacoco.core.data.SessionInfoStore;
import org.jacoco.core.internal.data.CRC64;

/**
 * Spike I reader. Args: classDumpDir execDir out.jsonl. Every `<id>.exec` in execDir is one
 * requirement's dump. Writes one JSON line per requirement with the lines that ran (any covered
 * instruction, the same rule as xtask's JaCoCo reader), keyed by package/SourceFile.java, and a
 * first line with every line that has instructions.
 */
public final class Lines {
    record Klass(long id, String name, byte[] bytes) {}

    public static void main(String[] args) throws IOException {
        long t0 = System.nanoTime();
        List<Klass> classes = new ArrayList<>();
        try (Stream<Path> walk = Files.walk(Path.of(args[0]))) {
            for (Path p : walk.filter(f -> f.toString().endsWith(".class")).toList()) {
                byte[] b = Files.readAllBytes(p);
                classes.add(new Klass(CRC64.classId(b), p.toString(), b));
            }
        }
        List<Path> execs;
        try (Stream<Path> list = Files.list(Path.of(args[1]))) {
            execs = list.filter(f -> f.toString().endsWith(".exec")).sorted().toList();
        }
        long t1 = System.nanoTime();
        try (PrintWriter out = new PrintWriter(Files.newBufferedWriter(Path.of(args[2])))) {
            out.println("{\"lines\":" + json(analyze(classes, new ExecutionDataStore(), false)) + "}");
            long analyzeNanos = 0;
            for (Path exec : execs) {
                long a = System.nanoTime();
                ExecutionDataStore store = new ExecutionDataStore();
                ExecutionDataReader reader = new ExecutionDataReader(new ByteArrayInputStream(Files.readAllBytes(exec)));
                reader.setExecutionDataVisitor(store);
                reader.setSessionInfoVisitor(new SessionInfoStore());
                reader.read();
                Map<String, TreeSet<Integer>> covered = analyze(classes, store, true);
                long us = (System.nanoTime() - a) / 1000;
                analyzeNanos += System.nanoTime() - a;
                String id = exec.getFileName().toString().replace(".exec", "");
                out.println("{\"id\":\"" + id + "\",\"us\":" + us + ",\"files\":" + json(covered) + "}");
            }
            out.println("{\"summary\":true,\"classes\":" + classes.size() + ",\"execs\":" + execs.size() + ",\"loadMs\":" + (t1 - t0) / 1e6
                    + ",\"analyzeMs\":" + analyzeNanos / 1e6 + ",\"totalMs\":" + (System.nanoTime() - t0) / 1e6 + "}");
        }
    }

    /** Only classes with a probe that ran are analysed when hitOnly, which is what makes a dump cheap to read. */
    private static Map<String, TreeSet<Integer>> analyze(List<Klass> classes, ExecutionDataStore store, boolean hitOnly) throws IOException {
        CoverageBuilder builder = new CoverageBuilder();
        Analyzer analyzer = new Analyzer(store, builder);
        for (Klass k : classes) {
            if (hitOnly) {
                ExecutionData d = store.get(k.id());
                if (d == null || !d.hasHits()) continue;
            }
            analyzer.analyzeClass(k.bytes(), k.name());
        }
        Map<String, TreeSet<Integer>> out = new TreeMap<>();
        for (IClassCoverage c : builder.getClasses()) {
            if (c.getSourceFileName() == null) continue;
            String key = c.getPackageName() + "/" + c.getSourceFileName();
            for (int line = c.getFirstLine(); line > 0 && line <= c.getLastLine(); line++) {
                var counter = c.getLine(line).getInstructionCounter();
                boolean keep = hitOnly ? counter.getCoveredCount() > 0 : counter.getTotalCount() > 0;
                if (keep) out.computeIfAbsent(key, x -> new TreeSet<>()).add(line);
            }
        }
        return out;
    }

    private static String json(Map<String, TreeSet<Integer>> m) {
        StringBuilder b = new StringBuilder("{");
        boolean first = true;
        for (var e : m.entrySet()) {
            if (!first) b.append(',');
            first = false;
            b.append('"').append(e.getKey()).append("\":").append(e.getValue().toString().replace(" ", ""));
        }
        return b.append('}').toString();
    }
}
