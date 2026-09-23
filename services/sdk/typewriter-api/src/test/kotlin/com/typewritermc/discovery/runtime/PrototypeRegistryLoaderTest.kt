package com.typewritermc.discovery.runtime

import com.typewritermc.discovery.AssembledTypeDiscovery
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.PrototypeBinding
import com.typewritermc.types.ConcreteTypePrototype
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.SerializationConcreteTypePrototype
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeProvider
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.serialization.Serializable

val PrototypeRegistryLoaderTest by testSuite {
    test("qualified metadata does not shadow a concrete prototype for the same runtime class") {
        val discovery =
            AssembledTypeDiscovery(
                catalog = TypeCatalog(listOf(declaredDefinition, qualifiedDefinition)),
                prototypeBindings =
                    listOf(
                        PrototypeBinding(
                            type = declaredType,
                            runtimeClass = SharedRuntimeValue::class.qualifiedName!!,
                            prototypeProviderClass = SharedRuntimeValuePrototypeProvider::class.qualifiedName!!,
                            domains = setOf(DiscoveryDomains.Realm),
                        ),
                    ),
                executableBindings = emptyList(),
                relations = emptyList(),
            )

        val prototypes =
            PrototypeRegistryLoader().load(
                discovery,
                DiscoveryDomains.Realm,
                SharedRuntimeValue::class.java.classLoader,
            )

        prototypes.require(SharedRuntimeValue::class).type shouldBe declaredType
    }
}

@Serializable
data class SharedRuntimeValue(
    val value: String,
)

class SharedRuntimeValuePrototypeProvider : TypePrototypeProvider {
    override fun prototype(): ConcreteTypePrototype<*> =
        SerializationConcreteTypePrototype(
            runtimeType = SharedRuntimeValue::class,
            type = declaredType,
            definition = declaredDefinition,
            serializer = SharedRuntimeValue.serializer(),
        )
}

private val representation =
    TypeExpression.Record(
        listOf(TypeField("value", TypeExpression.StringType())),
    )

private val declaredType =
    ResolvedTypeRef(
        TypeId.Declared(DeclaredTypeId.parse("019d58c184f170008000000000000001")),
        revision = 1,
    )

private val declaredDefinition =
    TypeDefinition(
        id = declaredType,
        kind = NominalTypeKind.CONCRETE,
        representation = representation,
    )

private val qualifiedDefinition =
    TypeDefinition(
        id =
            ResolvedTypeRef(
                TypeId.Qualified(
                    namespace = "com.typewritermc.discovery.runtime",
                    name = "SharedRuntimeValue",
                ),
                revision = 1,
            ),
        kind = NominalTypeKind.CONCRETE,
        representation = representation,
    )
