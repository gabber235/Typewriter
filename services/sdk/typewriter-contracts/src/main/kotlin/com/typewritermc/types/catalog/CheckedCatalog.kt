package com.typewritermc.types.catalog

import com.typewritermc.types.FORMULA_USE
import com.typewritermc.types.MAX_TYPE_DEPTH
import com.typewritermc.types.catalog.of
import com.typewritermc.types.catalog.reasons
import com.typewritermc.types.closedCases
import com.typewritermc.types.immutableListCopy
import com.typewritermc.types.isInstantiable
import com.typewritermc.types.mapTypes
import com.typewritermc.types.match
import com.typewritermc.types.member
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.parameterKeys
import com.typewritermc.types.parts
import com.typewritermc.types.qualified
import com.typewritermc.types.substitute
import com.typewritermc.types.template
import com.typewritermc.types.toTemplate
import com.typewritermc.types.toUse
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import com.typewritermc.types.walk
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.type_catalog.AppliedSchema
import skirout.editor.v1.type_catalog.ArgumentLocation
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DependentField
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PartialSchema
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResolvedField
import skirout.editor.v1.type_catalog.ResolvedRecordForm
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId
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

    /**
     * What [owner]'s configured [selection] means here: the creator's choices with every argument derived from the
     * owner's content filled. Complete when every parameter has an argument, partial while one has none. This is what a
     * resource's values mean; readers ask it and never read the stored selection.
     */
    fun typeOf(
        owner: ResourceId,
        selection: TypeSelection,
    ): Resolution<ResourceType>

    /**
     * What the creator's choices in [selection] make, with no argument derived from content: the answer for which
     * resources a selection is (matching, discovery) and for content that is on no resource yet.
     */
    fun authoredTypeOf(selection: TypeSelection): Resolution<ResourceType>

    /**
     * The applications the creator's choices in [selection] are known to read as: a complete type and its ancestors, or
     * the ancestors a partial type already fixes. Empty when the selection does not resolve.
     */
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

    /**
     * The code catalog plus what [source] declares. Cheap: it validates and caches only what it reaches, so [source]
     * must not change while the result is in use.
     */
    fun withContent(source: ContentSource): CheckedCatalog

    /** [use] with every field key replaced by where its chain leads. The code catalog has none, so it answers [use]. */
    fun expand(use: TypeUse): TypeUse
}

