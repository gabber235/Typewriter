package com.typewritermc.engine.runtime.testing

import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderDeployment
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.engine.runtime.EngineContentGateway
import com.typewritermc.engine.runtime.ReloadableEngineRuntime
import kotlinx.coroutines.test.TestScope
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.PublicationId

/** A reloadable engine runtime over [registrars] with the generated provider deployment of an empty catalog. */
fun TestScope.runtime(
    registrars: List<RuntimeRegistrar>,
    revisions: MutableList<Long>? = null,
    enforceImplementationCompatibility: Boolean = true,
): RuntimeFixture {
    val deployment = GeneratedProviderLoader().load(emptyList(), DeploymentFacts(emptyMap()), DiscoveryDomains.Execution)
    return RuntimeFixture(
        ReloadableEngineRuntime(
            deployment = deployment,
            registrars = registrars,
            parentScope = this,
            implementationToken = "implementation",
            enforceImplementationCompatibility = enforceImplementationCompatibility,
            contentGateway =
                revisions?.let { values ->
                    EngineContentGateway {
                        values +=
                            it.descriptor.publication.value
                                .substringAfter(":")
                                .toLong()
                    }
                },
        ),
        deployment,
    )
}

/** Published content at publication revision [revision]; the digest character only distinguishes the bytes. */
fun content(
    revision: Long,
    digestCharacter: Char,
    implementationToken: String = "implementation",
): LoadedPublishedContent =
    LoadedPublishedContent(
        PublishedContent(
            publication = PublicationId(value = "publication:$revision"),
            formatRevision = com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION,
            catalog = CatalogGeneration(value = "catalog:1"),
            implementationToken = implementationToken,
            outputs = emptyList(),
        ),
        emptyList(),
    )

/** An engine runtime with the deployment it was built from, so a test can check the deployment's lifetime. */
data class RuntimeFixture(
    val runtime: ReloadableEngineRuntime,
    val deployment: GeneratedProviderDeployment,
)

/** A registrar that records `register:<name>` when it registers and `close:<name>` when its owned scope closes, into [events]. */
class RecordingRegistrar(
    private val name: String,
    private val events: MutableList<String>,
    private val fail: Boolean = false,
) : RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() {
        events += "register:$name"
        scope.own { events += "close:$name" }
        if (fail) error("registration failed")
    }
}
