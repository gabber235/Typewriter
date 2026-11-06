package probe.agent;

import java.lang.classfile.ClassFile;
import java.lang.classfile.ClassHierarchyResolver;
import java.lang.classfile.ClassModel;
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
 * Spike N: four method prefixes, each a no-op unless the runner switched stepping on.
 *
 *   MinecraftServer.lambda$waitUntilNextTick$0  the next tick starts when a permit is taken, not at a deadline
 *   MinecraftServer.waitForTasks               idle: run the stepper hook, park until a permit or 50 us
 *   MinecraftServer.haveTime                   between ticks there is always time (chunk and task polling)
 *   ServerLevel.currentLagCompensationTick     Paper's block break clock counts server ticks, not 50 ms of wall clock
 */
public final class Agent {
    private static final ClassDesc STEP = ClassDesc.of("probe.agent.Step");
    private static final ClassDesc SERVER = ClassDesc.of("net.minecraft.server.MinecraftServer");

    private Agent() {}

    public static void premain(String args, Instrumentation inst) {
        if (args != null && args.contains("lag=tick")) Step.tickClock = true;
        inst.addTransformer(new ClassFileTransformer() {
            @Override
            public byte[] transform(ClassLoader loader, String name, Class<?> c, ProtectionDomain pd, byte[] bytes) {
                try {
                    return switch (name) {
                        case "net/minecraft/server/MinecraftServer" -> rewrite(loader, bytes, server());
                        case "net/minecraft/server/level/ServerLevel" -> rewrite(loader, bytes, level());
                        default -> null;
                    };
                } catch (Throwable t) {
                    t.printStackTrace();
                    return null;
                }
            }
        });
    }

    private static ClassTransform server() {
        // Paper's main loop waits here (Moonrise), not in waitUntilNextTick:
        //   waitingForNextTick = true; while (!Step.take()) { if (!pollTask()) Step.idle(); } waitingForNextTick = false;
        return prefixes(Map.of(
                "recordTaskExecutionTimeWhileWaiting()V", b -> guarded(b, "on", cb -> {
                    Label loop = cb.newLabel(), done = cb.newLabel(), polled = cb.newLabel();
                    cb.aload(0);
                    cb.iconst_1();
                    cb.putfield(SERVER, "waitingForNextTick", ConstantDescs.CD_boolean);
                    cb.labelBinding(loop);
                    cb.invokestatic(STEP, "take", MethodTypeDesc.of(ConstantDescs.CD_boolean));
                    cb.ifne(done);
                    cb.aload(0);
                    cb.invokevirtual(SERVER, "pollTask", MethodTypeDesc.of(ConstantDescs.CD_boolean));
                    cb.ifne(polled);
                    cb.invokestatic(STEP, "idle", MethodTypeDesc.of(ConstantDescs.CD_void));
                    cb.labelBinding(polled);
                    cb.goto_(loop);
                    cb.labelBinding(done);
                    cb.aload(0);
                    cb.iconst_0();
                    cb.putfield(SERVER, "waitingForNextTick", ConstantDescs.CD_boolean);
                    cb.return_();
                }),
                "lambda$waitUntilNextTick$0()Z", b -> guarded(b, "on", cb -> {
                    cb.invokestatic(STEP, "take", MethodTypeDesc.of(ConstantDescs.CD_boolean));
                    cb.ireturn();
                }),
                "waitForTasks()V", b -> guarded(b, "on", cb -> {
                    cb.invokestatic(STEP, "idle", MethodTypeDesc.of(ConstantDescs.CD_void));
                    cb.return_();
                }),
                "haveTime()Z", b -> guarded(b, "on", cb -> {
                    cb.invokestatic(STEP, "haveTime", MethodTypeDesc.of(ConstantDescs.CD_boolean));
                    cb.ireturn();
                })));
    }

    private static ClassTransform level() {
        return prefixes(Map.of("currentLagCompensationTick()J", b -> guarded(b, "tickClock", cb -> {
            cb.getstatic(SERVER, "currentTick", ConstantDescs.CD_int);
            cb.i2l();
            cb.lreturn();
        })));
    }

    private static void guarded(CodeBuilder b, String flag, Consumer<CodeBuilder> body) {
        Label skip = b.newLabel();
        b.getstatic(STEP, flag, ConstantDescs.CD_boolean);
        b.ifeq(skip);
        body.accept(b);
        b.labelBinding(skip);
    }

    /** One transform for all prefixes of a class (chained transformingMethods applied only the last one). */
    private static ClassTransform prefixes(Map<String, Consumer<CodeBuilder>> byMethod) {
        return (cb, e) -> {
            if (e instanceof MethodModel m && m.code().isPresent()) {
                String key = m.methodName().stringValue() + m.methodType().stringValue();
                Consumer<CodeBuilder> emit = byMethod.get(key);
                if (emit != null) {
                    cb.transformMethod(m, MethodTransform.transformingCode(prefixCode(key, emit)));
                    return;
                }
            }
            cb.with(e);
        };
    }

    private static CodeTransform prefixCode(String method, Consumer<CodeBuilder> emit) {
        CodeTransform code = new CodeTransform() {
            @Override
            public void accept(CodeBuilder b, CodeElement e) {
                b.with(e);
            }

            @Override
            public void atStart(CodeBuilder b) {
                emit.accept(b);
                System.err.println("[step-agent] prefixed " + method);
            }
        };
        return code;
    }

    private static byte[] rewrite(ClassLoader loader, byte[] bytes, ClassTransform t) {
        ClassFile cf = ClassFile.of(ClassFile.ClassHierarchyResolverOption.of(
                ClassHierarchyResolver.ofResourceParsing(loader).orElse(ClassHierarchyResolver.defaultResolver())));
        ClassModel model = cf.parse(bytes);
        return cf.transformClass(model, t);
    }
}
