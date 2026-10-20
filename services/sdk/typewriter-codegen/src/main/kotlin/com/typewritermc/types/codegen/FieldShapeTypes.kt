package com.typewritermc.types.codegen

import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.MemberName
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeVariableName
import com.squareup.kotlinpoet.UNIT
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.asTypeName
import com.squareup.kotlinpoet.joinToCode
import com.typewritermc.codegen.DefinitionReferences
import com.typewritermc.codegen.TypeParameterBindings
import com.typewritermc.codegen.appliedUseCode
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.codegen.mapCode
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import java.math.BigDecimal
import kotlin.reflect.KClass
import com.typewritermc.codegen.TypewriterApi as Api

/** The configuration scope a field's `configure` block receives. */
internal val FieldShape.configurationScope: TypeName
    get() =
        when (this) {
            is FieldShape.Nullable -> {
                Api.NullableField.parameterizedBy(value.configurationValue, value.configurationScope)
            }

            is FieldShape.Scalar -> {
                kind.configurationScope(native)
            }

            is FieldShape.Wrapped -> {
                kind.configurationScope(representation)
            }

            is FieldShape.Color -> {
                Api.ColorField
            }

            is FieldShape.Link -> {
                Api.LinkField.parameterizedBy(target)
            }

            is FieldShape.Sequence -> {
                when (kind) {
                    CollectionKind.List -> {
                        Api.ListField.parameterizedBy(item.configurationValue, item.configurationScope, item.expressionScope)
                    }

                    CollectionKind.Set -> {
                        Api.SetField.parameterizedBy(item.configurationValue, item.configurationScope)
                    }
                }
            }

            is FieldShape.Mapping -> {
                Api.MapField.parameterizedBy(
                    key.configurationValue,
                    value.configurationValue,
                    key.configurationScope,
                    value.configurationScope,
                )
            }

            is FieldShape.Enumeration -> {
                Api.EnumField.parameterizedBy(configurationValue)
            }

            is FieldShape.Record -> {
                names.configurationScope.parameterizedOrSelf(arguments.map(FieldShape::native))
            }

            is FieldShape.Parameter -> {
                Api.GenericValueConfigurationScope.parameterizedBy(configurationValue)
            }
        }

/** The value a configuration scope sees: wrappers expose their stored representation. */
internal val FieldShape.configurationValue: TypeName
    get() =
        when (this) {
            is FieldShape.Nullable -> value.configurationValue.copy(nullable = true)
            is FieldShape.Wrapped -> representation
            is FieldShape.Color -> representation
            else -> native.copy(nullable = false)
        }

/** The template a configuration descriptor expects: wrappers expect their stored scalar. */
internal val FieldShape.configurationExpected: TypeTemplate
    get() =
        when (this) {
            is FieldShape.Nullable -> TypeTemplate.Nullable(value.configurationExpected)
            is FieldShape.Wrapped -> TypeTemplate.Scalar(kind)
            else -> template
        }

/** The typed expression scope over a value of this shape. */
internal val FieldShape.expressionScope: TypeName
    get() =
        when (this) {
            is FieldShape.Nullable -> {
                Api.NullableExpressions.parameterizedBy(value.configurationValue)
            }

            is FieldShape.Scalar -> {
                kind.expressionScope(native)
            }

            is FieldShape.Wrapped -> {
                kind.expressionScope(representation)
            }

            is FieldShape.Color -> {
                Api.ColorExpressions
            }

            is FieldShape.Link -> {
                Api.LinkExpressions.parameterizedBy(target)
            }

            is FieldShape.Sequence -> {
                when (kind) {
                    CollectionKind.List -> Api.ListExpressions.parameterizedBy(item.native)
                    CollectionKind.Set -> Api.SetExpressions.parameterizedBy(item.native)
                }
            }

            is FieldShape.Mapping -> {
                Api.MapExpressions.parameterizedBy(key.native, value.native)
            }

            is FieldShape.Enumeration -> {
                Api.EnumExpressions.parameterizedBy(configurationValue)
            }

            is FieldShape.Record -> {
                names.expressions.parameterizedOrSelf(arguments.map(FieldShape::native))
            }

            is FieldShape.Parameter -> {
                Api.GenericValueExpressions.parameterizedBy(configurationValue)
            }
        }

/** Library expression scopes have a factory object named `<Scope>Factory` beside them. */
internal val FieldShape.expressionFactory: ClassName
    get() = (this as? FieldShape.Record)?.names?.expressionsFactory ?: expressionScope.rawClass.factory()

