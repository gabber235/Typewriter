package com.typewritermc.types.catalog

import com.typewritermc.authoring.DependentField
import com.typewritermc.authoring.PartialSchema
import com.typewritermc.authoring.StructuralResult
import com.typewritermc.authoring.arguments
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.type
import com.typewritermc.authoring.use
import com.typewritermc.authoring.validateStructure
import com.typewritermc.types.MAX_TYPE_DEPTH
import com.typewritermc.types.catalog.of
import com.typewritermc.types.catalog.reasons
import com.typewritermc.types.immutableListCopy
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.parameterKeys
import com.typewritermc.types.qualified
import com.typewritermc.types.substitute
import com.typewritermc.types.template
import com.typewritermc.types.toTemplate
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.authoring.ArgumentLocation
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.type_catalog.AppliedSchema
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResolvedField
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import java.util.concurrent.ConcurrentHashMap

/** A resolved application tied to the catalog generation and resolver that established its schema. */
class CheckedType internal constructor(
    val catalog: CatalogGeneration,
    val use: TypeUse,
    val schema: AppliedSchema,
    internal val resolver: CheckedCatalog,
)

fun CheckedType.resolve(use: TypeUse): Resolution<CheckedType> = resolver.resolve(use)

fun CheckedType.isNominalSubtype(
    actual: TypeDefinitionId,
    expected: TypeDefinitionId,
): Boolean = resolver.isNominalSubtype(actual, expected)

sealed interface Resolution<out T> {
    data class Ready<T>(
        val value: T,
    ) : Resolution<T>

    data class Invalid(
        val diagnostics: List<DeclarationDiagnostic>,
    ) : Resolution<Nothing>
}

/**
 * Resolves contributed declarations into the schemas used by authoring, native bindings, and portable expressions.
 *
 * Declaration availability and application validity are separate: an available generic declaration can still reject
 * an application's arity or bounds. Partial resolution preserves fields independent of unfinished arguments.
 * Readability describes permitted reads through nominal ancestry and generic applications; values retain their
 * actual type for editing and encoding.
 */
interface CheckedCatalog {
    val generation: CatalogGeneration

    fun definition(id: TypeDefinitionId): DeclarationStatus

    fun declaration(id: TypeDefinitionId): Resolution<TypeDefinition>

    fun resolve(candidate: TypeUse): Resolution<CheckedType>

    fun resolvePartial(selection: TypeSelection): Resolution<PartialSchema>

    fun knownApplications(selection: TypeSelection): Set<NamedTypeUse>

    fun isReadableAs(
        actual: TypeUse,
        expected: TypeUse,
    ): Boolean

    fun isTemplateReadableAs(
        actual: TypeTemplate,
        expected: TypeTemplate,
        parameterBounds: Map<ParameterKey, List<TypeTemplate>> = emptyMap(),
    ): Boolean

    /** Tests declaration ancestry without claiming that a pending application has valid arguments. */
    fun isNominalSubtype(
        actual: TypeDefinitionId,
        expected: TypeDefinitionId,
    ): Boolean

    fun concreteForms(expected: CheckedType): List<CheckedType>

    fun validateAuthoring(record: AuthoringRecord): StructuralResult
}

fun TypeTemplate.apply(arguments: Map<ParameterKey, TypeUse>): Resolution<TypeUse> =
    when (this) {
        is TypeTemplate.ParameterWrapper -> {
            val bound = arguments[value]
            if (bound != null) {
                Resolution.Ready(bound)
            } else {
                Resolution.Invalid(listOf(diagnostic(value.owner, "missing_parameter_binding")))
            }
        }

        is TypeTemplate.NamedWrapper -> {
            value.apply(arguments).map { it.use }
        }

        is TypeTemplate.NullableWrapper -> {
            value.value.apply(arguments).map { it.nullable() }
        }

        is TypeTemplate.ScalarWrapper -> {
            Resolution.Ready(value.use)
        }

        else -> {
            unknownVariant(this)
        }
    }

/** Applies the arguments of this template, keeping it a named application. */
fun NamedTypeTemplate.apply(arguments: Map<ParameterKey, TypeUse>): Resolution<NamedTypeUse> =
    this.arguments.mapResolution { it.apply(arguments) }.map { definition.namedUse(it) }

/**
 * Owns an immutable declaration snapshot and memoized application results for one catalog generation.
 *
 * Construction isolates invalid declarations and their dependents while leaving unrelated definitions available.
 * Resolution substitutes immediate field types without recursively expanding referenced record payloads, allowing
 * recursive authored structures. Application depth and reentrant resolution are bounded with declaration diagnostics.
 */
