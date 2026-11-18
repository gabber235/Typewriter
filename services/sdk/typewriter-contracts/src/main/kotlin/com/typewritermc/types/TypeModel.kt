package com.typewritermc.types

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.MetaSerializable
import skirout.editor.v1.type_catalog.DeclaredTypeId
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.FunctionParameterTemplate
import skirout.editor.v1.type_catalog.FunctionParameterUse
import skirout.editor.v1.type_catalog.FunctionTypeTemplate
import skirout.editor.v1.type_catalog.FunctionTypeUse
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

/** The id of the case [name] of this closed record, at this definition's revision. */
fun TypeDefinitionId.member(name: String): TypeDefinitionId =
    TypeDefinitionId(typeId = TypeId.createMember(owner = typeId, name = name), revision = revision)

/** The case name when this id is a member of a closed record, or null for any other id. */
val TypeDefinitionId.memberName: String? get() = (typeId as? TypeId.MemberWrapper)?.value?.name

/** The closed record that lists this case when this id is a member, or null for any other id. */
val TypeDefinitionId.memberOwner: TypeDefinitionId?
    get() = (typeId as? TypeId.MemberWrapper)?.let { TypeDefinitionId(typeId = it.value.owner, revision = revision) }

/** The use of the unit case [name] of the enum this use applies. */
fun NamedTypeUse.member(name: String): NamedTypeUse = NamedTypeUse(definition = definition.member(name), arguments = emptyList())

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

/** The function type this use is, or null for any other use. */
val TypeUse.function: FunctionTypeUse? get() = (this as? TypeUse.FunctionWrapper)?.value

/** Every type a function type mentions: context, then parameters, then its result. */
val FunctionTypeUse.parts: List<TypeUse> get() =
    context.map(FunctionParameterUse::type) + parameters.map(FunctionParameterUse::type) +
        result

/*
 * The structure of the type algebra. Each form answers its direct child types once, in [parts], and rebuilds itself
 * from replacements in the same order: within its own tree in [withParts], and across the trees in
 * [TypeTemplate.withUseParts] and [TypeUse.withTemplateParts], since a template is a use plus parameters. Every
 * traversal derives from these: [walk] and [mapTypes] rebuild within a tree, [TypeTemplate.toUse] and [TypeUse.toTemplate]
 * cross between them, and [zipParts] pairs the parts of two types of the same shape for structural matching. A new
 * form is threaded through every walker by answering these functions.
 */

/** The types this use is built from one level down: a named type's arguments, a nullable's value, a function's context, parameters and result. */
fun TypeUse.parts(): List<TypeUse> =
    when (this) {
        is TypeUse.NamedWrapper -> value.arguments
        is TypeUse.NullableWrapper -> listOf(value.value)
        is TypeUse.ScalarWrapper -> emptyList()
        is TypeUse.FunctionWrapper -> value.parts
        else -> unknownVariant(this)
    }

/** This use rebuilt from [parts], one per entry of [TypeUse.parts] in the same order, keeping its definition and slot names. */
fun TypeUse.withParts(parts: List<TypeUse>): TypeUse {
    require(parts.size == parts().size) { "Expected ${parts().size} parts, found ${parts.size}." }
    return when (this) {
        is TypeUse.NamedWrapper -> {
            TypeUse.NamedWrapper(value.copy(arguments = parts))
        }

        is TypeUse.NullableWrapper -> {
            parts.single().nullable()
        }

        is TypeUse.ScalarWrapper -> {
            this
        }

        is TypeUse.FunctionWrapper -> {
            val context = value.context.size
            val parameters = value.parameters.size
            TypeUse.createFunction(
                context = value.context.mapIndexed { index, slot -> slot.copy(type = parts[index]) },
                parameters = value.parameters.mapIndexed { index, slot -> slot.copy(type = parts[context + index]) },
                result = parts[context + parameters],
            )
        }

        else -> {
            unknownVariant(this)
        }
    }
}

/** The types this template is built from one level down, in the order of [TypeUse.parts]; a parameter has none. */
fun TypeTemplate.parts(): List<TypeTemplate> =
    when (this) {
        is TypeTemplate.NamedWrapper -> value.arguments
        is TypeTemplate.NullableWrapper -> listOf(value.value)
        is TypeTemplate.ScalarWrapper, is TypeTemplate.ParameterWrapper -> emptyList()
        is TypeTemplate.FunctionWrapper -> value.parts
        else -> unknownVariant(this)
    }

