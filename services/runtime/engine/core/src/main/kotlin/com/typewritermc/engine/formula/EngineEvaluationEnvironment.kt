package com.typewritermc.engine.formula

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.FieldPath
import com.typewritermc.authoring.append
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.field
import com.typewritermc.authoring.name
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.text
import com.typewritermc.elements.Element
import com.typewritermc.elements.Entry
import com.typewritermc.engine.Root
import com.typewritermc.engine.pages.Definition
import com.typewritermc.engine.reading.EntryLocation
import com.typewritermc.engine.reading.PublishedValues
import com.typewritermc.engine.reading.loaded
import com.typewritermc.engine.runtime.CompiledResourceGraph
import com.typewritermc.events.EntryScope
import com.typewritermc.formula.ContentReferences
import com.typewritermc.formula.Deferred
import com.typewritermc.formula.Formula
import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.FormulaFunction
import com.typewritermc.formula.Var
import com.typewritermc.formula.VarDefinition
import com.typewritermc.formula.check.CatalogType
import com.typewritermc.formula.check.CheckedBinding
import com.typewritermc.formula.check.CheckedFormula
import com.typewritermc.formula.check.ExtensionName
import com.typewritermc.formula.check.FormulaEnvironment
import com.typewritermc.formula.check.StoredFormula
import com.typewritermc.formula.check.StoredReference
import com.typewritermc.formula.check.check
import com.typewritermc.formula.check.readType
import com.typewritermc.formula.eval.CatalogEvaluationEnvironment
import com.typewritermc.formula.eval.Evaluation
import com.typewritermc.formula.eval.FailedEvaluation
import com.typewritermc.formula.eval.FunctionValue
import com.typewritermc.formula.eval.evaluate
import com.typewritermc.formula.eval.refTo
import com.typewritermc.identity.Protagonist
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.ResourceId
import com.typewritermc.types.Type
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResourceType
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.field
import com.typewritermc.types.fromValueAny
import com.typewritermc.types.named
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.toValueAny
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.compiled_content.CompilationContext
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FunctionParameterUse
import skirout.editor.v1.type_catalog.FunctionTypeUse
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import java.util.IdentityHashMap
import java.util.concurrent.ConcurrentHashMap

/**
 * Formulas over one publication: the checker and the interpreter ask it about the published [graph], and the entry
 * reader turns a value an entry stores at a path into what an accessor gives through it. Each formula is checked once,
 * on its first read, and the check is kept for the publication's life; a new publication builds a new environment.
 *
 * A name reads what the resource gives: a [Definition] its value, any other resource a Ref to it. A stored value that
 * is not in the publication, such as a protagonist's stored fact, is not read yet and fails as unfilled.
 */