class DefaultCheckedCatalog(
    override val generation: CatalogGeneration,
    declarations: List<TypeDefinition>,
    quarantine: List<DeclarationDiagnostic> = emptyList(),
) : CheckedCatalog {
    private val depthInvalidDefinitions = declarations.filter(TypeDefinition::exceedsTypeDepth).map(TypeDefinition::id).toSet()
    private val definitions =
        declarations
            .filterNot { it.id in depthInvalidDefinitions }
            .groupBy(TypeDefinition::id)
    private val unavailable = linkedMapOf<TypeDefinitionId, MutableList<DeclarationDiagnostic>>()
    private val cache = ConcurrentHashMap<ResolutionKey, Resolution<CheckedType>>()
    private val resolving = mutableSetOf<TypeUse>()

    init {
        depthInvalidDefinitions.forEach { markUnavailable(it, "type_depth_limit") }
        definitions.filterValues { it.size > 1 }.forEach { (id, _) -> markUnavailable(id, "duplicate_definition") }
        definitions
            .filterValues { it.size == 1 }
            .values
            .map(List<TypeDefinition>::single)
            .forEach(::validateDeclaration)
        markInheritanceCycles()
        quarantine.forEach(::markUnavailable)
        propagateUnavailableDependencies()
    }

    override fun definition(id: TypeDefinitionId): DeclarationStatus {
        val reasons = unavailable[id]
        return when {
            reasons != null -> DeclarationStatus.UnavailableWrapper(reasons.distinct())
            definitions[id] == null -> DeclarationStatus.UnavailableWrapper(listOf(diagnostic(id, "unknown_definition")))
            else -> DeclarationStatus.READY
        }
    }

    override fun declaration(id: TypeDefinitionId): Resolution<TypeDefinition> =
        when (val status = definition(id)) {
            DeclarationStatus.READY -> Resolution.Ready(definitions.getValue(id).single())
            is DeclarationStatus.UnavailableWrapper -> Resolution.Invalid(status.reasons)
            else -> unknownVariant(status)
        }

    override fun resolve(candidate: TypeUse): Resolution<CheckedType> {
        candidate.typeDepthFailure()?.let { return invalid(it, "type_depth_limit") }
        val key = ResolutionKey(candidate)
        cache[key]?.let { return it }
        synchronized(cache) {
            cache[key]?.let { return it }
            if (!resolving.add(candidate)) {
                val affected =
                    candidate.namedDefinition()
                        ?: error("Only named type resolution can reenter the checked catalog resolver.")
                return invalid(affected, "recursive_type_resolution")
            }
            try {
                val resolved =
                    when (candidate) {
                        is TypeUse.ScalarWrapper -> ready(candidate, ResolvedRepresentation.createScalar(kind = candidate.value))
                        is TypeUse.NullableWrapper -> resolveNullable(candidate)
                        is TypeUse.NamedWrapper -> resolveNamed(candidate.value)
                        else -> unknownVariant(candidate)
                    }
                cache[key] = resolved
                return resolved
            } finally {
                resolving.remove(candidate)
            }
        }
    }

    private fun TypeUse.namedDefinition(): TypeDefinitionId? =
        generateSequence(this) { (it as? TypeUse.NullableWrapper)?.value?.value }
            .firstOrNull { it !is TypeUse.NullableWrapper }
            ?.named
            ?.definition

    override fun resolvePartial(selection: TypeSelection): Resolution<PartialSchema> =
        when (selection) {
            is TypeSelection.CompleteWrapper -> {
                when (val resolved = resolve(selection.use.use)) {
                    is Resolution.Invalid -> {
                        resolved
                    }

                    is Resolution.Ready -> {
                        Resolution.Ready(
                            PartialSchema(
                                knownFields = resolved.value.schema.fields,
                                dependentFields = emptyList(),
                                pendingArguments = emptyList(),
                            ),
                        )
                    }
                }
            }

            is TypeSelection.PendingWrapper -> {
                resolvePending(selection)
            }

            else -> {
                unknownVariant(selection)
            }
        }

    override fun knownApplications(selection: TypeSelection): Set<NamedTypeUse> =
        when (selection) {
            is TypeSelection.CompleteWrapper -> {
                val resolved = resolve(selection.use.use) as? Resolution.Ready
                if (resolved == null) emptySet() else linkedSetOf(selection.use).apply { addAll(resolved.value.schema.ancestors) }
            }

            is TypeSelection.PendingWrapper -> {
                knownPendingApplications(selection)
            }

            else -> {
                unknownVariant(selection)
            }
        }

    override fun isReadableAs(
        actual: TypeUse,
        expected: TypeUse,
    ): Boolean {
        val resolvedActual = resolve(actual) as? Resolution.Ready ?: return false
        if (resolve(expected) !is Resolution.Ready) return false
        return isResolvedReadableAs(actual, expected, resolvedActual.value.schema)
    }

    override fun isTemplateReadableAs(
        actual: TypeTemplate,
        expected: TypeTemplate,
        parameterBounds: Map<ParameterKey, List<TypeTemplate>>,
    ): Boolean = isTemplateReadableAs(actual, expected, parameterBounds, linkedSetOf())

    override fun isNominalSubtype(
        actual: TypeDefinitionId,
        expected: TypeDefinitionId,
    ): Boolean {
        if (definition(actual) != DeclarationStatus.READY || definition(expected) != DeclarationStatus.READY) return false
        val visited = mutableSetOf<TypeDefinitionId>()
        val pending = ArrayDeque<TypeDefinitionId>()
        pending.add(actual)
        while (pending.isNotEmpty()) {
            val current = pending.removeFirst()
            if (!visited.add(current)) continue
            if (current == expected) return true
            definitions
                .getValue(current)
                .single()
                .parents
                .forEach { pending.add(it.definition) }
        }
        return false
    }

    override fun concreteForms(expected: CheckedType): List<CheckedType> =
        definitions.values
            .filter { it.size == 1 }
            .map(List<TypeDefinition>::single)
            .filter { (it.representation as? RepresentationTemplate.RecordWrapper)?.value?.abstract_ != true }
            .flatMap { definition -> inferConcreteApplications(definition, expected.use) }
            .distinct()
            .mapNotNull { named ->
                val candidate = named.use
                val resolved = resolve(candidate) as? Resolution.Ready ?: return@mapNotNull null
                resolved.value.takeIf { isResolvedReadableAs(candidate, expected.use, resolved.value.schema) }
            }

    override fun validateAuthoring(record: AuthoringRecord): StructuralResult = record.validateStructure(this)

    private fun knownPendingApplications(selection: TypeSelection.PendingWrapper): Set<NamedTypeUse> {
        if (definition(selection.definition) != DeclarationStatus.READY) return emptySet()
        val root = definitions.getValue(selection.definition).single()
        if (selection.arguments.size != root.parameters.size) return emptySet()
        val bindings =
            root.parameters
                .zip(selection.arguments)
                .mapNotNull { (parameter, argument) ->
                    val chosen = argument as? ArgumentSelection.ChosenWrapper ?: return@mapNotNull null
                    if (resolve(chosen.type) !is Resolution.Ready) return@mapNotNull null
                    parameter.key to chosen.type
                }.toMap()
        val applications = linkedSetOf<NamedTypeUse>()
        val visited = mutableSetOf<Pair<TypeDefinitionId, Map<ParameterKey, TypeUse>>>()

        fun visit(
            current: TypeDefinition,
            known: Map<ParameterKey, TypeUse>,
        ) {
            if (!visited.add(current.id to known)) return
            if (current.parameters.all { it.key in known }) {
                val application = current.id.namedUse(current.parameters.map { known.getValue(it.key) })
                if (resolve(application.use) is Resolution.Ready) applications += application
            }
            current.parents.forEach { parentTemplate ->
                val parentDefinition = definitions[parentTemplate.definition]?.singleOrNull() ?: return@forEach
                if (definition(parentDefinition.id) != DeclarationStatus.READY) return@forEach
                val parentBindings =
                    parentDefinition.parameters
                        .zip(parentTemplate.arguments)
                        .mapNotNull { (parameter, argument) ->
                            val applied = argument.apply(known) as? Resolution.Ready ?: return@mapNotNull null
                            parameter.key to applied.value
                        }.toMap()
                visit(parentDefinition, parentBindings)
            }
        }

        visit(root, bindings)
        return applications
    }

    private fun resolveNullable(candidate: TypeUse.NullableWrapper): Resolution<CheckedType> =
        when (val inner = resolve(candidate.value.value)) {
            is Resolution.Invalid -> {
                inner
            }

            is Resolution.Ready -> {
                Resolution.Ready(
                    CheckedType(
                        generation,
                        candidate,
                        inner.value.schema.copy(use = candidate),
                        this,
                    ),
                )
            }
        }

    /** Validates declaration applications without expanding the fields of referenced records. */
    private fun validateApplication(
        candidate: NamedTypeUse,
        visiting: MutableSet<NamedTypeUse> = linkedSetOf(),
    ): Resolution<Map<ParameterKey, TypeUse>> {
        candidate.use.typeDepthFailure()?.let { return invalid(it, "type_depth_limit") }
        val status = definition(candidate.definition)
        if (status is DeclarationStatus.UnavailableWrapper) return Resolution.Invalid(status.reasons)
        val definition = definitions.getValue(candidate.definition).single()
        if (candidate.arguments.size != definition.parameters.size) return invalid(candidate.definition, "argument_arity")
        if (!visiting.add(candidate)) return invalid(candidate.definition, "recursive_type_resolution")
        try {
            candidate.arguments.forEach { argument ->
                val validation = validateTypeApplication(argument, visiting)
                if (validation is Resolution.Invalid) return validation
            }
            val bindings =
                definition.parameters
                    .map(TypeParameter::key)
                    .zip(candidate.arguments)
                    .toMap()
            for (parameter in definition.parameters) {
                val actual = bindings.getValue(parameter.key)
                for (bound in parameter.bounds) {
                    val applied = bound.apply(bindings)
                    if (applied is Resolution.Invalid) return applied
                    applied as Resolution.Ready
                    val validation = validateTypeApplication(applied.value, visiting)
                    if (validation is Resolution.Invalid) return validation
                    if (!isTemplateReadableAs(actual.toTemplate(), applied.value.toTemplate(), emptyMap())) {
                        return invalid(candidate.definition, "argument_bound")
                    }
                }
            }
            for (parent in definition.parents) {
                val applied = parent.apply(bindings)
                if (applied is Resolution.Invalid) return applied
                val validation = validateTypeApplication((applied as Resolution.Ready).value.use, visiting)
                if (validation is Resolution.Invalid) return validation
            }
            return Resolution.Ready(bindings)
        } finally {
            visiting.remove(candidate)
        }
    }

    private fun validateTypeApplication(
        candidate: TypeUse,
        visiting: MutableSet<NamedTypeUse> = linkedSetOf(),
    ): Resolution<Unit> {
        candidate.typeDepthFailure()?.let { return invalid(it, "type_depth_limit") }
        return when (candidate) {
            is TypeUse.ScalarWrapper -> Resolution.Ready(Unit)
            is TypeUse.NullableWrapper -> validateTypeApplication(candidate.value.value, visiting)
            is TypeUse.NamedWrapper -> validateApplication(candidate.value, visiting).map { Unit }
            else -> unknownVariant(candidate)
        }
    }

    private fun resolveNamed(candidate: NamedTypeUse): Resolution<CheckedType> {
        val application = validateApplication(candidate)
        if (application is Resolution.Invalid) return application
        val bindings = (application as Resolution.Ready).value
        val definition = definitions.getValue(candidate.definition).single()
        val invalidArgument = candidate.arguments.firstNotNullOfOrNull { (resolve(it) as? Resolution.Invalid)?.diagnostics }
        if (invalidArgument != null) return Resolution.Invalid(invalidArgument)
        for (parameter in definition.parameters) {
            for (bound in parameter.bounds) {
                val applied = bound.apply(bindings)
                if (applied is Resolution.Invalid) return applied
                applied as Resolution.Ready
                if (resolve(applied.value) !is Resolution.Ready) return invalid(candidate.definition, "argument_bound")
            }
        }

        val parentUses = mutableListOf<NamedTypeUse>()
        val parentFields = mutableListOf<ResolvedField>()
        val ancestors = linkedSetOf<NamedTypeUse>()
        for (parentTemplate in definition.parents) {
            val applied = parentTemplate.apply(bindings)
            if (applied is Resolution.Invalid) return applied
            val parent = (applied as Resolution.Ready).value
            val resolvedParent = resolve(parent.use)
            if (resolvedParent is Resolution.Invalid) return resolvedParent
            resolvedParent as Resolution.Ready
            parentUses += parent
            parentFields += resolvedParent.value.schema.fields
            ancestors += parent
            ancestors += resolvedParent.value.schema.ancestors
        }
        if (ancestors.groupBy(NamedTypeUse::definition).values.any { uses -> uses.distinct().size > 1 }) {
            return invalid(candidate.definition, "inconsistent_parent_application")
        }

        val ownFields = (definition.representation as? RepresentationTemplate.RecordWrapper)?.value?.fields.orEmpty()
        val mergedFields = mergeFields(candidate.definition, parentFields, ownFields, bindings)
        if (mergedFields is Resolution.Invalid) return mergedFields
        mergedFields as Resolution.Ready
        val representation = resolveRepresentation(definition.representation, bindings, mergedFields.value)
        if (representation is Resolution.Invalid) return representation
        representation as Resolution.Ready
        val use = candidate.use
        val schema = AppliedSchema(use = use, representation = representation.value, fields = mergedFields.value, ancestors = ancestors)
        return Resolution.Ready(CheckedType(generation, use, schema, this))
    }

    private fun resolvePending(selection: TypeSelection.PendingWrapper): Resolution<PartialSchema> {
        val status = definition(selection.definition)
        if (status is DeclarationStatus.UnavailableWrapper) return Resolution.Invalid(status.reasons)
        val definition = definitions.getValue(selection.definition).single()
        if (selection.arguments.size != definition.parameters.size) return invalid(selection.definition, "argument_arity")
        val bindings = mutableMapOf<ParameterKey, TypeUse>()
        val pending = mutableListOf<ArgumentLocation>()
        selection.arguments.forEachIndexed { index, argument ->
            when (argument) {
                is ArgumentSelection.ChosenWrapper -> {
                    val resolution = resolve(argument.type)
                    if (resolution is Resolution.Invalid) return resolution
                    bindings[definition.parameters[index].key] = argument.type
                }

                ArgumentSelection.UNFILLED -> {
                    pending += ArgumentLocation(index = index)
                }

                else -> {
                    unknownVariant(argument)
                }
            }
        }
        if (pending.isEmpty()) {
            val complete = selection.definition.namedUse(definition.parameters.map { bindings.getValue(it.key) })
            return resolvePartial(TypeSelection.CompleteWrapper(complete))
        }
        for (parameter in definition.parameters) {
            val actual = bindings[parameter.key] ?: continue
            for (bound in parameter.bounds) {
                if (bound.parameterKeys().any { it !in bindings }) continue
                val applied = bound.apply(bindings)
                if (applied is Resolution.Invalid) return applied
                applied as Resolution.Ready
                val actualResolution = resolve(actual) as? Resolution.Ready ?: return invalid(definition.id, "argument_bound")
                if (resolve(applied.value) !is Resolution.Ready ||
                    !isResolvedReadableAs(actual, applied.value, actualResolution.value.schema)
                ) {
                    return invalid(definition.id, "argument_bound")
                }
            }
        }
        val partialFields = collectPartialFields(definition, bindings, linkedSetOf())
        if (partialFields is Resolution.Invalid) return partialFields
        partialFields as Resolution.Ready
        val known = mutableListOf<ResolvedField>()
        val dependent = mutableListOf<DependentField>()
        for (field in partialFields.value) {
            val missing =
                field.type
                    .parameterKeys()
                    .filterNot(bindings::containsKey)
                    .toSet()
            if (missing.isEmpty()) {
                val applied = field.type.apply(bindings)
                if (applied is Resolution.Invalid) return applied
                known += resolvedField(field.owner, (applied as Resolution.Ready).value)
            } else {
                dependent += DependentField(field.owner, field.type, missing)
            }
        }
        return Resolution.Ready(PartialSchema(known, dependent, pending))
    }

    private fun resolveRepresentation(
        representation: RepresentationTemplate,
        bindings: Map<ParameterKey, TypeUse>,
        fields: List<ResolvedField>,
    ): Resolution<ResolvedRepresentation> =
        when (representation) {
            is RepresentationTemplate.ScalarWrapper -> {
                Resolution.Ready(ResolvedRepresentation.createScalar(kind = representation.value.kind))
            }

            is RepresentationTemplate.RecordWrapper -> {
                Resolution.Ready(ResolvedRepresentation.createRecord(fields = fields, abstract_ = representation.value.abstract_))
            }

            is RepresentationTemplate.SequenceWrapper -> {
                val sequence = representation.value
                sequence.item.apply(bindings).map { ResolvedRepresentation.createSequence(item = it, kind = sequence.kind) }
            }

            is RepresentationTemplate.MappingWrapper -> {
                val key = representation.value.key.apply(bindings)
                if (key is Resolution.Invalid) return key
                val value = representation.value.value.apply(bindings)
                if (value is Resolution.Invalid) return value
                Resolution.Ready(
                    ResolvedRepresentation.createMapping(key = (key as Resolution.Ready).value, value = (value as Resolution.Ready).value),
                )
            }

            is RepresentationTemplate.EnumerationWrapper -> {
                Resolution.Ready(ResolvedRepresentation.createEnumeration(cases = representation.value.cases))
            }

            is RepresentationTemplate.LinkWrapper -> {
                val link = representation.value
                link.target.apply(bindings).map { ResolvedRepresentation.createLink(endpoint = link.endpoint, target = it) }
            }

            else -> {
                unknownVariant(representation)
            }
        }

    private fun mergeFields(
        affected: TypeDefinitionId,
        inherited: List<ResolvedField>,
        own: List<FieldDeclaration>,
        bindings: Map<ParameterKey, TypeUse>,
    ): Resolution<List<ResolvedField>> {
        val fieldOrder = (inherited.map(ResolvedField::key) + own.map { it.owner.name }).distinct()
        val inheritedByName = inherited.groupBy(ResolvedField::key).mapValues { (_, values) -> values.distinct() }.toMutableMap()
        val merged = linkedMapOf<String, ResolvedField>()
        for (field in own) {
            val applied = field.type.apply(bindings)
            if (applied is Resolution.Invalid) return applied
            applied as Resolution.Ready
            val inheritedFields = inheritedByName.remove(field.owner.name).orEmpty()
            val inheritedOwners = inheritedFields.map { FieldOwner(definition = it.declarationOwner, name = it.key) }.toSet()
            if (inheritedOwners.isNotEmpty() && !field.overrides.containsAll(inheritedOwners)) {
                return invalid(affected, "missing_field_override")
            }
            if (inheritedFields.isNotEmpty() &&
                (
                    validateTypeApplication(applied.value) is Resolution.Invalid ||
                        inheritedFields.any {
                            validateTypeApplication(it.type) is Resolution.Invalid ||
                                !isTemplateReadableAs(applied.value.toTemplate(), it.type.toTemplate(), emptyMap())
                        }
                )
            ) {
                return invalid(affected, "invalid_field_narrowing")
            }
            merged[field.owner.name] =
                resolvedField(field.owner, applied.value, inheritedFields.flatMap(ResolvedField::guarantees).distinct())
        }
        for ((name, inheritedFields) in inheritedByName) {
            val distinctOwners = inheritedFields.map(ResolvedField::declarationOwner).distinct()
            val distinctTypes = inheritedFields.map(ResolvedField::type).distinct()
            if (distinctOwners.size > 1 || distinctTypes.size > 1) {
                return invalid(affected, "ambiguous_inherited_field")
            }
            val field = inheritedFields.first()
            merged[name] = field.copy(guarantees = inheritedFields.flatMap(ResolvedField::guarantees).distinct())
        }
        return Resolution.Ready(fieldOrder.map(merged::getValue))
    }

    private fun validateDeclaration(definition: TypeDefinition) {
        if (definition.parameters
                .map(TypeParameter::name)
                .distinct()
                .size != definition.parameters.size
        ) {
            markUnavailable(definition.id, "duplicate_parameter_name")
        }
        definition.parameters.forEachIndexed { index, parameter ->
            if (parameter.key.owner != definition.id || parameter.key.index != index) {
                markUnavailable(definition.id, "invalid_parameter_key")
            }
        }
        val keys = definition.parameters.map(TypeParameter::key).toSet()
        val templates =
            buildList {
                definition.parameters.flatMapTo(this) { it.bounds }
                definition.parents.mapTo(this) { it.template }
                addAll(definition.representation.templates())
            }
        if (templates.flatMap { it.parameterKeys() }.any { it !in keys }) {
            markUnavailable(definition.id, "foreign_parameter")
        }
        templates.flatMap { it.namedTemplates() }.forEach { named ->
            val target = definitions[named.definition]
            if (target == null) {
                markUnavailable(definition.id, "unknown_dependency")
            } else if (target.size == 1 && named.arguments.size != target.single().parameters.size) {
                markUnavailable(definition.id, "template_argument_arity")
            }
        }
        val fields = (definition.representation as? RepresentationTemplate.RecordWrapper)?.value?.fields.orEmpty()
        if (fields.map { it.owner.name }.distinct().size != fields.size) markUnavailable(definition.id, "duplicate_field")
        if (fields.any { it.owner.definition != definition.id }) markUnavailable(definition.id, "invalid_field_owner")
    }

    private fun markInheritanceCycles() {
        val visiting = linkedSetOf<TypeDefinitionId>()
        val visited = mutableSetOf<TypeDefinitionId>()

        fun visit(id: TypeDefinitionId) {
            if (id in visiting) {
                visiting.dropWhile { it != id }.forEach { markUnavailable(it, "inheritance_cycle") }
                return
            }
            if (!visited.add(id)) return
            val definition = definitions[id]?.singleOrNull() ?: return
            visiting += id
            definition.parents.forEach { visit(it.definition) }
            visiting -= id
        }
        definitions.keys.forEach(::visit)
    }

    private fun propagateUnavailableDependencies() {
        var changed: Boolean
        do {
            changed = false
            definitions.values.mapNotNull(List<TypeDefinition>::singleOrNull).forEach { definition ->
                if (definition.id in unavailable) return@forEach
                val dependencies = definition.referencedDefinitions()
                if (dependencies.any { it in unavailable }) {
                    markUnavailable(definition.id, "unavailable_dependency")
                    changed = true
                }
            }
        } while (changed)
    }

    private fun sameApplicationFamily(
        actual: NamedTypeUse,
        expected: NamedTypeUse,
    ): Boolean =
        actual.definition == expected.definition &&
            actual.arguments.size == expected.arguments.size &&
            actual.arguments.zip(expected.arguments).all { (left, right) -> isReadableAs(left, right) }

    private fun inferConcreteApplications(
        definition: TypeDefinition,
        expectedUse: TypeUse,
    ): List<NamedTypeUse> {
        val expected = expectedUse.named ?: return emptyList()
        val ownTemplate = definition.id.namedTemplate(definition.parameters.map { it.key.template })
        return (listOf(ownTemplate) + ancestorTemplates(definition, linkedSetOf()))
            .asSequence()
            .filter { it.definition == expected.definition && it.arguments.size == expected.arguments.size }
            .mapNotNull { template ->
                val inferred = linkedMapOf<ParameterKey, TypeUse>()
                val matched = template.arguments.zip(expected.arguments).all { (left, right) -> infer(left, right, inferred) }
                if (!matched || definition.parameters.any { it.key !in inferred }) return@mapNotNull null
                definition.id.namedUse(definition.parameters.map { inferred.getValue(it.key) })
            }.toList()
    }

    private fun ancestorTemplates(
        definition: TypeDefinition,
        visiting: MutableSet<TypeDefinitionId>,
    ): List<NamedTypeTemplate> {
        if (!visiting.add(definition.id)) return emptyList()
        val ancestors = mutableListOf<NamedTypeTemplate>()
        for (parent in definition.parents) {
            ancestors += parent
            val parentDefinition = definitions[parent.definition]?.singleOrNull() ?: continue
            val substitutions =
                parentDefinition.parameters
                    .map(TypeParameter::key)
                    .zip(parent.arguments)
                    .toMap()
            ancestors += ancestorTemplates(parentDefinition, visiting).map { it.substitute(substitutions) }
        }
        visiting -= definition.id
        return ancestors
    }

    private fun infer(
        template: TypeTemplate,
        actual: TypeUse,
        inferred: MutableMap<ParameterKey, TypeUse>,
    ): Boolean =
        when (template) {
            is TypeTemplate.ParameterWrapper -> {
                inferred[template.value]?.let { it == actual } ?: run {
                    inferred[template.value] = actual
                    true
                }
            }

            is TypeTemplate.ScalarWrapper -> {
                actual == template.value.use
            }

            is TypeTemplate.NullableWrapper -> {
                actual is TypeUse.NullableWrapper && infer(template.value.value, actual.value.value, inferred)
            }

            is TypeTemplate.NamedWrapper -> {
                val named = template.value
                val actualNamed = actual.named
                actualNamed != null &&
                    named.definition == actualNamed.definition &&
                    named.arguments.size == actualNamed.arguments.size &&
                    named.arguments.zip(actualNamed.arguments).all { (left, right) -> infer(left, right, inferred) }
            }

            else -> {
                unknownVariant(template)
            }
        }

    private fun isResolvedReadableAs(
        actual: TypeUse,
        expected: TypeUse,
        actualSchema: AppliedSchema,
    ): Boolean {
        if (actual == expected) return true
        if (expected is TypeUse.NullableWrapper) {
            return (actual is TypeUse.NullableWrapper && isReadableAs(actual.value.value, expected.value.value)) ||
                (actual !is TypeUse.NullableWrapper && isReadableAs(actual, expected.value.value))
        }
        if (actual is TypeUse.NullableWrapper) return false
        val actualNamed = actual.named ?: return false
        val expectedNamed = expected.named ?: return false
        if (sameApplicationFamily(actualNamed, expectedNamed)) return true
        return actualSchema.ancestors.any { ancestor -> sameApplicationFamily(ancestor, expectedNamed) }
    }

    private fun isTemplateReadableAs(
        actual: TypeTemplate,
        expected: TypeTemplate,
        parameterBounds: Map<ParameterKey, List<TypeTemplate>>,
        visiting: MutableSet<Pair<TypeTemplate, TypeTemplate>>,
    ): Boolean {
        if (actual == expected) return true
        val pair = actual to expected
        if (!visiting.add(pair)) return false
        return try {
            when {
                expected is TypeTemplate.NullableWrapper -> {
                    val value = if (actual is TypeTemplate.NullableWrapper) actual.value.value else actual
                    isTemplateReadableAs(value, expected.value.value, parameterBounds, visiting)
                }

                actual is TypeTemplate.NullableWrapper -> {
                    false
                }

                actual is TypeTemplate.ParameterWrapper -> {
                    parameterBounds[actual.value].orEmpty().any { bound ->
                        isTemplateReadableAs(bound, expected, parameterBounds, visiting)
                    }
                }

                expected is TypeTemplate.ParameterWrapper -> {
                    false
                }

                actual is TypeTemplate.NamedWrapper && expected is TypeTemplate.NamedWrapper -> {
                    val required = expected.value
                    templateApplications(actual.value).any { application ->
                        application.definition == required.definition &&
                            application.arguments.size == required.arguments.size &&
                            application.arguments.zip(required.arguments).all { (value, bound) ->
                                isTemplateReadableAs(value, bound, parameterBounds, visiting)
                            }
                    }
                }

                else -> {
                    false
                }
            }
        } finally {
            visiting.remove(pair)
        }
    }

    private fun templateApplications(actual: NamedTypeTemplate): List<NamedTypeTemplate> {
        val applications = mutableListOf(actual)
        val pending = ArrayDeque<NamedTypeTemplate>()
        val visited = mutableSetOf<NamedTypeTemplate>()
        pending.add(actual)
        while (pending.isNotEmpty()) {
            val current = pending.removeFirst()
            if (!visited.add(current)) continue
            val definition = definitions[current.definition]?.singleOrNull() ?: continue
            if (definition.parameters.size != current.arguments.size) continue
            val bindings =
                definition.parameters
                    .map(TypeParameter::key)
                    .zip(current.arguments)
                    .toMap()
            definition.parents.forEach { parent ->
                val applied = parent.substitute(bindings)
                applications += applied
                pending += applied
            }
        }
        return applications
    }

    private fun collectPartialFields(
        definition: TypeDefinition,
        bindings: Map<ParameterKey, TypeUse>,
        visiting: MutableSet<TypeDefinitionId>,
    ): Resolution<List<FieldDeclaration>> {
        if (!visiting.add(definition.id)) return invalid(definition.id, "inheritance_cycle")
        val inherited = mutableListOf<FieldDeclaration>()
        for (parent in definition.parents) {
            val parentDefinition =
                definitions[parent.definition]?.singleOrNull()
                    ?: return invalid(definition.id, "unknown_dependency")
            val parentBindings = mutableMapOf<ParameterKey, TypeUse>()
            parent.arguments.forEachIndexed { index, argument ->
                if (argument.parameterKeys().any { it !in bindings }) return@forEachIndexed
                val applied = argument.apply(bindings)
                if (applied is Resolution.Invalid) return applied
                parentBindings[parentDefinition.parameters[index].key] = (applied as Resolution.Ready).value
            }
            val partialParent = collectPartialFields(parentDefinition, parentBindings, visiting)
            if (partialParent is Resolution.Invalid) return partialParent
            inherited +=
                (partialParent as Resolution.Ready).value.map { field ->
                    field.copy(type = field.type.substituteKnown(parentBindings))
                }
        }
        visiting -= definition.id
        val own = (definition.representation as? RepresentationTemplate.RecordWrapper)?.value?.fields.orEmpty()
        return Resolution.Ready(inherited + own)
    }

    private fun ready(
        use: TypeUse,
        representation: ResolvedRepresentation,
    ): Resolution<CheckedType> =
        Resolution.Ready(
            CheckedType(
                generation,
                use,
                AppliedSchema(use = use, representation = representation, fields = emptyList(), ancestors = emptyList()),
                this,
            ),
        )

    private fun invalid(
        affected: TypeDefinitionId,
        code: String,
    ): Resolution.Invalid = Resolution.Invalid(listOf(diagnostic(affected, code)))

    private fun markUnavailable(
        id: TypeDefinitionId,
        code: String,
    ) = markUnavailable(DeclarationDiagnostic.of(id, code))

    private fun markUnavailable(diagnostic: DeclarationDiagnostic) {
        val reasons = unavailable.getOrPut(diagnostic.affected, ::mutableListOf)
        val previous = reasons.indexOfFirst { it.code == diagnostic.code && it.field == diagnostic.field }
        val origins = if (previous < 0) diagnostic.origins else reasons[previous].origins + diagnostic.origins
        val owned =
            diagnostic.copy(
                origins = origins.distinct().immutableListCopy(),
                field = diagnostic.field?.let { it.copy(segments = it.segments.immutableListCopy()) },
            )
        if (previous < 0) reasons += owned else reasons[previous] = owned
    }
}

