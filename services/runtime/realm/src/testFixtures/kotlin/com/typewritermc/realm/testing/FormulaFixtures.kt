@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.testing

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.boundPath
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.field
import com.typewritermc.authoring.nativeReadProjection
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.checking.DraftType
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.LoadedCompiledArtifact
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION
import com.typewritermc.engine.pages.Definition
import com.typewritermc.engine.pages.DefinitionDefinition
import com.typewritermc.engine.pages.DefinitionDraftType
import com.typewritermc.engine.pages.StaticEntry
import com.typewritermc.engine.pages.definition
import com.typewritermc.engine.pages.staticPage
import com.typewritermc.engine.runtime.ResourceGraphContentGateway
import com.typewritermc.formula.ContentReferences
import com.typewritermc.formula.DefinitionScope
import com.typewritermc.formula.Formula
import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.FormulaReference
import com.typewritermc.formula.RecordValue
import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.Var
import com.typewritermc.formula.VarDefinition
import com.typewritermc.formula.eval.Evaluation
import com.typewritermc.formula.eval.EvaluationEnvironment
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.RealmReads
import com.typewritermc.realm.authoring.readNow
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.realm.formula.CheckFormula
import com.typewritermc.realm.formula.DynamicOf
import com.typewritermc.realm.formula.Evaluate
import com.typewritermc.realm.formula.FormulaSite
import com.typewritermc.realm.formula.FormulasOf
import com.typewritermc.realm.formula.RealmEvaluationEnvironment
import com.typewritermc.realm.operation.prepare
import com.typewritermc.realm.operation.preview
import com.typewritermc.realm.operation.shouldBePrepared
import com.typewritermc.realm.operation.shouldBeReady
import com.typewritermc.realm.publication.AuthoringAcceptance
import com.typewritermc.realm.publication.CompilationInputs
import com.typewritermc.realm.publication.ResourceGraphArtifactProducer
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.setup.SetupList
import com.typewritermc.setup.SetupRoot
import com.typewritermc.testing.routes.FixtureBoxDefinition
import com.typewritermc.testing.routes.FixtureLoot
import com.typewritermc.testing.routes.FixtureLootDefinition
import com.typewritermc.testing.routes.FixturePrizeDefinition
import com.typewritermc.testing.routes.FixtureSignalDefinition
import com.typewritermc.testing.routes.FixtureStockEntry
import com.typewritermc.testing.routes.fixtureContextEntry
import com.typewritermc.testing.routes.fixtureStaticEntry
import com.typewritermc.testing.routes.fixtureStockEntry
import com.typewritermc.testkit.complete
import com.typewritermc.testkit.ready
import com.typewritermc.types.Ref
import com.typewritermc.types.Type
import com.typewritermc.types.function
import com.typewritermc.types.functionUse
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.toSkir
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import io.kotest.matchers.collections.shouldContain
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompiledArtifactReference
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.PublicationId
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.editor.v1.typed_value.PortableValue
import skirout.kernel.v1.resource_id.ResourceId
import com.typewritermc.types.ResourceId as AuthorResourceId

/*
 * The formula demos' kit: one static page of Definitions, formulas and custom types, committed through the stored forms
 * the panel sends, and the reads that observe what the realm made of it. Bodies arrive with the layer step that needs
 * them; until then they throw NotImplementedError, so the demos are red for that reason alone.
 */

/** The text type, as a field or a Definition declares it. */
val stringUse: TypeUse = ScalarKind.TEXT.use

/** The text type a field added to a custom type holds. */
val textUse: TypeUse = ScalarKind.TEXT.use

/** The 32 bit integer type a Definition declares. */
val intUse: TypeUse = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use

/** The resource type of a Definition of [type]. */
fun definitionOf(type: TypeUse): NamedTypeUse = DefinitionDefinition.id.namedUse(listOf(type))

/** The stored type of the value of a Definition of [type]: a Var whose formulas read no context. */
fun definitionValueUse(type: TypeUse): TypeUse = VarDefinition.id.use(listOf(type, functionUse(result = type)))

/** A Definition's value written plainly as [value]. */
fun <T> plain(value: T): Var<T, DefinitionScope> = Var.Value(value)

