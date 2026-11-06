package com.typewritermc.types.catalog

import com.typewritermc.authoring.Misfit
import com.typewritermc.authoring.of
import com.typewritermc.authoring.structuralMisfits
import com.typewritermc.types.closedCases
import com.typewritermc.types.use
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

/*
 * The rules declarations obey. The structural ones hold for code and content alike, so a finding reads the same for
 * both; the creator rules hold only for what a resource declares, which arrives from clients and is checked where the
 * catalog overlay first reaches it.
 */

/** The codes that say why a content type stands in as the error type. */
val CONTENT_TYPE_PROBLEMS: Set<String> =
    setOf(
        "content_type_missing",
        "content_alias_loop",
        "declaration_owner_mismatch",
        "declaration_revision",
        "declaration_has_parameters",
        "declaration_key",
        "declaration_parent",
        "declaration_open_form",
        "declaration_field_form",
        "duplicate_definition",
        "duplicate_field",
        "invalid_field_owner",
        "not_a_listed_case",
        "case_missing_parent",
        "inheritance_cycle",
        "argument_bound",
    )

/** The structural rules both catalogs share, pure over one declaration list: codes per declaration, absent when it has none. */
fun List<TypeDefinition>.structuralProblems(): Map<TypeDefinitionId, List<String>> {
    val byId = groupBy { it.id }
    val single = byId.filterValues { it.size == 1 }.mapValues { it.value.single() }
    val cycles = single.inheritanceCycles()
    return byId
        .mapValues { (id, found) ->
            buildList {
                if (found.size > 1) {
                    add("duplicate_definition")
                    return@buildList
                }
                val definition = found.single()
                val fields = definition.recordFields()
                if (fields.map { it.owner.name }.distinct().size != fields.size) add("duplicate_field")
                if (fields.any { it.owner.definition != id }) add("invalid_field_owner")
                definition.parents.forEach { parent ->
                    val cases = single[parent.definition]?.closedCases() ?: return@forEach
                    if (cases.none { it.definition == id }) add("not_a_listed_case")
                }
                definition.closedCases()?.forEach { case ->
                    val listed = single[case.definition] ?: return@forEach
                    if (listed.parents.none { it.definition == id }) add("case_missing_parent")
                }
                if (id in cycles) add("inheritance_cycle")
            }.distinct()
        }.filterValues { it.isNotEmpty() }
}

/** The ids on a parent cycle. */
private fun Map<TypeDefinitionId, TypeDefinition>.inheritanceCycles(): Set<TypeDefinitionId> {
    val onCycle = mutableSetOf<TypeDefinitionId>()
    val visiting = linkedSetOf<TypeDefinitionId>()
    val visited = mutableSetOf<TypeDefinitionId>()

    fun visit(id: TypeDefinitionId) {
        if (id in visiting) {
            onCycle += visiting.dropWhile { it != id }
            return
        }
        if (!visited.add(id)) return
        val definition = this[id] ?: return
        visiting += id
        definition.parents.forEach { visit(it.definition) }
        visiting -= id
    }
    keys.forEach(::visit)
    return onCycle
}

/**
 * Codes per declaration that a creator may not set: the shared structural rules, then the ones only creators have.
 * A declaration that obeys them is absent.
 */
fun List<TypeDefinition>.declarationProblems(owner: ResourceId): Map<TypeDefinitionId, List<String>> {
    val shared = structuralProblems()
    val unions = filter { it.closedCases() != null }.mapTo(hashSetOf()) { it.id }
    return associate { definition ->
        definition.id to
            (
                shared[definition.id].orEmpty() +
                    buildList {
                        if (definition.id.contentOwner() != owner) add("declaration_owner_mismatch")
                        if (definition.id.revision != 1) add("declaration_revision")
                        if (definition.parameters.isNotEmpty()) add("declaration_has_parameters")
                        // A field key only appears in a use, where it means what that field holds.
                        if (definition.id.namesFieldKey()) add("declaration_key")
                        // A parent is only a closed union declared on this resource; the shared rules check that it lists this case.
                        if (definition.parents.any { it.definition !in unions }) add("declaration_parent")
                        if (definition.recordForm() == RecordForm.OPEN) add("declaration_open_form")
                        if (definition.recordFields().any { it.overrides.isNotEmpty() || it.hasConstructorDefault }) {
                            add(
                                "declaration_field_form",
                            )
                        }
                    }
            ).distinct()
    }.filterValues { it.isNotEmpty() }
}

private fun TypeDefinition.recordFields(): List<FieldDeclaration> =
    (representation as? RepresentationTemplate.RecordWrapper)
        ?.value
        ?.fields
        .orEmpty()

private fun TypeDefinition.recordForm(): RecordForm? = (representation as? RepresentationTemplate.RecordWrapper)?.value?.form