private fun diagnostic(
    affected: TypeDefinitionId,
    code: String,
) = DeclarationDiagnostic.of(affected, code)

/**
 * Keys memoized resolutions by a structural hash computed without allocation; generated Skir hash codes build a list
 * per struct, which made every cache hit several times slower. Equality is the generated structural equality.
 */
private class ResolutionKey(
    val use: TypeUse,
) {
    private val hash = use.structuralHash()

    override fun hashCode(): Int = hash

    override fun equals(other: Any?): Boolean = other is ResolutionKey && other.hash == hash && other.use == use
}

private fun TypeUse.structuralHash(): Int =
    when (this) {
        is TypeUse.NamedWrapper -> {
            value.arguments.fold(value.definition.structuralHash()) { hash, argument ->
                31 * hash +
                    argument.structuralHash()
            }
        }

        is TypeUse.NullableWrapper -> {
            31 * value.value.structuralHash() + 1
        }

        is TypeUse.ScalarWrapper -> {
            value.structuralHash()
        }

        else -> {
            kind.ordinal
        }
    }

private fun TypeDefinitionId.structuralHash(): Int {
    val identity =
        when (val id = typeId) {
            is TypeId.DeclaredWrapper -> id.value.value.hashCode()
            is TypeId.QualifiedWrapper -> 31 * id.value.namespace.hashCode() + id.value.name.hashCode()
            else -> id.kind.ordinal
        }
    return 31 * identity + revision
}