/** This template rebuilt from [parts], one per entry of [TypeTemplate.parts] in the same order. */
fun TypeTemplate.withParts(parts: List<TypeTemplate>): TypeTemplate {
    require(parts.size == parts().size) { "Expected ${parts().size} parts, found ${parts.size}." }
    return when (this) {
        is TypeTemplate.NamedWrapper -> {
            value.copy(arguments = parts).template
        }

        is TypeTemplate.NullableWrapper -> {
            parts.single().nullable()
        }

        is TypeTemplate.ScalarWrapper, is TypeTemplate.ParameterWrapper -> {
            this
        }

        is TypeTemplate.FunctionWrapper -> {
            val context = value.context.size
            val parameters = value.parameters.size
            TypeTemplate.createFunction(
                context = value.context.mapIndexed { index, slot -> slot.copy(type = parts[index]) },
                parameters = value.parameters.mapIndexed { index, slot -> slot.copy(type = parts[context + index]) },
                result = parts[context + parameters],
            )
        }

        else -> {
            unknownVariant(this)
        }
    }
}

/**
 * This template as a use rebuilt from [parts], one per entry of [TypeTemplate.parts] in the same order; a parameter has
 * no use form.
 */
fun TypeTemplate.withUseParts(parts: List<TypeUse>): TypeUse {
    require(parts.size == parts().size) { "Expected ${parts().size} parts, found ${parts.size}." }
    return when (this) {
        is TypeTemplate.NamedWrapper -> {
            value.definition.use(parts)
        }

        is TypeTemplate.NullableWrapper -> {
            parts.single().nullable()
        }

        is TypeTemplate.ScalarWrapper -> {
            value.use
        }

        is TypeTemplate.ParameterWrapper -> {
            throw IllegalArgumentException("A parameter has no use form.")
        }

        is TypeTemplate.FunctionWrapper -> {
            val context = value.context.size
            val parameters = value.parameters.size
            functionUse(
                context = value.context.mapIndexed { index, slot -> slot.name to parts[index] },
                parameters = value.parameters.mapIndexed { index, slot -> slot.name to parts[context + index] },
                result = parts[context + parameters],
            )
        }

        else -> {
            unknownVariant(this)
        }
    }
}

/** This use as a template rebuilt from [parts], one per entry of [TypeUse.parts] in the same order. */
fun TypeUse.withTemplateParts(parts: List<TypeTemplate>): TypeTemplate {
    require(parts.size == parts().size) { "Expected ${parts().size} parts, found ${parts.size}." }
    return when (this) {
        is TypeUse.NamedWrapper -> {
            value.definition.template(parts)
        }

        is TypeUse.NullableWrapper -> {
            parts.single().nullable()
        }

        is TypeUse.ScalarWrapper -> {
            value.template
        }

        is TypeUse.FunctionWrapper -> {
            val context = value.context.size
            val parameters = value.parameters.size
            functionTemplate(
                context = value.context.mapIndexed { index, slot -> slot.name to parts[index] },
                parameters = value.parameters.mapIndexed { index, slot -> slot.name to parts[context + index] },
                result = parts[context + parameters],
            )
        }

        else -> {
            unknownVariant(this)
        }
    }
}

/**
 * This template as a use: [parameter] answers the use each parameter stands for, every other form is rebuilt from its
 * converted parts. Null as soon as [parameter] answers null.
 */
fun TypeTemplate.toUse(parameter: (ParameterKey) -> TypeUse?): TypeUse? {
    if (this is TypeTemplate.ParameterWrapper) return parameter(value)
    return withUseParts(parts().map { part -> part.toUse(parameter) ?: return null })
}

/** The use this template is when it mentions no parameter, or null when it mentions one. */
val TypeTemplate.closedUse: TypeUse? get() = toUse { null }

/**
 * The parts of this use paired with those of [other] when the two have the same shape (form, definition, scalar and
 * slot names), else null.
 */
