package com.typewritermc.engine.runtime

import com.typewritermc.loader.DeploymentContext
import com.typewritermc.loader.DeploymentEntrypoint
import com.typewritermc.loader.DeploymentRuntime
import kotlinx.coroutines.CoroutineScope
import java.net.URL
import java.net.URLClassLoader

/**
 * Supplies verified engine, capability, and extension artifacts for one staged deployment.
 *
 * [artifacts] are mounted into one child classloader. [activationTargets] identify generated source sets in deterministic
 * activation order. The resulting runtime owns and closes the child classloader.
 */
data class EngineDeploymentPackage(
    val artifacts: List<URL>,
    val activationTargets: List<String>,
    val gateways: EngineGatewayRegistry,
    val contentGateway: EngineContentGateway? = null,
)

/** Resolves and verifies the complete package for a desired engine child before activation begins. */
fun interface EngineDeploymentPackageFactory {
    suspend fun stage(context: DeploymentContext): EngineDeploymentPackage
}

/**
 * Converts a staged engine package into a loader managed, replaceable runtime.
 *
 * A fresh child classloader contains the selected engine and all extension code. Package or activator failure closes that
 * classloader before propagating the cause, leaving the current deployment available for rollback.
 */
class EngineDeploymentEntrypoint(
    private val packageFactory: EngineDeploymentPackageFactory,
    private val parentScope: CoroutineScope,
    private val activatorLoader: GeneratedActivatorLoader = GeneratedActivatorLoader(),
    private val parentClassLoader: ClassLoader = EngineDeploymentEntrypoint::class.java.classLoader,
) : DeploymentEntrypoint {
    override suspend fun start(context: DeploymentContext): DeploymentRuntime {
        val deployment = packageFactory.stage(context)
        val classLoader = URLClassLoader(deployment.artifacts.toTypedArray(), parentClassLoader)
        return try {
            val activators = activatorLoader.load(classLoader, deployment.activationTargets)
            ReloadableEngineRuntime(
                classLoader,
                EngineActivationPlan(activators, deployment.gateways, deployment.contentGateway),
                parentScope,
            )
        } catch (failure: Throwable) {
            runCatching { classLoader.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }
}
