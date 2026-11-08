package com.typewritermc.types.codegen

import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.Modifier
import com.squareup.kotlinpoet.ANY
import com.squareup.kotlinpoet.STRING
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.ksp.TypeParameterResolver
import com.squareup.kotlinpoet.ksp.toClassName
import com.squareup.kotlinpoet.ksp.toTypeName
import com.typewritermc.codegen.KnownTypes
import com.typewritermc.codegen.annotation
import com.typewritermc.codegen.compiledBounds
import com.typewritermc.codegen.isOneOf
import com.typewritermc.codegen.isType
import com.typewritermc.codegen.portableScalarKind
import com.typewritermc.codegen.valueClassStoredType
import com.typewritermc.types.Color
import com.typewritermc.types.FORMULA_USE
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterString
import com.typewritermc.types.template
import com.typewritermc.types.toTemplate
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeTemplate
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * The one classification of an authoring field. Emitters derive every Kotlin type and every runtime descriptor from
 * it with exhaustive `when`s, so a new kind of field fails to compile in every emitter until each handles it.
 */
internal sealed interface FieldShape {
    /** The portable template of this value. */
    val template: TypeTemplate

    /** The Kotlin type as authored, with nullability and type arguments. */
    val native: TypeName

    data class Nullable(
        val value: FieldShape,
        override val template: TypeTemplate,
        override val native: TypeName,
    ) : FieldShape

    data class Scalar(
        val kind: ScalarKind,
        override val template: TypeTemplate,
        override val native: TypeName,
    ) : FieldShape

    /** A nominal wrapper stored as a scalar: value classes and `@TypewriterString` types. */
    data class Wrapped(
        val kind: ScalarKind,
        val representation: TypeName,
        override val template: TypeTemplate,
        override val native: TypeName,
    ) : FieldShape

    /** The `Color` value class: stored like a wrapper, but configured and presented with color scopes. */
    data class Color(
        val kind: ScalarKind,
        val representation: TypeName,
        override val template: TypeTemplate,
        override val native: TypeName,
    ) : FieldShape

    /** A resource reference; [erased] replaces type parameters by their bounds for runtime casts. */
    data class Link(
        val target: TypeName,
        val erased: TypeName,
        override val template: TypeTemplate,
        override val native: TypeName,
    ) : FieldShape

    data class Sequence(
        val kind: CollectionKind,
        val item: FieldShape,
        override val template: TypeTemplate,
        override val native: TypeName,
    ) : FieldShape

    data class Mapping(
        val key: FieldShape,
        val value: FieldShape,
        override val template: TypeTemplate,
        override val native: TypeName,
    ) : FieldShape

    data class Enumeration(
        override val template: TypeTemplate,
        override val native: TypeName,
    ) : FieldShape

    /** A generated record type; [abstract] records are polymorphic. */
    data class Record(
        val names: SdkNames,
        val arguments: List<FieldShape>,
        val abstract: Boolean,
        override val template: TypeTemplate,
        override val native: TypeName,
    ) : FieldShape

    /**
     * A function type, stored as the Formula record. [stored] is the Formula record shape that configures, presents
     * and drafts the value; [native] stays the Kotlin type as authored, a function type or a Var's context marker.
     */
    data class Function(
        val stored: Record,
        override val template: TypeTemplate,
        override val native: TypeName,
    ) : FieldShape

    /** A type parameter of the declaration that owns the field. */
    data class Parameter(
        val index: Int,
        override val template: TypeTemplate,
        override val native: TypeName,
    ) : FieldShape
}

/** The Formula record, which stores the value of every function type. */
private val formulaShape: FieldShape.Record =
    FieldShape.Record(
        SdkNames.of(Api.Formula),
        emptyList(),
        abstract = false,
        template = FORMULA_USE.toTemplate().template,
        native = Api.Formula,
    )

/** Classifies a value from its portable template and resolved Kotlin type. The only KSType inspection for fields. */
context(parameters: TypeParameterResolver)
internal fun classify(
    template: TypeTemplate,
    type: KSType,
): FieldShape {
    val native = type.toTypeName(parameters)
    return when (template) {
        is TypeTemplate.NullableWrapper -> FieldShape.Nullable(classify(template.value.value, type.makeNotNullable()), template, native)
        is TypeTemplate.ParameterWrapper -> FieldShape.Parameter(template.value.index, template, native)
        is TypeTemplate.ScalarWrapper -> FieldShape.Scalar(template.value, template, native.copy(nullable = false))
        is TypeTemplate.NamedWrapper -> classifyNamed(template.value, type, native)
        is TypeTemplate.FunctionWrapper -> FieldShape.Function(formulaShape, template, native)
        else -> unknownVariant(template)
    }
}

