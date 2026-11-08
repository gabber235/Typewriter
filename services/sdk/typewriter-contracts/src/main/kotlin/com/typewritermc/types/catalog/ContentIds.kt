package com.typewritermc.types.catalog

import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.checking.InputIdentity
import com.typewritermc.types.VAR_TYPE_ID
import com.typewritermc.types.declared
import com.typewritermc.types.mapTypes
import com.typewritermc.types.member
import com.typewritermc.types.named
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.ContentKey
import skirout.editor.v1.type_catalog.ContentTypeId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/*
 * Content ids name the resource that declares a type, so a lookup needs no index. A generated key names a declaration
 * on that resource; a field key, which only a use holds, means whatever that field of the resource holds.
 */

/** What the realm's resources say about types. Two reads, so a tracked source records a declaration and a held value as separate facts. */
interface ContentSource {
    /** The declarations [owner] holds; empty when it holds none or does not exist. */
    fun declarations(owner: ResourceId): List<TypeDefinition>

    /** The plain type held directly at [field] of [owner], such as an alias's value. Null when there is none. */
    fun heldType(
        owner: ResourceId,
        field: String,
    ): TypeUse?
}

/** The one source over a record lookup. [observe] records each read; the default records nothing. */
fun contentSourceOf(
    records: (ResourceId) -> AuthoringRecord?,
    observe: (InputIdentity) -> Unit = {},
): ContentSource =
    object : ContentSource {
        override fun declarations(owner: ResourceId): List<TypeDefinition> {
            observe(InputIdentity.Types(owner))
            return records(owner)?.types.orEmpty()
        }

        override fun heldType(
            owner: ResourceId,
            field: String,
        ): TypeUse? {
            observe(InputIdentity.Value(ValueLocation.of(owner, ValuePath.root.field(field))))
            return records(owner)?.heldTypeAt(field)
        }
    }

/** A source over declarations alone, as a compiled artifact carries them. It holds no values, so a field key finds nothing. */
fun contentSourceOf(declarations: List<TypeDefinition>): ContentSource =
    object : ContentSource {
        private val byOwner = declarations.groupBy { checkNotNull(it.id.contentOwner()) { "Only content declarations have an owner." } }

        override fun declarations(owner: ResourceId): List<TypeDefinition> = byOwner[owner].orEmpty()

        override fun heldType(
            owner: ResourceId,
            field: String,
        ): TypeUse? = null
    }

/** The case of Var that holds a value as written. */
private val VAR_VALUE_CASE: TypeDefinitionId = TypeDefinitionId.declared(VAR_TYPE_ID).member("Value")

/** The plain type_use the field [field] holds, through Var.Value when it is one; null for any other value. */
fun AuthoringRecord.heldTypeAt(field: String): TypeUse? {
    val held = fields.firstOrNull { it.name == field }?.value ?: return null
    (held as? DataValue.TypeUseWrapper)?.let { return it.value }
    val named = held as? DataValue.NamedWrapper ?: return null
    if (named.value.actualType.definition != VAR_VALUE_CASE) return null
    val inner =
        (named.value.payload as? DataValue.RecordWrapper)
            ?.value
            ?.fields
            ?.firstOrNull { it.name == "value" }
            ?.value
    return (inner as? DataValue.TypeUseWrapper)?.value
}

/** The id of the declaration [key] on [resource]. */
fun TypeDefinitionId.Companion.content(
    resource: ResourceId,
    key: String,
): TypeDefinitionId =
    TypeDefinitionId(
        typeId = TypeId.ContentWrapper(ContentTypeId(resource = resource, key = ContentKey.GeneratedWrapper(key))),
        revision = 1,
    )

/** The id that means whatever the field [field] of [resource] holds. Only a use holds one. */
fun TypeDefinitionId.Companion.contentField(
    resource: ResourceId,
    field: String,
): TypeDefinitionId =
    TypeDefinitionId(
        typeId = TypeId.ContentWrapper(ContentTypeId(resource = resource, key = ContentKey.FieldWrapper(field))),
        revision = 1,
    )