class EngineEvaluationEnvironment(
    private val graph: CompiledResourceGraph,
    catalog: CheckedCatalog,
    bindings: NativeBindingRegistry,
    private val formulas: EngineFormulas,
) : CatalogEvaluationEnvironment(catalog, bindings),
    FormulaEnvironment {
    /** Each resource by id, at its root compilation where it has several. */
    private val keys: Map<ResourceId, CompiledResourceKey> =
        graph.stored.keys
            .groupBy { it.source.toResourceId() }
            .mapValues { (_, keys) -> keys.firstOrNull { it.context == CompilationContext.Root } ?: keys.first() }

    /** The key of each published instance, so a scope's entry finds its resource. */
    private val instances =
        IdentityHashMap<Any, CompiledResourceKey>().apply {
            graph.resources.forEach { (key, value) -> put(value, key) }
        }

    private val sites = ConcurrentHashMap<CompiledResourceKey, List<VarSite>>()
    private val checks = ConcurrentHashMap<Pair<CompiledResourceKey, String>, CheckedFormula>()

    /** The resources whose exported value is being evaluated on this thread, so Definitions that read each other fail. */
    private val exporting = ThreadLocal.withInitial { linkedSetOf<CompiledResourceKey>() }

    /** Every value of this publication as it was compiled, the stored values the entry reader reads by default. */
    val published: PublishedValues = PublishedValues(graph)

    private val types = ConcurrentHashMap<EntryLocation, TypeUse>()

    /** Where [entry] stores the value at [path]. Throws [FormulaReadException] for an entry of another publication. */
    fun locationOf(
        entry: Entry,
        path: ValuePath,
    ): EntryLocation {
        val key = instances[entry] ?: throw FormulaReadException("${entry.name} is not part of this publication.")
        return EntryLocation(key, path)
    }

    /**
     * What an accessor of [scope] gives for [stored], the value at [location]: a written `Var` value as written, a
     * formula evaluated with the scope's subject as `protagonist` and each other context parameter's record from the
     * scope's context, such as the `event`, any other value decoded as its declared type, and null where nothing is
     * stored. Throws [FormulaReadException] when the formula has problems or its evaluation fails.
     */
    fun valueAt(
        location: EntryLocation,
        stored: DataValue?,
        scope: EntryScope<*>,
    ): Any? {
        val type = typeAt(location)
        val site = varSite(location.path, type, stored) ?: return stored?.let { decode(type, it) }
        if (site.value !is Var.Computed) return read(location.resource, site, emptyMap())
        val context = site.expected.context.associate { parameter -> parameter.name to contextValue(parameter, scope) }
        return read(location.resource, site, context)
    }

    /**
     * The value of the `Var` field at [field] on [resource], with [context] giving each context parameter its Kotlin
     * value by name, such as `protagonist` for a book's condition. Throws [FormulaReadException] when the field is
     * missing, a context value is missing, the formula has problems, or its evaluation fails.
     */
    fun evaluate(
        resource: ResourceId,
        field: FieldPath,
        context: Map<String, Any?> = emptyMap(),
    ): Any? {
        val key = keys[resource] ?: throw FormulaReadException("${resource.value} is not part of this publication.")
        val location = EntryLocation(key, field.path)
        val site =
            varSite(field.path, typeAt(location), published.loaded(location))
                ?: throw FormulaReadException("${resourceName(resource)} has no Var field at ${field.path.text}.")
        return read(key, site, context)
    }

    private fun read(
        key: CompiledResourceKey,
        site: VarSite,
        context: Map<String, Any?>,
    ): Any? {
        when (val value = site.value) {
            null -> return null
            is Var.Value -> return value.value
            is Var.Computed -> Unit
        }
        val name = "${resourceName(key.source.toResourceId())}.${site.field}"
        val checked = checkedAt(key, site)
        if (checked.problems.isNotEmpty()) {
            throw FormulaReadException("The formula of $name has problems: ${checked.problems.joinToString { it.message }}.")
        }
        return try {
            val locals =
                site.expected.context.associate { parameter ->
                    if (parameter.name !in context) {
                        throw FormulaReadException("The formula of $name reads ${parameter.name}, which was not given.")
                    }
                    parameter.name to binding(parameter.type).toValueAny(context[parameter.name], this)
                }
            when (val result = checked.tree.evaluate(locals, locationOf(key, site))) {
                is Evaluation.Value -> binding(site.held).fromValueAny(force(result.value), this)
                is Evaluation.Failed -> throw FormulaReadException("The formula of $name failed: ${result.reason}.")
                Evaluation.NotEvaluated -> throw FormulaReadException("The formula of $name was not evaluated.")
            }
        } catch (failed: FailedEvaluation) {
            throw FormulaReadException("The formula of $name failed: ${failed.reason}.", failed)
        }
    }

    /** The context value [parameter] takes for [scope]: its subject as `protagonist`, else the context record of its type. */
    private fun contextValue(
        parameter: FunctionParameterUse,
        scope: EntryScope<*>,
    ): Any {
        val missing = { FormulaReadException("${scope.entry.name} reads ${parameter.name}, which this run does not have.") }
        if (parameter.name == PROTAGONIST) return scope.subject as? Protagonist ?: throw missing()
        val type = binding(parameter.type).nativeClass ?: throw missing()
        return scope.context.all.firstOrNull(type::isInstance) ?: throw missing()
    }

    /** The `Var` at [path] when [type] is a `Var` type: the type it holds, its formula's function type, and [stored] decoded. */
    private fun varSite(
        path: ValuePath,
        type: TypeUse,
        stored: DataValue?,
    ): VarSite? {
        val use = type.withoutNullable().named?.takeIf { it.definition == VarDefinition.id } ?: return null
        val held = use.arguments.getOrNull(0) ?: return null
        val expected = (use.arguments.getOrNull(1) as? TypeUse.FunctionWrapper)?.value ?: return null
        return VarSite(path, held, expected, stored?.let { decode(type, it) as Var<*, *>? })
    }

    /**
     * The declared type of the value at [location], walking the resource's checked type field by field, into the item
     * type of a list or set, and into the key or value type of a map row.
     */
    private fun typeAt(location: EntryLocation): TypeUse =
        types.getOrPut(location) {
            val root =
                graph.stored[location.resource]?.schema ?: throw FormulaReadException("${location.resource.source.value} is not published.")
            location.path.segments.fold(root.use) { type, segment ->
                val checked = if (type == root.use) root else checkedOf(type)
                checked?.typeBelow(type, segment)
                    ?: throw FormulaReadException(
                        "${resourceName(location.resource.source.toResourceId())} has no value at ${location.path.text}.",
                    )
            }
        }

    /**
     * The type one [segment] below [type], whose checked form this is. An item of a map stays at the map's type, so the
     * following key or value segment reads the map's key or value type.
     */
    private fun CheckedType.typeBelow(
        type: TypeUse,
        segment: PathSegment,
    ): TypeUse? {
        val representation = schema.representation
        return when (segment) {
            is PathSegment.FieldWrapper -> {
                schema.fields.firstOrNull { it.key == segment.name }?.type
            }

            is PathSegment.ItemWrapper -> {
                (representation as? ResolvedRepresentation.SequenceWrapper)?.value?.item
                    ?: type.takeIf { representation is ResolvedRepresentation.MappingWrapper }
            }

            PathSegment.MAP_KEY -> {
                (representation as? ResolvedRepresentation.MappingWrapper)?.value?.key
            }

            PathSegment.MAP_VALUE -> {
                (representation as? ResolvedRepresentation.MappingWrapper)?.value?.value
            }

            else -> {
                null
            }
        }
    }

    private fun checkedOf(type: TypeUse): CheckedType? = (catalog.resolve(type.withoutNullable()) as? Resolution.Ready)?.value

    /** The Var fields of [key]'s stored record, each with its lowered type and its value, null where none is stored. */
    private fun sitesOf(key: CompiledResourceKey): List<VarSite> =
        sites.getOrPut(key) {
            val stored = graph.stored.getValue(key)
            val record = stored.value.unwrapNamed() as? DataValue.RecordWrapper ?: return@getOrPut emptyList()
            stored.schema.schema.fields.mapNotNull { declared ->
                val use = declared.type.named?.takeIf { it.definition == VarDefinition.id } ?: return@mapNotNull null
                val held = use.arguments.getOrNull(0) ?: return@mapNotNull null
                val expected = (use.arguments.getOrNull(1) as? TypeUse.FunctionWrapper)?.value ?: return@mapNotNull null
                val value = record.field(declared.key)?.let { data -> decode(declared.type, data) as Var<*, *>? }
                VarSite(ValuePath.root.field(declared.key), held, expected, value)
            }
        }

    /** The check of [site]'s formula, made on its first read. A Var.Computed holding a function is not checked. */
    private fun checkedAt(
        key: CompiledResourceKey,
        site: VarSite,
    ): CheckedFormula =
        checks.getOrPut(key to site.field) {
            val formula = (site.value as Var.Computed<*, *>).formula
            if (site.held is TypeUse.FunctionWrapper) {
                val name = "${resourceName(key.source.toResourceId())}.${site.field}"
                throw FormulaReadException("$name computes a function, which needs a written body.")
            }
            formula.stored().check(site.expected)
        }

    // Evaluation: what the interpreter reads from the publication.

    override fun evaluateDeferred(value: Deferred): Any? = throw FailedEvaluation(FormulaFailure.Unfilled(value.at))

    override fun typeName(id: TypeDefinitionId): String? = formulas.typeName(id)

    override fun resourceName(id: ResourceId): String =
        keys[id]
            ?.let { graph.resources[it] as? Element }
            ?.name
            ?.takeIf(String::isNotEmpty) ?: id.value

    /** A Definition gives its value; any other resource a Ref to itself. */
    override fun exported(resource: ResourceId): Any? {
        val key = keys[resource] ?: throw dependency(resource)
        if (graph.resources[key] !is Definition<*>) return refTo(resource)
        val site = sitesOf(key).firstOrNull { it.field == DEFINITION_VALUE } ?: throw dependency(resource)
        return valueOf(key, site)
    }

    /** The field [field] of [resource] as stored; a Var field gives its value. */
    override fun fieldOf(
        resource: ResourceId,
        field: String,
    ): Any? {
        val key = keys[resource] ?: throw dependency(resource)
        sitesOf(key).firstOrNull { it.field == field }?.let { return valueOf(key, it) }
        val stored = graph.stored.getValue(key)
        val declared =
            stored.schema.schema.fields
                .firstOrNull { it.key == field } ?: throw dependency(resource)
        val data =
            (stored.value.unwrapNamed() as? DataValue.RecordWrapper)?.field(field)
                ?: throw FailedEvaluation(FormulaFailure.Unfilled(ValueLocation.of(key.source).field(field)))
        return binding(declared.type).toValueAny(decode(declared.type, data), this)
    }

    /**
     * The evaluation value [site] holds: a written value through its binding, a function body as a function value,
     * and a pure formula evaluated now. A formula that reads context has no value outside a scope.
     */
    private fun valueOf(
        key: CompiledResourceKey,
        site: VarSite,
    ): Any? {
        val resource = key.source.toResourceId()
        val held = site.held
        return when (val value = site.value) {
            null -> {
                throw FailedEvaluation(FormulaFailure.Unfilled(locationOf(key, site)))
            }

            is Var.Value -> {
                if (held is TypeUse.FunctionWrapper) {
                    functionValue(key, site, value.value as Formula, held.value)
                } else {
                    binding(held).toValueAny(value.value, this)
                }
            }

            is Var.Computed -> {
                val checked = checkedAt(key, site)
                if (checked.problems.isNotEmpty() || site.expected.context.isNotEmpty()) throw dependency(resource)
                val active = exporting.get()
                if (!active.add(key)) {
                    throw FailedEvaluation(FormulaFailure.Cycle(active.map { it.source }.distinct().sortedBy { it.value }))
                }
                try {
                    when (val result = checked.tree.evaluate(emptyMap(), locationOf(key, site))) {
                        is Evaluation.Value -> result.value
                        is Evaluation.Failed -> throw FailedEvaluation(result.reason)
                        Evaluation.NotEvaluated -> throw dependency(resource)
                    }
                } finally {
                    active.remove(key)
                }
            }
        }
    }

    /** A written function body as the function value naming it gives, checked once like any formula. */
    private fun functionValue(
        key: CompiledResourceKey,
        site: VarSite,
        body: Formula,
        type: FunctionTypeUse,
    ): FunctionValue {
        val checked = checks.getOrPut(key to site.field) { body.stored().check(type) }
        if (checked.problems.isNotEmpty()) throw dependency(key.source.toResourceId())
        val parameters = type.parameters.map { CheckedBinding.Named(it.name, it.type) }
        return FunctionValue(checked.tree, parameters, emptyMap(), locationOf(key, site))
    }

    // Checking: what the checker asks about the publication.

    override fun resolve(use: TypeUse): Resolution<CheckedType> = catalog.resolve(use)

    override fun expand(use: TypeUse): TypeUse = catalog.expand(use)

    override fun unappliedType(definition: TypeDefinitionId): Resolution<ResourceType> =
        catalog.authoredTypeOf(TypeSelection.of(definition))

    /** Every name of published content is stored as a reference, so a name with none names no resource. */
    override fun inScope(name: String): List<ResourceId> = emptyList()

    override fun functions(name: String): List<FormulaFunction> = formulas.functions(name)

    /** A Definition gives its value's type, a Var read as its value; any other resource a Ref to its type. */
    override fun reference(target: ResourceId): TypeUse? {
        val key = keys[target] ?: return null
        if (graph.resources[key] is Definition<*>) {
            return graph.stored
                .getValue(key)
                .schema.schema.fields
                .firstOrNull { it.key == DEFINITION_VALUE }
                ?.type
                ?.let(::readType)
        }
        val type =
            graph.stored
                .getValue(key)
                .schema.use
        return ContentReferences.Source.Definition.id
            .use(listOf(type))
    }

    override fun catalogTypeNamed(name: String): List<CatalogType> = formulas.catalogTypeNamed(name)

    override fun extensions(): Set<ExtensionName> = formulas.extensions()

    /** The type a `Definition<Type>` holds as written. */
    override fun typeValue(target: ResourceId): TypeUse? {
        val definition = keys[target]?.let { graph.resources[it] } as? Definition<*> ?: return null
        return ((definition.value as? Var.Value<*, *>)?.value as? Type)?.use
    }

    override fun isMissing(id: TypeDefinitionId): Boolean = catalog.definition(id) is DeclarationStatus.UnavailableWrapper

    private fun decode(
        type: TypeUse,
        data: DataValue,
    ): Any? {
        val checked = checked(type)
        return when (val complete = checked.complete(data)) {
            is CompletenessResult.Complete -> binding(type).decode(complete.value)
            else -> error("A published value at a $type is not complete: $complete")
        }
    }

    private fun locationOf(
        key: CompiledResourceKey,
        site: VarSite,
    ): ValueLocation = ValueLocation.of(key.source).append(site.path)

    private fun dependency(resource: ResourceId) = FailedEvaluation(FormulaFailure.Dependency(resource.toSkir()))

    private fun TypeUse.withoutNullable(): TypeUse = if (this is TypeUse.NullableWrapper) value.value.withoutNullable() else this

    /** One `Var` field of a published resource: the type it holds, the function type its formula is checked as, and its value. */
    private data class VarSite(
        val path: ValuePath,
        val held: TypeUse,
        val expected: FunctionTypeUse,
        val value: Var<*, *>?,
    ) {
        /** The site's path as text: its name in messages and its key among the checked formulas. */
        val field: String = path.text
    }

    private companion object {
        const val PROTAGONIST = "protagonist"

        /** The field whose value naming a Definition gives. */
        val DEFINITION_VALUE: String = Definition<*>::value.name
    }
}

/** A Kotlin formula as the checker reads it: its source and the resources it names. */
private fun Formula.stored(): StoredFormula = StoredFormula(source, references.map { StoredReference(it.at, it.target.target) })

/** Why reading a formula field failed: the formula has problems, or its evaluation failed. */
class FormulaReadException(
    message: String,
    cause: Throwable? = null,
) : RuntimeException(message, cause)