context(parameters: TypeParameterResolver)
private fun classifyNamed(
    template: NamedTypeTemplate,
    type: KSType,
    native: TypeName,
): FieldShape {
    val declaration = type.declaration as KSClassDeclaration
    val arguments = type.arguments.map { requireNotNull(it.type) { "Star projections are not authorable." }.resolve() }
    return when {
        declaration isType Ref::class.asClassName() -> {
            val target = arguments[1]
            FieldShape.Link(target.toTypeName(parameters), type.makeNotNullable().erasedTypeName(), template.template, native)
        }

        declaration isOneOf KnownTypes.lists -> {
            FieldShape.Sequence(CollectionKind.LIST, classify(template.arguments.single(), arguments.single()), template.template, native)
        }

        declaration isOneOf KnownTypes.sets -> {
            FieldShape.Sequence(CollectionKind.SET, classify(template.arguments.single(), arguments.single()), template.template, native)
        }

        declaration isOneOf KnownTypes.maps -> {
            FieldShape.Mapping(
                classify(template.arguments[0], arguments[0]),
                classify(template.arguments[1], arguments[1]),
                template.template,
                native,
            )
        }

        else -> {
            declaration.declarationShape(
                template = template.template,
                native = native,
                arguments = template.arguments.zip(arguments) { argument, argumentType -> classify(argument, argumentType) },
            )
        }
    }
}

/**
 * Classifies a declaration that is not a collection or reference: colors, wrappers, enums and records.
 * Also used for a declaration's own root shape, where [arguments] are its type variables.
 */
context(parameters: TypeParameterResolver)
internal fun KSClassDeclaration.declarationShape(
    template: TypeTemplate,
    native: TypeName,
    arguments: List<FieldShape>,
): FieldShape {
    val wrapped = scalarRepresentation()
    return when {
        this isType Color::class.asClassName() -> {
            val representation = requireNotNull(wrapped) { "Color must wrap a portable scalar." }
            FieldShape.Color(representation.kind, representation.type, template, native)
        }

        wrapped != null -> {
            FieldShape.Wrapped(wrapped.kind, wrapped.type, template, native)
        }

        classKind == ClassKind.ENUM_CLASS -> {
            FieldShape.Enumeration(template, native)
        }

        else -> {
            FieldShape.Record(SdkNames.of(this), arguments, isAbstractDeclaration, template, native)
        }
    }
}

/** A nominal scalar: the portable kind it stores and the Kotlin type of its stored value. */
internal data class ScalarRepresentation(
    val kind: ScalarKind,
    val type: TypeName,
)

/** `@TypewriterString` types are Text over String; value classes are their single property's scalar kind. */
context(parameters: TypeParameterResolver)
internal fun KSClassDeclaration.scalarRepresentation(): ScalarRepresentation? {
    if (annotation<TypewriterString>() != null) return ScalarRepresentation(ScalarKind.TEXT, STRING)
    val stored = valueClassStoredType() ?: return null
    val kind = stored.portableScalarKind() ?: return null
    return ScalarRepresentation(kind, stored.toTypeName(parameters))
}

/**
 * Interfaces, abstract and sealed classes, whose values are always one of their concrete subtypes. KSP reports only
 * the modifiers written in source, so a sealed class carries SEALED without ABSTRACT.
 */
internal val KSClassDeclaration.isAbstractDeclaration: Boolean
    get() = classKind == ClassKind.INTERFACE || Modifier.ABSTRACT in modifiers || Modifier.SEALED in modifiers

/**
 * This type with every type parameter replaced by its first non Any bound, or `Any?` without one.
 * Native bindings cast through erased types because the declaration's own type variables are not in scope there.
 */
internal fun KSType.erasedTypeName(): TypeName {
    val declaration = declaration
    val erased =
        if (declaration is KSTypeParameter) {
            declaration
                .compiledBounds()
                .firstOrNull()
                ?.erasedTypeName()
                ?: ANY.copy(nullable = true)
        } else {
            val raw = (declaration as KSClassDeclaration).toClassName()
            raw.parameterizedOrSelf(arguments.map { it.type?.resolve()?.erasedTypeName() ?: ANY.copy(nullable = true) })
        }
    return if (isMarkedNullable) erased.copy(nullable = true) else erased
}