fun TypeUse.zipParts(other: TypeUse): List<Pair<TypeUse, TypeUse>>? {
    val mine = parts()
    val theirs = other.parts()
    return if (mine.size == theirs.size && withParts(theirs) == other) mine.zip(theirs) else null
}

/** The parts of this template paired with those of [other] when the two have the same shape, else null. */
fun TypeTemplate.zipParts(other: TypeTemplate): List<Pair<TypeTemplate, TypeTemplate>>? {
    val mine = parts()
    val theirs = other.parts()
    return if (mine.size == theirs.size && withParts(theirs) == other) mine.zip(theirs) else null
}

/**
 * The parts of this template paired with those of [other] when [other] has this template's shape, else null; a
 * parameter has no shape.
 */
fun TypeTemplate.zipParts(other: TypeUse): List<Pair<TypeTemplate, TypeUse>>? {
    if (this is TypeTemplate.ParameterWrapper) return null
    val mine = parts()
    val theirs = other.parts()
    return if (mine.size == theirs.size && withUseParts(theirs) == other) mine.zip(theirs) else null
}

/**
 * Answers a named pattern node itself, or null to match it part by part as every other node is. [matchAll] matches
 * pattern parts against candidate parts under the same bindings; a false answer from it leaves them as they were, so
 * a hook may try several alternatives in turn.
 */
fun interface NamedMatch<C> {
    fun match(
        pattern: NamedTypeTemplate,
        candidate: C,
        matchAll: (List<Pair<TypeTemplate, C>>) -> Boolean,
    ): Boolean?
}

/**
 * Whether [candidate] is an instance of this pattern: a parameter binds to the first candidate part it meets and must
 * meet an equal part everywhere else, [named] may answer a named node (nominal subtyping, a supertype's application),
 * and every other node matches a candidate of the same shape part by part. On success [bindings] holds what each
 * parameter met; a failed match leaves [bindings] as they were.
 */
fun TypeTemplate.match(
    candidate: TypeUse,
    bindings: MutableMap<ParameterKey, TypeUse>,
    named: NamedMatch<TypeUse>? = null,
): Boolean = Matcher<TypeUse>(TypeTemplate::zipParts, named).matchAll(listOf(this to candidate), bindings)

/** [match] against a candidate template, whose own parameters are opaque parts a pattern parameter can bind to. */
fun TypeTemplate.match(
    candidate: TypeTemplate,
    bindings: MutableMap<ParameterKey, TypeTemplate>,
    named: NamedMatch<TypeTemplate>? = null,
): Boolean = Matcher<TypeTemplate>(TypeTemplate::zipParts, named).matchAll(listOf(this to candidate), bindings)

private class Matcher<C : Any>(
    private val zip: (TypeTemplate, C) -> List<Pair<TypeTemplate, C>>?,
    private val named: NamedMatch<C>?,
) {
    /** Bindings only grow during a match, so a trial copy commits by adding what it bound. */
    fun matchAll(
        pairs: List<Pair<TypeTemplate, C>>,
        bindings: MutableMap<ParameterKey, C>,
    ): Boolean {
        val trial = LinkedHashMap(bindings)
        if (!pairs.all { (pattern, candidate) -> match(pattern, candidate, trial) }) return false
        bindings.putAll(trial)
        return true
    }

    private fun match(
        pattern: TypeTemplate,
        candidate: C,
        bindings: MutableMap<ParameterKey, C>,
    ): Boolean {
        if (pattern is TypeTemplate.ParameterWrapper) {
            val bound = bindings[pattern.value] ?: return true.also { bindings[pattern.value] = candidate }
            return bound == candidate
        }
        pattern.named?.let { node ->
            named?.match(node, candidate) { pairs -> matchAll(pairs, bindings) }?.let { return it }
        }
        return zip(pattern, candidate)?.all { (part, candidatePart) -> match(part, candidatePart, bindings) } == true
    }
}

/** This use and every use inside it, outermost first, each part before the next part. */
fun TypeUse.walk(): Sequence<TypeUse> =
    sequence {
        yield(this@walk)
        parts().forEach { yieldAll(it.walk()) }
    }

/** This template and every template inside it, outermost first, each part before the next part. */
fun TypeTemplate.walk(): Sequence<TypeTemplate> =
    sequence {
        yield(this@walk)
        parts().forEach { yieldAll(it.walk()) }
    }