/** Null when the declaration is not a closed union, so an open or concrete parent is skipped. */
private fun TypeDefinition.closedCases(): List<NamedTypeTemplate>? = representation.closedCases()

/**
 * One problem at the root of [owner] per declaration this record may not store, used or not: an id that names another
 * resource (declaration_owner_mismatch) or a field key, which only a use may name (declaration_key).
 */
fun AuthoringRecord.misfiledDeclarations(owner: ResourceId): List<ValueProblem> =
    types
        .flatMap { definition ->
            buildList {
                if (definition.id.contentOwner() != owner) add("declaration_owner_mismatch")
                if (definition.id.namesFieldKey()) add("declaration_key")
            }
        }.distinct()
        .map { ValueProblem(location = ValueLocation.of(owner), code = it) }

/** The use the configuration names, with each chosen argument of a pending one; null for a pending one with none chosen. */
fun TypeSelection.uses(): List<TypeUse> =
    when (this) {
        is TypeSelection.CompleteWrapper -> listOf(value.use)
        is TypeSelection.PendingWrapper -> value.arguments.mapNotNull { (it as? ArgumentSelection.ChosenWrapper)?.value }
        else -> emptyList()
    }

/** Every TypeUse this record stores in its configuration and values (type_use and actual_type): the roots of reachability. */
fun AuthoringRecord.storedUses(): Sequence<TypeUse> =
    sequence {
        yieldAll(configuration.uses())
        val pending = ArrayDeque(fields.map { it.value })
        while (pending.isNotEmpty()) {
            val value = pending.removeFirst()
            when (value) {
                is DataValue.TypeUseWrapper -> yield(value.value)
                is DataValue.NamedWrapper -> yield(value.value.actualType.use)
                else -> Unit
            }
            pending += value.children()
        }
    }

/** The values directly inside [this]: a named value's payload, a record's fields, collection items, and map keys and values. */
private fun DataValue.children(): List<DataValue> =
    when (this) {
        is DataValue.NamedWrapper -> listOf(value.payload)
        is DataValue.RecordWrapper -> value.fields.map { it.value }
        is DataValue.ListValueWrapper -> value.items.map { it.value }
        is DataValue.SetValueWrapper -> value.items.map { it.value }
        is DataValue.MapValueWrapper -> value.rows.flatMap { listOf(it.key, it.value) }
        else -> emptyList()
    }

/** Every definition this record names, in what it stores and inside its declarations. */
fun AuthoringRecord.referencedDefinitions(): Sequence<TypeDefinitionId> =
    storedUses().flatMap { it.referencedDefinitions() } + types.asSequence().flatMap { it.referencedDefinitions() }

/**
 * This record without the declarations nothing it stores reaches. Reachability starts at the configuration and every
 * stored type use and follows declarations from there, so a nested or recursive declaration goes with its user.
 */
fun AuthoringRecord.withoutUnreachableTypes(): AuthoringRecord {
    if (types.isEmpty()) return this
    val byId = types.associateBy { it.id }
    val reachable = linkedSetOf<TypeDefinitionId>()
    val pending = ArrayDeque(storedUses().flatMap { it.referencedDefinitions() }.toList())
    while (pending.isNotEmpty()) {
        val id = pending.removeFirst()
        if (!reachable.add(id)) continue
        byId[id]?.let { definition -> pending += definition.referencedDefinitions() }
    }
    val kept = types.filter { it.id in reachable }
    return if (kept.size == types.size) this else copy(types = kept)
}

/** The code that says why [id] stands in as the error type, or null when it is ready. */
fun CheckedCatalog.unavailableCode(id: TypeDefinitionId): String? =
    (definition(id) as? DeclarationStatus.UnavailableWrapper)
        ?.value
        ?.firstOrNull { it.code in CONTENT_TYPE_PROBLEMS }
        ?.code

/** One misfit per type the configuration names that is gone or invalid, at the root, each carrying its id. */
fun AuthoringRecord.missingContent(
    owner: ResourceId,
    catalog: CheckedCatalog,
): List<Misfit> =
    configuration
        .uses()
        .flatMap { it.referencedDefinitions() }
        .distinct()
        .filter { it.contentOwner() != null }
        .mapNotNull { id -> catalog.unavailableCode(id)?.let { Misfit(ValueProblem(location = ValueLocation.of(owner), code = it), id) } }

/**
 * Every way this record does not fit its current schema, each problem at its own location, on any record. Under a
 * missing type the error record has no fields, so each old field is its own unknown_field: adding a field is a new
 * problem, and removing one is not. [linkFit] gives the link problems the projection judged for this record.
 */
fun AuthoringRecord.misfits(
    owner: ResourceId,
    catalog: CheckedCatalog,
    linkFit: () -> List<ValueProblem> = { emptyList() },
): List<Misfit> = missingContent(owner, catalog) + structuralMisfits(owner, catalog) + linkFit().map { Misfit(it) }