/** A Definition's value computed by the formula [source]. */
fun computed(source: String): Var<Any?, DefinitionScope> = Var.Computed(Formula(source))

/** Where a Definition keeps its plain value. */
fun plainValueLocation(resource: ResourceId): ValueLocation = ValueLocation.of(resource, ValuePath.root.field("value").field("value"))

/** Sets the value of the Definition [resource] to [value], stored as the value of a Definition of [type]. */
fun RealmFixture.setVar(
    resource: ResourceId,
    type: TypeUse,
    value: Var<*, DefinitionScope>,
): EditIntent =
    EditIntent.createSetValue(
        at = ValueLocation.of(resource, ValuePath.root.field("value")),
        value = encoder.encode(definitionValueUse(type), value),
    )

/** The saved value of the Definition [resource] as Kotlin reads it, or null when it holds none. */
fun RealmFixture.varValue(resource: ResourceId): Var<*, *>? =
    views.read { view ->
        val record = view.resources.getValue(resource)
        val type = (record.configuration as TypeSelection.CompleteWrapper).value.arguments.single()
        val stored = record.valueAt(ValuePath.root.field("value")).takeUnless { it == DataValue.UNFILLED } ?: return@read null
        val checked = view.catalog.checked.ready(definitionValueUse(type))
        view.catalog.nativeBindings
            .bind(checked)
            .decode(checked.complete(stored).complete()) as Var<*, *>
    }

/** The draft a check reads a Definition of [type] through, with its value read as Kotlin's [T]. */
fun <T> definitionDraft(type: TypeUse): DefinitionDraftType<T> = DefinitionDraftType(nativeReadProjection(type))

/**
 * Reads [record] staged as [resource] over the saved content, without admission, through the generated draft [type]:
 * what a check sees of a value the catalog no longer accepts.
 */
fun <D, R> RealmFixture.readDraft(
    resource: ResourceId,
    record: AuthoringRecord,
    type: DraftType<D>,
    read: AuthoredReads.(D) -> R,
): R =
    views.capture().use { lease ->
        val reads = CapturedAuthoringReads(lease.stagedView(mapOf(resource to record)))
        val selection = (record.configuration as TypeSelection.CompleteWrapper).value
        val binding = reads.binding(boundPath<Any>(ValueLocation.of(resource), TypeUse.NamedWrapper(selection)))
        reads.read(type.bind((binding as Availability.Available).value))
    }

/** Previews changing the type of the Definition [resource] to [to], as the argument editor asks. */
fun RealmFixture.previewTypeChange(
    resource: ResourceId,
    to: TypeUse,
): PreviewTypeArgumentChangeResponse = preview(resource, TypeSelection.CompleteWrapper(definitionOf(to)))

/**
 * Publishes the realm's saved content into an engine: the Realm assesses and compiles it as a publication does, and an
 * engine content gateway admits the compiled artifacts. Returns the resources the engine holds, by id.
 */
suspend fun RealmFixture.publishToEngine(): Map<ResourceId, Any> =
    views.capture().use { captured ->
        val assessment = RealmCheckRuntime(views).use { checks -> AuthoringAcceptance(views, checks).evaluate(captured) }
        val view = captured.root
        val compiled =
            with(CompilationInputs(view, assessment.resources)) {
                ResourceGraphArtifactProducer.compile(ResourceGraphArtifactProducer.roots(view))
            }
        val artifacts =
            compiled.map { result ->
                val artifact =
                    checkNotNull(
                        (result as? CompilationResult.Success)?.artifact,
                    ) { "${result.root.resource.value} did not compile: $result" }
                LoadedCompiledArtifact(
                    CompiledArtifactReference(
                        root = artifact.root,
                        formatRevision = artifact.formatRevision,
                        mediaType = artifact.mediaType,
                        semanticDigest = artifact.semanticDigest.value,
                    ),
                    artifact.payload,
                )
            }
        val content =
            LoadedPublishedContent(
                PublishedContent(
                    publication = PublicationId(value = "publication:engine"),
                    formatRevision = PUBLISHED_CONTENT_FORMAT_REVISION,
                    catalog = view.catalog.generation,
                    implementationToken = "implementation",
                    outputs = emptyList(),
                ),
                artifacts,
            )
        val gateway = ResourceGraphContentGateway(view.catalog.checked, view.catalog.nativeBindings, view.catalog.relations)
        gateway.apply(content)
        checkNotNull(gateway.graph).resources.mapKeys { (key, _) -> key.source }
    }

