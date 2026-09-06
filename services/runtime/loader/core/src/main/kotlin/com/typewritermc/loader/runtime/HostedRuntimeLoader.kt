package com.typewritermc.loader.runtime

import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedRuntimeProvider
import com.typewritermc.loader.api.StagedHostedRuntime
import java.net.URLClassLoader
import java.nio.file.Path
import java.util.ServiceLoader

/**
 * Stages a runtime from resolved context and executable paths.
 *
 * Success transfers runtime and class loader ownership to the caller. Failure must release resources acquired
 * while staging.
 */
fun interface HostedRuntimeStager {
    suspend fun stage(
        context: HostedDeploymentContext,
        classPath: List<Path>,
    ): LoadedHostedRuntime
}

/**
 * Loads exactly one hosted provider through ServiceLoader in a new URL class loader.
 *
 * The parent supplies shared API types. Staging failure closes the loader with cleanup causes preserved; success
 * must be released through [LoadedHostedRuntime].
 */
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

/**
 * Owns the staged runtime and the class loader retaining its artifact code.
 *
 * Closure attempts runtime cleanup before class loader cleanup and collects failures with later causes suppressed.
 */
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
