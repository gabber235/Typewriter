package com.typewritermc.codegen

import com.squareup.kotlinpoet.CodeBlock
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.EndpointId
import com.typewritermc.types.EnumVariant
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import java.util.Collections

private fun Iterable<CodeBlock>.listCode(): CodeBlock =
    CodeBlock
        .builder()
        .add("listOf(")
        .apply {
            forEachIndexed { index, value ->
                if (index > 0) add(", ")
                add("%L", value)
            }
        }.add(")")
        .build()

fun String.kotlinLiteral(): CodeBlock = CodeBlock.of("%S", this)

fun TypeDefinitionId.kotlinCode(): CodeBlock {
    val typeCode =
        when (val identity = type) {
            is TypeId.Declared -> CodeBlock.of("%T(%T.parse(%S))", TypeId.Declared::class, DeclaredTypeId::class, identity.id.toString())
            is TypeId.Qualified -> CodeBlock.of("%T(%S, %S)", TypeId.Qualified::class, identity.namespace, identity.name)
        }
    return CodeBlock.of("%T(%L, %L)", TypeDefinitionId::class, typeCode, revision)
}

fun ParameterKey.kotlinCode(): CodeBlock = CodeBlock.of("%T(%L, %L)", ParameterKey::class, owner.kotlinCode(), index)

fun TypeUse.kotlinCode(): CodeBlock =
    when (this) {
        is TypeUse.Named -> {
            CodeBlock.of(
                "%T(%L, %L)",
                TypeUse.Named::class,
                definition.kotlinCode(),
                arguments.map(TypeUse::kotlinCode).listCode(),
            )
        }

        is TypeUse.Nullable -> {
            CodeBlock.of("%T(%L)", TypeUse.Nullable::class, value.kotlinCode())
        }

        is TypeUse.Scalar -> {
            CodeBlock.of("%T(%L)", TypeUse.Scalar::class, kind.kotlinCode())
        }
    }

fun TypeTemplate.kotlinCode(): CodeBlock =
    when (this) {
        is TypeTemplate.Named -> {
            CodeBlock.of(
                "%T(%L, %L)",
                TypeTemplate.Named::class,
                definition.kotlinCode(),
                arguments.map(TypeTemplate::kotlinCode).listCode(),
            )
        }

        is TypeTemplate.Parameter -> {
            CodeBlock.of("%T(%L)", TypeTemplate.Parameter::class, key.kotlinCode())
        }

        is TypeTemplate.Nullable -> {
            CodeBlock.of("%T(%L)", TypeTemplate.Nullable::class, value.kotlinCode())
        }

        is TypeTemplate.Scalar -> {
            CodeBlock.of("%T(%L)", TypeTemplate.Scalar::class, kind.kotlinCode())
        }
    }

fun TypeTemplate.completeUseCode(): CodeBlock =
    when (this) {
        is TypeTemplate.Parameter -> {
            error("A free parameter does not form a complete type use")
        }

        is TypeTemplate.Named -> {
            CodeBlock.of(
                "%T(%L, %L)",
                TypeUse.Named::class,
                definition.kotlinCode(),
                arguments.map(TypeTemplate::completeUseCode).listCode(),
            )
        }

        is TypeTemplate.Nullable -> {
            CodeBlock.of("%T(%L)", TypeUse.Nullable::class, value.completeUseCode())
        }

        is TypeTemplate.Scalar -> {
            CodeBlock.of("%T(%L)", TypeUse.Scalar::class, kind.kotlinCode())
        }
    }

fun TypeTemplate.parameterKeys(): Set<ParameterKey> =
    when (this) {
        is TypeTemplate.Parameter -> setOf(key)
        is TypeTemplate.Named -> arguments.flatMapTo(linkedSetOf()) { it.parameterKeys() }
        is TypeTemplate.Nullable -> value.parameterKeys()
        is TypeTemplate.Scalar -> emptySet()
    }

fun ScalarKind.kotlinCode(): CodeBlock =
    when (this) {
        ScalarKind.Unit -> CodeBlock.of("%T", ScalarKind.Unit::class)
        ScalarKind.Boolean -> CodeBlock.of("%T", ScalarKind.Boolean::class)
        ScalarKind.Text -> CodeBlock.of("%T", ScalarKind.Text::class)
        ScalarKind.Bytes -> CodeBlock.of("%T", ScalarKind.Bytes::class)
        ScalarKind.Decimal -> CodeBlock.of("%T", ScalarKind.Decimal::class)
        ScalarKind.Timestamp -> CodeBlock.of("%T", ScalarKind.Timestamp::class)
        ScalarKind.Duration -> CodeBlock.of("%T", ScalarKind.Duration::class)
        is ScalarKind.Integer -> CodeBlock.of("%T(%T.%L)", ScalarKind.Integer::class, IntegerWidth::class, width.name)
        is ScalarKind.Float -> CodeBlock.of("%T(%T.%L)", ScalarKind.Float::class, FloatWidth::class, width.name)
    }

