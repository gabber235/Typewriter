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

/**
 * Overrides parts of a type's display. Every type has a display: codegen derives an omitted [name] from the class
 * name in sentence case and fills an omitted [icon] or [color] with the framework defaults, so the annotation is only
 * needed for what differs.
 *
 * [icon] uses Iconify `prefix:name` syntax, or inline SVG source. [color] uses `#RRGGBB` syntax. [searchKey] is the
 * search scope keyword of a resource type, such as `book` in `book:"Main story"`; resource types without one use the
 * class name in lower case. Codegen rejects a search key on a type that is not a resource.
 */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterDisplay(
    val name: String = "",
    val description: String = "",
    val icon: String = "",
    val color: String = "",
    val searchKey: String = "",
)

/** Display data of a type, always complete: codegen fills every part [TypewriterDisplay] leaves out. */
data class TypeDisplay(
    val name: String,
    val description: String,
    val icon: Icon,
    val color: Color,
) {
    companion object {
        /** The icon of a type whose display names none. */
        val DEFAULT_ICON: Icon = Icon.Iconify("material-symbols:category")

        /** The color of a type whose display names none. */
        val DEFAULT_COLOR: Color = Color(0xFF607D8Bu)
    }
}

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

/** A declaration's type expression, which may still refer to the owning definition's generic parameters. */
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

/** A concrete type application with no free parameters; catalog resolution still checks its validity and bounds. */
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

/** Lifts a concrete type application into a template with no free parameters. */
fun TypeUse.toTemplate(): TypeTemplate =
    when (this) {
        is TypeUse.Named -> TypeTemplate.Named(definition, arguments.map { it.toTemplate() })
        is TypeUse.Nullable -> TypeTemplate.Nullable(value.toTemplate())
        is TypeUse.Scalar -> TypeTemplate.Scalar(kind)
    }

/** Collects the generic parameters this template refers to, in first occurrence order. */
fun TypeTemplate.parameterKeys(): Set<ParameterKey> =
    when (this) {
        is TypeTemplate.Parameter -> setOf(key)
        is TypeTemplate.Named -> arguments.flatMapTo(linkedSetOf()) { it.parameterKeys() }
        is TypeTemplate.Nullable -> value.parameterKeys()
        is TypeTemplate.Scalar -> emptySet()
    }

/** Replaces parameters bound in [arguments], leaving unbound parameters symbolic. */
fun TypeTemplate.substitute(arguments: Map<ParameterKey, TypeTemplate>): TypeTemplate =
    when (this) {
        is TypeTemplate.Parameter -> arguments[key] ?: this
        is TypeTemplate.Named -> copy(arguments = this.arguments.map { it.substitute(arguments) })
        is TypeTemplate.Nullable -> copy(value = value.substitute(arguments))
        is TypeTemplate.Scalar -> this
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

/**
 * The UI context for which a presentation is selected. A type can provide different layouts for
 * its main workspace, inspector, references, search results, and editor nodes.
 *
 * The host requests a role when selecting a presentation for a subject. Registering a role does
 * not create a UI surface. If no presentation matches, selection follows the catalog's explicit
 * role fallbacks; roles do not automatically inherit an editor or inspector layout.
 */
@Serializable
enum class PresentationRole {
    /**
     * The main workspace for an opened resource, such as a page graph or timeline.
     * The workspace host requests this role separately from the resource's inspector.
     */
    WORKSPACE_EDITOR,

    /**
     * Editable properties for a resource or nested value. Used by resource inspectors,
     * editing review, and delegated field controls. Layouts can compose inherited inspector
     * material from the subject's parent types.
     */
    INSPECTOR,

    /**
     * A compact preview of the selected reference target inside a link control.
     * Writes, pointer input, and focus are disabled by the host. Also serves as the default
     * fallback for [REFERENCE_PICKER_RESULT].
     */
    REFERENCE_PREVIEW,

    /**
     * A candidate target in a reference picker, including reference questions during creation.
     * The picker owns selection and disables writes. Missing presentations fall back to
     * [REFERENCE_PREVIEW]. Supports result appearance metadata for the surrounding row.
     */
    REFERENCE_PICKER_RESULT,

    /**
     * An existing resource in authoring search. The surrounding result owns navigation and
     * selection and disables writes. Supports result appearance metadata for the surrounding row.
     */
    RESOURCE_SEARCH_RESULT,

    /**
     * The content of a resource node within an editor, independent of graph or timeline layout.
     * Currently requested by page graphs, tag graphs, and tag drag previews. The containing
     * editor supplies the node's bounds and surrounding interaction.
     */
    EDITOR_NODE,
}
