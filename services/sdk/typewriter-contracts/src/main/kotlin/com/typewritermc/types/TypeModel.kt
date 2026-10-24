package com.typewritermc.types

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.MetaSerializable
import skirout.editor.v1.type_catalog.DeclaredTypeId
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import kotlin.reflect.KClass
import kotlin.uuid.Uuid

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
 * class name in lower case. Codegen rejects a search key on a type that is not a resource and the key `type`, which
 * editors reserve for their type selector.
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

/** The catalog wire form of this display; the author facing icon and color convert here once. */
fun TypeDisplay.toWire(): skirout.editor.v1.catalog.TypeDisplay =
    skirout.editor.v1.catalog.TypeDisplay(
        name = name,
        description = description,
        icon = icon.toWire(),
        color =
            skirout.kernel.v1.color
                .Color(argb = color.argb.toInt()),
    )

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterRecordContract

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterString

/**
 * Parses a declared type id from any UUID text form into its canonical 32 character lowercase hexadecimal form, so
 * one declaration never becomes two catalog keys. Fails on text that is not a UUID.
 */
fun DeclaredTypeId.Companion.parse(value: String): DeclaredTypeId = DeclaredTypeId(value = Uuid.parse(value).toHexString())

/** The id of a definition declared by a qualified name, the form of builtin and framework definitions. */
fun TypeDefinitionId.Companion.qualified(
    namespace: String,
    name: String,
    revision: Int = 1,
): TypeDefinitionId = TypeDefinitionId(typeId = TypeId.createQualified(namespace = namespace, name = name), revision = revision)

/** The id of a definition declared with a `@TypewriterType` UUID, parsed into its canonical form. */
fun TypeDefinitionId.Companion.declared(
    id: String,
    revision: Int = 1,
): TypeDefinitionId = TypeDefinitionId(typeId = TypeId.DeclaredWrapper(DeclaredTypeId.parse(id)), revision = revision)

/** This definition applied to [arguments]. */
fun TypeDefinitionId.namedUse(arguments: List<TypeUse> = emptyList()): NamedTypeUse = NamedTypeUse(definition = this, arguments = arguments)

/** The type use applying this definition to [arguments]. */
fun TypeDefinitionId.use(arguments: List<TypeUse> = emptyList()): TypeUse = TypeUse.NamedWrapper(namedUse(arguments))

/** The template applying this definition to [arguments]. */
fun TypeDefinitionId.namedTemplate(arguments: List<TypeTemplate> = emptyList()): NamedTypeTemplate =
    NamedTypeTemplate(definition = this, arguments = arguments)

/** The type template applying this definition to [arguments]. */
fun TypeDefinitionId.template(arguments: List<TypeTemplate> = emptyList()): TypeTemplate =
    TypeTemplate.NamedWrapper(namedTemplate(arguments))

val NamedTypeUse.use: TypeUse get() = TypeUse.NamedWrapper(this)

val NamedTypeTemplate.template: TypeTemplate get() = TypeTemplate.NamedWrapper(this)

val ScalarKind.use: TypeUse get() = TypeUse.ScalarWrapper(this)

val ScalarKind.template: TypeTemplate get() = TypeTemplate.ScalarWrapper(this)

/** The template that refers to this generic parameter. */
val ParameterKey.template: TypeTemplate get() = TypeTemplate.ParameterWrapper(this)

/** This type, or an explicit null. */
fun TypeUse.nullable(): TypeUse = TypeUse.createNullable(value = this)

/** This template, or an explicit null. */
fun TypeTemplate.nullable(): TypeTemplate = TypeTemplate.createNullable(value = this)

/** The named application this use is, or null for a nullable or scalar use. */
val TypeUse.named: NamedTypeUse? get() = (this as? TypeUse.NamedWrapper)?.value

/** The named application this template is, or null for any other template. */
val TypeTemplate.named: NamedTypeTemplate? get() = (this as? TypeTemplate.NamedWrapper)?.value

/** The number of bits an integer of this width holds. */
val IntegerWidth.bits: Int
    get() =
        when (this) {
            IntegerWidth.SIGNED_EIGHT, IntegerWidth.UNSIGNED_EIGHT -> 8
            IntegerWidth.SIGNED_SIXTEEN, IntegerWidth.UNSIGNED_SIXTEEN -> 16
            IntegerWidth.SIGNED_THIRTY_TWO, IntegerWidth.UNSIGNED_THIRTY_TWO -> 32
            IntegerWidth.SIGNED_SIXTY_FOUR, IntegerWidth.UNSIGNED_SIXTY_FOUR -> 64
            else -> unknownVariant(this)
        }

