package com.typewritermc.engine.formula.testing

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.discovery.CatalogAssembly
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.OwnedNativeBinding
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.assemble
import com.typewritermc.elements.Entry
import com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION
import com.typewritermc.engine.Root
import com.typewritermc.engine.events.EventEntry
import com.typewritermc.engine.events.EventEntryDefinition
import com.typewritermc.engine.events.PublishedEntries
import com.typewritermc.engine.events.publishedEntries
import com.typewritermc.engine.events.testing.links
import com.typewritermc.engine.events.testing.protagonist
import com.typewritermc.engine.formula.EngineEvaluationEnvironment
import com.typewritermc.engine.formula.EngineFormulas
import com.typewritermc.engine.pages.Definition
import com.typewritermc.engine.pages.DefinitionDefinition
import com.typewritermc.engine.pages.SequencePage
import com.typewritermc.engine.pages.SequencePageDefinition
import com.typewritermc.engine.runtime.CompiledResourceGraph
import com.typewritermc.events.Candidate
import com.typewritermc.events.Context
import com.typewritermc.events.Event
import com.typewritermc.events.EventContext
import com.typewritermc.events.EventDefinition
import com.typewritermc.formula.ContentReferences
import com.typewritermc.formula.DefinitionScope
import com.typewritermc.formula.Formula
import com.typewritermc.formula.FormulaFunction
import com.typewritermc.formula.FormulaReference
import com.typewritermc.formula.RecordValue
import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.Var
import com.typewritermc.identity.Engine
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.ProtagonistDefinition
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.library.Book
import com.typewritermc.library.BookContext
import com.typewritermc.library.BookDefinition
import com.typewritermc.types.EvaluationValues
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.Ref
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.declared
import com.typewritermc.types.fromValueAny
import com.typewritermc.types.integerScalar
import com.typewritermc.types.toSkir
import com.typewritermc.types.toTemplate
import com.typewritermc.types.toValueAny
import com.typewritermc.types.use
import skirout.editor.v1.compiled_content.CompilationContext
import skirout.editor.v1.compiled_content.CompiledResource
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import java.nio.file.Path
import kotlin.reflect.KClass

// A publication of real engine entries over the catalog an engine deployment assembles: the core artifact's types,
// bindings and formula functions, engine core's types, and the fixture event. Formulas are checked and run
// against it as an engine runs them.

/** A chat line [protagonist] sent: the chat-like event the formula fixtures' entries are about. */
data class Said(
    val protagonist: Protagonist,
    val message: String,
) : Event

/** The catalog declaration of [Said], an event record with a protagonist and a message, as codegen declares one. */
object SaidDefinition {
    val id: TypeDefinitionId = TypeDefinitionId.declared("e1f0000000000000000000000000a001")

    val definition: TypeDefinition =
        recordDefinition(
            id,
            "protagonist" to TypeTemplate.createNamed(definition = ProtagonistDefinition.id, arguments = emptyList()),
            "message" to ScalarKind.TEXT.use.toTemplate(),
            parents = listOf(NamedTypeTemplate(definition = EventDefinition.id, arguments = emptyList())),
        )
}

/** A concrete record type [id] with [fields] in order, each declared on [id] itself, as codegen declares one. */
fun recordDefinition(
    id: TypeDefinitionId,
    vararg fields: Pair<String, TypeTemplate>,
    parents: List<NamedTypeTemplate> = emptyList(),
): TypeDefinition =
    TypeDefinition(
        id = id,
        parameters = emptyList(),
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    fields.map { (name, type) ->
                        FieldDeclaration(
                            owner = FieldOwner(definition = id, name = name),
                            type = type,
                            overrides = emptyList(),
                            hasConstructorDefault = false,
                        )
                    },
                form = RecordForm.CONCRETE,
            ),
        parents = parents,
    )

/**
 * Binds [Said] for formulas: a record value with its protagonist and message, each through its own binding. An event
 * reaches a formula as a context value and is never stored, so it has no stored form.
 */
object SaidNativeBindingFactory : NativeBindingFactory {
    override val definition: TypeDefinitionId = SaidDefinition.id
    override val provider: NativeBindingId = NativeBindingId(value = "test.said")
    override val nativeClass: KClass<*> = Said::class