private fun ScalarKind.structuralHash(): Int =
    when (this) {
        is ScalarKind.IntegerWrapper -> 31 * kind.ordinal + value.width.kind.ordinal
        is ScalarKind.FloatWrapper -> 31 * kind.ordinal + value.width.kind.ordinal
        else -> kind.ordinal
    }

private fun TypeUse.typeDepthFailure(): TypeDefinitionId? {
    val pending = ArrayDeque<Pair<TypeUse, Int>>()
    pending.addLast(this to 1)
    var nearestDefinition: TypeDefinitionId? = null
    while (pending.isNotEmpty()) {
        val (current, depth) = pending.removeLast()
        val named = current.named
        if (named != null && nearestDefinition == null) nearestDefinition = named.definition
        if (depth > MAX_TYPE_DEPTH) {
            return named?.definition ?: nearestDefinition ?: TYPE_USE_DIAGNOSTIC_OWNER
        }
        when (current) {
            is TypeUse.NamedWrapper -> {
                current.value.arguments
                    .asReversed()
                    .forEach { pending.addLast(it to depth + 1) }
            }

            is TypeUse.NullableWrapper -> {
                pending.addLast(current.value.value to depth + 1)
            }

            else -> {
                Unit
            }
        }
    }
    return null
}

private fun TypeDefinition.exceedsTypeDepth(): Boolean {
    val roots = mutableListOf<TypeTemplate>()
    parameters.forEach { roots += it.bounds }
    parents.mapTo(roots) { it.template }
    roots += representation.templates()
    val pending = ArrayDeque<Pair<TypeTemplate, Int>>()
    roots.asReversed().forEach { pending.addLast(it to 1) }
    while (pending.isNotEmpty()) {
        val (current, depth) = pending.removeLast()
        if (depth > MAX_TYPE_DEPTH) return true
        when (current) {
            is TypeTemplate.NamedWrapper -> {
                current.value.arguments
                    .asReversed()
                    .forEach { pending.addLast(it to depth + 1) }
            }

            is TypeTemplate.NullableWrapper -> {
                pending.addLast(current.value.value to depth + 1)
            }

            else -> {
                Unit
            }
        }
    }
    return false
}

