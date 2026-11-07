package com.typewritermc.realm.testing

import com.typewritermc.authoring.bind
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.orNull
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.elements.ElementFields
import com.typewritermc.engine.pages.DefinitionDefinition
import com.typewritermc.engine.pages.DefinitionFields
import com.typewritermc.formula.DynamicProvider
import com.typewritermc.formula.Dynamics
import com.typewritermc.formula.Formula
import com.typewritermc.formula.VarDefinition
import com.typewritermc.library.PageFields
import com.typewritermc.realm.authoring.readNow
import com.typewritermc.realm.catalog.CONTENT_RULE
import com.typewritermc.realm.formula.NameAt
import com.typewritermc.realm.formula.NamedAs
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.testing.routes.FixtureStaticEntryDraftType
import com.typewritermc.types.FORMULA_USE
import com.typewritermc.types.functionUse
import com.typewritermc.types.member
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.record
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import kotlin.coroutines.cancellation.CancellationException

/*
 * The scope kit: hooks whose behaviour a test picks by naming a resource, and the reads that show what a name means
 * at a formula, what naming a resource gives, and which resources the content rule judged.
 */

/**
 * Hooks a test drives by name. A FixtureStaticEntry named `throw`, `recurse`, `linkage` or `cancel` makes its hook
 * fail in that way. A Definition named `with_own_scope` gives its value field a scope of its own, where `smith` means
 * each element of its page named `own_smith`.
 */
object FixtureHooks : DynamicProvider {
    override fun Dynamics.register() {
        each(FixtureStaticEntryDraftType) { entry ->
            when (entry.name.orNull()) {
                "throw" -> error("The fixture hook broke.")
                "recurse" -> recurse(0)
                "linkage" -> throw NoClassDefFoundError("com/example/RemovedClass")
                "cancel" -> throw IllegalStateException("A wrapped cancellation.", CancellationException("cancelled"))
            }
        }
        each(DefinitionDefinition.id) { id ->
            val resource = id.toResourceId()
            if (read(DefinitionFields.name.bind(resource)).orNull() != "with_own_scope") return@each
            val page = read(DefinitionFields.page.bind(resource)).orNull()?.target ?: return@each
            scope(DefinitionFields.value) {
                read(PageFields.elements.bind(page)).orNull().orEmpty().forEach { element ->
                    if (read(ElementFields.name.bind(element.target)).orNull() == "own_smith") resource("smith", element.target.toSkir())
                }
            }
        }
    }

    private fun recurse(depth: Int): Int = recurse(depth + 1) + 1
}

/** A dynamic provider whose register throws. */
object BrokenDynamics : DynamicProvider {
    override fun Dynamics.register(): Unit = error("The fixture dynamic provider broke.")
}

/** A dynamic provider whose register fails to link a class it needs. */
object UnlinkableDynamics : DynamicProvider {
    override fun Dynamics.register(): Unit = throw NoClassDefFoundError("com/example/RemovedDynamicClass")
}

/** The route fixtures with [FixtureHooks] and the extra dynamic [providers] registered. */
fun hookCatalog(vararg providers: DynamicProvider): RealmCatalog = routeFixtureCatalog.copy(dynamics = listOf(FixtureHooks) + providers)

/** The resources [name] means at the value of the Definition [resource], read as a check pass reads it. */
fun RealmFixture.meaningOf(
    resource: ResourceId,
    name: String,
): List<ResourceId> = readNow(NameAt(ValueLocation.of(resource, ValuePath.root.field("value")), name))

/** What a formula gets when it names [resource]: its export's type, or a Ref to its type. */
fun RealmFixture.namingType(resource: ResourceId): TypeUse? = readNow(NamedAs(resource))

/** The codes of the error findings on [resource] once the checks settled. */
suspend fun RealmFixture.errorCodesOn(resource: ResourceId): List<String> {
    settle()
    return errorsOn(resource).map { it.code }
}

/** The codes of every finding and check failure once the checks settled. */
suspend fun RealmFixture.allFindingCodes(): List<String> {
    settle()
    return checks.findings().flatMap { set ->
        set.findings.map { it.code } + (set.outcome as? CheckOutcome.FailedWrapper)?.value.orEmpty().map { it.code }
    }
}

/** The resources the content rule judged once the checks settled: each one that holds content worth a finding set. */
suspend fun RealmFixture.contentJudged(): Set<ResourceId> {
    settle()
    return checks
        .findings()
        .filter { it.ticket.instance.rule == CONTENT_RULE }
        .mapTo(linkedSetOf()) { it.ticket.instance.location.resource }
}

/** How often each formula was checked so far, after the checks settled. */
suspend fun RealmFixture.settledFormulaChecks(): Map<ValueLocation, Long> {
    settle()
    return graphRuns.formulaChecks()
}

/** The resources whose formulas were checked again since [before], after the checks settled. */
suspend fun RealmFixture.formulaChecksSince(before: Map<ValueLocation, Long>): Set<ResourceId> {
    settle()
    return graphRuns.formulaChecks().grewFrom(before).mapTo(linkedSetOf()) { it.resource }
}

/** The evidence of the content rule's finding set on [resource] once the checks settled. */
suspend fun RealmFixture.contentEvidence(resource: ResourceId): List<EditExpectation> = contentSet(resource).expectations

/** The content rule's finding set on [resource] once the checks settled. */
suspend fun RealmFixture.contentSet(resource: ResourceId): FindingSet {
    settle()
    return checks.findings().single { it.ticket.instance.rule == CONTENT_RULE && it.ticket.instance.location.resource == resource }
}

/** The error findings that block publishing now, counted per resource they point at. */
suspend fun RealmFixture.publicationBlockersByResource(): Map<ResourceId?, Int> =
    publicationBlockers().groupingBy { it.primary?.resource }.eachCount()

/**
 * A Definition's value computed by the formula [source], stored as the value of a Definition of [type]. Each name in
 * [references] is bound to its resource wherever it appears in [source].
 */
fun RealmFixture.computedVar(
    type: TypeUse,
    source: String,
    references: Map<String, ResourceId> = emptyMap(),
): DataValue =
    DataValue.named(
        VarDefinition.id.member("Computed").namedUse(listOf(type, functionUse(result = type))),
        DataValue.record("formula" to encoder.encode(FORMULA_USE.use, boundFormula(source, references))),
    )

/** Creates the element [resource] again on the static page from the record [saved] it had before a delete, and commits it. */
suspend fun RealmFixture.restore(
    resource: ResourceId,
    saved: AuthoringRecord,
): CommitPreparedEditResponse {
    val (_, writes) = elementWrites(resource) { saved }
    return commit { writes() }
}

/** Sets the title of the book [book]. */
fun retitle(
    book: ResourceId,
    title: String,
): EditIntent =
    EditIntent.createSetValue(at = ValueLocation.of(book, ValuePath.root.field("title")), value = DataValue.StringValueWrapper(title))

/** [resource]'s saved record with the link stored in [field] pointed at [target], as no commit would write it. */
fun RealmFixture.relinked(
    resource: ResourceId,
    field: String,
    target: ResourceId,
): AuthoringRecord = record(resource).with(field, checkNotNull(value(resource, field)).pointedAt(target))

private fun DataValue.pointedAt(target: ResourceId): DataValue =
    when (this) {
        is DataValue.LinkWrapper -> DataValue.LinkWrapper(value.copy(target = value.target.copy(resource = target)))
        is DataValue.NamedWrapper -> DataValue.named(value.actualType, value.payload.pointedAt(target))
        else -> error("$this holds no link.")
    }
