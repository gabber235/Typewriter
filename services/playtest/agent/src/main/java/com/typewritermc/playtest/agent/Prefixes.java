package com.typewritermc.playtest.agent;

import java.lang.classfile.ClassFile;
import java.lang.classfile.ClassHierarchyResolver;
import java.lang.classfile.ClassTransform;
import java.lang.classfile.CodeBuilder;
import java.lang.classfile.CodeElement;
import java.lang.classfile.CodeTransform;
import java.lang.classfile.Label;
import java.lang.classfile.MethodModel;
import java.lang.classfile.MethodTransform;
import java.lang.constant.ClassDesc;
import java.lang.constant.ConstantDescs;
import java.lang.constant.MethodTypeDesc;
import java.lang.instrument.ClassFileTransformer;
import java.lang.instrument.Instrumentation;
import java.security.ProtectionDomain;
import java.util.Map;
import java.util.function.Consumer;

/**
 * Makes stock Paper's main loop wait for a {@link Step} permit instead of a deadline. Each prefix does
 * nothing until {@link Step#on} is true:
 *
 * <ul>
 *   <li>{@code MinecraftServer.recordTaskExecutionTimeWhileWaiting}, Paper's wait between ticks: wait
 *       for a permit, handling tasks meanwhile.
 *   <li>{@code MinecraftServer.waitForTasks}: one idle pass of {@link Step#idle}.
 *   <li>{@code MinecraftServer.haveTime}: between stepped ticks there is always time.
 *   <li>{@code ServerLevel.currentLagCompensationTick}: Paper's block break clock counts ticks, not
 *       50 ms of wall time.
 * </ul>
 *
 * Every prefix it applies lands in {@link Step#applied}, so the plugin can refuse a Paper whose methods
 * moved.
 */
public final class Prefixes {
    private static final ClassDesc STEP = ClassDesc.of("com.typewritermc.playtest.agent.Step");
    private static final ClassDesc SERVER = ClassDesc.of("net.minecraft.server.MinecraftServer");
    private static final MethodTypeDesc BOOLEAN = MethodTypeDesc.of(ConstantDescs.CD_boolean);
    private static final MethodTypeDesc VOID = MethodTypeDesc.of(ConstantDescs.CD_void);

    private Prefixes() {}

    /** Installs the prefixes; {@link StepAgent} calls it once this class loads from the bootstrap path. */
    public static void install(Instrumentation instrumentation) {
        instrumentation.addTransformer(new ClassFileTransformer() {
            @Override
            public byte[] transform(ClassLoader loader, String name, Class<?> redefined, ProtectionDomain domain, byte[] bytes) {
                try {
                    return switch (name) {
                        case "net/minecraft/server/MinecraftServer" -> rewrite(loader, bytes, "MinecraftServer", server());
                        case "net/minecraft/server/level/ServerLevel" -> rewrite(loader, bytes, "ServerLevel", level());
                        default -> null;
                    };
                } catch (RuntimeException | LinkageError failure) {
                    // A transformer's exception is dropped by the JVM; the missing prefix fails the plugin's boot check.
                    failure.printStackTrace();
                    return null;
                }
            }
        });
    }

    private static Map<String, Consumer<CodeBuilder>> server() {
        return Map.of(
                "recordTaskExecutionTimeWhileWaiting()V", code -> {
                    // waitingForNextTick = true; while (!Step.take()) { if (!pollTask()) Step.idle(); } waitingForNextTick = false; return;
                    Label loop = code.newLabel(), polled = code.newLabel(), done = code.newLabel();
                    code.aload(0).iconst_1().putfield(SERVER, "waitingForNextTick", ConstantDescs.CD_boolean);
                    code.labelBinding(loop);
                    code.invokestatic(STEP, "take", BOOLEAN).ifne(done);
                    code.aload(0).invokevirtual(SERVER, "pollTask", BOOLEAN).ifne(polled);
                    code.invokestatic(STEP, "idle", VOID);
                    code.labelBinding(polled);
                    code.goto_(loop);
                    code.labelBinding(done);
                    code.aload(0).iconst_0().putfield(SERVER, "waitingForNextTick", ConstantDescs.CD_boolean);
                    code.return_();
                },
                "waitForTasks()V", code -> code.invokestatic(STEP, "idle", VOID).return_(),
                "haveTime()Z", code -> code.invokestatic(STEP, "haveTime", BOOLEAN).ireturn());
    }

    private static Map<String, Consumer<CodeBuilder>> level() {
        return Map.of("currentLagCompensationTick()J", code ->
                code.getstatic(SERVER, "currentTick", ConstantDescs.CD_int).i2l().lreturn());
    }

    /** One transform over every prefixed method of a class: chained per method transforms applied only the last. */
    private static byte[] rewrite(ClassLoader loader, byte[] bytes, String owner, Map<String, Consumer<CodeBuilder>> prefixes) {
        var file = ClassFile.of(ClassFile.ClassHierarchyResolverOption.of(
                ClassHierarchyResolver.ofResourceParsing(loader).orElse(ClassHierarchyResolver.defaultResolver())));
        ClassTransform transform = (builder, element) -> {
            if (element instanceof MethodModel method && method.code().isPresent()) {
                String name = method.methodName().stringValue();
                Consumer<CodeBuilder> prefix = prefixes.get(name + method.methodType().stringValue());
                if (prefix != null) {
                    builder.transformMethod(method, MethodTransform.transformingCode(guarded(prefix)));
                    Step.applied.add(owner + "." + name);
                    return;
                }
            }
            builder.with(element);
        };
        return file.transformClass(file.parse(bytes), transform);
    }

    /** {@code if (Step.on) { prefix }} ahead of the method's own code. */
    private static CodeTransform guarded(Consumer<CodeBuilder> prefix) {
        return new CodeTransform() {
            @Override
            public void atStart(CodeBuilder code) {
                Label original = code.newLabel();
                code.getstatic(STEP, "on", ConstantDescs.CD_boolean).ifeq(original);
                prefix.accept(code);
                code.labelBinding(original);
            }

            @Override
            public void accept(CodeBuilder code, CodeElement element) {
                code.with(element);
            }
        };
    }
}