/** The resource that declares this id, through the owner of a member; null for a code id. */
fun TypeDefinitionId.contentOwner(): ResourceId? = typeId.contentOwner()

private fun TypeId.contentOwner(): ResourceId? =
    when (this) {
        is TypeId.ContentWrapper -> value.resource
        is TypeId.MemberWrapper -> value.owner.contentOwner()
        else -> null
    }

/** The field key this id names directly, or null. */
fun TypeDefinitionId.fieldKey(): String? = ((typeId as? TypeId.ContentWrapper)?.value?.key as? ContentKey.FieldWrapper)?.value

/** Whether this id, or the owner of a member, names a field key, so a case of a union named through a field is covered. */
fun TypeDefinitionId.namesFieldKey(): Boolean = typeId.namesFieldKey()

private fun TypeId.namesFieldKey(): Boolean =
    when (this) {
        is TypeId.ContentWrapper -> value.key is ContentKey.FieldWrapper
        is TypeId.MemberWrapper -> value.owner.namesFieldKey()
        else -> false
    }

/** Whether this use names a content type anywhere. */
fun TypeUse.mentionsContent(): Boolean = referencedDefinitions().any { it.contentOwner() != null }

/** Rebuilds the use, outermost first: [replace] answers a replacement for a named use, or null to keep it and visit its arguments. */
fun TypeUse.mapNamed(replace: (NamedTypeUse) -> TypeUse?): TypeUse = mapTypes { use -> use.named?.let(replace) }

/** This id with every content resource that [copies] maps replaced by its copy, through the owner of a member. */
fun TypeDefinitionId.remappingContent(copies: Map<ResourceId, ResourceId>): TypeDefinitionId =
    if (contentOwner() in copies) copy(typeId = typeId.remappingContent(copies)) else this

private fun TypeId.remappingContent(copies: Map<ResourceId, ResourceId>): TypeId =
    when (this) {
        is TypeId.ContentWrapper -> TypeId.ContentWrapper(value.copy(resource = copies[value.resource] ?: value.resource))
        is TypeId.MemberWrapper -> TypeId.MemberWrapper(value.copy(owner = value.owner.remappingContent(copies)))
        else -> this
    }

/** This use with every content id remapped by [copies]. */
fun TypeUse.remappingContent(copies: Map<ResourceId, ResourceId>): TypeUse =
    mapNamed { named ->
        TypeUse.NamedWrapper(
            NamedTypeUse(
                definition = named.definition.remappingContent(copies),
                arguments = named.arguments.map { it.remappingContent(copies) },
            ),
        )
    }

private fun NamedTypeUse.remappingContent(copies: Map<ResourceId, ResourceId>): NamedTypeUse =
    (TypeUse.NamedWrapper(this).remappingContent(copies) as TypeUse.NamedWrapper).value

private fun TypeTemplate.remappingContent(copies: Map<ResourceId, ResourceId>): TypeTemplate =
    mapTypes { template ->
        when (template) {
            is TypeTemplate.NamedWrapper -> TypeTemplate.NamedWrapper(template.value.remappingContent(copies))
            is TypeTemplate.ParameterWrapper -> TypeTemplate.ParameterWrapper(template.value.copy(owner = template.value.owner.remappingContent(copies)))
            else -> null
        }
    }

private fun NamedTypeTemplate.remappingContent(copies: Map<ResourceId, ResourceId>): NamedTypeTemplate =
    NamedTypeTemplate(definition = definition.remappingContent(copies), arguments = arguments.map { it.remappingContent(copies) })

private fun FieldOwner.remappingContent(copies: Map<ResourceId, ResourceId>): FieldOwner =
    copy(definition = definition.remappingContent(copies))

