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
import com.typewritermc.formula.DefinitionScope
import com.typewritermc.formula.Formula
import com.typewritermc.formula.Var
import com.typewritermc.formula.VarDefinition
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.realm.operation.prepare
import com.typewritermc.realm.operation.preview
import com.typewritermc.realm.operation.shouldBePrepared
import com.typewritermc.realm.operation.shouldBeReady
import com.typewritermc.realm.publication.AuthoringAcceptance
import com.typewritermc.realm.publication.CompilationInputs
import com.typewritermc.realm.publication.ResourceGraphArtifactProducer
import com.typewritermc.setup.SetupList
import com.typewritermc.setup.SetupRoot
import com.typewritermc.testing.routes.fixtureStaticEntry
import com.typewritermc.testkit.complete
import com.typewritermc.testkit.ready
import com.typewritermc.types.function
import com.typewritermc.types.functionUse
import com.typewritermc.types.integerScalar
import com.typewritermc.types.namedUse
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import io.kotest.matchers.collections.shouldContain
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompiledArtifactReference
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.PublicationId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

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

/**
 * A static page holding what [block] declares, returning its handles by name. Content a later layer step has not built
 * yet is marked pending instead of thrown while the suite is configured, so a demo stays red inside its own tests.
 */
fun SetupRoot.formulaPage(block: FormulaPageBuilder.() -> Unit): FormulaPage =
    library {
        books.book("formulas") {
            pages.staticPage("formulas") { FormulaPageBuilder(elements).apply(block).page(handle.id.toSkir()) }
        }
    }

/** Declares Definitions, formulas, custom types and entries on one static page. */
class FormulaPageBuilder internal constructor(
    private val elements: SetupList<StaticEntry>,
) {
    private val named = linkedMapOf<String, ResourceId>()
    private var pending: String? = null

    /** A Definition named [name] of [type] holding the plain Kotlin [value]. */
    fun definition(
        name: String,
        type: TypeUse,
        value: Any?,
    ): ResourceId = add(name, type, plain(value))

    /**
     * A Definition named [name] of [type] whose value is the formula [source]: the body itself when [type] is a function
     * type, which stores its body as a plain Formula, and a computed value otherwise.
     */
    fun formula(
        name: String,
        type: TypeUse,
        source: String,
    ): ResourceId = add(name, type, if (type.function != null) plain(Formula(source)) else computed(source))

    /** A Definition named [name] holding the custom type [build] declares. */
    fun customType(
        name: String,
        build: TypeDefinitionBuilder.() -> Unit,
    ): ResourceId = TODO("Definition holding a custom type")

    /** A FixtureStaticEntry named [name], a real entry next to the Definitions. */
    fun smith(name: String = "smith"): ResourceId =
        elements
            .fixtureStaticEntry(name) { this.name = name }
            .id
            .toSkir()
            .also { named[name] = it }

    /** Marks [content] as not built yet; every handle of the page then throws NotImplementedError naming it. */
    internal fun pending(content: String) {
        pending = pending ?: content
    }

    internal fun page(id: ResourceId): FormulaPage = FormulaPage(id, named.toMap(), pending)

    private fun add(
        name: String,
        type: TypeUse,
        value: Var<*, DefinitionScope>,
    ): ResourceId {
        @Suppress("UNCHECKED_CAST")
        val held = value as Var<Any?, DefinitionScope>
        return elements
            .definition<Any?>(name, type) {
                this.name = name
                this.value = held
            }.id
            .toSkir()
            .also { named[name] = it }
    }
}

/** The fields and cases of one custom type declaration. */
class TypeDefinitionBuilder {
    /** A field [name] holding [type]. */
    fun field(
        name: String,
        type: TypeUse,
    ): Unit = TODO("custom type field")
}

/** Demo 1, the roadmap's acceptance goal: base_reward, bonus and total. */
fun FormulaPageBuilder.demoOneDefinitions() {
    definition("base_reward", intUse, 50)
    formula("bonus", functionUse(parameters = listOf("level" to intUse), result = intUse), "level * 2")
    formula("total", intUse, "base_reward + bonus(10)")
}

/** Demo 2: the Reward type, first_reward, giver_name, gift and door; needs [FormulaPageBuilder.smith] and demo 1. */
fun FormulaPageBuilder.demoTwoDefinitions(): Unit = pending("demo two content")

/** The handles of a formula page: the page and every resource the demos name. */
class FormulaPage internal constructor(
    private val page: ResourceId,
    private val named: Map<String, ResourceId>,
    private val pending: String?,
) {
    val pageId: ResourceId get() = page.also { built() }
    val baseReward: ResourceId get() = handle("base_reward")
    val bonus: ResourceId get() = handle("bonus")
    val total: ResourceId get() = handle("total")
    val smith: ResourceId get() = handle("smith")
    val reward: ResourceId get() = handle("Reward")
    val firstReward: ResourceId get() = handle("first_reward")
    val giverName: ResourceId get() = handle("giver_name")
    val gift: ResourceId get() = handle("gift")
    val door: ResourceId get() = handle("door")

    private fun handle(name: String): ResourceId {
        built()
        return named[name] ?: error("The formula page declares no $name.")
    }

    private fun built() {
        pending?.let { throw NotImplementedError("An operation is not implemented: $it") }
    }
}

/** What the realm computed for formulas: a value at a path, the text as an author reads it, and the checked type. */
class FormulaReads internal constructor() {
    /** The evaluated value of [resource], or of the field at [path] inside it, as a plain Kotlin value. */
    fun value(
        resource: ResourceId,
        vararg path: String,
    ): Any? = TODO("formula evaluation")

    /** The formula text of [resource] with references shown by their targets' current names. */
    fun display(resource: ResourceId): String = TODO("formula display")

    /** The checked type of [resource]'s value. */
    fun type(resource: ResourceId): TypeUse = TODO("formula type")
}

/** The formula reads on this realm. */
val RealmFixture.formulas: FormulaReads get() = FormulaReads()

/** The error findings whose primary location is on [resource], after the checks settled. */
fun RealmFixture.errorsOn(resource: ResourceId): List<Diagnostic> = TODO("findings by resource")

/** How often the graph computed each CheckRun so far, per check instance, counting an equal rerun too. */
fun RealmFixture.settledRuns(): Map<CheckInstanceId, Long> = TODO("graph run counts")

/** The check instances the graph computed again since [before]. */
fun RealmFixture.rerunSince(before: Map<CheckInstanceId, Long>): Set<CheckInstanceId> = TODO("graph reruns")

/** The resources these check instances judge. */
fun Set<CheckInstanceId>.resources(): Set<ResourceId> = TODO("check instance resources")

/** Waits until every check the last commit started has finished. */
suspend fun RealmFixture.settle(): Unit = TODO("check settling")

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

/** The resources the formula references of [resource] point at. */
fun RealmFixture.referenceTargets(resource: ResourceId): List<ResourceId> = TODO("formula reference targets")

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
): EditIntent = TODO("rename intent")

/** Deletes [resource]. */
fun delete(resource: ResourceId): EditIntent = TODO("delete intent")

/** Points the plain giver link of the gift Definition [gift] at [to]. */
fun setGiver(
    gift: ResourceId,
    to: ResourceId,
): EditIntent = TODO("set giver intent")

/** Replaces the formula text of [resource] with [source]. */
fun setFormula(
    resource: ResourceId,
    source: String,
): EditIntent = TODO("set formula intent")

/** Adds the field [name] holding [type] to the custom type the Definition [type] declares. */
fun addField(
    type: ResourceId,
    name: String,
    field: TypeUse,
): EditIntent = TODO("add field intent")
