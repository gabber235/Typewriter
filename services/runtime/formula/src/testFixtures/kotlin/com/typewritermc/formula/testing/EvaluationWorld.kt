package com.typewritermc.formula.testing

import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.formula.CoreFormulas
import com.typewritermc.formula.Deferred
import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.FormulaFunction
import com.typewritermc.formula.NamedValue
import com.typewritermc.formula.RecordValue
import com.typewritermc.formula.check.FormulaEnvironment
import com.typewritermc.formula.eval.CatalogEvaluationEnvironment
import com.typewritermc.formula.eval.Evaluation
import com.typewritermc.formula.eval.EvaluationEnvironment
import com.typewritermc.formula.eval.EvaluationLimits
import com.typewritermc.formula.eval.evaluate
import com.typewritermc.formula.eval.refTo
import com.typewritermc.formula.stdlib.CollectionFormulasGeneratedFormulaProvider
import com.typewritermc.formula.stdlib.NumberFormulasGeneratedFormulaProvider
import com.typewritermc.formula.stdlib.TextFormulasGeneratedFormulaProvider
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.member
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldBeEmpty
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import kotlin.time.Duration.Companion.seconds

// The interpreter's test world: resources with stored values over the evaluation catalog, checked and run the way a
// formula is in the realm, so each case reads as source, expected type and value.

/** A resource of the world: what naming it gives, its fields, and for a `Definition<Type>` the type it holds. */
data class EvaluationResource(
    val name: String,
    val naming: TypeUse,
    val value: Any?,
    val fields: Map<String, Any?> = emptyMap(),
    val typeValue: TypeUse? = null,
    val id: ResourceId = ResourceId(name),
)

/** The stored, not yet evaluated value of [field] on the resource [resource]. */
fun deferredField(
    resource: String,
    field: String,
): Deferred = Deferred(ValueLocation.of(ResourceId(resource).toSkir()).field(field))

val goldUse: TypeUse = GoldDefinition.id.use()
val rewardUse: TypeUse = RewardDefinition.id.use()
val smithUse: TypeUse = SmithDefinition.id.use()

/** A set of [item]. */
fun setType(item: TypeUse): TypeUse = StandardTypes.set.use(listOf(item))

private val crewUse = CrewDefinition.id.use()
private val moodUse = MoodDefinition.id.use()

/** The resources every interpreter case sees. */
val evaluationResources: List<EvaluationResource> =
    listOf(
        EvaluationResource("door", DoorDefinition.id.use(), NamedValue(DoorOpenDefinition.id.use(), Unit)),
        EvaluationResource("money", PaymentDefinition.id.use(), RecordValue(PaymentMoneyDefinition.id.use(), mapOf("amount" to 50))),
        EvaluationResource("storedFree", PaymentDefinition.id.use(), NamedValue(PaymentFreeDefinition.id.use(), Unit)),
        EvaluationResource("winter", SeasonDefinition.id.use(), NamedValue(SeasonDefinition.id.member("WINTER").use(), Unit)),
        EvaluationResource("storedGold", goldUse, RecordValue(goldUse, mapOf("amount" to 5))),
        EvaluationResource("storedPrize", prizeUse, RecordValue(prizeUse, mapOf("gold" to 5))),
        EvaluationResource("storedReward", rewardUse, RecordValue(rewardUse, mapOf("gold" to 5, "chest" to false))),
        EvaluationResource("aliasedPrize", prizeAliasUse, RecordValue(prizeUse, mapOf("gold" to 5))),
        EvaluationResource("Prize", ScalarKind.TYPE.use, null, typeValue = prizeAliasUse),
        EvaluationResource("Award", ScalarKind.TYPE.use, null, typeValue = awardUse),
        EvaluationResource(
            "smith",
            refType(smithUse),
            refTo(ResourceId("smith")),
            fields = mapOf("name" to "Old Smith", "mood" to deferredField("smith", "mood")),
        ),
        EvaluationResource(
            "anvil",
            refType(smithUse),
            refTo(ResourceId("anvil")),
            fields = mapOf("name" to "Anvil", "mood" to deferredField("anvil", "mood")),
        ),
        EvaluationResource(
            "crew",
            crewUse,
            RecordValue(
                crewUse,
                mapOf("members" to listOf(refTo(ResourceId("smith")), refTo(ResourceId("anvil")))),
            ),
        ),
        EvaluationResource("calm", moodUse, RecordValue(moodUse, mapOf("level" to deferredField("calm", "level")))),
        EvaluationResource("tags", setType(int), linkedSetOf(1, 2)),
        EvaluationResource("wait", ScalarKind.DURATION.use, 90.seconds),
        EvaluationResource("maybe", nullable(int), null),
        EvaluationResource("some", nullable(int), 4),
    )

