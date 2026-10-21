package com.typewritermc.codegen

import com.squareup.kotlinpoet.ClassName
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

/** `emptyList()` when empty, inline for one item, otherwise one item per line. */
internal fun Iterable<CodeBlock>.listCode(): CodeBlock {
    val items = toList()
    return when (items.size) {
        0 -> {
            CodeBlock.of("emptyList()")
        }

        1 -> {
            CodeBlock.of("listOf(%L)", items.single())
        }

        else -> {
            CodeBlock
                .builder()
                .add("listOf(\n⇥")
                .apply { items.forEach { add("%L,\n", it) } }
                .add("⇤)")
                .build()
        }
    }
}

/** `emptySet()` when empty, otherwise `setOf(...)` with the same layout as [listCode]. */
internal fun Iterable<CodeBlock>.setCode(): CodeBlock {
    val items = toList()
    return when (items.size) {
        0 -> {
            CodeBlock.of("emptySet()")
        }

        1 -> {
            CodeBlock.of("setOf(%L)", items.single())
        }

        else -> {
            CodeBlock
                .builder()
                .add("setOf(\n⇥")
                .apply { items.forEach { add("%L,\n", it) } }
                .add("⇤)")
                .build()
        }
    }
}

/** `emptyMap()` when empty, otherwise one `key to value` entry per line. */
internal fun Iterable<Pair<CodeBlock, CodeBlock>>.mapCode(): CodeBlock {
    val entries = toList()
    if (entries.isEmpty()) return CodeBlock.of("emptyMap()")
    return CodeBlock
        .builder()
        .add("mapOf(\n⇥")
        .apply { entries.forEach { (key, value) -> add("%L to %L,\n", key, value) } }
        .add("⇤)")
        .build()
}

/** Renders named constructor arguments one per line, so generated declarations stay readable. */
internal fun namedArguments(vararg arguments: Pair<String, CodeBlock>): CodeBlock =
    CodeBlock
        .builder()
        .add("(\n⇥")
        .apply { arguments.forEach { (name, value) -> add("%N = %L,\n", name, value) } }
        .add("⇤)")
        .build()

/**
 * Resolves each type definition id to the generated object that states it, so generated code writes every id once.
 *
 * Inside an owner object its own id is the bare `id`; everywhere else it is `Owner.id`. Callers build the owner table
 * before emission and report ids without an owner as declaration diagnostics, so [code] never meets an unknown id.
 */
internal class DefinitionReferences(
    private val owners: Map<TypeDefinitionId, ClassName>,
    private val self: TypeDefinitionId? = null,
) {
    fun code(id: TypeDefinitionId): CodeBlock =
        when (id) {
            self -> CodeBlock.of("id")
            in owners -> CodeBlock.of("%T.id", owners.getValue(id))
            else -> error("No generated definition owns $id.")
        }

    /** References as seen from inside the owner of [definition]. */
    fun inside(definition: TypeDefinitionId): DefinitionReferences = DefinitionReferences(owners, definition)
}

/** The single literal statement of an id, used only for an owner's own `id` property. */
internal fun TypeDefinitionId.declarationCode(): CodeBlock {
    val identity =
        when (val identity = type) {
            is TypeId.Declared -> CodeBlock.of("%T(%T.parse(%S))", TypeId.Declared::class, DeclaredTypeId::class, identity.id.toString())
            is TypeId.Qualified -> CodeBlock.of("%T(%S,♢%S)", TypeId.Qualified::class, identity.namespace, identity.name)
        }
    return CodeBlock.of("%T(%L,♢%L)", TypeDefinitionId::class, identity, revision)
}

context(references: DefinitionReferences)
internal fun TypeDefinitionId.kotlinCode(): CodeBlock = references.code(this)

context(_: DefinitionReferences)
internal fun ParameterKey.kotlinCode(): CodeBlock = CodeBlock.of("%T(%L,♢%L)", ParameterKey::class, owner.kotlinCode(), index)

