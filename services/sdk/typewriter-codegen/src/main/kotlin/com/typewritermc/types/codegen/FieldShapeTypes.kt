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
import com.typewritermc.codegen.appliedNamedUseCode
import com.typewritermc.codegen.appliedUseCode
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.codegen.mapCode
import com.typewritermc.configuration.name
import com.typewritermc.configuration.root
import com.typewritermc.types.nullable
import com.typewritermc.types.template
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
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
                    CollectionKind.LIST -> {
                        Api.ListField.parameterizedBy(item.configurationValue, item.configurationScope, item.expressionScope)
                    }

                    CollectionKind.SET -> {
                        Api.SetField.parameterizedBy(item.configurationValue, item.configurationScope)
                    }

                    else -> {
                        unknownVariant(kind)
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
            is FieldShape.Nullable -> value.configurationExpected.nullable()
            is FieldShape.Wrapped -> kind.template
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
                    CollectionKind.LIST -> Api.ListExpressions.parameterizedBy(item.native)
                    CollectionKind.SET -> Api.SetExpressions.parameterizedBy(item.native)
                    else -> unknownVariant(kind)
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
                    kind == CollectionKind.LIST && item is FieldShape.Link -> Api.ResourcesControl.parameterizedBy(item.target)
                    kind == CollectionKind.LIST -> Api.ListControl.parameterizedBy(item.presentationNested)
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
            is FieldShape.Link -> RepresentationKind.LINK
            is FieldShape.Sequence -> if (kind == CollectionKind.LIST) RepresentationKind.LIST else RepresentationKind.SET
            is FieldShape.Mapping -> RepresentationKind.MAP
            is FieldShape.Enumeration -> RepresentationKind.ENUMERATION
            is FieldShape.Record, is FieldShape.Parameter -> RepresentationKind.RECORD
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
            (if (kind == CollectionKind.LIST) Api.DraftList else Api.DraftSet).parameterizedBy(item.draftType(draftVariables))
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
                if (kind == CollectionKind.LIST) Api.listDraftProjection else Api.setDraftProjection,
                template.appliedNamedUseCode(),
                item.draftProjection(),
            )
        }

        is FieldShape.Mapping -> {
            CodeBlock.of(
                "%M(%L,♢%L,♢%L)",
                Api.mapDraftProjection,
                template.appliedNamedUseCode(),
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
        template.appliedNamedUseCode(),
        TypeUse.ScalarWrapper::class,
        kind.kotlinCode(),
    )

/** Nested slot descriptors of a configuration field: nullable values, collection items, map keys and values. */
context(_: DefinitionReferences)
internal fun FieldShape.nestedConfigurationScopes(): CodeBlock {
    val slots =
        when (this) {
            is FieldShape.Nullable -> listOf(FieldPatternSegment.VALUES to value)
            is FieldShape.Sequence -> listOf(FieldPatternSegment.ITEMS to item)
            is FieldShape.Mapping -> listOf(FieldPatternSegment.KEYS to key, FieldPatternSegment.VALUES to value)
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
        representationKind.constant,
        configurationExpected.kotlinCode(),
        configurationScope.rawClass,
        expressionFactory,
        configurationScopeCreation("nested", RelativeFieldPattern.root),
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
            representationKind.constant,
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
            is TypeTemplate.ParameterWrapper -> true
            is TypeTemplate.NamedWrapper -> value.arguments.any { it.containsParameter }
            is TypeTemplate.NullableWrapper -> value.value.containsParameter
            is TypeTemplate.ScalarWrapper -> false
            else -> unknownVariant(this)
        }

internal fun RelativeFieldPattern.kotlinCode(): CodeBlock =
    if (segments.isEmpty()) {
        CodeBlock.of("%T.%M", RelativeFieldPattern::class, ROOT_PATTERN)
    } else {
        CodeBlock.of("%T(segments = listOf(%L))", RelativeFieldPattern::class, segments.map { it.kotlinCode() }.joinToCode(",♢"))
    }

internal fun FieldPatternSegment.kotlinCode(): CodeBlock =
    when (this) {
        is FieldPatternSegment.FieldWrapper -> CodeBlock.of("%T.%M(%S)", FieldPatternSegment::class, FIELD_SEGMENT, name)
        FieldPatternSegment.ITEMS -> CodeBlock.of("%T.ITEMS", FieldPatternSegment::class)
        FieldPatternSegment.KEYS -> CodeBlock.of("%T.KEYS", FieldPatternSegment::class)
        FieldPatternSegment.VALUES -> CodeBlock.of("%T.VALUES", FieldPatternSegment::class)
        else -> unknownVariant(this)
    }

/** The name of the generated constant of this representation kind, which emitted code refers to. */
internal val RepresentationKind.constant: String get() = kind.name.removeSuffix("_CONST")

private val ROOT_PATTERN = MemberName("com.typewritermc.configuration", "root", isExtension = true)

private val FIELD_SEGMENT = MemberName("com.typewritermc.configuration", "field", isExtension = true)

private fun ClassName.factory(): ClassName = peerClass(simpleName + "Factory")

private fun ScalarKind.configurationScope(native: TypeName): TypeName =
    when (this) {
        ScalarKind.TEXT -> Api.Text
        is ScalarKind.IntegerWrapper -> Api.Integer.parameterizedBy(native)
        is ScalarKind.FloatWrapper -> Api.Real.parameterizedBy(native)
        ScalarKind.DECIMAL -> Api.Decimal
        ScalarKind.BOOLEAN -> Api.BooleanField
        ScalarKind.BYTES -> Api.Bytes
        ScalarKind.TIMESTAMP -> Api.TimestampField
        ScalarKind.DURATION -> Api.DurationField
        ScalarKind.UNIT -> Api.RecordField.parameterizedBy(UNIT, Api.GenericValueExpressions.parameterizedBy(UNIT))
        else -> unknownVariant(this)
    }

private fun ScalarKind.expressionScope(native: TypeName): TypeName =
    when (this) {
        ScalarKind.TEXT -> Api.TextExpressions
        is ScalarKind.IntegerWrapper, is ScalarKind.FloatWrapper -> Api.NumberExpressions.parameterizedBy(native.copy(nullable = false))
        ScalarKind.DECIMAL -> Api.NumberExpressions.parameterizedBy(BigDecimal::class.asTypeName())
        ScalarKind.BOOLEAN -> Api.BooleanExpressions
        ScalarKind.BYTES -> Api.BytesExpressions
        ScalarKind.TIMESTAMP -> Api.TimestampExpressions
        ScalarKind.DURATION -> Api.DurationExpressions
        ScalarKind.UNIT -> Api.GenericValueExpressions.parameterizedBy(UNIT)
        else -> unknownVariant(this)
    }

private fun ScalarKind.presentationControl(native: TypeName): TypeName =
    when (this) {
        ScalarKind.TEXT -> {
            Api.TextControl
        }

        is ScalarKind.IntegerWrapper, is ScalarKind.FloatWrapper, ScalarKind.DECIMAL -> {
            Api.NumberControl.parameterizedBy(
                native.copy(nullable = false),
            )
        }

        ScalarKind.BOOLEAN -> {
            Api.BooleanControl
        }

        ScalarKind.BYTES -> {
            Api.BytesControl
        }

        ScalarKind.TIMESTAMP -> {
            Api.DateTimeControl
        }

        ScalarKind.DURATION -> {
            Api.DurationControl
        }

        ScalarKind.UNIT -> {
            Api.Control
        }

        else -> {
            unknownVariant(this)
        }
    }

internal val ScalarKind.representationKind: RepresentationKind
    get() =
        when (this) {
            ScalarKind.UNIT -> RepresentationKind.UNIT
            ScalarKind.BOOLEAN -> RepresentationKind.BOOLEAN
            ScalarKind.TEXT -> RepresentationKind.TEXT
            ScalarKind.BYTES -> RepresentationKind.BYTES
            is ScalarKind.IntegerWrapper -> RepresentationKind.INTEGER
            is ScalarKind.FloatWrapper -> RepresentationKind.FLOAT
            ScalarKind.DECIMAL -> RepresentationKind.DECIMAL
            ScalarKind.TIMESTAMP -> RepresentationKind.TIMESTAMP
            ScalarKind.DURATION -> RepresentationKind.DURATION
            else -> unknownVariant(this)
        }

/** A generic draft projection is a function named like the projection object of a non generic declaration. */
internal val SdkNames.draftProjectionFunction: MemberName
    get() = MemberName(draftProjection.packageName, draftProjection.simpleName)