/** Whether an integer of this width holds negative values. */
val IntegerWidth.signed: Boolean
    get() =
        when (this) {
            IntegerWidth.SIGNED_EIGHT,
            IntegerWidth.SIGNED_SIXTEEN,
            IntegerWidth.SIGNED_THIRTY_TWO,
            IntegerWidth.SIGNED_SIXTY_FOUR,
            -> true

            IntegerWidth.UNSIGNED_EIGHT,
            IntegerWidth.UNSIGNED_SIXTEEN,
            IntegerWidth.UNSIGNED_THIRTY_TWO,
            IntegerWidth.UNSIGNED_SIXTY_FOUR,
            -> false

            else -> unknownVariant(this)
        }

/** Every integer width, in declaration order. */
val IntegerWidth.Companion.entries: List<IntegerWidth>
    get() =
        listOf(
            IntegerWidth.SIGNED_EIGHT,
            IntegerWidth.SIGNED_SIXTEEN,
            IntegerWidth.SIGNED_THIRTY_TWO,
            IntegerWidth.SIGNED_SIXTY_FOUR,
            IntegerWidth.UNSIGNED_EIGHT,
            IntegerWidth.UNSIGNED_SIXTEEN,
            IntegerWidth.UNSIGNED_THIRTY_TWO,
            IntegerWidth.UNSIGNED_SIXTY_FOUR,
        )

/** Every float width, in declaration order. */
val FloatWidth.Companion.entries: List<FloatWidth> get() = listOf(FloatWidth.THIRTY_TWO, FloatWidth.SIXTY_FOUR)

/** The integer scalar of [width]. */
fun integerScalar(width: IntegerWidth): ScalarKind = ScalarKind.createInteger(width = width)

/** The float scalar of [width]. */
fun floatScalar(width: FloatWidth): ScalarKind = ScalarKind.createFloat(width = width)

/** Lifts a concrete type application into a template with no free parameters. */
fun TypeUse.toTemplate(): TypeTemplate =
    when (this) {
        is TypeUse.NamedWrapper -> value.toTemplate().template
        is TypeUse.NullableWrapper -> value.value.toTemplate().nullable()
        is TypeUse.ScalarWrapper -> value.template
        else -> unknownVariant(this)
    }

/** Lifts a concrete named application into a template with no free parameters. */
fun NamedTypeUse.toTemplate(): NamedTypeTemplate = definition.namedTemplate(arguments.map(TypeUse::toTemplate))

/** Collects the generic parameters this template refers to, in first occurrence order. */
fun TypeTemplate.parameterKeys(): Set<ParameterKey> =
    when (this) {
        is TypeTemplate.ParameterWrapper -> setOf(value)
        is TypeTemplate.NamedWrapper -> value.arguments.flatMapTo(linkedSetOf()) { it.parameterKeys() }
        is TypeTemplate.NullableWrapper -> value.value.parameterKeys()
        is TypeTemplate.ScalarWrapper -> emptySet()
        else -> unknownVariant(this)
    }

/** Replaces parameters bound in [arguments], leaving unbound parameters symbolic. */
fun TypeTemplate.substitute(arguments: Map<ParameterKey, TypeTemplate>): TypeTemplate =
    when (this) {
        is TypeTemplate.ParameterWrapper -> arguments[value] ?: this
        is TypeTemplate.NamedWrapper -> value.substitute(arguments).template
        is TypeTemplate.NullableWrapper -> value.value.substitute(arguments).nullable()
        is TypeTemplate.ScalarWrapper -> this
        else -> unknownVariant(this)
    }

/** Replaces parameters bound in [arguments] within the arguments of this application. */
fun NamedTypeTemplate.substitute(arguments: Map<ParameterKey, TypeTemplate>): NamedTypeTemplate =
    copy(arguments = this.arguments.map { it.substitute(arguments) })

/**
 * The dense Skir JSON of this type: deterministic and distinct for distinct types. Binding signatures, capability
 * identities, digests and stable orderings derive from it rather than from the debug `toString`.
 */
val TypeUse.canonicalText: String get() = TypeUse.serializer.toJsonCode(this)

/** The dense Skir JSON of this template, with the guarantees of [TypeUse.canonicalText]. */
val TypeTemplate.canonicalText: String get() = TypeTemplate.serializer.toJsonCode(this)

/** The dense Skir JSON of this definition id, with the guarantees of [TypeUse.canonicalText]. */
val TypeDefinitionId.canonicalText: String get() = TypeDefinitionId.serializer.toJsonCode(this)

/**
 * Fails on the unknown variant of a Skir value. Values are validated where they enter, so code below the boundary
 * only meets this for a value that skipped validation.
 */
fun unknownVariant(value: Any): Nothing = error("Unknown ${value::class.qualifiedName} variant.")
