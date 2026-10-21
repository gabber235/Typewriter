package com.typewritermc.codegen

import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.typewritermc.types.named
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DeclaredTypeId
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.EnumVariant
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import java.util.Collections
import kotlin.reflect.KClass

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
        when (val identity = typeId) {
            is TypeId.DeclaredWrapper -> {
                CodeBlock.of(
                    "%T(%T(value·=·%S))",
                    TypeId.DeclaredWrapper::class,
                    DeclaredTypeId::class,
                    identity.value.value,
                )
            }

            is TypeId.QualifiedWrapper -> {
                CodeBlock.of(
                    "%T.createQualified(namespace·=·%S,♢name·=·%S)",
                    TypeId::class,
                    identity.value.namespace,
                    identity.value.name,
                )
            }

            else -> {
                unknownVariant(identity)
            }
        }
    return CodeBlock.of("%T(typeId·=·%L,♢revision·=·%L)", TypeDefinitionId::class, identity, revision)
}

context(references: DefinitionReferences)
internal fun TypeDefinitionId.kotlinCode(): CodeBlock = references.code(this)

context(_: DefinitionReferences)
internal fun ParameterKey.kotlinCode(): CodeBlock =
    CodeBlock.of("%T(owner·=·%L,♢index·=·%L)", ParameterKey::class, owner.kotlinCode(), index)

context(_: DefinitionReferences)
internal fun TypeUse.kotlinCode(): CodeBlock =
    when (this) {
        is TypeUse.NamedWrapper -> createNamedCode(TypeUse::class, value.definition.kotlinCode(), value.arguments.map { it.kotlinCode() })
        is TypeUse.NullableWrapper -> CodeBlock.of("%T.createNullable(value·=·%L)", TypeUse::class, value.value.kotlinCode())
        is TypeUse.ScalarWrapper -> CodeBlock.of("%T(%L)", TypeUse.ScalarWrapper::class, value.kotlinCode())
        else -> unknownVariant(this)
    }

context(_: DefinitionReferences)
internal fun NamedTypeUse.kotlinCode(): CodeBlock = namedUseCode(definition.kotlinCode(), arguments.map { it.kotlinCode() })

context(_: DefinitionReferences)
internal fun TypeTemplate.kotlinCode(): CodeBlock =
    when (this) {
        is TypeTemplate.NamedWrapper -> {
            createNamedCode(
                TypeTemplate::class,
                value.definition.kotlinCode(),
                value.arguments.map { it.kotlinCode() },
            )
        }

        is TypeTemplate.ParameterWrapper -> {
            CodeBlock.of("%T(%L)", TypeTemplate.ParameterWrapper::class, value.kotlinCode())
        }

        is TypeTemplate.NullableWrapper -> {
            CodeBlock.of("%T.createNullable(value·=·%L)", TypeTemplate::class, value.value.kotlinCode())
        }

        is TypeTemplate.ScalarWrapper -> {
            CodeBlock.of("%T(%L)", TypeTemplate.ScalarWrapper::class, value.kotlinCode())
        }

        else -> {
            unknownVariant(this)
        }
    }

context(_: DefinitionReferences)
internal fun NamedTypeTemplate.kotlinCode(): CodeBlock =
    CodeBlock.of(
        "%T(definition·=·%L,♢arguments·=·%L)",
        NamedTypeTemplate::class,
        definition.kotlinCode(),
        arguments.map { it.kotlinCode() }.listCode(),
    )

/** The complete type use of a template without free parameters. */
context(_: DefinitionReferences)
internal fun TypeTemplate.completeUseCode(): CodeBlock = useCode { error("A free parameter does not form a complete type use") }

/** The complete named application of a template without free parameters. */
context(_: DefinitionReferences)
internal fun NamedTypeTemplate.completeUseCode(): CodeBlock = namedUseCode(definition.kotlinCode(), arguments.map { it.completeUseCode() })

internal fun ScalarKind.kotlinCode(): CodeBlock =
    when (this) {
        ScalarKind.UNIT -> CodeBlock.of("%T", ScalarKind.UNIT::class)
        ScalarKind.BOOLEAN -> CodeBlock.of("%T", ScalarKind.BOOLEAN::class)
        ScalarKind.TEXT -> CodeBlock.of("%T", ScalarKind.TEXT::class)
        ScalarKind.BYTES -> CodeBlock.of("%T", ScalarKind.BYTES::class)
        ScalarKind.DECIMAL -> CodeBlock.of("%T", ScalarKind.DECIMAL::class)
        ScalarKind.TIMESTAMP -> CodeBlock.of("%T", ScalarKind.TIMESTAMP::class)
        ScalarKind.DURATION -> CodeBlock.of("%T", ScalarKind.DURATION::class)
        is ScalarKind.IntegerWrapper -> CodeBlock.of("%T.createInteger(width·=·%L)", ScalarKind::class, value.width.kotlinCode())
        is ScalarKind.FloatWrapper -> CodeBlock.of("%T.createFloat(width·=·%L)", ScalarKind::class, value.width.kotlinCode())
        else -> unknownVariant(this)
    }

private fun IntegerWidth.kotlinCode(): CodeBlock = CodeBlock.of("%T", this::class)

private fun FloatWidth.kotlinCode(): CodeBlock = CodeBlock.of("%T", this::class)

private fun CollectionKind.kotlinCode(): CodeBlock = CodeBlock.of("%T", this::class)