/** What each deferred value of [evaluationResources] evaluates to. */
val evaluationDeferred: Map<Deferred, Any?> =
    mapOf(
        deferredField("smith", "mood") to 3,
        deferredField("anvil", "mood") to 2,
        deferredField("calm", "level") to 4,
    )

private val evaluationFunctions: Map<String, List<FormulaFunction>> =
    (
        CollectionFormulasGeneratedFormulaProvider().functions +
            NumberFormulasGeneratedFormulaProvider().functions +
            TextFormulasGeneratedFormulaProvider().functions +
            EvaluationFormulasGeneratedFormulaProvider().functions +
            CoreFormulas.functions
    ).groupBy(FormulaFunction::name)

private val typeNames: Map<String, TypeDefinitionId> =
    mapOf(
        "Gold" to GoldDefinition.id,
        "Box" to BoxDefinition.id,
        "Reward" to RewardDefinition.id,
        "Settings" to SettingsDefinition.id,
        "Season" to SeasonDefinition.id,
        "Coins" to CoinsDefinition.id,
        "Door" to DoorDefinition.id,
        "Payment" to PaymentDefinition.id,
        "Mood" to MoodDefinition.id,
        "Crew" to CrewDefinition.id,
        "Measure" to MeasureDefinition.id,
        "Smith" to SmithDefinition.id,
        "Signal" to SignalDefinition.id,
    )

private val prizeDefinition: TypeDefinitionId = (prizeUse as TypeUse.NamedWrapper).value.definition

/** The world formulas are checked and run in: [resources] in scope, and each deferred value standing for its answer in [deferred]. */
class EvaluationWorld(
    private val resources: List<EvaluationResource> = evaluationResources,
    private val deferred: Map<Deferred, Any?> = evaluationDeferred,
) {
    private fun resource(id: ResourceId): EvaluationResource = resources.first { it.id == id }

    val checking: FormulaEnvironment =
        object : FormulaEnvironment {
            override fun resolve(use: TypeUse): Resolution<CheckedType> = evaluationCatalog.resolve(use)

            override fun expand(use: TypeUse): TypeUse = evaluationCatalog.expand(use)

            override fun inScope(name: String): List<ResourceId> = resources.filter { it.name == name }.map(EvaluationResource::id)

            override fun functions(name: String): List<FormulaFunction> = evaluationFunctions[name].orEmpty()

            override fun reference(target: ResourceId): TypeUse? = resources.firstOrNull { it.id == target }?.naming

            override fun catalogTypeNamed(name: String): List<TypeUse> = listOfNotNull(typeNames[name]?.use())

            override fun typeValue(target: ResourceId): TypeUse? = resources.firstOrNull { it.id == target }?.typeValue

            override fun isMissing(id: TypeDefinitionId): Boolean = false
        }

    val evaluating: EvaluationEnvironment =
        object : CatalogEvaluationEnvironment(evaluationCatalog, evaluationBindings) {
            override fun evaluateDeferred(value: Deferred): Any? = deferred.getValue(value)

            override fun fieldOf(
                resource: ResourceId,
                field: String,
            ): Any? = resource(resource).fields.getValue(field)

            override fun exported(resource: ResourceId): Any? = resource(resource).value

            override fun typeName(id: TypeDefinitionId): String? =
                if (id == prizeDefinition) "Prize" else typeNames.entries.firstOrNull { it.value == id }?.key

            override fun resourceName(id: ResourceId): String = resource(id).name
        }
}

/** Where every case's formula sits. */
val evaluationSite: ValueLocation = ValueLocation.of(ResourceId("formula").toSkir())

/**
 * Checks [source] against [expected] in [world], requires it to check without problems, and runs it as the formula at
 * [evaluationSite].
 */
fun run(
    source: String,
    expected: TypeUse,
    world: EvaluationWorld = EvaluationWorld(),
    limits: EvaluationLimits = EvaluationLimits(),
): Evaluation<Any?> {
    val checked = check(source, expected, world.checking)
    withClue("problems of $source") { checked.problems.shouldBeEmpty() }
    return with(world.evaluating) { checked.tree.evaluate(emptyMap(), evaluationSite, limits) }
}

/** The failure of a failed evaluation, or null when it did not fail. */
val Evaluation<*>.failure: FormulaFailure? get() = (this as? Evaluation.Failed)?.reason

/** Runs [body] on a thread with a small stack, as a caller with little stack left would, and gives its result. */
fun <T> onSmallStack(body: () -> T): T {
    var result: Result<T>? = null
    val thread = Thread(null, { result = runCatching(body) }, "small-stack", SMALL_STACK_BYTES)
    thread.start()
    thread.join()
    return checkNotNull(result).getOrThrow()
}

private const val SMALL_STACK_BYTES = 256L * 1024
