package com.typewritermc.types

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.MetaSerializable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.reflect.KClass
import kotlin.uuid.Uuid

@JvmInline
@Serializable(with = DeclaredTypeIdSerializer::class)
@TypewriterString
value class DeclaredTypeId(
    val value: Uuid,
) {
    companion object {
        fun parse(value: String): DeclaredTypeId = DeclaredTypeId(Uuid.parse(value))
    }

    override fun toString(): String = value.toHexString()
}

@OptIn(ExperimentalSerializationApi::class)
@MetaSerializable
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterType(
    val id: String,
    val revision: Int = 1,
)

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterTypeImports(
    vararg val types: KClass<*>,
)

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterDisplay(
    val name: String,
    val description: String = "",
    val icon: String,
    val color: String,
)

data class TypeDisplay(
    val name: String,
    val description: String,
    val icon: String,
    val color: String,
)

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterRecordContract

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterString

@Serializable
sealed interface TypeId {
    @Serializable
    @SerialName("declared")
    data class Declared(
        val id: DeclaredTypeId,
    ) : TypeId

    @Serializable
    @SerialName("qualified")
    data class Qualified(
        val namespace: String,
        val name: String,
    ) : TypeId {
        init {
            require(namespace.isNotBlank()) { "Type namespace must not be blank." }
            require(name.isNotBlank()) { "Type name must not be blank." }
        }
    }
}

@Serializable
data class TypeDefinitionId(
    val type: TypeId,
    val revision: Int,
) {
    init {
        require(revision > 0) { "Type revision must be positive." }
    }
}

@Serializable
data class ParameterKey(
    val owner: TypeDefinitionId,
    val index: Int,
) {
    init {
        require(index >= 0) { "Parameter index must not be negative." }
    }
}

@Serializable
enum class IntegerWidth(
    val bits: Int,
    val signed: kotlin.Boolean,
) {
    SIGNED_8(8, true),
    SIGNED_16(16, true),
    SIGNED_32(32, true),
    SIGNED_64(64, true),
    UNSIGNED_8(8, false),
    UNSIGNED_16(16, false),
    UNSIGNED_32(32, false),
    UNSIGNED_64(64, false),
}

@Serializable
enum class FloatWidth {
    FLOAT_32,
    FLOAT_64,
}

@Serializable
sealed interface TypeTemplate {
    @Serializable
    @SerialName("parameter")
    data class Parameter(
        val key: ParameterKey,
    ) : TypeTemplate

    @Serializable
    @SerialName("named")
    data class Named(
        val definition: TypeDefinitionId,
        val arguments: List<TypeTemplate> = emptyList(),
    ) : TypeTemplate

    @Serializable
    @SerialName("nullable")
    data class Nullable(
        val value: TypeTemplate,
    ) : TypeTemplate

    @Serializable
    @SerialName("scalar")
    data class Scalar(
        val kind: ScalarKind,
    ) : TypeTemplate
}

@Serializable
sealed interface TypeUse {
    @Serializable
    @SerialName("named")
    data class Named(
        val definition: TypeDefinitionId,
        val arguments: List<TypeUse> = emptyList(),
    ) : TypeUse

    @Serializable
    @SerialName("nullable")
    data class Nullable(
        val value: TypeUse,
    ) : TypeUse

    @Serializable
    @SerialName("scalar")
    data class Scalar(
        val kind: ScalarKind,
    ) : TypeUse
}

@Serializable
data class TypeDefinition(
    val id: TypeDefinitionId,
    val parameters: List<TypeParameter> = emptyList(),
    val representation: RepresentationTemplate,
    val parents: List<TypeTemplate.Named> = emptyList(),
)

@Serializable
data class PresentationId(
    val namespace: String,
    val name: String,
) {
    init {
        require(namespace.isNotBlank()) { "Presentation namespace must not be blank." }
        require(name.isNotBlank()) { "Presentation name must not be blank." }
    }
}

@Serializable
enum class PresentationRole {
    EDITOR,
    INSPECTOR,
    REFERENCE_SUMMARY,
    REFERENCE_OPTION,
    COLLECTION_ITEM,
    CATALOG_OPTION,
    AUTHORING_RESULT,
    PAGE_TILE,
    GRAPH_NODE,
    INSPECTOR_HEADER,
}