/** A static page holding what [block] declares, returning its handles by name. */
fun SetupRoot.formulaPage(block: FormulaPageBuilder.() -> Unit): FormulaPage =
    library {
        books.book("formulas") {
            pages.staticPage("formulas") { FormulaPageBuilder(elements).apply(block).page(handle.id.toSkir()) }
        }
    }

/**
 * A library of static pages holding what [block] declares, returning the handles of every book, page and element by
 * key. Elements of every page share one key space, so two elements of one name take different keys.
 */
fun SetupRoot.formulaLibrary(block: FormulaLibraryBuilder.() -> Unit): FormulaPage {
    val declared = FormulaLibraryBuilder().apply(block)
    val named = linkedMapOf<String, ResourceId>()
    library {
        declared.books.forEach { (bookKey, pagesOfBook) ->
            books.book(bookKey) {
                named[bookKey] = handle.id.toSkir()
                pagesOfBook.forEach { (pageKey, page) ->
                    pages.staticPage(pageKey) {
                        named[pageKey] = handle.id.toSkir()
                        FormulaPageBuilder(elements, named).apply(page)
                    }
                }
            }
        }
    }
    return FormulaPage(
        named.getValue(
            declared.books
                .first()
                .second
                .first()
                .first,
        ),
        named.toMap(),
    )
}

/** The books of a formula library, each with its static pages, in order. */
class FormulaLibraryBuilder internal constructor() {
    internal val books = mutableListOf<Pair<String, List<Pair<String, FormulaPageBuilder.() -> Unit>>>>()

    /** A book keyed [key] holding the pages [block] declares. */
    fun book(
        key: String,
        block: FormulaBookBuilder.() -> Unit,
    ) {
        books += key to FormulaBookBuilder().apply(block).pages
    }
}

/** The static pages of one book of a formula library. */
class FormulaBookBuilder internal constructor() {
    internal val pages = mutableListOf<Pair<String, FormulaPageBuilder.() -> Unit>>()

    /** A static page keyed [key] holding what [block] declares. */
    fun page(
        key: String,
        block: FormulaPageBuilder.() -> Unit,
    ) {
        pages += key to block
    }
}