/** This declaration with every content id it holds remapped by [copies]: its own, its fields', parents', cases' and templates'. */
fun TypeDefinition.remappingContent(copies: Map<ResourceId, ResourceId>): TypeDefinition {
    val representation =
        when (val shape = representation) {
            is RepresentationTemplate.RecordWrapper -> {
                val record = shape.value
                val form =
                    (record.form as? RecordForm.ClosedWrapper)?.let { closed ->
                        RecordForm.createClosed(cases = closed.value.cases.map { it.remappingContent(copies) })
                    } ?: record.form
                RepresentationTemplate.createRecord(
                    fields =
                        record.fields.map { field ->
                            field.copy(
                                owner = field.owner.remappingContent(copies),
                                type = field.type.remappingContent(copies),
                                overrides = field.overrides.map { it.remappingContent(copies) },
                            )
                        },
                    form = form,
                )
            }

            is RepresentationTemplate.SequenceWrapper -> {
                RepresentationTemplate.createSequence(item = shape.value.item.remappingContent(copies), kind = shape.value.kind)
            }

            is RepresentationTemplate.MappingWrapper -> {
                RepresentationTemplate.createMapping(
                    key = shape.value.key.remappingContent(copies),
                    value = shape.value.value.remappingContent(copies),
                )
            }

            is RepresentationTemplate.LinkWrapper -> {
                RepresentationTemplate.createLink(endpoint = shape.value.endpoint, target = shape.value.target.remappingContent(copies))
            }

            else -> {
                shape
            }
        }
    return copy(
        id = id.remappingContent(copies),
        parameters =
            parameters.map { parameter ->
                parameter.copy(
                    key = parameter.key.copy(owner = parameter.key.owner.remappingContent(copies)),
                    bounds = parameter.bounds.map { it.remappingContent(copies) },
                )
            },
        representation = representation,
        parents = parents.map { it.remappingContent(copies) },
    )
}

/** This value with every content id in its actual types and held types remapped by [copies]. */
fun DataValue.remappingContent(copies: Map<ResourceId, ResourceId>): DataValue = mapTypeUses { it.remappingContent(copies) }

/**
 * This value with [transform] applied to every type it holds: each named value's actual type and each held type. An
 * actual type stays named, so [transform] keeps a named use named.
 */
fun DataValue.mapTypeUses(transform: (TypeUse) -> TypeUse): DataValue =
    when (this) {
        is DataValue.TypeUseWrapper -> {
            DataValue.TypeUseWrapper(transform(value))
        }

        is DataValue.NamedWrapper -> {
            val actual = (transform(TypeUse.NamedWrapper(value.actualType)) as? TypeUse.NamedWrapper)?.value ?: value.actualType
            DataValue.createNamed(actualType = actual, payload = value.payload.mapTypeUses(transform))
        }

        is DataValue.RecordWrapper -> {
            DataValue.createRecord(fields = value.fields.map { it.copy(value = it.value.mapTypeUses(transform)) })
        }

        is DataValue.ListValueWrapper -> {
            DataValue.createListValue(items = value.items.map { it.copy(value = it.value.mapTypeUses(transform)) })
        }

        is DataValue.SetValueWrapper -> {
            DataValue.createSetValue(items = value.items.map { it.copy(value = it.value.mapTypeUses(transform)) })
        }

        is DataValue.MapValueWrapper -> {
            DataValue.createMapValue(
                rows = value.rows.map { it.copy(key = it.key.mapTypeUses(transform), value = it.value.mapTypeUses(transform)) },
            )
        }

        else -> {
            this
        }
    }

/** This record with every content id remapped by [copies], so a copy's users point at the copied types. */
fun AuthoringRecord.remappingContent(copies: Map<ResourceId, ResourceId>): AuthoringRecord =
    AuthoringRecord(
        configuration =
            when (val selection = configuration) {
                is TypeSelection.CompleteWrapper -> {
                    TypeSelection.CompleteWrapper(selection.value.remappingContent(copies))
                }

                is TypeSelection.PendingWrapper -> {
                    TypeSelection.createPending(
                        definition = selection.value.definition,
                        arguments =
                            selection.value.arguments.map { argument ->
                                (argument as? ArgumentSelection.ChosenWrapper)?.let {
                                    ArgumentSelection.ChosenWrapper(
                                        it.value.remappingContent(copies),
                                    )
                                }
                                    ?: argument
                            },
                    )
                }

                else -> {
                    selection
                }
            },
        fields = fields.map { it.copy(value = it.value.remappingContent(copies)) },
        types = types.map { it.remappingContent(copies) },
    )
