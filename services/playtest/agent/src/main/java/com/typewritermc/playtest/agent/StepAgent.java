package com.typewritermc.playtest.agent;

import java.lang.instrument.Instrumentation;

/**
 * The step agent's entry point. Paper runs from its class path, where the JVM also puts the agent's
 * jar, so the prefixed server classes and the plugin share the one copy of {@link Step} the application
 * class loader holds, and an ahead of time cache serves the server's classes as well.
 */
public final class StepAgent {
    private StepAgent() {}

    public static void premain(String arguments, Instrumentation instrumentation) {
        Prefixes.install(instrumentation);
    }
}
