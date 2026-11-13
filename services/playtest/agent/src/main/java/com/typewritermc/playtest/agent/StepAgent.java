package com.typewritermc.playtest.agent;

import java.io.IOException;
import java.lang.instrument.Instrumentation;
import java.lang.reflect.InvocationTargetException;
import java.net.URI;
import java.nio.file.Path;
import java.util.jar.JarFile;

/**
 * The step agent's entry point. Paperclip loads the server in a class loader that skips the application
 * class path, so the prefixes and the plugin find {@link Step} only on the bootstrap path. This class
 * puts its own jar there before anything loads {@link Step}, then starts {@link Prefixes} from that
 * path, so every part of the agent and the server shares one copy of each class.
 */
public final class StepAgent {
    private StepAgent() {}

    public static void premain(String arguments, Instrumentation instrumentation) throws IOException, ReflectiveOperationException {
        var jar = Path.of(URI.create(StepAgent.class.getProtectionDomain().getCodeSource().getLocation().toString()));
        instrumentation.appendToBootstrapClassLoaderSearch(new JarFile(jar.toFile()));
        try {
            Class.forName("com.typewritermc.playtest.agent.Prefixes", true, null).getMethod("install", Instrumentation.class).invoke(null, instrumentation);
        } catch (InvocationTargetException failed) {
            throw new IllegalStateException("the step agent could not install its prefixes", failed.getCause());
        }
    }
}