/** Declares Definitions, formulas, custom types and entries on one static page. */
class FormulaPageBuilder internal constructor(
    private val elements: SetupList<StaticEntry>,
    private val named: MutableMap<String, ResourceId> = linkedMapOf(),
) {
    /** A Definition named [name] of [type] holding the plain Kotlin [value]. */
    fun definition(
        name: String,
        type: TypeUse,
        value: Any?,
        key: String = name,
    ): ResourceId = add(name, type, plain(value), key)

    /**
     * A Definition named [name] of [type] whose value is the formula [source]: the body itself when [type] is a function
     * type, which stores its body as a plain Formula, and a computed value otherwise.
     */
    fun formula(
        name: String,
        type: TypeUse,
        source: String,
        key: String = name,
    ): ResourceId = add(name, type, if (type.function != null) plain(Formula(source)) else computed(source), key)

    /**
     * A Definition named [name] of the plain type [type] computed by [source], whose references already point each name
     * of [references] at its resource, as the commit binder would have saved them. A null target is a reference a
     * delete emptied.
     */
    fun bound(
        name: String,
        type: TypeUse,
        source: String,
        references: Map<String, ResourceId>,
        key: String = name,
    ): ResourceId = add(name, type, Var.Computed<Any?, DefinitionScope>(boundFormula(source, references)), key)

    /** A Definition named [name] of the function type [type] whose value is computed by [source], where a body belongs. */
    fun computedFunction(
        name: String,
        type: TypeUse,
        source: String,
    ): ResourceId = add(name, type, computed(source))

    /** A FixtureContextEntry named [name] whose value is computed by [source] in a context only the engine gives. */
    fun contextual(
        name: String,
        source: String,
    ): ResourceId =
        elements
            .fixtureContextEntry(name) {
                this.name = name
                chained = Var.Computed(Formula(source))
            }.id
            .toSkir()
            .also { named[name] = it }

    /** A FixtureContextEntry named [name] whose value is plainly [value]. */
    fun contextual(
        name: String,
        value: Int,
    ): ResourceId =
        elements
            .fixtureContextEntry(name) {
                this.name = name
                chained = Var.Value(value)
            }.id
            .toSkir()
            .also { named[name] = it }

    /** A FixtureStockEntry named [name], which exports its [stock], holding [loot]. */
    fun stock(
        name: String,
        stock: Var<Int, DefinitionScope> = Var.Value(0),
        loot: FixtureLoot = FixtureLoot(),
    ): ResourceId =
        elements
            .fixtureStockEntry(name) {
                this.name = name
                this.stock = stock
                this.loot = loot
            }.id
            .toSkir()
            .also { named[name] = it }

    /** The type the custom type [build] declares on the Definition [name], as its values name it. */
    fun customTypeUse(
        name: String,
        build: TypeDefinitionBuilder.() -> Unit,
    ): TypeUse = declares { record(build = build) }.on(elements.idOf(name).toSkir()).use

    /** A Definition named [name] of the content type [type] declares, holding the value [value] builds from that type. */
    fun definition(
        name: String,
        type: ContentTypes,
        value: (TypeUse) -> DataValue,
    ): ResourceId =
        declared(name, type) { declared ->
            val written = value(declared.use)
            declared.use to
                when (written) {
                    is DataValue.NamedWrapper -> PortableValue(actualType = written.value.actualType.use, payload = written.value.payload)
                    else -> PortableValue(actualType = declared.use, payload = written)
                }
        }

    /** A Definition named [name] holding the custom type [build] declares. */
    fun customType(
        name: String,
        build: TypeDefinitionBuilder.() -> Unit,
    ): ResourceId = declared(name, declares { record(build = build) }) { typeUse to Type(it.use) }

    /** A Definition named [name] holding the type [of], an alias its users name by its value field. */
    fun alias(
        name: String,
        of: TypeUse,
    ): ResourceId = declared(name, plainType(of)) { typeUse to Type(it.use) }

    /** A FixtureStaticEntry named [name] under [key], a real entry next to the Definitions. */
    fun smith(
        name: String = "smith",
        key: String = name,
    ): ResourceId =
        elements
            .fixtureStaticEntry(key) { this.name = name }
            .id
            .toSkir()
            .also { named[key] = it }

    /** The resource this library declared as [key] so far. */
    fun named(key: String): ResourceId = named[key] ?: error("The formula page declares no $key yet.")

    internal fun page(id: ResourceId): FormulaPage = FormulaPage(id, named.toMap())

    /** A Definition named [name] whose declarations [types] builds on it, of the type and value [held] picks. */
    private fun declared(
        name: String,
        types: ContentTypes,
        held: (DeclaredTypes) -> Pair<TypeUse, Any?>,
    ): ResourceId {
        val declared = types.on(elements.idOf(name).toSkir())
        val (type, value) = held(declared)
        return elements
            .definition<Any?>(name, type) {
                this.name = name
                this.types = declared.types
                this.value = plain(value)
            }.id
            .toSkir()
            .also { named[name] = it }
    }

    private fun add(
        name: String,
        type: TypeUse,
        value: Var<*, DefinitionScope>,
        key: String = name,
    ): ResourceId {
        @Suppress("UNCHECKED_CAST")
        val held = value as Var<Any?, DefinitionScope>
        return elements
            .definition<Any?>(key, type) {
                this.name = name
                this.value = held
            }.id
            .toSkir()
            .also { named[key] = it }
    }
}

/** Demo 1, the roadmap's acceptance goal: base_reward, bonus and total. */
fun FormulaPageBuilder.demoOneDefinitions() {
    definition("base_reward", intUse, 50)
    formula("bonus", functionUse(parameters = listOf("level" to intUse), result = intUse), "level * 2")
    formula("total", intUse, "base_reward + bonus(10)")
}