    override fun bind(
        actual: CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        object : NativeBinding<Said> {
            private val protagonist by lazy { arguments.resolver.bind(ProtagonistDefinition.id.use()) }
            override val provider = this@SaidNativeBindingFactory.provider
            override val signature = "test.said"
            override val actualType: TypeUse = actual.use
            override val nativeClass: KClass<*> = Said::class

            override fun encode(value: Said): DataValue = error("An event is never stored.")

            override fun decode(value: CompleteValue): Said = error("An event is never stored.")

            override fun fromValue(
                value: Any?,
                values: EvaluationValues,
            ): Said {
                val record = values.resolve(value) as RecordValue
                return Said(
                    protagonist.fromValueAny(values.resolve(record.fields["protagonist"]), values) as Protagonist,
                    values.resolve(record.fields["message"]) as String,
                )
            }

            override fun toValue(
                value: Said,
                values: EvaluationValues,
            ): Any? =
                RecordValue(
                    actualType,
                    mapOf("protagonist" to protagonist.toValueAny(value.protagonist, values), "message" to value.message),
                )
        }
}

/** The formula types `Int` and `String`, for a Definition's type argument. */
val int: TypeUse = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
val text: TypeUse = ScalarKind.TEXT.use

/** One resource of a publication: its id, its actual type, and its Kotlin value. */
data class PublishedResource(
    val id: String,
    val type: TypeUse,
    val value: Any,
)

/**
 * A formula whose [names] each reference the resource of that id, at its first occurrence in [source], as the realm
 * stores a bound name.
 */
fun formula(
    source: String,
    vararg names: String,
): Formula =
    Formula(
        source,
        names.map { name ->
            val start = source.indexOf(name)
            require(start >= 0) { "$name does not occur in $source." }
            FormulaReference(TextSpan(start, start + name.length), Ref<ContentReferences.Source, Resource>(ResourceId(name)))
        },
    )

/** A `Definition<T>` named [id] on a static page, holding [value]; [type] is `T`. */
fun definition(
    id: String,
    type: TypeUse,
    value: Var<*, DefinitionScope>,
): PublishedResource =
    PublishedResource(
        id,
        DefinitionDefinition.id.use(listOf(type)),
        @Suppress("UNCHECKED_CAST")
        Definition(Ref(ResourceId("page")), GraphPlacement(), id, value as Var<Any?, DefinitionScope>),
    )

/** An event entry named [id] about [Said] on the page [page], whose chain starts while [condition] holds and links to [next]. */
fun saidEntry(
    id: String,
    condition: Var<Boolean, EventContext<Said>> = Var.Value(true),
    page: String = "sequence",
    next: List<String> = emptyList(),
): PublishedResource =
    PublishedResource(
        id,
        EventEntryDefinition.id.use(listOf(SaidDefinition.id.use())),
        EventEntry(page = Ref(ResourceId(page)), name = id, placement = GraphPlacement(), triggers = links(next), condition = condition),
    )

/** A book named [id] whose content applies to a protagonist while [condition] holds. */
fun book(
    id: String,
    condition: Var<Boolean, BookContext>,
): PublishedResource = PublishedResource(id, BookDefinition.id.use(), Book(library = Ref(ResourceId("library")), condition = condition))

/** A sequence page named [id] in the book [book]. */
fun sequencePage(
    id: String,
    book: String,
): PublishedResource = PublishedResource(id, SequencePageDefinition.id.use(), SequencePage(book = Ref(ResourceId(book)), name = id))

/** The formula functions and code type names of the fixture catalog, as an engine deployment collects them. */
val fixtureFormulas: EngineFormulas get() = EngineFormulas.of(fixtureAssembly)

/**
 * [resources] published together, as an engine admits them: one compiled graph over the fixture catalog. Each
 * [environment] is the evaluation of one publication.
 */
class FormulaPublication(
    vararg resources: PublishedResource,
) {
    val graph: CompiledResourceGraph = assemble(resources.toList())

    /** A new evaluation of this publication, with what [formulas] formulas may call. */
    fun environment(formulas: EngineFormulas = fixtureFormulas): EngineEvaluationEnvironment =
        EngineEvaluationEnvironment(graph, fixtureAssembly.checked, fixtureAssembly.bindings, formulas)

    /** The entries of this publication as the engine [engine] gives them to handlers, reading their fields through [environment]. */
    fun entries(
        environment: EngineEvaluationEnvironment = environment(),
        engine: Engine = Engine(EngineId("engine")),
    ): PublishedEntries = publishedEntries(graph, environment, engine)

    /** The published entry [id], as a candidate for [subject] in [context], reading through [environment]. */
    fun <E : Entry> candidate(
        id: String,
        context: Context,
        environment: EngineEvaluationEnvironment = environment(),
        subject: Protagonist = protagonist(),
    ): Candidate<E> {
        val published = checkNotNull(entries(environment).entry(ResourceId(id))) { "$id is not a published entry." }
        @Suppress("UNCHECKED_CAST")
        return Candidate(published.entry as E, published.priority, subject, context, environment)
    }
}

/** The formula functions of [base], less those named in [withdrawn] at the time a formula is checked. */
class WithdrawableFormulas(
    private val base: EngineFormulas = fixtureFormulas,
) : EngineFormulas by base {
    var withdrawn: Set<String> = emptySet()

    override fun functions(name: String): List<FormulaFunction> = if (name in withdrawn) emptyList() else base.functions(name)
}

private fun assemble(resources: List<PublishedResource>): CompiledResourceGraph {
    val compiled = resources.map { it.compiled() }
    val facts =
        RuntimeCompilationFacts(
            formatRevision = RESOURCE_GRAPH_FORMAT_REVISION,
            root = compiled.first().key,
            resources = compiled,
            edges = emptyList(),
            types = emptyList(),
            relations = emptyList(),
        )
    return CompiledResourceGraph.assemble(listOf(facts), fixtureAssembly.relations, fixtureAssembly.checked, fixtureAssembly.bindings)
}

private fun PublishedResource.compiled(): CompiledResource {
    val checked =
        when (val resolved = fixtureAssembly.checked.resolve(type)) {
            is Resolution.Ready -> resolved.value
            is Resolution.Invalid -> error("$id has a type that does not resolve: ${resolved.diagnostics}")
        }
    val binding = fixtureAssembly.bindings.bind(checked)

    @Suppress("UNCHECKED_CAST")
    val encoded = (binding as NativeBinding<Any>).encode(value) as DataValue.NamedWrapper
    val named = checkNotNull((type as? TypeUse.NamedWrapper)?.value) { "$id needs a named type." }
    return CompiledResource(
        key = CompiledResourceKey(source = ResourceId(id).toSkir(), context = CompilationContext.Root),
        actualType = named,
        bindingProvider = binding.provider,
        bindingSignature = binding.signature,
        value = encoded.value,
    )
}

/** The core artifact and engine core as a deployment loads them, plus the fixture event and entry. */
private val fixtureAssembly: CatalogAssembly by lazy {
    val deployment =
        GeneratedProviderLoader().load(
            listOf(
                GeneratedProviderArtifact(ArtifactId("typewritermc:core"), Book::class.codeSource()),
                GeneratedProviderArtifact(ArtifactId("typewritermc:engine-core"), Definition::class.codeSource()),
            ),
            DeploymentFacts(),
            DiscoveryDomains.Execution,
            acceptedKinds =
                setOf(
                    GeneratedProviderKind.Type,
                    GeneratedProviderKind.NativeBinding,
                    GeneratedProviderKind.Relation,
                    GeneratedProviderKind.EndpointBindings,
                    GeneratedProviderKind.Formula,
                ),
        )
    val loaded = deployment.providers.contributions
    val origin = loaded.declarations.first().origin
    loaded
        .copy(
            declarations =
                loaded.declarations +
                    OwnedTypeDeclaration(origin, SaidDefinition.definition, nativeClass = Said::class, name = "Said") +
                    OwnedTypeDeclaration(origin, TallyEntryDefinition.definition, nativeClass = TallyEntry::class, name = "TallyEntry"),
            nativeBindings =
                loaded.nativeBindings + OwnedNativeBinding(origin, SaidNativeBindingFactory) +
                    OwnedNativeBinding(origin, TallyEntryNativeBindingFactory),
        ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "engine formula test")))
}

private fun KClass<*>.codeSource(): Path =
    Path.of(
        java.protectionDomain.codeSource.location
            .toURI(),
    )
