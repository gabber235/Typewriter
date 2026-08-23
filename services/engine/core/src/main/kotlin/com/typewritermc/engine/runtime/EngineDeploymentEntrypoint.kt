package com.typewritermc.engine.runtime

import com.typewritermc.discovery.AssembledTypeDiscovery
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.runtime.DiscoveryArtifactPackage
import com.typewritermc.discovery.runtime.DiscoveryModuleLoader
import com.typewritermc.discovery.runtime.RuntimeRegistrar
import com.typewritermc.loader.DeploymentContext
import com.typewritermc.loader.DeploymentEntrypoint
import com.typewritermc.loader.DeploymentRuntime
import kotlinx.coroutines.CoroutineScope

data class EngineDeploymentPackage(
    val artifacts: DiscoveryArtifactPackage,
    val discovery: AssembledTypeDiscovery,
    val contentGateway: EngineContentGateway? = null,
)

fun interface EngineDeploymentPackageFactory {
    suspend fun stage(context: DeploymentContext): EngineDeploymentPackage
}

class EngineDeploymentEntrypoint(
    private val packageFactory: EngineDeploymentPackageFactory,
    private val parentScope: CoroutineScope,
    private val discoveryLoader: DiscoveryModuleLoader = DiscoveryModuleLoader(),
) : DeploymentEntrypoint {
    override suspend fun start(context: DeploymentContext): DeploymentRuntime {
        val staged = packageFactory.stage(context)
        val deployment = discoveryLoader.load(staged.artifacts, DiscoveryDomains.Execution, staged.discovery)
        return try {
            ReloadableEngineRuntime(
                deployment = deployment,
                registrars = deployment.application.koin.getAll<RuntimeRegistrar>(),
                parentScope = parentScope,
                contentGateway = staged.contentGateway,
            )
        } catch (failure: Throwable) {
            runCatching { deployment.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }
}
