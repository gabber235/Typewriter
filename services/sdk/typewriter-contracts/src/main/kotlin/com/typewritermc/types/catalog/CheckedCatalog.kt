package com.typewritermc.types.catalog

import com.typewritermc.authoring.ArgumentLocation
import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.DependentField
import com.typewritermc.authoring.PartialSchema
import com.typewritermc.authoring.StructuralResult
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.validateStructure
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.RuleId
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.immutableCopy
import kotlinx.serialization.Serializable
import java.util.concurrent.ConcurrentHashMap

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

@Serializable
data class ResolvedField(
    val key: String,
    val declarationOwner: TypeDefinitionId,
    val type: TypeUse,
    val guarantees: List<RuleId> = emptyList(),
)

sealed interface DeclarationStatus {
    data object Ready : DeclarationStatus

    data class Unavailable(
        val reasons: List<DeclarationDiagnostic>,
    ) : DeclarationStatus
}

interface CheckedCatalog {
    val generation: CatalogGeneration

    fun definition(id: TypeDefinitionId): DeclarationStatus

    fun declaration(id: TypeDefinitionId): Resolution<TypeDefinition>

    fun resolve(candidate: TypeUse): Resolution<CheckedType>

    fun resolvePartial(selection: TypeSelection): Resolution<PartialSchema>

    fun knownApplications(selection: TypeSelection): Set<TypeUse.Named>

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
        is TypeTemplate.Parameter -> {
            val value = arguments[key]
            if (value != null) {
                Resolution.Ready(value)
            } else {
                Resolution.Invalid(listOf(diagnostic(key.owner, "missing_parameter_binding")))
            }
        }

        is TypeTemplate.Named -> {
            val applied = this.arguments.mapResolution { it.apply(arguments) }
            when (applied) {
                is Resolution.Invalid -> applied
                is Resolution.Ready -> Resolution.Ready(TypeUse.Named(definition, applied.value))
            }
        }

        is TypeTemplate.Nullable -> {
            when (val applied = value.apply(arguments)) {
                is Resolution.Invalid -> applied
                is Resolution.Ready -> Resolution.Ready(TypeUse.Nullable(applied.value))
            }
        }

        is TypeTemplate.Scalar -> {
            Resolution.Ready(TypeUse.Scalar(kind))
        }
    }