/** This template with each parameter replaced by its use in [arguments]; invalid at the first parameter [arguments] leaves unbound. */
fun TypeTemplate.apply(arguments: Map<ParameterKey, TypeUse>): Resolution<TypeUse> =
    toUse(arguments::get)?.let { Resolution.Ready(it) }
        ?: Resolution.Invalid(listOf(diagnostic(parameterKeys().first { it !in arguments }.owner, "missing_parameter_binding")))

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
class DefaultCheckedCatalog private constructor(
    override val generation: CatalogGeneration,
    private val validated: ValidatedDeclarations,
    private val content: ContentLayer?,
) : CheckedCatalog {
    constructor(
        generation: CatalogGeneration,
        declarations: List<TypeDefinition>,
        quarantine: List<DeclarationDiagnostic> = emptyList(),
    ) : this(generation, ValidatedDeclarations(declarations, quarantine), null)

    private val definitions get() = validated.definitions
    private val unavailable get() = validated.unavailable

    // The cache and the reentrancy guard stay per instance: an overlay's answers depend on its source.
    private val cache = ConcurrentHashMap<ResolutionKey, Resolution<CheckedType>>()
    private val resolving = mutableSetOf<TypeUse>()

    /** Shares the code catalog's validated declarations, so an overlay costs nothing until it reaches a content id. */
    override fun withContent(source: ContentSource): CheckedCatalog {
        val base = content?.base ?: this
        return DefaultCheckedCatalog(generation, base.validated, ContentLayer(base, source))
    }

    /** The code catalog plus [source] judged by the declaration rules alone, which a declaration's bound check resolves through. */
    internal fun withDeclaredContent(source: ContentSource): DefaultCheckedCatalog =
        DefaultCheckedCatalog(generation, validated, ContentLayer(this, source, checksBounds = false))

    override fun expand(use: TypeUse): TypeUse {
        val layer = content ?: return use
        return if (use.mentionsContent()) layer.expandFieldKeys(use, emptySet()) else use
    }

    /** The public answer, and the only one that says why a content id stands in as the error type. */
    override fun definition(id: TypeDefinitionId): DeclarationStatus {
        val layer = content
        if (layer == null || id.contentOwner() == null) return status(id)
        return when (val target = layer.target(id)) {
            is ContentTarget.Declared -> {
                layer
                    .invalid(target.definition.id)
                    .takeIf { it.isNotEmpty() }
                    ?.let { codes -> DeclarationStatus.UnavailableWrapper(codes.map { diagnostic(id, it) }) }
                    ?: DeclarationStatus.READY
            }

            // An alias of a type that exists. One that contains itself (A := List<A>) or names a gone alias keeps a field key after expansion.
            is ContentTarget.Plain -> {
                layer
                    .leftover(target.use, id)
                    .takeIf { it.isNotEmpty() }
                    ?.let { codes -> DeclarationStatus.UnavailableWrapper(codes.map { diagnostic(id, it) }) }
                    ?: DeclarationStatus.READY
            }

            ContentTarget.Missing -> {
                DeclarationStatus.UnavailableWrapper(listOf(diagnostic(id, "content_type_missing")))
            }

            ContentTarget.Loop -> {
                DeclarationStatus.UnavailableWrapper(listOf(diagnostic(id, "content_alias_loop")))
            }
        }
    }

    override fun declaration(id: TypeDefinitionId): Resolution<TypeDefinition> {
        val expanded = content?.expandId(id) ?: id
        return when (val status = definition(expanded)) {
            DeclarationStatus.READY -> Resolution.Ready(checkNotNull(lookup(expanded)))
            is DeclarationStatus.UnavailableWrapper -> Resolution.Invalid(status.reasons)
            else -> unknownVariant(status)
        }
    }

    /** The resolver's status: the error type is READY, so a use of a gone content type resolves and no reader needs an exception. */
    private fun status(id: TypeDefinitionId): DeclarationStatus {
        unavailable[id]?.let { return DeclarationStatus.UnavailableWrapper(it.distinct()) }
        return if (lookup(id) ==
            null
        ) {
            DeclarationStatus.UnavailableWrapper(listOf(diagnostic(id, "unknown_definition")))
        } else {
            DeclarationStatus.READY
        }
    }

    /** The definition behind [id] for the resolver. A content id whose chain loops, ends at nothing or is invalid answers the error type. */
    private fun lookup(id: TypeDefinitionId): TypeDefinition? {
        definitions[id]?.singleOrNull()?.let { return it }
        val layer = content ?: return null
        if (id.contentOwner() == null) return null
        return when (val target = layer.target(id)) {
            is ContentTarget.Declared -> {
                if (layer.invalid(target.definition.id).isEmpty()) layer.expandFields(target.definition) else errorRecord(id)
            }

            is ContentTarget.Plain, ContentTarget.Loop, ContentTarget.Missing -> {
                errorRecord(id)
            }
        }
    }

    override fun resolve(candidate: TypeUse): Resolution<CheckedType> {
        val layer = content ?: return resolveHere(candidate)
        if (!candidate.mentionsContent()) return layer.base.resolve(candidate).resolvingHere()
        return resolveHere(layer.expandFieldKeys(candidate, emptySet()))
    }

    /**
     * The code catalog's answer, resolving what it holds through this catalog: a code type can hold content, such as a
     * `Type` value naming a declaration, so its nested values must reach the content this catalog sees.
     */
    private fun Resolution<CheckedType>.resolvingHere(): Resolution<CheckedType> =
        when (this) {
            is Resolution.Ready -> Resolution.Ready(CheckedType(value.catalog, value.use, value.schema, this@DefaultCheckedCatalog))
            is Resolution.Invalid -> this
        }

    /**
     * A part of a use [resolve] already expanded. Expanding it again would unfold an alias that contains itself one level
     * deeper and meet the use being resolved, so its leftover field keys stay and resolve as the error type.
     */
    private fun resolveExpanded(part: TypeUse): Resolution<CheckedType> =
        if (content == null ||
            !part.mentionsContent()
        ) {
            resolve(part)
        } else {
            resolveHere(part)
        }

    private fun resolveHere(candidate: TypeUse): Resolution<CheckedType> {
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
                        is TypeUse.FunctionWrapper -> resolveFunction(candidate)
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

    override fun typeOf(
        owner: ResourceId,
        selection: TypeSelection,
    ): Resolution<ResourceType> = authoredTypeOf(selection)

    override fun authoredTypeOf(selection: TypeSelection): Resolution<ResourceType> {
        val availability = status(selection.definition)
        if (availability is DeclarationStatus.UnavailableWrapper) return Resolution.Invalid(availability.reasons)
        val definition = checkNotNull(lookup(selection.definition))
        val chosen = chosenArguments(selection, definition) ?: return invalid(selection.definition, "argument_arity")
        if (chosen.size == definition.parameters.size) {
            return when (val resolved = resolve(selection.definition.namedUse(definition.parameters.map { chosen.getValue(it.key) }).use)) {
                is Resolution.Invalid -> resolved
                is Resolution.Ready -> Resolution.Ready(ResourceType.Complete(resolved.value))
            }
        }
        return resolvePartial(definition, chosen.mapValues { expand(it.value) })
    }

    override fun knownApplications(selection: TypeSelection): Set<NamedTypeUse> =
        when (val type = authoredTypeOf(selection)) {
            is Resolution.Invalid -> {
                emptySet()
            }

            is Resolution.Ready -> {
                when (val resolved = type.value) {
                    is ResourceType.Complete -> {
                        linkedSetOf(checkNotNull(resolved.checked.use.named)).apply { addAll(resolved.checked.schema.ancestors) }
                    }

                    is ResourceType.Partial -> {
                        val definition = checkNotNull(lookup(selection.definition))
                        knownPartialApplications(definition, checkNotNull(chosenArguments(selection, definition)).mapValues { expand(it.value) })
                    }
                }
            }
        }

    /** The arguments a creator chose for [definition], by parameter key. Null when a choice names a parameter [definition] does not have, or names one twice. */
    private fun chosenArguments(
        selection: TypeSelection,
        definition: TypeDefinition,
    ): Map<ParameterKey, TypeUse>? {
        val chosen = linkedMapOf<ParameterKey, TypeUse>()
        for (argument in selection.arguments) {
            val parameter = definition.parameters.getOrNull(argument.parameter) ?: return null
            if (chosen.put(parameter.key, argument.type) != null) return null
        }
        return chosen
    }

    /** [template] with every field key replaced by where its chain leads. A field key names no parameters, so it expands as a use. */
    private fun expandTemplate(template: TypeTemplate): TypeTemplate =
        if (content == null) {
            template
        } else {
            template.mapTypes { node ->
                val named = node.named ?: return@mapTypes null
                if (named.definition.namesFieldKey()) expand(named.definition.use()).toTemplate() else null
            }
        }

    override fun isReadableAs(
        actual: TypeUse,
        expected: TypeUse,
    ): Boolean {
        val expandedActual = expand(actual)
        val expandedExpected = expand(expected)
        val resolvedActual = resolve(expandedActual) as? Resolution.Ready ?: return false
        if (resolve(expandedExpected) !is Resolution.Ready) return false
        return isResolvedReadableAs(expandedActual, expandedExpected, resolvedActual.value.schema)
    }

    override fun isTemplateReadableAs(
        actual: TypeTemplate,
        expected: TypeTemplate,
        parameterBounds: Map<ParameterKey, List<TypeTemplate>>,
    ): Boolean = isTemplateReadableAs(expandTemplate(actual), expandTemplate(expected), parameterBounds, linkedSetOf())

    /** An id whose chain does not end at a declaration is the error type: a subtype of nothing but itself. */
    override fun isNominalSubtype(
        actual: TypeDefinitionId,
        expected: TypeDefinitionId,
    ): Boolean {
        val layer = content
        val from = if (layer == null) actual else layer.expandId(actual) ?: return actual == expected
        val to = if (layer == null) expected else layer.expandId(expected) ?: return false
        if (status(from) != DeclarationStatus.READY || status(to) != DeclarationStatus.READY) return false
        val visited = mutableSetOf<TypeDefinitionId>()
        val pending = ArrayDeque<TypeDefinitionId>()
        pending.add(from)
        while (pending.isNotEmpty()) {
            val current = pending.removeFirst()
            if (!visited.add(current)) continue
            if (current == to) return true
            lookup(current)?.parents?.forEach { pending.add(it.definition) }
        }
        return false
    }

    override fun concreteForms(expected: CheckedType): List<CheckedType> {
        expected.schema.representation.closedCases()?.let { cases ->
            return cases
                .mapNotNull { case -> (resolve(case.use) as? Resolution.Ready)?.value }
                .flatMap { case -> if (case.schema.representation.isInstantiable()) listOf(case) else concreteForms(case) }
                .distinct()
                // A case of a generic union may fix its parent's arguments (`Count : Result<Int>`), so it is a form of
                // only the applications it reads as.
                .filter { case -> isResolvedReadableAs(case.use, expected.use, case.schema) }
        }
        return definitions.values
            .filter { it.size == 1 }
            .map(List<TypeDefinition>::single)
            .filter { it.representation.isInstantiable() }
            .flatMap { definition -> inferConcreteApplications(definition, expected.use) }
            .distinct()
            .mapNotNull { named ->
                val candidate = named.use
                val resolved = resolve(candidate) as? Resolution.Ready ?: return@mapNotNull null
                resolved.value.takeIf { isResolvedReadableAs(candidate, expected.use, resolved.value.schema) }
            }
    }

    private fun knownPartialApplications(
        root: TypeDefinition,
        chosen: Map<ParameterKey, TypeUse>,
    ): Set<NamedTypeUse> {
        val bindings = chosen.filterValues { resolve(it) is Resolution.Ready }
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
                val parentDefinition = lookup(parentTemplate.definition) ?: return@forEach
                if (status(parentDefinition.id) != DeclarationStatus.READY) return@forEach
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

    /**
     * A function type checks as itself and stores as the Formula record: its schema is Formula's, under the function's
     * own use, so checking sees the function and storage sees the record.
     */
    private fun resolveFunction(candidate: TypeUse.FunctionWrapper): Resolution<CheckedType> {
        candidate.parts().forEach { part -> (resolveExpanded(part) as? Resolution.Invalid)?.let { return it } }
        return when (val formula = resolveNamed(FORMULA_USE)) {
            is Resolution.Invalid -> formula
            is Resolution.Ready -> Resolution.Ready(CheckedType(generation, candidate, formula.value.schema.copy(use = candidate), this))
        }
    }

    private fun resolveNullable(candidate: TypeUse.NullableWrapper): Resolution<CheckedType> =
        when (val inner = resolveExpanded(candidate.value.value)) {
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
        val availability = status(candidate.definition)
        if (availability is DeclarationStatus.UnavailableWrapper) return Resolution.Invalid(availability.reasons)
        val definition = checkNotNull(lookup(candidate.definition))
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
        candidate.named?.let { named -> return validateApplication(named, visiting).map { Unit } }
        return candidate.parts().mapResolution { validateTypeApplication(it, visiting) }.map { Unit }
    }

    private fun resolveNamed(candidate: NamedTypeUse): Resolution<CheckedType> {
        val application = validateApplication(candidate)
        if (application is Resolution.Invalid) return application
        val bindings = (application as Resolution.Ready).value
        val definition = checkNotNull(lookup(candidate.definition))
        val invalidArgument = candidate.arguments.firstNotNullOfOrNull { (resolveExpanded(it) as? Resolution.Invalid)?.diagnostics }
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

    /** The partial type of [definition] under the [bindings] a creator chose, while at least one parameter has none. */
    private fun resolvePartial(
        definition: TypeDefinition,
        bindings: Map<ParameterKey, TypeUse>,
    ): Resolution<ResourceType> {
        for (argument in bindings.values) {
            val resolution = resolve(argument)
            if (resolution is Resolution.Invalid) return resolution
        }
        val pending = definition.parameters.withIndex().filter { it.value.key !in bindings }.map { ArgumentLocation(index = it.index) }
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
                known += resolvedField(field, (applied as Resolution.Ready).value)
            } else {
                dependent += DependentField(owner = field.owner, type = field.type, missing = missing)
            }
        }
        return Resolution.Ready(
            ResourceType.Partial(definition.id, PartialSchema(knownFields = known, dependentFields = dependent, pendingArguments = pending)),
        )
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
                representation.value.form
                    .resolve(bindings)
                    .map { form -> ResolvedRepresentation.createRecord(fields = fields, form = form) }
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
                resolvedField(field, applied.value, inheritedFields.flatMap(ResolvedField::guarantees).distinct())
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

    private fun RecordForm.resolve(bindings: Map<ParameterKey, TypeUse>): Resolution<ResolvedRecordForm> =
        when (this) {
            RecordForm.CONCRETE -> {
                Resolution.Ready(ResolvedRecordForm.CONCRETE)
            }

            RecordForm.OPEN -> {
                Resolution.Ready(ResolvedRecordForm.OPEN)
            }

            is RecordForm.ClosedWrapper -> {
                val cases =
                    value.cases.map { case ->
                        when (val applied = case.template.apply(bindings)) {
                            is Resolution.Invalid -> return applied
                            is Resolution.Ready -> applied.value.named ?: return invalid(case.definition, "invalid_case")
                        }
                    }
                Resolution.Ready(ResolvedRecordForm.createClosed(cases = cases))
            }

            else -> {
                unknownVariant(this)
            }
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
                if (!template.template.match(expectedUse, inferred) ||
                    definition.parameters.any { it.key !in inferred }
                ) {
                    return@mapNotNull null
                }
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
            val parentDefinition = lookup(parent.definition) ?: continue
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
            val definition = lookup(current.definition) ?: continue
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
                lookup(parent.definition)
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
                    field.copy(type = field.type.substitute(parentBindings.mapValues { (_, use) -> use.toTemplate() }))
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
}

/**
 * The validated code declarations of one generation. Overlays share them, so a view's catalog never validates code
 * again. They are written only while this is built.
 */
private class ValidatedDeclarations(
    declarations: List<TypeDefinition>,
    quarantine: List<DeclarationDiagnostic>,
) {
    private val depthInvalidDefinitions = declarations.filter(TypeDefinition::exceedsTypeDepth).map(TypeDefinition::id).toSet()
    val definitions: Map<TypeDefinitionId, List<TypeDefinition>> =
        declarations
            .filterNot { it.id in depthInvalidDefinitions }
            .groupBy(TypeDefinition::id)
    private val reasons = linkedMapOf<TypeDefinitionId, MutableList<DeclarationDiagnostic>>()
    val unavailable: Map<TypeDefinitionId, List<DeclarationDiagnostic>> get() = reasons

    init {
        depthInvalidDefinitions.forEach { markUnavailable(it, "type_depth_limit") }
        definitions
            .filterValues { it.size == 1 }
            .values
            .map(List<TypeDefinition>::single)
            .forEach(::validateDeclaration)
        definitions.values
            .flatten()
            .structuralProblems()
            .forEach { (id, codes) -> codes.forEach { markUnavailable(id, it) } }
        quarantine.forEach(::markUnavailable)
        propagateUnavailableDependencies()
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
        templates.flatMap { template -> template.walk().mapNotNull { it.named } }.forEach { named ->
            val target = definitions[named.definition]
            if (target == null) {
                markUnavailable(definition.id, "unknown_dependency")
            } else if (target.size == 1 && named.arguments.size != target.single().parameters.size) {
                markUnavailable(definition.id, "template_argument_arity")
            }
        }
    }

    private fun propagateUnavailableDependencies() {
        var changed: Boolean
        do {
            changed = false
            definitions.values.mapNotNull(List<TypeDefinition>::singleOrNull).forEach { definition ->
                if (definition.id in reasons) return@forEach
                val dependencies = definition.storedDefinitions()
                if (dependencies.any { it in reasons }) {
                    markUnavailable(definition.id, "unavailable_dependency")
                    changed = true
                }
            }
        } while (changed)
    }

    private fun markUnavailable(
        id: TypeDefinitionId,
        code: String,
    ) = markUnavailable(DeclarationDiagnostic.of(id, code))

    private fun markUnavailable(diagnostic: DeclarationDiagnostic) {
        val existing = reasons.getOrPut(diagnostic.affected, ::mutableListOf)
        val previous = existing.indexOfFirst { it.code == diagnostic.code && it.field == diagnostic.field }
        val origins = if (previous < 0) diagnostic.origins else existing[previous].origins + diagnostic.origins
        val owned =
            diagnostic.copy(
                origins = origins.distinct().immutableListCopy(),
                field = diagnostic.field?.let { it.copy(segments = it.segments.immutableListCopy()) },
            )
        if (previous < 0) existing += owned else existing[previous] = owned
    }
}

/** What a view's catalog adds to the code catalog: the declarations [source] holds, validated once per owner when first reached. */
private class ContentLayer(
    val base: DefaultCheckedCatalog,
    val source: ContentSource,
    private val checksBounds: Boolean = true,
) {
    private val problemsByOwner = ConcurrentHashMap<ResourceId, Map<TypeDefinitionId, List<String>>>()

    /** The same content without bound checks, so judging a declaration's bounds never asks for its own judgement. */
    private val declared by lazy { base.withDeclaredContent(source) }

    /** The one walk for every content id: a field key through its chain, a member through its owner, a generated key on its owner. */
    fun target(
        id: TypeDefinitionId,
        visiting: Set<TypeDefinitionId> = emptySet(),
    ): ContentTarget {
        if (id.fieldKey() == null && id.namesFieldKey()) {
            val member = (id.typeId as TypeId.MemberWrapper).value
            val owner = TypeDefinitionId(typeId = member.owner, revision = id.revision)
            return when (val found = target(owner, visiting)) {
                is ContentTarget.Declared -> target(found.definition.id.member(member.name), visiting)
                is ContentTarget.Plain -> ContentTarget.Missing
                ContentTarget.Loop, ContentTarget.Missing -> found
            }
        }
        val owner = checkNotNull(id.contentOwner())
        val field =
            id.fieldKey()
                ?: return source.declarations(owner).firstOrNull { it.id == id }?.let(ContentTarget::Declared) ?: ContentTarget.Missing
        if (id in visiting) return ContentTarget.Loop
        val held = source.heldType(owner, field) ?: return ContentTarget.Missing
        val next =
            held.named?.definition?.takeIf { it.contentOwner() != null && held.named?.arguments.isNullOrEmpty() }
                ?: return ContentTarget.Plain(held)
        return target(next, visiting + id)
    }

    /** Replaces each field key by where its chain leads, all through the use. A key whose chain loops or ends at nothing stays. */
    fun expandFieldKeys(
        use: TypeUse,
        visiting: Set<TypeDefinitionId>,
    ): TypeUse =
        use.mapNamed { named ->
            if (!named.definition.namesFieldKey() || named.definition in visiting) return@mapNamed null
            when (val found = target(named.definition)) {
                is ContentTarget.Declared -> found.definition.id.use()
                is ContentTarget.Plain -> expandFieldKeys(found.use, visiting + named.definition)
                ContentTarget.Loop, ContentTarget.Missing -> null
            }
        }

    /** The declared id an id stands for, or null when its chain does not end at a declaration. */
    fun expandId(id: TypeDefinitionId): TypeDefinitionId? =
        if (!id.namesFieldKey()) id else (target(id) as? ContentTarget.Declared)?.definition?.id

    /** Why field keys stay in [use] after expansion from [id]: a key back to [id] or into a loop is an alias loop, a dead end is missing. */
    fun leftover(
        use: TypeUse,
        id: TypeDefinitionId,
    ): List<String> =
        expandFieldKeys(use, setOf(id))
            .referencedDefinitions()
            .filter { it.namesFieldKey() }
            .map { key -> if (key == id || target(key) == ContentTarget.Loop) "content_alias_loop" else "content_type_missing" }
            .distinct()
            .sorted()

    /** The creator rules over the owner's whole list, once per owner: the boundary check for untrusted declarations. */
    fun invalid(id: TypeDefinitionId): List<String> {
        val owner = checkNotNull(id.contentOwner())
        return problemsByOwner
            .getOrPut(owner) {
                val declarations = source.declarations(owner)
                val problems = declarations.declarationProblems(owner)
                if (!checksBounds) return@getOrPut problems
                problems +
                    declarations
                        .filter { it.id !in problems }
                        .associate { it.id to it.boundProblems() }
                        .filterValues { it.isNotEmpty() }
            }[id]
            .orEmpty()
    }

    /**
     * `argument_bound` when a code type this declaration holds applies an argument outside its parameter's bound, as
     * `Ref<Int>` and `Ref` to a content record do. Code declarations resolve each use when it is read; a creator's
     * declaration is refused up front.
     */
    private fun TypeDefinition.boundProblems(): List<String> =
        representation
            .templates()
            .mapNotNull { (it.apply(emptyMap()) as? Resolution.Ready)?.value }
            .any { use -> (declared.resolve(use) as? Resolution.Invalid)?.diagnostics?.any { it.code == "argument_bound" } == true }
            .let { if (it) listOf("argument_bound") else emptyList() }

    /** The declaration with every field key in its templates replaced by where its chain leads. Content declarations take no parameters. */
    fun expandFields(definition: TypeDefinition): TypeDefinition =
        definition.mapTemplates { template ->
            template.mapTypes { node ->
                val named = node.named ?: return@mapTypes null
                if (named.definition.namesFieldKey()) expandFieldKeys(named.definition.use(), emptySet()).toTemplate() else null
            }
        }
}

/** Where a content id leads. resolve and definition both ask this one walk. */
private sealed interface ContentTarget {
    data class Declared(
        val definition: TypeDefinition,
    ) : ContentTarget

    /** An alias: a held type with no content id at its top. */
    data class Plain(
        val use: TypeUse,
    ) : ContentTarget

    data object Loop : ContentTarget

    data object Missing : ContentTarget
}

/** The error type: an empty concrete record with no parents. definition(id) says why it stands in. */
private fun errorRecord(id: TypeDefinitionId) =
    TypeDefinition(
        id = id,
        parameters = emptyList(),
        parents = emptyList(),
        representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
    )

/** This declaration with [transform] applied to every template it holds: parents, bounds and its representation's. */
private fun TypeDefinition.mapTemplates(transform: (TypeTemplate) -> TypeTemplate): TypeDefinition {
    fun named(template: NamedTypeTemplate): NamedTypeTemplate =
        (transform(template.template) as? TypeTemplate.NamedWrapper)?.value ?: template
    val representation =
        when (val shape = representation) {
            is RepresentationTemplate.RecordWrapper -> {
                val record = shape.value
                val form =
                    (record.form as? RecordForm.ClosedWrapper)?.let { closed ->
                        RecordForm.createClosed(cases = closed.value.cases.map(::named))
                    } ?: record.form
                RepresentationTemplate.createRecord(fields = record.fields.map { it.copy(type = transform(it.type)) }, form = form)
            }

            is RepresentationTemplate.SequenceWrapper -> {
                RepresentationTemplate.createSequence(item = transform(shape.value.item), kind = shape.value.kind)
            }

            is RepresentationTemplate.MappingWrapper -> {
                RepresentationTemplate.createMapping(key = transform(shape.value.key), value = transform(shape.value.value))
            }

            is RepresentationTemplate.LinkWrapper -> {
                RepresentationTemplate.createLink(endpoint = shape.value.endpoint, target = transform(shape.value.target))
            }

            else -> {
                shape
            }
        }
    return copy(
        parameters = parameters.map { parameter -> parameter.copy(bounds = parameter.bounds.map(transform)) },
        parents = parents.map(::named),
        representation = representation,
    )
}

private fun diagnostic(
    affected: TypeDefinitionId,
    code: String,
) = DeclarationDiagnostic.of(affected, code)

/**
 * Keys memoized resolutions by a structural hash that allocates nothing for named and scalar uses; generated Skir hash
 * codes build a list per struct, which made every cache hit several times slower. Equality is the generated structural
 * equality.
 */
private class ResolutionKey(
    val use: TypeUse,
) {
    private val hash = use.structuralHash()

    override fun hashCode(): Int = hash

    override fun equals(other: Any?): Boolean = other is ResolutionKey && other.hash == hash && other.use == use
}

private fun TypeUse.structuralHash(): Int = parts().fold(ownHash()) { hash, part -> 31 * hash + part.structuralHash() }

/** The hash of what this node says itself, not counting its parts: its form, definition, scalar or slot names. */
private fun TypeUse.ownHash(): Int =
    when (this) {
        is TypeUse.NamedWrapper -> {
            value.definition.structuralHash()
        }

        is TypeUse.NullableWrapper -> {
            kind.ordinal
        }

        is TypeUse.ScalarWrapper -> {
            value.structuralHash()
        }

        is TypeUse.FunctionWrapper -> {
            (value.context + value.parameters).fold(kind.ordinal) { hash, slot -> 31 * hash + slot.name.hashCode() }
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun TypeDefinitionId.structuralHash(): Int {
    val identity =
        when (val id = typeId) {
            is TypeId.DeclaredWrapper -> id.value.value.hashCode()
            is TypeId.QualifiedWrapper -> 31 * id.value.namespace.hashCode() + id.value.name.hashCode()
            is TypeId.MemberWrapper -> 31 * id.value.owner.hashCode() + id.value.name.hashCode()
            is TypeId.ContentWrapper -> 31 * id.value.resource.hashCode() + id.value.key.hashCode()
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
        current
            .parts()
            .asReversed()
            .forEach { pending.addLast(it to depth + 1) }
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
        current
            .parts()
            .asReversed()
            .forEach { pending.addLast(it to depth + 1) }
    }
    return false
}

private val TYPE_USE_DIAGNOSTIC_OWNER = TypeDefinitionId.qualified("typewriter", "TypeUse")

private fun resolvedField(
    declaration: FieldDeclaration,
    type: TypeUse,
    guarantees: List<skirout.editor.v1.type_catalog.RuleId> = emptyList(),
) = ResolvedField(
    key = declaration.owner.name,
    declarationOwner = declaration.owner.definition,
    type = type,
    guarantees = guarantees,
    hasConstructorDefault = declaration.hasConstructorDefault,
)

private fun <T, R> Resolution<T>.flatMap(transform: (T) -> Resolution<R>): Resolution<R> =
    when (this) {
        is Resolution.Invalid -> this
        is Resolution.Ready -> transform(value)
    }

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

/** Reports declaration readiness from this catalog generation's canonical quarantine. */
fun CheckedCatalog.isReady(id: TypeDefinitionId): Boolean = definition(id) == DeclarationStatus.READY

/** Checks the declarations a named template references while preserving symbolic free parameters. */
fun CheckedCatalog.isReady(template: NamedTypeTemplate): Boolean = isReady(template.definition) && template.arguments.all(::isReady)

/** Checks referenced declarations while preserving symbolic free parameters. */
fun CheckedCatalog.isReady(template: TypeTemplate): Boolean = template.walk().all { node -> node.named?.definition?.let(::isReady) ?: true }