/** The presentation control of a field of this shape. */
internal val FieldShape.presentationControl: TypeName
    get() =
        when (this) {
            is FieldShape.Nullable -> {
                Api.NullableControl.parameterizedBy(value.presentationNested)
            }

            is FieldShape.Scalar -> {
                kind.presentationControl(native)
            }

            is FieldShape.Wrapped -> {
                kind.presentationControl(representation)
            }

            is FieldShape.Color -> {
                Api.ColorControl
            }

            is FieldShape.Link -> {
                Api.LinkControl.parameterizedBy(target)
            }

            is FieldShape.Sequence -> {
                when {
                    kind == CollectionKind.List && item is FieldShape.Link -> Api.ResourceLinksControl.parameterizedBy(item.target)
                    kind == CollectionKind.List -> Api.ListControl.parameterizedBy(item.presentationNested)
                    else -> Api.SetControl.parameterizedBy(item.presentationNested)
                }
            }

            is FieldShape.Mapping -> {
                Api.MapControl.parameterizedBy(key.presentationNested, value.presentationNested)
            }

            is FieldShape.Enumeration -> {
                Api.EnumControl.parameterizedBy(native)
            }

            is FieldShape.Record -> {
                if (abstract) {
                    Api.PolymorphicControl.parameterizedBy(native)
                } else {
                    Api.RecordControl.parameterizedBy(presentationScope)
                }
            }

            is FieldShape.Parameter -> {
                Api.Control
            }
        }

/** The scope a nested slot exposes: concrete records expose their typed presentation scope directly. */
internal val FieldShape.presentationNested: TypeName
    get() = if (this is FieldShape.Record && !abstract) presentationScope else presentationControl

private val FieldShape.Record.presentationScope: TypeName
    get() = names.presentationScope.parameterizedOrSelf(arguments.map(FieldShape::native))

internal val FieldShape.representationKind: RepresentationKind
    get() =
        when (this) {
            is FieldShape.Nullable -> value.representationKind
            is FieldShape.Scalar -> kind.representationKind
            is FieldShape.Wrapped -> kind.representationKind
            is FieldShape.Color -> kind.representationKind
            is FieldShape.Link -> RepresentationKind.Link
            is FieldShape.Sequence -> if (kind == CollectionKind.List) RepresentationKind.List else RepresentationKind.Set
            is FieldShape.Mapping -> RepresentationKind.Map
            is FieldShape.Enumeration -> RepresentationKind.Enum
            is FieldShape.Record, is FieldShape.Parameter -> RepresentationKind.Record
        }

/** The read side type exposed on drafts; type parameters map to the draft's `D<index>` variables. */
internal fun FieldShape.draftType(draftVariables: List<TypeVariableName>): TypeName =
    when (this) {
        is FieldShape.Nullable -> {
            value.draftType(draftVariables).copy(nullable = true)
        }

        is FieldShape.Parameter -> {
            draftVariables[index].copy(nullable = native.isNullable)
        }

        is FieldShape.Scalar, is FieldShape.Enumeration -> {
            native
        }

        is FieldShape.Link -> {
            erased
        }

        is FieldShape.Wrapped -> {
            representation
        }

        is FieldShape.Color -> {
            representation
        }

        is FieldShape.Sequence -> {
            (if (kind == CollectionKind.List) Api.DraftList else Api.DraftSet).parameterizedBy(item.draftType(draftVariables))
        }

        is FieldShape.Mapping -> {
            Api.MapDraft.parameterizedBy(key.draftType(draftVariables), value.draftType(draftVariables))
        }

        is FieldShape.Record -> {
            names.draft.parameterizedOrSelf(arguments.map { it.draftType(draftVariables) })
        }
    }

/** The read projection of a value of this shape; type parameters read through `argument<index>`. */
context(_: TypeParameterBindings, _: DefinitionReferences)
internal fun FieldShape.draftProjection(): CodeBlock =
    when (this) {
        is FieldShape.Parameter -> {
            CodeBlock.of("argument%L", index)
        }

        is FieldShape.Nullable -> {
            CodeBlock.of("%M(%L)", Api.nullableReadProjection, value.draftProjection())
        }

        is FieldShape.Scalar -> {
            CodeBlock.of("%M<%T>(%L)", Api.nativeReadProjection, configurationValue, template.appliedUseCode())
        }

        is FieldShape.Wrapped -> {
            representationProjection(kind, representation)
        }

        is FieldShape.Color -> {
            representationProjection(kind, representation)
        }

        is FieldShape.Sequence -> {
            CodeBlock.of(
                "%M(%L,♢%L)",
                if (kind == CollectionKind.List) Api.listDraftProjection else Api.setDraftProjection,
                template.appliedUseCode(),
                item.draftProjection(),
            )
        }

        is FieldShape.Mapping -> {
            CodeBlock.of(
                "%M(%L,♢%L,♢%L)",
                Api.mapDraftProjection,
                template.appliedUseCode(),
                key.draftProjection(),
                value.draftProjection(),
            )
        }

        is FieldShape.Link -> {
            CodeBlock.of("%M<%T>(%L)", Api.nativeReadProjection, erased, template.appliedUseCode())
        }

        is FieldShape.Enumeration -> {
            CodeBlock.of("%M<%T>(%L)", Api.nativeReadProjection, native, template.appliedUseCode())
        }

        is FieldShape.Record -> {
            if (arguments.isEmpty()) {
                CodeBlock.of("%T", names.draftProjection)
            } else {
                CodeBlock.of(
                    "%M(%L)",
                    names.draftProjectionFunction,
                    arguments.map { it.draftProjection() }.joinToCode(",♢"),
                )
            }
        }
    }