/** `createNamed` of the Skir enum [type], the shortcut for its named variant. */
private fun createNamedCode(
    type: KClass<*>,
    definition: CodeBlock,
    arguments: List<CodeBlock>,
): CodeBlock = CodeBlock.of("%T.createNamed(definition·=·%L,♢arguments·=·%L)", type, definition, arguments.listCode())

private fun namedUseCode(
    definition: CodeBlock,
    arguments: List<CodeBlock>,
): CodeBlock = CodeBlock.of("%T(definition·=·%L,♢arguments·=·%L)", NamedTypeUse::class, definition, arguments.listCode())

/** The type use of this template, with each parameter supplied by [parameter]. */
context(_: DefinitionReferences)
private fun TypeTemplate.useCode(parameter: (ParameterKey) -> CodeBlock): CodeBlock =
    when (this) {
        is TypeTemplate.ParameterWrapper -> {
            parameter(value)
        }

        is TypeTemplate.NamedWrapper -> {
            createNamedCode(TypeUse::class, value.definition.kotlinCode(), value.arguments.map { it.useCode(parameter) })
        }

        is TypeTemplate.NullableWrapper -> {
            CodeBlock.of("%T.createNullable(value·=·%L)", TypeUse::class, value.value.useCode(parameter))
        }

        is TypeTemplate.ScalarWrapper -> {
            CodeBlock.of("%T(%L)", TypeUse.ScalarWrapper::class, value.kotlinCode())
        }

        else -> {
            unknownVariant(this)
        }
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
internal fun TypeTemplate.appliedUseCode(): CodeBlock = useCode { key -> bindings[key] }

/** The named application of this named template with each parameter replaced by its runtime binding. */
context(bindings: TypeParameterBindings, _: DefinitionReferences)
internal fun TypeTemplate.appliedNamedUseCode(): CodeBlock {
    val named = requireNotNull(named) { "Only a named template forms a named application." }
    return namedUseCode(named.definition.kotlinCode(), named.arguments.map { it.useCode { key -> bindings[key] } })
}

context(_: DefinitionReferences)
internal fun TypeParameter.kotlinCode(): CodeBlock =
    CodeBlock.of(
        "%T(key·=·%L,♢name·=·%S,♢bounds·=·%L)",
        TypeParameter::class,
        key.kotlinCode(),
        name,
        bounds.map { it.kotlinCode() }.listCode(),
    )

context(_: DefinitionReferences)
internal fun FieldOwner.kotlinCode(): CodeBlock =
    CodeBlock.of("%T(definition·=·%L,♢name·=·%S)", FieldOwner::class, definition.kotlinCode(), name)

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
        is RepresentationTemplate.ScalarWrapper -> {
            CodeBlock.of("%T.createScalar(kind·=·%L)", RepresentationTemplate::class, value.kind.kotlinCode())
        }

        is RepresentationTemplate.RecordWrapper -> {
            CodeBlock.of(
                "%T.createRecord%L",
                RepresentationTemplate::class,
                namedArguments(
                    "fields" to value.fields.map { it.kotlinCode() }.listCode(),
                    "abstract_" to CodeBlock.of("%L", value.abstract_),
                ),
            )
        }

        is RepresentationTemplate.SequenceWrapper -> {
            CodeBlock.of(
                "%T.createSequence(item·=·%L,♢kind·=·%L)",
                RepresentationTemplate::class,
                value.item.kotlinCode(),
                value.kind.kotlinCode(),
            )
        }

        is RepresentationTemplate.MappingWrapper -> {
            CodeBlock.of(
                "%T.createMapping(key·=·%L,♢value·=·%L)",
                RepresentationTemplate::class,
                value.key.kotlinCode(),
                value.value.kotlinCode(),
            )
        }

        is RepresentationTemplate.EnumerationWrapper -> {
            CodeBlock.of(
                "%T.createEnumeration(cases·=·%L)",
                RepresentationTemplate::class,
                value.cases.map { CodeBlock.of("%T(key·=·%S)", EnumVariant::class, it.key) }.listCode(),
            )
        }

        is RepresentationTemplate.LinkWrapper -> {
            CodeBlock.of(
                "%T.createLink(endpoint·=·%T(value·=·%S),♢target·=·%L)",
                RepresentationTemplate::class,
                EndpointId::class,
                value.endpoint.value,
                value.target.kotlinCode(),
            )
        }

        else -> {
            unknownVariant(this)
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
            is TypeTemplate.NamedWrapper -> {
                ids += template.value.definition
                template.value.arguments.forEach(::visit)
            }

            is TypeTemplate.NullableWrapper -> {
                visit(template.value.value)
            }

            is TypeTemplate.ParameterWrapper -> {
                ids += template.value.owner
            }

            else -> {
                Unit
            }
        }
    }
    parameters.forEach { parameter -> parameter.bounds.forEach(::visit) }
    parents.forEach { parent -> visit(TypeTemplate.NamedWrapper(parent)) }
    when (val representation = representation) {
        is RepresentationTemplate.RecordWrapper -> {
            representation.value.fields.forEach { field ->
                ids += field.owner.definition
                ids += field.overrides.map(FieldOwner::definition)
                visit(field.type)
            }
        }

        is RepresentationTemplate.SequenceWrapper -> {
            visit(representation.value.item)
        }

        is RepresentationTemplate.MappingWrapper -> {
            visit(representation.value.key)
            visit(representation.value.value)
        }

        is RepresentationTemplate.LinkWrapper -> {
            visit(representation.value.target)
        }

        else -> {
            Unit
        }
    }
    return ids
}
