package com.typewritermc.discovery

import com.typewritermc.checking.CheckRecipe
import com.typewritermc.checking.RealmCheckProvider
import com.typewritermc.configuration.ConfigurationProvider
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.types.NativeBindingFactory
import skirout.editor.v1.catalog.EndpointBindingTemplate
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId

data class ProviderOrigin(
    val owner: DeclarationOwner,
    val artifact: ArtifactId,
    val sourcePart: String,
)

data class OwnedConfiguration(
    val origin: ProviderOrigin,
    val target: TypeDefinitionId,
    val callback: ConfigurationProvider,
)

data class OwnedPresentation(
    val origin: ProviderOrigin,
    val descriptor: PresentationDescriptor,
    val provider: PresentationProvider,
    val reference: com.typewritermc.presentation.PresentationReference? = null,
)

/** A resource display declared by [origin]; catalog assembly checks and compiles its formulas. */
data class OwnedResourceDisplay(
    val origin: ProviderOrigin,
    val provider: GeneratedResourceDisplayProvider,
)

data class OwnedNativeBinding(
    val origin: ProviderOrigin,
    val factory: NativeBindingFactory,
)

data class OwnedCheck(
    val origin: ProviderOrigin,
    val ruleOrigin: RuleOrigin,
    val provider: RealmCheckProvider,
)

data class OwnedCheckRecipe(
    val origin: ProviderOrigin,
    val recipe: CheckRecipe,
)

interface OwnedProviderRegistry {
    fun retain(origin: ProviderOrigin): ProviderLease

    fun configurations(): List<OwnedConfiguration>

    fun presentations(): List<OwnedPresentation>

    fun nativeBindings(): List<OwnedNativeBinding>

    fun checks(): List<OwnedCheck>
}

interface ProviderLease : AutoCloseable

data class CatalogContributions(
    val declarations: List<OwnedTypeDeclaration>,
    val relations: List<RelationContract> = emptyList(),
    val endpointBindings: List<EndpointBindingTemplate> = emptyList(),
    val configurations: List<OwnedConfiguration> = emptyList(),
    val presentations: List<OwnedPresentation> = emptyList(),
    val nativeBindings: List<OwnedNativeBinding> = emptyList(),
    val checks: List<OwnedCheck> = emptyList(),
    val operations: List<com.typewritermc.operations.OperationDeclaration> = emptyList(),
    val displays: List<OwnedResourceDisplay> = emptyList(),
)

internal class ImmutableOwnedProviderRegistry(
    private val ownedConfigurations: List<OwnedConfiguration>,
    private val ownedPresentations: List<OwnedPresentation>,
    private val ownedNativeBindings: List<OwnedNativeBinding>,
    private val ownedChecks: List<OwnedCheck>,
) : OwnedProviderRegistry {
    override fun retain(origin: ProviderOrigin): ProviderLease {
        require(
            ownedConfigurations.any { it.origin == origin } ||
                ownedPresentations.any { it.origin == origin } ||
                ownedNativeBindings.any { it.origin == origin } ||
                ownedChecks.any { it.origin == origin },
        ) { "Unknown provider origin $origin." }
        return ImmutableProviderLease
    }

    override fun configurations(): List<OwnedConfiguration> = ownedConfigurations

    override fun presentations(): List<OwnedPresentation> = ownedPresentations

    override fun nativeBindings(): List<OwnedNativeBinding> = ownedNativeBindings

    override fun checks(): List<OwnedCheck> = ownedChecks
}

private data object ImmutableProviderLease : ProviderLease {
    override fun close() = Unit
}