context(_: DefinitionReferences)
internal fun TypeUse.kotlinCode(): CodeBlock =
    when (this) {
        is TypeUse.Named -> {
            CodeBlock.of(
                "%T(%L,♢%L)",
                TypeUse.Named::class,
                definition.kotlinCode(),
                arguments.map { it.kotlinCode() }.listCode(),
            )
        }

        is TypeUse.Nullable -> {
            CodeBlock.of("%T(%L)", TypeUse.Nullable::class, value.kotlinCode())
        }

        is TypeUse.Scalar -> {
            CodeBlock.of("%T(%L)", TypeUse.Scalar::class, kind.kotlinCode())
        }
    }

context(_: DefinitionReferences)
internal fun TypeTemplate.kotlinCode(): CodeBlock =
    when (this) {
        is TypeTemplate.Named -> {
            CodeBlock.of("%T(%L,♢%L)", TypeTemplate.Named::class, definition.kotlinCode(), arguments.map { it.kotlinCode() }.listCode())
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

/** The complete type use of a template without free parameters. */
context(_: DefinitionReferences)
internal fun TypeTemplate.completeUseCode(): CodeBlock =
    when (this) {
        is TypeTemplate.Parameter -> {
            error("A free parameter does not form a complete type use")
        }

        is TypeTemplate.Named -> {
            CodeBlock.of("%T(%L,♢%L)", TypeUse.Named::class, definition.kotlinCode(), arguments.map { it.completeUseCode() }.listCode())
        }

        is TypeTemplate.Nullable -> {
            CodeBlock.of("%T(%L)", TypeUse.Nullable::class, value.completeUseCode())
        }

        is TypeTemplate.Scalar -> {
            CodeBlock.of("%T(%L)", TypeUse.Scalar::class, kind.kotlinCode())
        }
    }

internal fun ScalarKind.kotlinCode(): CodeBlock =
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

/** Kotlin expressions that supply the runtime type use of each type parameter. */
@JvmInline
internal value class TypeParameterBindings private constructor(
    private val expressions: Map<ParameterKey, CodeBlock>,
) {
    operator fun get(key: ParameterKey): CodeBlock = requireNotNull(expressions[key]) { "Missing type parameter binding: $key" }

    companion object {
        fun from(expressions: Map<ParameterKey, CodeBlock>): TypeParameterBindings =
            TypeParameterBindings(Collections.unmodifiableMap(LinkedHashMap(expressions)))
    }
}

/** The type use of this template with each parameter replaced by its runtime binding. */
context(bindings: TypeParameterBindings, _: DefinitionReferences)
internal fun TypeTemplate.appliedUseCode(): CodeBlock =
    when (this) {
        is TypeTemplate.Parameter -> {
            bindings[key]
        }

        is TypeTemplate.Named -> {
            CodeBlock.of("%T(%L,♢%L)", TypeUse.Named::class, definition.kotlinCode(), arguments.map { it.appliedUseCode() }.listCode())
        }

        is TypeTemplate.Nullable -> {
            CodeBlock.of("%T(%L)", TypeUse.Nullable::class, value.appliedUseCode())
        }

        is TypeTemplate.Scalar -> {
            CodeBlock.of("%T(%L)", TypeUse.Scalar::class, kind.kotlinCode())
        }
    }

context(_: DefinitionReferences)
internal fun TypeParameter.kotlinCode(): CodeBlock =
    CodeBlock.of(
        "%T(key = %L,♢name = %S,♢bounds = %L)",
        TypeParameter::class,
        key.kotlinCode(),
        name,
        bounds.map { it.kotlinCode() }.listCode(),
    )

context(_: DefinitionReferences)
internal fun FieldOwner.kotlinCode(): CodeBlock = CodeBlock.of("%T(%L,♢%S)", FieldOwner::class, definition.kotlinCode(), name)

context(_: DefinitionReferences)
internal fun FieldDeclaration.kotlinCode(): CodeBlock =
    CodeBlock.of(
        "%T%L",
        FieldDeclaration::class,
        namedArguments(
            "owner" to owner.kotlinCode(),
            "type" to type.kotlinCode(),
            "overrides" to overrides.map { it.kotlinCode() }.listCode(),
            "hasConstructorDefault" to CodeBlock.of("%L", hasConstructorDefault),
        ),
    )

context(_: DefinitionReferences)
internal fun RepresentationTemplate.kotlinCode(): CodeBlock =
    when (this) {
        is RepresentationTemplate.Scalar -> {
            CodeBlock.of("%T(%L)", RepresentationTemplate.Scalar::class, kind.kotlinCode())
        }

        is RepresentationTemplate.Record -> {
            CodeBlock.of(
                "%T%L",
                RepresentationTemplate.Record::class,
                namedArguments(
                    "fields" to fields.map { it.kotlinCode() }.listCode(),
                    "abstract" to CodeBlock.of("%L", abstract),
                ),
            )
        }

        is RepresentationTemplate.Sequence -> {
            CodeBlock.of("%T(%L,♢%T.%L)", RepresentationTemplate.Sequence::class, item.kotlinCode(), CollectionKind::class, kind.name)
        }

        is RepresentationTemplate.Mapping -> {
            CodeBlock.of("%T(%L,♢%L)", RepresentationTemplate.Mapping::class, key.kotlinCode(), value.kotlinCode())
        }

        is RepresentationTemplate.Enumeration -> {
            CodeBlock.of(
                "%T(%L)",
                RepresentationTemplate.Enumeration::class,
                cases.map { CodeBlock.of("%T(%S)", EnumVariant::class, it.key) }.listCode(),
            )
        }

        is RepresentationTemplate.Link -> {
            CodeBlock.of("%T(%T(%S),♢%L)", RepresentationTemplate.Link::class, EndpointId::class, endpoint.value, target.kotlinCode())
        }
    }

context(_: DefinitionReferences)
internal fun TypeDefinition.kotlinCode(): CodeBlock =
    CodeBlock.of(
        "%T%L",
        TypeDefinition::class,
        namedArguments(
            "id" to id.kotlinCode(),
            "parameters" to parameters.map { it.kotlinCode() }.listCode(),
            "representation" to representation.kotlinCode(),
            "parents" to parents.map { it.kotlinCode() }.listCode(),
        ),
    )

/** Every definition id a definition mentions: its own, parents, field types, overrides, parameter bounds and links. */
internal fun TypeDefinition.referencedIds(): Set<TypeDefinitionId> {
    val ids = linkedSetOf(id)

    fun visit(template: TypeTemplate) {
        when (template) {
            is TypeTemplate.Named -> {
                ids += template.definition
                template.arguments.forEach(::visit)
            }

            is TypeTemplate.Nullable -> {
                visit(template.value)
            }

            is TypeTemplate.Parameter -> {
                ids += template.key.owner
            }

            is TypeTemplate.Scalar -> {
                Unit
            }
        }
    }
    parameters.forEach { parameter -> parameter.bounds.forEach(::visit) }
    parents.forEach(::visit)
    when (val representation = representation) {
        is RepresentationTemplate.Record -> {
            representation.fields.forEach { field ->
                ids += field.owner.definition
                ids += field.overrides.map(FieldOwner::definition)
                visit(field.type)
            }
        }

        is RepresentationTemplate.Sequence -> {
            visit(representation.item)
        }

        is RepresentationTemplate.Mapping -> {
            visit(representation.key)
            visit(representation.value)
        }

        is RepresentationTemplate.Link -> {
            visit(representation.target)
        }

        is RepresentationTemplate.Enumeration, is RepresentationTemplate.Scalar -> {
            Unit
        }
    }
    return ids
}