private val TYPE_USE_DIAGNOSTIC_OWNER = TypeDefinitionId.qualified("typewriter", "TypeUse")

private fun resolvedField(
    owner: FieldOwner,
    type: TypeUse,
    guarantees: List<skirout.editor.v1.type_catalog.RuleId> = emptyList(),
) = ResolvedField(key = owner.name, declarationOwner = owner.definition, type = type, guarantees = guarantees)

private fun <T, R> Resolution<T>.map(transform: (T) -> R): Resolution<R> =
    when (this) {
        is Resolution.Invalid -> this
        is Resolution.Ready -> Resolution.Ready(transform(value))
    }

private fun <T, R> Iterable<T>.mapResolution(transform: (T) -> Resolution<R>): Resolution<List<R>> {
    val values = mutableListOf<R>()
    for (item in this) {
        when (val result = transform(item)) {
            is Resolution.Invalid -> return result
            is Resolution.Ready -> values += result.value
        }
    }
    return Resolution.Ready(values)
}

private fun TypeTemplate.namedTemplates(): List<NamedTypeTemplate> =
    when (this) {
        is TypeTemplate.NullableWrapper -> value.value.namedTemplates()
        is TypeTemplate.NamedWrapper -> listOf(value) + value.arguments.flatMap { it.namedTemplates() }
        else -> emptyList()
    }

