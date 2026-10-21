package com.typewritermc.discovery

import com.typewritermc.authoring.DisplayFormulas
import com.typewritermc.capability.RealmCapabilityProvider
import com.typewritermc.checking.RealmCheckProvider
import com.typewritermc.configuration.ConfigurationProvider
import com.typewritermc.presentation.CollectionProjectionSpec
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.types.TypeDisplay
import skirout.editor.v1.catalog.EndpointBindingTemplate
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.type_catalog.ResourceTarget
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import kotlin.reflect.KClass

interface GeneratedTypeProvider {
    val definition: TypeDefinition
    val nativeClass: KClass<*>?
        get() = null

    /** The complete display codegen fills for every declared type; null only for providers codegen does not own. */
    val display: TypeDisplay?
        get() = null

    /** The search scope keyword of a resource type, or null for a type that is not a resource. */
    val searchKey: String?
        get() = null
}

interface GeneratedRelationProvider {
    val contract: RelationContract
}

interface GeneratedEndpointBindingsProvider {
    val bindings: List<EndpointBindingTemplate>
}

interface GeneratedConfigurationProvider : ConfigurationProvider {
    val target: TypeDefinitionId
}

interface GeneratedPresentationProvider : PresentationProvider {
    val reference: com.typewritermc.presentation.PresentationReference? get() = null

    fun descriptor(origin: ProviderOrigin): PresentationDescriptor
}

/** One authored resource display: the resources it applies to and its formulas, built on demand at assembly. */
interface GeneratedResourceDisplayProvider {
    val target: ResourceTarget

    fun formulas(): DisplayFormulas
}

/** One operation object: its identity, target and input from compile time, and the declaration it runs at assembly. */
interface GeneratedResourceOperationProvider {
    fun contribute(origin: ProviderOrigin): com.typewritermc.operations.OperationDeclaration
}

interface GeneratedCheckProvider : RealmCheckProvider {
    val target: TypeDefinitionId
}

fun interface CapabilityOwnerResolver {
    fun resolve(owner: KClass<*>): Any
}

interface GeneratedCapabilityProvider {
    fun bind(resolver: CapabilityOwnerResolver): RealmCapabilityProvider
}

interface GeneratedCollectionProjectionProvider {
    val specification: CollectionProjectionSpec
}

/** Carries a registrar declaration identity and its eligible runtime domains through generated discovery. */
data class RuntimeRegistrarDescriptor(
    val id: RuntimeRegistrarId,
    val domains: Set<DiscoveryDomainId>,
) {
    init {
        require(domains.isNotEmpty()) { "Runtime registrars must select at least one runtime domain." }
    }
}

interface GeneratedRuntimeRegistrarProvider {
    val descriptor: RuntimeRegistrarDescriptor

    fun bind(instantiator: GeneratedProviderInstantiator): RuntimeRegistrar
}