context(_: TypeParameterBindings, _: DefinitionReferences)
private fun FieldShape.representationProjection(
    kind: ScalarKind,
    representation: TypeName,
): CodeBlock =
    CodeBlock.of(
        "%M<%T>(%L,♢%T(%L))",
        Api.representationReadProjection,
        representation,
        template.appliedUseCode(),
        TypeUse.Scalar::class,
        kind.kotlinCode(),
    )

/** Nested slot descriptors of a configuration field: nullable values, collection items, map keys and values. */
context(_: DefinitionReferences)
internal fun FieldShape.nestedConfigurationScopes(): CodeBlock {
    val slots =
        when (this) {
            is FieldShape.Nullable -> listOf(FieldPatternSegment.Values to value)
            is FieldShape.Sequence -> listOf(FieldPatternSegment.Items to item)
            is FieldShape.Mapping -> listOf(FieldPatternSegment.Keys to key, FieldPatternSegment.Values to value)
            else -> emptyList()
        }
    return slots.map { (segment, shape) -> segment.kotlinCode() to shape.nestedConfigurationDescriptor() }.mapCode()
}

context(_: DefinitionReferences)
private fun FieldShape.nestedConfigurationDescriptor(): CodeBlock =
    CodeBlock.of(
        "%T(%T.%L,♢%L,♢%T::class,♢%T) { nested ->\n⇥%L\n⇤}",
        Api.NestedConfigurationScope,
        RepresentationKind::class,
        representationKind.name,
        configurationExpected.kotlinCode(),
        configurationScope.rawClass,
        expressionFactory,
        configurationScopeCreation("nested", RelativeFieldPattern()),
    )

/**
 * Creates the configuration scope of a value at [pattern] inside [collection]. Generated records get their own Impl
 * over a nested collection; library scopes come from `collection.field(...)`.
 */
context(_: DefinitionReferences)
internal fun FieldShape.configurationScopeCreation(
    collection: String,
    pattern: RelativeFieldPattern,
): CodeBlock =
    if (this is FieldShape.Record) {
        val implementation = names.configurationScopeImpl.parameterizedOrSelf(arguments.map(FieldShape::native))
        if (pattern.segments.isEmpty()) {
            CodeBlock.of("%T(%N)", implementation, collection)
        } else {
            CodeBlock.of("%T(%N.nested(%L))", implementation, collection, pattern.kotlinCode())
        }
    } else {
        CodeBlock.of(
            "%N.field(\n⇥%L,\n%T.%L,\n%L,\n%T::class as %T,\n%L,\n%T,\n⇤)",
            collection,
            pattern.kotlinCode(),
            RepresentationKind::class,
            representationKind.name,
            configurationExpected.kotlinCode(),
            configurationScope.rawClass,
            KClass::class.asClassName().parameterizedBy(configurationScope),
            nestedConfigurationScopes(),
            expressionFactory,
        )
    }

/** Nested slot descriptors of a presentation field, including the fields of a concrete record. */
internal fun FieldShape.nestedPresentationScopes(): CodeBlock {
    val slots =
        when (this) {
            is FieldShape.Nullable -> listOf(Api.NestedPresentationSlotValues to value)
            is FieldShape.Sequence -> listOf(Api.NestedPresentationSlotItems to item)
            is FieldShape.Mapping -> listOf(Api.NestedPresentationSlotKeys to key, Api.NestedPresentationSlotValues to value)
            is FieldShape.Record -> if (abstract) emptyList() else listOf(Api.NestedPresentationSlotFields to this)
            else -> emptyList()
        }
    return slots
        .map { (slot, shape) -> CodeBlock.of("%M", slot) to shape.nestedPresentationDescriptor() }
        .mapCode()
}