private fun TypeTemplate.substituteKnown(bindings: Map<ParameterKey, TypeUse>): TypeTemplate =
    when (this) {
        is TypeTemplate.ParameterWrapper -> bindings[value]?.toTemplate() ?: this
        is TypeTemplate.NamedWrapper -> value.copy(arguments = value.arguments.map { it.substituteKnown(bindings) }).template
        is TypeTemplate.NullableWrapper -> value.value.substituteKnown(bindings).nullable()
        else -> this
    }

/** Reports declaration readiness from this catalog generation's canonical quarantine. */
fun CheckedCatalog.isReady(id: TypeDefinitionId): Boolean = definition(id) == DeclarationStatus.READY

/** Checks the declarations a named template references while preserving symbolic free parameters. */
fun CheckedCatalog.isReady(template: NamedTypeTemplate): Boolean = isReady(template.definition) && template.arguments.all(::isReady)

/** Checks referenced declarations while preserving symbolic free parameters. */
fun CheckedCatalog.isReady(template: TypeTemplate): Boolean =
    when (template) {
        is TypeTemplate.ParameterWrapper, is TypeTemplate.ScalarWrapper -> true
        is TypeTemplate.NullableWrapper -> isReady(template.value.value)
        is TypeTemplate.NamedWrapper -> isReady(template.value)
        else -> unknownVariant(template)
    }