class DefaultCheckedCatalog(
    override val generation: CatalogGeneration,
    declarations: List<TypeDefinition>,
) : CheckedCatalog {
    private val depthInvalidDefinitions = declarations.filter(TypeDefinition::exceedsTypeDepth).map(TypeDefinition::id).toSet()
    private val definitions =
        declarations
            .filterNot { it.id in depthInvalidDefinitions }
            .map(TypeDefinition::immutableCopy)
            .groupBy(TypeDefinition::id)
    private val unavailable = linkedMapOf<TypeDefinitionId, MutableList<DeclarationDiagnostic>>()
    private val cache = ConcurrentHashMap<TypeUse, Resolution<CheckedType>>()
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
        propagateUnavailableDependencies()
    }

    override fun definition(id: TypeDefinitionId): DeclarationStatus {
        val reasons = unavailable[id]
        return when {
            reasons != null -> DeclarationStatus.Unavailable(reasons.distinct())
            definitions[id] == null -> DeclarationStatus.Unavailable(listOf(diagnostic(id, "unknown_definition")))
            else -> DeclarationStatus.Ready
        }
    }

    override fun declaration(id: TypeDefinitionId): Resolution<TypeDefinition> =
        when (val status = definition(id)) {
            DeclarationStatus.Ready -> Resolution.Ready(definitions.getValue(id).single())
            is DeclarationStatus.Unavailable -> Resolution.Invalid(status.reasons)
        }

    override fun resolve(candidate: TypeUse): Resolution<CheckedType> {
        candidate.typeDepthFailure()?.let { return invalid(it, "type_depth_limit") }
        cache[candidate]?.let { return it }
        synchronized(cache) {
            cache[candidate]?.let { return it }
            if (!resolving.add(candidate)) {
                val affected =
                    candidate.namedDefinition()
                        ?: error("Only named type resolution can reenter the checked catalog resolver.")
                return invalid(affected, "recursive_type_resolution")
            }
            try {
                val resolved =
                    when (candidate) {
                        is TypeUse.Scalar -> ready(candidate, ResolvedRepresentation.Scalar(candidate.kind))
                        is TypeUse.Nullable -> resolveNullable(candidate)
                        is TypeUse.Named -> resolveNamed(candidate)
                    }
                cache[candidate] = resolved
                return resolved
            } finally {
                resolving.remove(candidate)
            }
        }
    }

    private fun TypeUse.namedDefinition(): TypeDefinitionId? =
        when (val current = generateSequence(this) { (it as? TypeUse.Nullable)?.value }.firstOrNull { it !is TypeUse.Nullable }) {
            is TypeUse.Named -> current.definition
            else -> null
        }

    override fun resolvePartial(selection: TypeSelection): Resolution<PartialSchema> =
        when (selection) {
            is TypeSelection.Complete -> {
                when (val resolved = resolve(selection.use)) {
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

            is TypeSelection.Pending -> {
                resolvePending(selection)
            }
        }

    override fun knownApplications(selection: TypeSelection): Set<TypeUse.Named> =
        when (selection) {
            is TypeSelection.Complete -> {
                val resolved = resolve(selection.use) as? Resolution.Ready
                if (resolved == null) emptySet() else linkedSetOf(selection.use).apply { addAll(resolved.value.schema.ancestors) }
            }

            is TypeSelection.Pending -> {
                knownPendingApplications(selection)
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
        if (definition(actual) !is DeclarationStatus.Ready || definition(expected) !is DeclarationStatus.Ready) return false
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
            .filter { (it.representation as? RepresentationTemplate.Record)?.abstract != true }
            .flatMap { definition -> inferConcreteApplications(definition, expected.use) }
            .distinct()
            .mapNotNull { candidate ->
                val resolved = resolve(candidate) as? Resolution.Ready ?: return@mapNotNull null
                resolved.value.takeIf { isResolvedReadableAs(candidate, expected.use, resolved.value.schema) }
            }

    override fun validateAuthoring(record: AuthoringRecord): StructuralResult = record.validateStructure(this)

    private fun knownPendingApplications(selection: TypeSelection.Pending): Set<TypeUse.Named> {
        if (definition(selection.definition) !is DeclarationStatus.Ready) return emptySet()
        val root = definitions.getValue(selection.definition).single()
        if (selection.arguments.size != root.parameters.size) return emptySet()
        val bindings =
            root.parameters
                .zip(selection.arguments)
                .mapNotNull { (parameter, argument) ->
                    val chosen = argument as? ArgumentSelection.Chosen ?: return@mapNotNull null
                    if (resolve(chosen.type) !is Resolution.Ready) return@mapNotNull null
                    parameter.key to chosen.type
                }.toMap()
        val applications = linkedSetOf<TypeUse.Named>()
        val visited = mutableSetOf<Pair<TypeDefinitionId, Map<ParameterKey, TypeUse>>>()

        fun visit(
            current: TypeDefinition,
            known: Map<ParameterKey, TypeUse>,
        ) {
            if (!visited.add(current.id to known)) return
            if (current.parameters.all { it.key in known }) {
                val application = TypeUse.Named(current.id, current.parameters.map { known.getValue(it.key) })
                if (resolve(application) is Resolution.Ready) applications += application
            }
            current.parents.forEach { parentTemplate ->
                val parentDefinition = definitions[parentTemplate.definition]?.singleOrNull() ?: return@forEach
                if (definition(parentDefinition.id) !is DeclarationStatus.Ready) return@forEach
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

    private fun resolveNullable(candidate: TypeUse.Nullable): Resolution<CheckedType> =
        when (val inner = resolve(candidate.value)) {
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

    private fun resolveNamed(candidate: TypeUse.Named): Resolution<CheckedType> {
        val status = definition(candidate.definition)
        if (status is DeclarationStatus.Unavailable) return Resolution.Invalid(status.reasons)
        val definition = definitions.getValue(candidate.definition).single()
        if (candidate.arguments.size != definition.parameters.size) {
            return invalid(candidate.definition, "argument_arity")
        }
        val invalidArgument = candidate.arguments.firstNotNullOfOrNull { (resolve(it) as? Resolution.Invalid)?.diagnostics }
        if (invalidArgument != null) return Resolution.Invalid(invalidArgument)
        val bindings =
            definition.parameters
                .map(TypeParameter::key)
                .zip(candidate.arguments)
                .toMap()
        val resolvedArguments = candidate.arguments.associateWith { resolve(it) as Resolution.Ready }
        for (parameter in definition.parameters) {
            val actual = bindings.getValue(parameter.key)
            for (bound in parameter.bounds) {
                val applied = bound.apply(bindings)
                if (applied is Resolution.Invalid) return applied
                applied as Resolution.Ready
                if (resolve(applied.value) !is Resolution.Ready) return invalid(candidate.definition, "argument_bound")
                if (!isResolvedReadableAs(actual, applied.value, resolvedArguments.getValue(actual).value.schema)) {
                    return invalid(candidate.definition, "argument_bound")
                }
            }
        }

        val parentUses = mutableListOf<TypeUse.Named>()
        val parentFields = mutableListOf<ResolvedField>()
        val ancestors = linkedSetOf<TypeUse.Named>()
        for (parentTemplate in definition.parents) {
            val applied = parentTemplate.apply(bindings)
            if (applied is Resolution.Invalid) return applied
            val parent = (applied as Resolution.Ready).value as TypeUse.Named
            val resolvedParent = resolve(parent)
            if (resolvedParent is Resolution.Invalid) return resolvedParent
            resolvedParent as Resolution.Ready
            parentUses += parent
            parentFields += resolvedParent.value.schema.fields
            ancestors += parent
            ancestors += resolvedParent.value.schema.ancestors
        }
        if (ancestors.groupBy(TypeUse.Named::definition).values.any { uses -> uses.distinct().size > 1 }) {
            return invalid(candidate.definition, "inconsistent_parent_application")
        }

        val ownFields = (definition.representation as? RepresentationTemplate.Record)?.fields.orEmpty()
        val mergedFields = mergeFields(candidate.definition, parentFields, ownFields, bindings)
        if (mergedFields is Resolution.Invalid) return mergedFields
        mergedFields as Resolution.Ready
        val representation = resolveRepresentation(definition.representation, bindings, mergedFields.value)
        if (representation is Resolution.Invalid) return representation
        representation as Resolution.Ready
        val schema = AppliedSchema(candidate, representation.value, mergedFields.value, ancestors)
        return Resolution.Ready(CheckedType(generation, candidate, schema, this))
    }

    private fun resolvePending(selection: TypeSelection.Pending): Resolution<PartialSchema> {
        val status = definition(selection.definition)
        if (status is DeclarationStatus.Unavailable) return Resolution.Invalid(status.reasons)
        val definition = definitions.getValue(selection.definition).single()
        if (selection.arguments.size != definition.parameters.size) return invalid(selection.definition, "argument_arity")
        val bindings = mutableMapOf<ParameterKey, TypeUse>()
        val pending = mutableListOf<ArgumentLocation>()
        selection.arguments.forEachIndexed { index, argument ->
            when (argument) {
                is ArgumentSelection.Chosen -> {
                    val resolution = resolve(argument.type)
                    if (resolution is Resolution.Invalid) return resolution
                    bindings[definition.parameters[index].key] = argument.type
                }

                ArgumentSelection.Unfilled -> {
                    pending += ArgumentLocation(index)
                }
            }
        }
        if (pending.isEmpty()) {
            val complete = TypeUse.Named(selection.definition, definition.parameters.map { bindings.getValue(it.key) })
            return resolvePartial(TypeSelection.Complete(complete))
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
                known += ResolvedField(field.owner.name, field.owner.definition, (applied as Resolution.Ready).value)
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
            is RepresentationTemplate.Scalar -> {
                Resolution.Ready(ResolvedRepresentation.Scalar(representation.kind))
            }

            is RepresentationTemplate.Record -> {
                Resolution.Ready(ResolvedRepresentation.Record(fields, representation.abstract))
            }

            is RepresentationTemplate.Sequence -> {
                representation.item.apply(bindings).map { ResolvedRepresentation.Sequence(it, representation.kind) }
            }

            is RepresentationTemplate.Mapping -> {
                val key = representation.key.apply(bindings)
                if (key is Resolution.Invalid) return key
                val value = representation.value.apply(bindings)
                if (value is Resolution.Invalid) return value
                Resolution.Ready(ResolvedRepresentation.Mapping((key as Resolution.Ready).value, (value as Resolution.Ready).value))
            }

            is RepresentationTemplate.Enumeration -> {
                Resolution.Ready(ResolvedRepresentation.Enumeration(representation.cases))
            }

            is RepresentationTemplate.Link -> {
                representation.target.apply(bindings).map { ResolvedRepresentation.Link(representation.endpoint, it) }
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
            val inheritedOwners = inheritedFields.map { com.typewritermc.types.FieldOwner(it.declarationOwner, it.key) }.toSet()
            if (inheritedOwners.isNotEmpty() && !field.overrides.containsAll(inheritedOwners)) {
                return invalid(affected, "missing_field_override")
            }
            if (inheritedFields.any { !isReadableAs(applied.value, it.type) }) {
                return invalid(affected, "invalid_field_narrowing")
            }
            merged[field.owner.name] =
                ResolvedField(
                    field.owner.name,
                    field.owner.definition,
                    applied.value,
                    inheritedFields.flatMap(ResolvedField::guarantees).distinct(),
                )
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
                addAll(definition.parents)
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
        val fields = (definition.representation as? RepresentationTemplate.Record)?.fields.orEmpty()
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
                val dependencies = definition.requiredDefinitions()
                if (dependencies.any { it in unavailable }) {
                    markUnavailable(definition.id, "unavailable_dependency")
                    changed = true
                }
            }
        } while (changed)
    }

    private fun sameApplicationFamily(
        actual: TypeUse.Named,
        expected: TypeUse.Named,
    ): Boolean =
        actual.definition == expected.definition &&
            actual.arguments.size == expected.arguments.size &&
            actual.arguments.zip(expected.arguments).all { (left, right) -> isReadableAs(left, right) }

    private fun inferConcreteApplications(
        definition: TypeDefinition,
        expected: TypeUse,
    ): List<TypeUse.Named> {
        if (expected !is TypeUse.Named) return emptyList()
        val ownTemplate =
            TypeTemplate.Named(
                definition.id,
                definition.parameters.map { TypeTemplate.Parameter(it.key) },
            )
        return (listOf(ownTemplate) + ancestorTemplates(definition, linkedSetOf()))
            .asSequence()
            .filter { it.definition == expected.definition && it.arguments.size == expected.arguments.size }
            .mapNotNull { template ->
                val inferred = linkedMapOf<ParameterKey, TypeUse>()
                val matched = template.arguments.zip(expected.arguments).all { (left, right) -> infer(left, right, inferred) }
                if (!matched || definition.parameters.any { it.key !in inferred }) return@mapNotNull null
                TypeUse.Named(definition.id, definition.parameters.map { inferred.getValue(it.key) })
            }.toList()
    }

    private fun ancestorTemplates(
        definition: TypeDefinition,
        visiting: MutableSet<TypeDefinitionId>,
    ): List<TypeTemplate.Named> {
        if (!visiting.add(definition.id)) return emptyList()
        val ancestors = mutableListOf<TypeTemplate.Named>()
        for (parent in definition.parents) {
            ancestors += parent
            val parentDefinition = definitions[parent.definition]?.singleOrNull() ?: continue
            val substitutions =
                parentDefinition.parameters
                    .map(TypeParameter::key)
                    .zip(parent.arguments)
                    .toMap()
            ancestors += ancestorTemplates(parentDefinition, visiting).map { it.substitute(substitutions) as TypeTemplate.Named }
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
            is TypeTemplate.Parameter -> {
                inferred[template.key]?.let { it == actual } ?: run {
                    inferred[template.key] = actual
                    true
                }
            }

            is TypeTemplate.Scalar -> {
                actual == TypeUse.Scalar(template.kind)
            }

            is TypeTemplate.Nullable -> {
                actual is TypeUse.Nullable && infer(template.value, actual.value, inferred)
            }

            is TypeTemplate.Named -> {
                actual is TypeUse.Named &&
                    template.definition == actual.definition &&
                    template.arguments.size == actual.arguments.size &&
                    template.arguments.zip(actual.arguments).all { (left, right) -> infer(left, right, inferred) }
            }
        }

    private fun isResolvedReadableAs(
        actual: TypeUse,
        expected: TypeUse,
        actualSchema: AppliedSchema,
    ): Boolean {
        if (actual == expected) return true
        if (expected is TypeUse.Nullable) {
            return (actual is TypeUse.Nullable && isReadableAs(actual.value, expected.value)) ||
                (actual !is TypeUse.Nullable && isReadableAs(actual, expected.value))
        }
        if (actual is TypeUse.Nullable) return false
        if (actual is TypeUse.Scalar || expected is TypeUse.Scalar) return false
        actual as TypeUse.Named
        expected as TypeUse.Named
        if (sameApplicationFamily(actual, expected)) return true
        return actualSchema.ancestors.any { ancestor -> sameApplicationFamily(ancestor, expected) }
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
                expected is TypeTemplate.Nullable -> {
                    val value = if (actual is TypeTemplate.Nullable) actual.value else actual
                    isTemplateReadableAs(value, expected.value, parameterBounds, visiting)
                }

                actual is TypeTemplate.Nullable -> {
                    false
                }

                actual is TypeTemplate.Parameter -> {
                    parameterBounds[actual.key].orEmpty().any { bound ->
                        isTemplateReadableAs(bound, expected, parameterBounds, visiting)
                    }
                }

                expected is TypeTemplate.Parameter -> {
                    false
                }

                actual is TypeTemplate.Scalar || expected is TypeTemplate.Scalar -> {
                    false
                }

                actual is TypeTemplate.Named && expected is TypeTemplate.Named -> {
                    templateApplications(actual).any { application ->
                        application.definition == expected.definition &&
                            application.arguments.size == expected.arguments.size &&
                            application.arguments.zip(expected.arguments).all { (value, required) ->
                                isTemplateReadableAs(value, required, parameterBounds, visiting)
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

    private fun templateApplications(actual: TypeTemplate.Named): List<TypeTemplate.Named> {
        val applications = mutableListOf(actual)
        val pending = ArrayDeque<TypeTemplate.Named>()
        val visited = mutableSetOf<TypeTemplate.Named>()
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
                val applied = parent.substitute(bindings) as TypeTemplate.Named
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
        val own = (definition.representation as? RepresentationTemplate.Record)?.fields.orEmpty()
        return Resolution.Ready(inherited + own)
    }

    private fun ready(
        use: TypeUse,
        representation: ResolvedRepresentation,
    ): Resolution<CheckedType> =
        Resolution.Ready(CheckedType(generation, use, AppliedSchema(use, representation, emptyList(), emptySet()), this))

    private fun invalid(
        affected: TypeDefinitionId,
        code: String,
    ): Resolution.Invalid = Resolution.Invalid(listOf(diagnostic(affected, code)))

    private fun markUnavailable(
        id: TypeDefinitionId,
        code: String,
    ) {
        unavailable.getOrPut(id, ::mutableListOf) += diagnostic(id, code)
    }
}

private fun diagnostic(
    affected: TypeDefinitionId,
    code: String,
) = DeclarationDiagnostic(affected, code)

private fun TypeUse.typeDepthFailure(): TypeDefinitionId? {
    val pending = ArrayDeque<Pair<TypeUse, Int>>()
    pending.addLast(this to 1)
    var nearestDefinition: TypeDefinitionId? = null
    while (pending.isNotEmpty()) {
        val (current, depth) = pending.removeLast()
        if (current is TypeUse.Named && nearestDefinition == null) nearestDefinition = current.definition
        if (depth > MAX_TYPE_USE_DEPTH) {
            return (current as? TypeUse.Named)?.definition ?: nearestDefinition ?: TYPE_USE_DIAGNOSTIC_OWNER
        }
        when (current) {
            is TypeUse.Named -> current.arguments.asReversed().forEach { pending.addLast(it to depth + 1) }
            is TypeUse.Nullable -> pending.addLast(current.value to depth + 1)
            is TypeUse.Scalar -> Unit
        }
    }
    return null
}

private fun TypeDefinition.exceedsTypeDepth(): Boolean {
    val roots = mutableListOf<TypeTemplate>()
    parameters.forEach { roots += it.bounds }
    roots += parents
    when (val shape = representation) {
        is RepresentationTemplate.Scalar, is RepresentationTemplate.Enumeration -> {
        }

        is RepresentationTemplate.Record -> {
            shape.fields.forEach { roots += it.type }
        }

        is RepresentationTemplate.Sequence -> {
            roots += shape.item
        }

        is RepresentationTemplate.Mapping -> {
            roots += shape.key
            roots += shape.value
        }

        is RepresentationTemplate.Link -> {
            roots += shape.target
        }
    }
    val pending = ArrayDeque<Pair<TypeTemplate, Int>>()
    roots.asReversed().forEach { pending.addLast(it to 1) }
    while (pending.isNotEmpty()) {
        val (current, depth) = pending.removeLast()
        if (depth > MAX_TYPE_USE_DEPTH) return true
        when (current) {
            is TypeTemplate.Named -> current.arguments.asReversed().forEach { pending.addLast(it to depth + 1) }
            is TypeTemplate.Nullable -> pending.addLast(current.value to depth + 1)
            is TypeTemplate.Parameter, is TypeTemplate.Scalar -> Unit
        }
    }
    return false
}

private const val MAX_TYPE_USE_DEPTH = 512
private val TYPE_USE_DIAGNOSTIC_OWNER = TypeDefinitionId(TypeId.Qualified("typewriter", "TypeUse"), 1)

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

private fun TypeTemplate.parameterKeys(): Set<ParameterKey> =
    when (this) {
        is TypeTemplate.Parameter -> setOf(key)
        is TypeTemplate.Named -> arguments.flatMapTo(linkedSetOf()) { it.parameterKeys() }
        is TypeTemplate.Nullable -> value.parameterKeys()
        is TypeTemplate.Scalar -> emptySet()
    }

private fun RepresentationTemplate.templates(): List<TypeTemplate> =
    when (this) {
        is RepresentationTemplate.Scalar,
        is RepresentationTemplate.Enumeration,
        -> emptyList()

        is RepresentationTemplate.Record -> fields.map(FieldDeclaration::type)

        is RepresentationTemplate.Sequence -> listOf(item)

        is RepresentationTemplate.Mapping -> listOf(key, value)

        is RepresentationTemplate.Link -> listOf(target)
    }

private fun TypeDefinition.requiredDefinitions(): Set<TypeDefinitionId> =
    buildSet {
        parents.forEach { add(it.definition) }
        parameters.flatMap(TypeParameter::bounds).forEach { addAll(it.namedDefinitions()) }
        representation.templates().forEach { addAll(it.namedDefinitions()) }
    }

private fun TypeTemplate.namedDefinitions(): Set<TypeDefinitionId> =
    when (this) {
        is TypeTemplate.Parameter,
        is TypeTemplate.Scalar,
        -> {
            emptySet()
        }

        is TypeTemplate.Nullable -> {
            value.namedDefinitions()
        }

        is TypeTemplate.Named -> {
            buildSet {
                add(definition)
                arguments.forEach { addAll(it.namedDefinitions()) }
            }
        }
    }

private fun TypeTemplate.namedTemplates(): List<TypeTemplate.Named> =
    when (this) {
        is TypeTemplate.Parameter,
        is TypeTemplate.Scalar,
        -> emptyList()

        is TypeTemplate.Nullable -> value.namedTemplates()

        is TypeTemplate.Named -> listOf(this) + arguments.flatMap { it.namedTemplates() }
    }

private fun TypeTemplate.substituteKnown(bindings: Map<ParameterKey, TypeUse>): TypeTemplate =
    when (this) {
        is TypeTemplate.Parameter -> bindings[key]?.toTemplate() ?: this
        is TypeTemplate.Named -> copy(arguments = arguments.map { it.substituteKnown(bindings) })
        is TypeTemplate.Nullable -> copy(value = value.substituteKnown(bindings))
        is TypeTemplate.Scalar -> this
    }

private fun TypeTemplate.substitute(bindings: Map<ParameterKey, TypeTemplate>): TypeTemplate =
    when (this) {
        is TypeTemplate.Parameter -> bindings[key] ?: this
        is TypeTemplate.Named -> copy(arguments = arguments.map { it.substitute(bindings) })
        is TypeTemplate.Nullable -> copy(value = value.substitute(bindings))
        is TypeTemplate.Scalar -> this
    }

private fun TypeUse.toTemplate(): TypeTemplate =
    when (this) {
        is TypeUse.Named -> TypeTemplate.Named(definition, arguments.map { it.toTemplate() })
        is TypeUse.Nullable -> TypeTemplate.Nullable(value.toTemplate())
        is TypeUse.Scalar -> TypeTemplate.Scalar(kind)
    }