private fun FieldShape.nestedPresentationDescriptor(): CodeBlock =
    if (this is FieldShape.Record && !abstract) {
        CodeBlock.of(
            "%T(%T::class as %T,♢create = { nested·->♢%T(nested) })",
            Api.NestedPresentationScope,
            names.presentationScope,
            KClass::class.asClassName().parameterizedBy(presentationScope),
            names.presentationScopeImpl.parameterizedOrSelf(arguments.map(FieldShape::native)),
        )
    } else {
        CodeBlock.of(
            "%T(%T::class as %T,♢nested = %L)",
            Api.NestedPresentationScope,
            presentationControl.rawClass,
            KClass::class.asClassName().parameterizedBy(presentationNested),
            nestedPresentationScopes(),
        )
    }

/** Whether this value's template mentions a type parameter of its owner. */
internal val TypeTemplate.containsParameter: Boolean
    get() =
        when (this) {
            is TypeTemplate.Parameter -> true
            is TypeTemplate.Named -> arguments.any { it.containsParameter }
            is TypeTemplate.Nullable -> value.containsParameter
            is TypeTemplate.Scalar -> false
        }

internal fun RelativeFieldPattern.kotlinCode(): CodeBlock =
    if (segments.isEmpty()) {
        CodeBlock.of("%T()", RelativeFieldPattern::class)
    } else {
        CodeBlock.of("%T(listOf(%L))", RelativeFieldPattern::class, segments.map { it.kotlinCode() }.joinToCode(",♢"))
    }

internal fun FieldPatternSegment.kotlinCode(): CodeBlock =
    when (this) {
        is FieldPatternSegment.Field -> CodeBlock.of("%T(%S)", FieldPatternSegment.Field::class, name)
        FieldPatternSegment.Items -> CodeBlock.of("%T", FieldPatternSegment.Items::class)
        FieldPatternSegment.Keys -> CodeBlock.of("%T", FieldPatternSegment.Keys::class)
        FieldPatternSegment.Values -> CodeBlock.of("%T", FieldPatternSegment.Values::class)
    }

private fun ClassName.factory(): ClassName = peerClass(simpleName + "Factory")

private fun ScalarKind.configurationScope(native: TypeName): TypeName =
    when (this) {
        ScalarKind.Text -> Api.Text
        is ScalarKind.Integer -> Api.Integer.parameterizedBy(native)
        is ScalarKind.Float -> Api.Real.parameterizedBy(native)
        ScalarKind.Decimal -> Api.Decimal
        ScalarKind.Boolean -> Api.BooleanField
        ScalarKind.Bytes -> Api.Bytes
        ScalarKind.Timestamp -> Api.TimestampField
        ScalarKind.Duration -> Api.DurationField
        ScalarKind.Unit -> Api.RecordField.parameterizedBy(UNIT, Api.GenericValueExpressions.parameterizedBy(UNIT))
    }

private fun ScalarKind.expressionScope(native: TypeName): TypeName =
    when (this) {
        ScalarKind.Text -> Api.TextExpressions
        is ScalarKind.Integer, is ScalarKind.Float -> Api.NumberExpressions.parameterizedBy(native.copy(nullable = false))
        ScalarKind.Decimal -> Api.NumberExpressions.parameterizedBy(BigDecimal::class.asTypeName())
        ScalarKind.Boolean -> Api.BooleanExpressions
        ScalarKind.Bytes -> Api.BytesExpressions
        ScalarKind.Timestamp -> Api.TimestampExpressions
        ScalarKind.Duration -> Api.DurationExpressions
        ScalarKind.Unit -> Api.GenericValueExpressions.parameterizedBy(UNIT)
    }

private fun ScalarKind.presentationControl(native: TypeName): TypeName =
    when (this) {
        ScalarKind.Text -> Api.TextControl
        is ScalarKind.Integer, is ScalarKind.Float, ScalarKind.Decimal -> Api.NumberControl.parameterizedBy(native.copy(nullable = false))
        ScalarKind.Boolean -> Api.BooleanControl
        ScalarKind.Bytes -> Api.BytesControl
        ScalarKind.Timestamp -> Api.DateTimeControl
        ScalarKind.Duration -> Api.DurationControl
        ScalarKind.Unit -> Api.Control
    }

internal val ScalarKind.representationKind: RepresentationKind
    get() =
        when (this) {
            ScalarKind.Unit -> RepresentationKind.Unit
            ScalarKind.Boolean -> RepresentationKind.Boolean
            ScalarKind.Text -> RepresentationKind.Text
            ScalarKind.Bytes -> RepresentationKind.Bytes
            is ScalarKind.Integer -> RepresentationKind.Integer
            is ScalarKind.Float -> RepresentationKind.Float
            ScalarKind.Decimal -> RepresentationKind.Decimal
            ScalarKind.Timestamp -> RepresentationKind.Timestamp
            ScalarKind.Duration -> RepresentationKind.Duration
        }

/** A generic draft projection is a function named like the projection object of a non generic declaration. */
internal val SdkNames.draftProjectionFunction: MemberName
    get() = MemberName(draftProjection.packageName, draftProjection.simpleName)