/** Demo 2: the Reward type, first_reward, giver_name, gift and door; needs [FormulaPageBuilder.smith] and demo 1. */
fun FormulaPageBuilder.demoTwoDefinitions() {
    definition(
        "door",
        declares {
            union {
                case("Open")
                case("Closed")
            }
        },
    ) { caseValue(it, "Open") }
    val reward =
        customType("Reward") {
            field("giver", entryRef)
            field("helper", entryRef)
            field("gold", intUse)
        }
    formula("first_reward", fieldKey(reward), "Reward(giver = smith, helper = smith, gold = total)")
    formula("giver_name", textUse, "first_reward.giver.name")
    val smith = named("smith")
    definition(
        "gift",
        declares {
            record {
                field("giver", entryRef)
                field("gold", intUse)
            }
        },
    ) { recordValue(it, "giver" to contentLink(smith), "gold" to DataValue.integer(5)) }
}

/** The handles of a formula page: the page and every resource the demos name. */
class FormulaPage internal constructor(
    private val page: ResourceId,
    private val named: Map<String, ResourceId>,
) {
    val pageId: ResourceId get() = page
    val baseReward: ResourceId get() = named("base_reward")
    val bonus: ResourceId get() = named("bonus")
    val total: ResourceId get() = named("total")
    val smith: ResourceId get() = named("smith")
    val reward: ResourceId get() = named("Reward")
    val firstReward: ResourceId get() = named("first_reward")
    val giverName: ResourceId get() = named("giver_name")
    val gift: ResourceId get() = named("gift")
    val door: ResourceId get() = named("door")

    /** The resource the page declared as [name]. */
    fun named(name: String): ResourceId = named[name] ?: error("The formula page declares no $name.")
}

/** What the realm computed for formulas: a value at a path, the text as an author reads it, and the checked type. */
class FormulaReads internal constructor(
    private val realm: RealmFixture,
) {
    /**
     * The evaluated value of [resource], or of the field at [path] inside it, with everything inside evaluated: a
     * scalar as its Kotlin value, a record as its RecordValue. Fails when the evaluation did not give a value.
     */
    fun value(
        resource: ResourceId,
        vararg path: String,
    ): Any? =
        realm.views.pin().use { pinned ->
            with(pinned.reads) {
                val environment = RealmEvaluationEnvironment(this, null)
                val evaluated = read(Evaluate(siteOf(resource)))
                val value = (evaluated as? Evaluation.Value)?.value
                if (evaluated !is Evaluation.Value) throw AssertionError("${resource.value} gave $evaluated, not a value.")
                environment.force(path.fold<String, Any?>(value) { holder, field -> environment.fieldIn(holder, field) })
            }
        }

    /** What evaluating [resource] gave: its exported value, or the value its one formula computes. */
    fun evaluation(resource: ResourceId): Evaluation<Any?> = realm.readNow(Evaluate(realm.evaluationSite(resource)))

    /** Where the formula [source] stored on [resource] sits, and the value it computes. */
    fun site(
        resource: ResourceId,
        source: String,
    ): FormulaSite = realm.readNow(FormulasOf(resource)).single { it.formula.source == source }

    /** What evaluating the value the formula [source] on [resource] computes gave. */
    fun evaluation(
        resource: ResourceId,
        source: String,
    ): Evaluation<Any?> = realm.readNow(Evaluate(site(resource, source).holder))

    /** Why evaluating [resource] failed, or null when it did not fail. */
    fun failure(resource: ResourceId): FormulaFailure? = (evaluation(resource) as? Evaluation.Failed)?.reason

    /** The formula text of [resource] with references shown by their targets' current names. */
    fun display(resource: ResourceId): String = realm.displayOf(resource)

    /** The checked type of [resource]'s formula. */
    fun type(resource: ResourceId): TypeUse? = realm.readNow(CheckFormula(realm.readNow(FormulasOf(resource)).single().at))?.type
}

/** Where evaluating [resource] starts: its export, or the value its one formula computes. */
private fun RealmFixture.evaluationSite(resource: ResourceId): ValueLocation =
    readNow(DynamicOf(resource)).exports ?: readNow(FormulasOf(resource)).single().holder

context(reads: RealmReads)
private fun siteOf(resource: ResourceId): ValueLocation =
    reads.read(DynamicOf(resource)).exports ?: reads.read(FormulasOf(resource)).single().holder

