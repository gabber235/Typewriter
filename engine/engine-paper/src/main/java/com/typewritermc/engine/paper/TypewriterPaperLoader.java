package com.typewritermc.engine.paper;

import io.papermc.paper.plugin.loader.PluginClasspathBuilder;
import io.papermc.paper.plugin.loader.PluginLoader;
import io.papermc.paper.plugin.loader.library.impl.MavenLibraryResolver;
import org.eclipse.aether.artifact.DefaultArtifact;
import org.eclipse.aether.graph.Dependency;
import org.eclipse.aether.repository.RemoteRepository;
import org.jetbrains.annotations.NotNull;

/**
 * This is a required class. It must be implemented in Java.
 * Paper cannot load Kotlin classes unless the Kotlin runtime is loaded.
 * This class loads the Kotlin runtime, therefore it must be written in Java.
 */
@SuppressWarnings("UnstableApiUsage") // the entire plugin loader is 'unstable'
public class TypewriterPaperLoader implements PluginLoader {
    @Override
    public void classloader(@NotNull PluginClasspathBuilder classpathBuilder) {
        RemoteRepository central = new RemoteRepository.Builder(
            "central",
            "default",
            "https://repo1.maven.org/maven2/"
        ).build();

        addDependency(classpathBuilder, "org.jetbrains.kotlin:kotlin-stdlib:2.0.21", central);
        addDependency(classpathBuilder, "org.jetbrains.kotlin:kotlin-reflect:2.0.21", central);
        addDependency(classpathBuilder, "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2",
            central);
        addDependency(classpathBuilder, "com.corundumstudio.socketio:netty-socketio:1.7.19",
            central);

        addDependency(classpathBuilder,
            "com.github.shynixn.mccoroutine:mccoroutine-bukkit-api:2.22.0", central);
        addDependency(classpathBuilder,
            "com.github.shynixn.mccoroutine:mccoroutine-bukkit-core:2.22.0", central);

        addDependency(classpathBuilder, "io.ktor:ktor-server-core-jvm:2.3.12", central);
        addDependency(classpathBuilder, "io.ktor:ktor-server-netty-jvm:2.3.12", central);
        addDependency(classpathBuilder, "org.jetbrains.kotlinx:kotlinx-serialization-core:1.8.1",
            central);
        addDependency(classpathBuilder, "org.bstats:bstats-bukkit:3.1.0", central);
    }

    public void addDependency(PluginClasspathBuilder classpathBuilder, String artifact,
                              RemoteRepository... repositories) {
        MavenLibraryResolver resolver = new MavenLibraryResolver();
        resolver.addDependency(new Dependency(new DefaultArtifact(artifact), "provided"));
        for (RemoteRepository repository : repositories) {
            resolver.addRepository(repository);
        }
        classpathBuilder.addLibrary(resolver);
    }
}