package com.typewritermc.loader.runtime

import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedRuntimeProvider
import com.typewritermc.loader.api.StagedHostedRuntime
import java.net.URLClassLoader
import java.nio.file.Path
import java.util.ServiceLoader

fun interface HostedRuntimeStager {
    suspend fun stage(
        context: HostedDeploymentContext,
        classPath: List<Path>,
    ): LoadedHostedRuntime
}

class HostedRuntimeLoader(
    private val parentClassLoader: ClassLoader = HostedRuntimeProvider::class.java.classLoader,
) : HostedRuntimeStager {
    override suspend fun stage(
        context: HostedDeploymentContext,
        classPath: List<Path>,
    ): LoadedHostedRuntime {
        val classLoader = URLClassLoader(classPath.map { it.toUri().toURL() }.toTypedArray(), parentClassLoader)
        try {
            val providers = ServiceLoader.load(HostedRuntimeProvider::class.java, classLoader).toList()
            require(providers.size == 1) {
                "A hosted artifact must provide exactly one HostedRuntimeProvider, but found ${providers.size}."
            }
            return LoadedHostedRuntime(providers.single().stage(context), classLoader)
        } catch (failure: Throwable) {
            runCatching { classLoader.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }
}

class LoadedHostedRuntime internal constructor(
    val runtime: StagedHostedRuntime,
    private val classLoader: URLClassLoader,
) {
    suspend fun close() {
        val failures = mutableListOf<Throwable>()
        try {
            runtime.close()
        } catch (failure: Throwable) {
            failures += failure
        }
        runCatching { classLoader.close() }.exceptionOrNull()?.let(failures::add)
        failures.firstOrNull()?.let { failure ->
            failures.drop(1).forEach(failure::addSuppressed)
            throw failure
        }
    }
}