/** Field [field] of an evaluated record, or of the resource a reference names, as a formula's field read gives it. */
private fun EvaluationEnvironment.fieldIn(
    holder: Any?,
    field: String,
): Any? =
    resolve(
        when (holder) {
            is RecordValue -> holder.fields[field]
            is Ref<*, *> -> fieldOf(holder.target, field)
            else -> throw AssertionError("$holder has no field $field.")
        },
    )

/** The formula reads on this realm. */
val RealmFixture.formulas: FormulaReads get() = FormulaReads(this)

/** The error findings whose primary location is on [resource], after the checks settled. */
fun RealmFixture.errorsOn(resource: ResourceId): List<Diagnostic> =
    checks.findings().flatMap { set -> set.findings + set.failures() }.filter {
        it.primary?.resource == resource && it.severity == DiagnosticSeverity.ERROR
    }

/** How often the graph computed each CheckRun so far, per check instance, counting an equal rerun too. */
suspend fun RealmFixture.settledRuns(): Map<CheckInstanceId, Long> {
    settle()
    return graphRuns.checkRuns()
}

/** The check instances the graph computed again since [before]. */
fun RealmFixture.rerunSince(before: Map<CheckInstanceId, Long>): Set<CheckInstanceId> = graphRuns.checkRuns().grewFrom(before)

/** The resources these check instances judge. */
fun Set<CheckInstanceId>.resources(): Set<ResourceId> = mapTo(linkedSetOf()) { it.location.resource }

/** Waits until every check the last commit started has finished. */
suspend fun RealmFixture.settle(): Unit = checks.drain()

private fun FindingSet.failures(): List<Diagnostic> = (outcome as? CheckOutcome.FailedWrapper)?.value.orEmpty()

/** Changes the type of the Definition [resource] to [to] with the repair the preview proposes, as the panel commits it. */
suspend fun RealmFixture.commitPreparedTypeChange(
    resource: ResourceId,
    to: TypeUse,
): CommitPreparedEditResponse = commit(prepare(previewTypeChange(resource, to).shouldBeReady()).shouldBePrepared())

/** The saved record of [resource]. */
fun RealmFixture.record(resource: ResourceId): AuthoringRecord = resources.getValue(resource)

/** The saved records of [resources], in order. */
fun RealmFixture.records(vararg resources: ResourceId): List<AuthoringRecord> = resources.map { record(it) }

/** The saved value at the field [path] of [resource]. */
fun RealmFixture.value(
    resource: ResourceId,
    vararg path: String,
): DataValue? = record(resource).valueAt(path.fold(ValuePath.root, ValuePath::field))

/**
 * The formula [source] with a reference at every whole word occurrence of each name of [references], pointing at its
 * resource.
 */
fun boundFormula(
    source: String,
    references: Map<String, ResourceId>,
): Formula =
    Formula(
        source,
        references
            .flatMap { (name, target) ->
                Regex("\\b${Regex.escape(name)}\\b").findAll(source).map { match ->
                    FormulaReference(
                        TextSpan(match.range.first, match.range.last + 1),
                        Ref(AuthorResourceId(target.value)),
                    )
                }
            }.sortedBy { it.at.start },
    )

/** The findings that block publishing now. */
suspend fun RealmFixture.publicationBlockers(): List<Diagnostic> =
    views
        .capture()
        .use { captured ->
            RealmCheckRuntime(views).use { checks -> AuthoringAcceptance(views, checks).evaluate(captured).findings }
        }.filter { it.severity == DiagnosticSeverity.ERROR }

/** Asserts that one of these findings points at [resource]. */
infix fun List<Diagnostic>.shouldContainLocation(resource: ResourceId) {
    mapNotNull { it.primary?.resource } shouldContain resource
}

/** Renames [resource] to [name]. */
fun rename(
    resource: ResourceId,
    name: String,
): EditIntent =
    EditIntent.createSetValue(at = ValueLocation.of(resource, ValuePath.root.field("name")), value = DataValue.StringValueWrapper(name))

/** Deletes [resource]. */
fun delete(resource: ResourceId): EditIntent = EditIntent.createDeleteResource(id = resource)

