package com.typewritermc.discovery

import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.capability.RealmCapabilityProvider
import com.typewritermc.checking.RealmCheckProvider
import com.typewritermc.configuration.ConfigurationProvider
import com.typewritermc.presentation.CollectionProjectionSpec
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.RelationContract
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeDisplay
import kotlin.reflect.KClass

enum class GeneratedProviderKind(
    val key: String,
) {
    Type("type"),
    NativeBinding("nativeBinding"),
    Resource("resource"),
    Relation("relation"),
    EndpointBindings("endpointBindings"),
    Configuration("configuration"),
    Presentation("presentation"),
    Check("check"),
    Capability("capability"),
    Registrar("registrar"),
    CollectionProjection("collectionProjection"),
}

data class GeneratedProviderIndexEntry(
    val kind: GeneratedProviderKind,
    val providerClass: String,
    val sourcePart: String,
)

const val GENERATED_PROVIDER_INDEX_PATH: String = "META-INF/typewriter/generated-providers"

interface GeneratedTypeProvider {
    val definition: TypeDefinition
    val display: TypeDisplay?
        get() = null
}

interface GeneratedRelationProvider {
    val contract: RelationContract
}

interface GeneratedEndpointBindingsProvider {
    val bindings: List<EndpointBindingTemplate>
}

interface GeneratedResourceProvider {
    val definition: AuthoringResourceDefinition
}

interface GeneratedConfigurationProvider : ConfigurationProvider {
    val target: TypeDefinitionId
}

interface GeneratedPresentationProvider : PresentationProvider {
    fun descriptor(origin: ProviderOrigin): PresentationDescriptor
}

interface GeneratedCheckProvider : RealmCheckProvider {
    val target: TypeDefinitionId
}

fun interface CapabilityOwnerResolver {
    fun resolve(owner: KClass<*>): Any
}

interface GeneratedCapabilityProvider {
    val descriptor: RealmCapabilityDescriptor

    fun bind(resolver: CapabilityOwnerResolver): RealmCapabilityProvider
}

interface GeneratedCollectionProjectionProvider {
    val specification: CollectionProjectionSpec
}