/** Rebuilds this use outermost first: [replace] answers a replacement, kept as it is, or null to keep the node and rebuild its parts. */
fun TypeUse.mapTypes(replace: (TypeUse) -> TypeUse?): TypeUse = replace(this) ?: withParts(parts().map { it.mapTypes(replace) })

/** Rebuilds this template outermost first: [replace] answers a replacement, kept as it is, or null to keep the node and rebuild its parts. */
fun TypeTemplate.mapTypes(replace: (TypeTemplate) -> TypeTemplate?): TypeTemplate =
    replace(this) ?: withParts(parts().map { it.mapTypes(replace) })

/** The names of a function type's context slots, then of its parameters; two function types agree only on equal names. */
val FunctionTypeUse.slotNames: Pair<List<String>, List<String>> get() =
    context.map(FunctionParameterUse::name) to
        parameters.map(FunctionParameterUse::name)

/** The names of a function template's context slots, then of its parameters. */
val FunctionTypeTemplate.slotNames: Pair<List<String>, List<String>>
    get() = context.map(FunctionParameterTemplate::name) to parameters.map(FunctionParameterTemplate::name)

/** Every type a function template mentions: context, then parameters, then its result. */
val FunctionTypeTemplate.parts: List<TypeTemplate>
    get() = context.map(FunctionParameterTemplate::type) + parameters.map(FunctionParameterTemplate::type) + result

/** The function type use with these named context slots, parameters and result. */
fun functionUse(
    context: List<Pair<String, TypeUse>> = emptyList(),
    parameters: List<Pair<String, TypeUse>> = emptyList(),
    result: TypeUse,
): TypeUse =
    TypeUse.createFunction(
        context = context.map { (name, type) -> FunctionParameterUse(name = name, type = type) },
        parameters = parameters.map { (name, type) -> FunctionParameterUse(name = name, type = type) },
        result = result,
    )

/** The function type template with these named context slots, parameters and result. */
fun functionTemplate(
    context: List<Pair<String, TypeTemplate>> = emptyList(),
    parameters: List<Pair<String, TypeTemplate>> = emptyList(),
    result: TypeTemplate,
): TypeTemplate =
    TypeTemplate.createFunction(
        context = context.map { (name, type) -> FunctionParameterTemplate(name = name, type = type) },
        parameters = parameters.map { (name, type) -> FunctionParameterTemplate(name = name, type = type) },
        result = result,
    )

/** The record every function type is stored as: its body's source and the references inside it. */
val FORMULA_USE: NamedTypeUse = NamedTypeUse(definition = TypeDefinitionId.declared(FORMULA_TYPE_ID), arguments = emptyList())

/** The id of the Formula record, declared in typewriter-api beside its endpoint. */
const val FORMULA_TYPE_ID = "a2ac548560b44c90a92d929a273eacc5"

/** The id of Var, declared in typewriter-api; an alias reads the type its Value case holds. */
const val VAR_TYPE_ID = "acacc4ba2c064f5484d99d06a597d05b"

/**
 * The use a value at this position is stored as: a function type stores its body as a Formula record, every other
 * use stores itself. Nested positions keep their own use; only the outer position is replaced.
 */
val TypeUse.storedUse: TypeUse get() = if (this is TypeUse.FunctionWrapper) FORMULA_USE.use else this

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
fun TypeUse.toTemplate(): TypeTemplate = withTemplateParts(parts().map(TypeUse::toTemplate))

/** Lifts a concrete named application into a template with no free parameters. */
fun NamedTypeUse.toTemplate(): NamedTypeTemplate = definition.namedTemplate(arguments.map(TypeUse::toTemplate))

/** Collects the generic parameters this template refers to, in first occurrence order. */
fun TypeTemplate.parameterKeys(): Set<ParameterKey> = walk().mapNotNullTo(linkedSetOf()) { (it as? TypeTemplate.ParameterWrapper)?.value }

/** Replaces parameters bound in [arguments], leaving unbound parameters symbolic. */
fun TypeTemplate.substitute(arguments: Map<ParameterKey, TypeTemplate>): TypeTemplate =
    mapTypes { template -> (template as? TypeTemplate.ParameterWrapper)?.let { arguments[it.value] ?: it } }

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