/** Points the plain giver link of the gift Definition [gift] at [to]. */
fun setGiver(
    gift: ResourceId,
    to: ResourceId,
): EditIntent = setReference(gift, "giver", to)

/** Adds the field [name] holding [field] to the one custom type the Definition [type] declares. */
fun RealmFixture.addField(
    type: ResourceId,
    name: String,
    field: TypeUse,
): EditIntent {
    val declaration = declaredTypes(type).single()
    val record = (declaration.representation as RepresentationTemplate.RecordWrapper).value
    val added =
        FieldDeclaration(
            owner = FieldOwner(definition = declaration.id, name = name),
            type = field.toTemplate(),
            overrides = emptyList(),
            hasConstructorDefault = false,
        )
    val representation = RepresentationTemplate.createRecord(fields = record.fields + added, form = record.form)
    return setTypes(
        type,
        listOf(
            TypeDefinition(
                id = declaration.id,
                parameters = declaration.parameters,
                representation = representation,
                parents = declaration.parents,
            ),
        ),
    )
}

/** The code record the route fixtures declare, holding Vars and references. */
val lootUse: TypeUse = FixtureLootDefinition.id.use()

/** The code union the route fixtures declare, whose other case holds a Var. */
val signalUse: TypeUse = FixtureSignalDefinition.id.use()

/** The open type the route fixtures declare. */
val prizeUse: TypeUse = FixturePrizeDefinition.id.use()

/** The code generic the route fixtures declare, holding [item]. */
fun boxOf(item: TypeUse): TypeUse = FixtureBoxDefinition.id.use(listOf(item))

/** A reference to the stock entry [target], as a loot's givers hold it. */
fun stockRef(target: ResourceId): Ref<ContentReferences.Source, FixtureStockEntry> = Ref(AuthorResourceId(target.value))

/** The error findings on each of [resources] after the checks settled. */
suspend fun RealmFixture.errorSet(vararg resources: ResourceId): Set<Diagnostic> {
    settle()
    return resources.flatMapTo(linkedSetOf()) { errorsOn(it) }
}

/**
 * The route fixtures plus a second extension's subtype of the open prize type, a record holding a Var, as a later
 * generation would add it.
 */
val prizeExtensionCatalog: RealmCatalog =
    routeFixtureCatalog.copy(
        declarations = { loaded ->
            val treasure = TypeDefinitionId.qualified("prize-extension", "treasure")
            listOf(
                OwnedTypeDeclaration(
                    loaded.declarations.first().origin,
                    TypeDefinition.partial(
                        id = treasure,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = treasure, name = "gold"),
                                            type = definitionValueUse(intUse).toTemplate(),
                                        ),
                                    ),
                                form = RecordForm.CONCRETE,
                            ),
                        parents = listOf(FixturePrizeDefinition.id.namedTemplate()),
                    ),
                ),
            )
        },
    )

/** The route fixtures plus a second extension's record whose source name is also `FixtureLoot`. */
val sameSourceNameCatalog: RealmCatalog =
    routeFixtureCatalog.copy(
        declarations = { loaded ->
            val twin = TypeDefinitionId.qualified("loot-extension", "FixtureLoot")
            listOf(
                OwnedTypeDeclaration(
                    loaded.declarations.first().origin,
                    TypeDefinition.partial(
                        id = twin,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                    ),
                ),
            )
        },
    )

private val changingCode: TypeDefinitionId = TypeDefinitionId.qualified("generation-test", "purse")

/** A code record no Kotlin class backs, whose fields [changingCodeCatalog] picks per generation. */
val changingCodeUse: TypeUse = changingCode.use()

/** The route fixtures plus [changingCodeUse] holding gold, and silver when [withSilver]. */
fun changingCodeCatalog(withSilver: Boolean): RealmCatalog =
    routeFixtureCatalog.copy(
        declarations = { loaded ->
            val names = if (withSilver) listOf("gold", "silver") else listOf("gold")
            listOf(
                OwnedTypeDeclaration(
                    loaded.declarations.first().origin,
                    TypeDefinition.partial(
                        id = changingCode,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    names.map {
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = changingCode, name = it),
                                            type = intUse.toTemplate(),
                                        )
                                    },
                                form = RecordForm.CONCRETE,
                            ),
                    ),
                ),
            )
        },
    )
