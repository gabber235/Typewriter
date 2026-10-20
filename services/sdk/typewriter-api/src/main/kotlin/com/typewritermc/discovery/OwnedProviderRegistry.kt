package com.typewritermc.discovery

import com.typewritermc.checking.CheckRecipe
import com.typewritermc.checking.RealmCheckProvider
import com.typewritermc.configuration.ConfigurationProvider
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.RelationContract
import com.typewritermc.types.TypeDefinitionId

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