@JvmInline
value class TypeParameterBindings private constructor(
    private val expressions: Map<ParameterKey, CodeBlock>,
) {
    operator fun get(key: ParameterKey): CodeBlock = requireNotNull(expressions[key]) { "Missing type parameter binding: $key" }

    companion object {
        fun from(expressions: Map<ParameterKey, CodeBlock>): TypeParameterBindings =
            TypeParameterBindings(Collections.unmodifiableMap(LinkedHashMap(expressions)))
    }
}

context(bindings: TypeParameterBindings)
fun TypeTemplate.appliedUseCode(): CodeBlock =
    when (this) {
        is TypeTemplate.Parameter -> {
            bindings[key]
        }

        is TypeTemplate.Named -> {
            CodeBlock.of(
                "%T(%L, %L)",
                TypeUse.Named::class,
                definition.kotlinCode(),
                arguments
                    .map {
                        it.appliedUseCode()
                    }.listCode(),
            )
        }

        is TypeTemplate.Nullable -> {
            CodeBlock.of("%T(%L)", TypeUse.Nullable::class, value.appliedUseCode())
        }

        is TypeTemplate.Scalar -> {
            CodeBlock.of("%T(%L)", TypeUse.Scalar::class, kind.kotlinCode())
        }
    }

fun TypeParameter.kotlinCode(): CodeBlock =
    CodeBlock.of(
        "%T(key = %L, name = %S, bounds = %L)",
        TypeParameter::class,
        key.kotlinCode(),
        name,
        bounds.map(TypeTemplate::kotlinCode).listCode(),
    )

fun FieldOwner.kotlinCode(): CodeBlock = CodeBlock.of("%T(%L, %S)", FieldOwner::class, definition.kotlinCode(), name)

fun FieldDeclaration.kotlinCode(): CodeBlock =
    CodeBlock.of(
        "%T(owner = %L, type = %L, overrides = %L, hasConstructorDefault = %L)",
        FieldDeclaration::class,
        owner.kotlinCode(),
        type.kotlinCode(),
        overrides.map(FieldOwner::kotlinCode).listCode(),
        hasConstructorDefault,
    )

fun RepresentationTemplate.kotlinCode(): CodeBlock =
    when (this) {
        is RepresentationTemplate.Scalar -> {
            CodeBlock.of("%T(%L)", RepresentationTemplate.Scalar::class, kind.kotlinCode())
        }

        is RepresentationTemplate.Record -> {
            CodeBlock.of(
                "%T(fields = %L, abstract = %L)",
                RepresentationTemplate.Record::class,
                fields.map(FieldDeclaration::kotlinCode).listCode(),
                abstract,
            )
        }

        is RepresentationTemplate.Sequence -> {
            CodeBlock.of(
                "%T(%L, %T.%L)",
                RepresentationTemplate.Sequence::class,
                item.kotlinCode(),
                CollectionKind::class,
                kind.name,
            )
        }

        is RepresentationTemplate.Mapping -> {
            CodeBlock.of(
                "%T(%L, %L)",
                RepresentationTemplate.Mapping::class,
                key.kotlinCode(),
                value.kotlinCode(),
            )
        }

        is RepresentationTemplate.Enumeration -> {
            CodeBlock.of(
                "%T(%L)",
                RepresentationTemplate.Enumeration::class,
                cases
                    .map {
                        CodeBlock.of("%T(%S)", EnumVariant::class, it.key)
                    }.listCode(),
            )
        }

        is RepresentationTemplate.Link -> {
            CodeBlock.of(
                "%T(%T(%S), %L)",
                RepresentationTemplate.Link::class,
                EndpointId::class,
                endpoint.value,
                target.kotlinCode(),
            )
        }
    }

fun TypeDefinition.kotlinCode(): CodeBlock =
    CodeBlock.of(
        "%T(id = %L, parameters = %L, representation = %L, parents = %L)",
        TypeDefinition::class,
        id.kotlinCode(),
        parameters.map(TypeParameter::kotlinCode).listCode(),
        representation.kotlinCode(),
        parents.map(TypeTemplate::kotlinCode).listCode(),
    )
