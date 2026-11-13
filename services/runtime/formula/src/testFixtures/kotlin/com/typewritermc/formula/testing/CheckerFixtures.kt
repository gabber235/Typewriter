package com.typewritermc.formula.testing

import com.typewritermc.formula.ContentReferences
import com.typewritermc.formula.CoreFormulas
import com.typewritermc.formula.FormulaDefinition
import com.typewritermc.formula.FormulaFunction
import com.typewritermc.formula.FormulaReferenceDefinition
import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.TextSpanDefinition
import com.typewritermc.formula.VarComputedDefinition
import com.typewritermc.formula.VarDefinition
import com.typewritermc.formula.VarValueDefinition
import com.typewritermc.formula.check.CatalogType
import com.typewritermc.formula.check.CheckedFormula
import com.typewritermc.formula.check.ExtensionName
import com.typewritermc.formula.check.FormulaEnvironment
import com.typewritermc.formula.check.NameMeaning
import com.typewritermc.formula.check.StoredFormula
import com.typewritermc.formula.check.StoredReference
import com.typewritermc.formula.check.checkFormula
import com.typewritermc.formula.stdlib.CollectionFormulasGeneratedFormulaProvider
import com.typewritermc.formula.stdlib.NumberFormulasGeneratedFormulaProvider
import com.typewritermc.formula.stdlib.TextFormulasGeneratedFormulaProvider
import com.typewritermc.types.ResourceDefinition
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.floatScalar
import com.typewritermc.types.functionUse
import com.typewritermc.types.integerScalar
import com.typewritermc.types.member
import com.typewritermc.types.memberName
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.nullable
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.FunctionParameterTemplate
import skirout.editor.v1.type_catalog.FunctionTypeTemplate
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

// The checker's test world: a small catalog, a few providers and the resources in scope, stated here once so each
// checker case reads as source, expected type and answer.

val int: TypeUse = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
val long: TypeUse = integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR).use
val float: TypeUse = floatScalar(FloatWidth.THIRTY_TWO).use
val double: TypeUse = floatScalar(FloatWidth.SIXTY_FOUR).use
val decimal: TypeUse = ScalarKind.DECIMAL.use
val string: TypeUse = ScalarKind.TEXT.use
val boolean: TypeUse = ScalarKind.BOOLEAN.use

fun nullable(type: TypeUse): TypeUse = type.nullable()

fun listType(item: TypeUse): TypeUse = StandardTypes.list.use(listOf(item))

val intRange: TypeUse = StandardTypes.intRange.use()

fun mapType(
    key: TypeUse,
    value: TypeUse,
): TypeUse = StandardTypes.map.use(listOf(key, value))

/** A reference to a resource of [target], as content and formulas see it. */
fun refType(target: TypeUse): TypeUse =
    ContentReferences.Source.Definition.id
        .use(listOf(target))

/** The function type with these [parameters] and [context], returning [result]. */
fun function(
    vararg parameters: Pair<String, TypeUse>,
    context: List<Pair<String, TypeUse>> = emptyList(),
    result: TypeUse,
): TypeUse = functionUse(context = context, parameters = parameters.toList(), result = result)

private fun typeId(name: String): TypeDefinitionId = TypeDefinitionId.qualified("formula-test", name)

/** The record [id] with [fields] of [form] under [parents]; a constructor may leave out the fields in [defaulted]. */
private fun record(
    id: TypeDefinitionId,
    fields: List<Pair<String, TypeUse>> = emptyList(),
    form: RecordForm = RecordForm.CONCRETE,
    parents: List<TypeDefinitionId> = emptyList(),
    defaulted: Set<String> = emptySet(),
): TypeDefinition =
    TypeDefinition.partial(
        id = id,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    fields.map { (name, type) ->
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = id, name = name),
                            type = type.toTemplate(),
                            hasConstructorDefault = name in defaulted,
                        )
                    },
                form = form,
            ),
        parents = parents.map { it.namedTemplate() },
    )

private fun unitCase(id: TypeDefinitionId): TypeDefinition =
    TypeDefinition.partial(
        id = id,
        representation = RepresentationTemplate.createScalar(kind = ScalarKind.UNIT),
        parents =
            listOfNotNull(
                (id.typeId as? TypeId.MemberWrapper)
                    ?.value
                    ?.let {
                        TypeDefinitionId(typeId = it.owner, revision = 1)
                    }?.namedTemplate(),
            ),
    )

private fun closed(
    id: TypeDefinitionId,
    vararg cases: String,
): TypeDefinition = record(id, form = RecordForm.createClosed(cases = cases.map { id.member(it).namedTemplate() }))

private val entityId = typeId("Entity")
private val namedId = typeId("Named")
private val npcId = typeId("Npc")
private val playerId = typeId("Player")
private val itemId = typeId("Item")
private val rewardId = typeId("Reward")
private val doorId = typeId("Door")
private val paymentId = typeId("Payment")
private val animalId = typeId("Animal")
private val catId = typeId("Cat")
private val smithId = typeId("Smith")
private val townId = typeId("Town")
private val energyId = typeId("Energy")
private val tallyId = typeId("Tally")
private val goneId = typeId("Gone")

val npc: TypeUse = npcId.use()
val player: TypeUse = playerId.use()
val item: TypeUse = itemId.use()
val reward: TypeUse = rewardId.use()
val door: TypeUse = doorId.use()
val payment: TypeUse = paymentId.use()
val smithType: TypeUse = smithId.use()

/** A `Var` holding [value] whose formulas read nothing, as `Var<T>` lowers. */
fun varType(value: TypeUse): TypeUse = VarDefinition.id.use(listOf(value, functionUse(result = value)))

/** The definitions every formula test catalog holds: the standard types, resources, references, Vars and formulas. */
val formulaCoreDefinitions: List<TypeDefinition> =
    StandardTypes.definitions +
        listOf(
            ResourceDefinition.definition,
            ContentReferences.Source.Definition.definition,
            VarDefinition.definition,
            VarValueDefinition.definition,
            VarComputedDefinition.definition,
            FormulaDefinition.definition,
            FormulaReferenceDefinition.definition,
            TextSpanDefinition.definition,
        )

private val testCatalog =
    DefaultCheckedCatalog(
        CatalogGeneration(value = "formula checker test"),
        formulaCoreDefinitions +
            listOf(
                record(entityId, form = RecordForm.OPEN),
                record(namedId, form = RecordForm.OPEN),
                record(npcId, listOf("name" to string), parents = listOf(entityId, namedId)),
                record(playerId),
                record(itemId, listOf("is_ok" to boolean)),
                record(rewardId, listOf("gold" to int, "chest" to boolean), defaulted = setOf("chest")),
                closed(doorId, "Open", "Closed"),
                unitCase(doorId.member("Open")),
                unitCase(doorId.member("Closed")),
                closed(paymentId, "Money", "Free"),
                record(paymentId.member("Money"), listOf("amount" to int), parents = listOf(paymentId)),
                unitCase(paymentId.member("Free")),
                record(animalId, form = RecordForm.OPEN),
                record(catId, parents = listOf(animalId)),
                record(townId, listOf("name" to string), parents = listOf(ResourceDefinition.id)),
                record(
                    smithId,
                    listOf(
                        "name" to string,
                        "mood" to varType(int),
                        "home" to refType(townId.use()),
                        "ratings" to listType(varType(int)),
                        "marks" to mapType(string, varType(int)),
                        "ledger" to varType(listType(varType(int))),
                        "tallies" to listType(tallyId.use()),
                    ),
                    parents = listOf(ResourceDefinition.id),
                ),
                record(energyId, listOf("amount" to int)),
                record(tallyId, listOf("count" to varType(int), "extras" to listType(varType(int)))),
            ),
    )

/** The code types formulas name by their source name, each declared by the extension its id's namespace names. */
private val catalogNames: Map<String, List<CatalogType>> =
    listOf(entityId, namedId, npcId, playerId, itemId, rewardId, doorId, paymentId, animalId, catId, townId)
        .map { (it.typeId as TypeId.QualifiedWrapper).value to it.use() }
        .groupBy({ (id, _) -> id.name }, { (id, use) -> CatalogType(use, ExtensionName.of(id.namespace)) })

/** A provider function with these slots; the checker never runs it. */
private fun provider(
    name: String,
    receiver: TypeUse? = null,
    parameters: List<Pair<String, TypeUse>> = emptyList(),
    result: TypeUse,
): FormulaFunction =
    FormulaFunction(
        name = name,
        typeParameters = emptyList(),
        signature =
            FunctionTypeTemplate(
                context = listOfNotNull(receiver?.let { FunctionParameterTemplate(name = "this", type = it.toTemplate()) }),
                parameters = parameters.map { (slot, type) -> FunctionParameterTemplate(name = slot, type = type.toTemplate()) },
                result = result.toTemplate(),
            ),
        defaulted = emptySet(),
    ) { error("The checker test world does not run providers.") }

/** `fun <T : Entity> T.rank(): Int`, `fun <T : Entity> loudest(of: List<T>): T` and `fun <T : Entity> List<T>.rankAll(): Int`. */
private val boundedProviders: List<FormulaFunction> =
    listOf("rank", "loudest", "rankAll").map { name ->
        val key = ParameterKey(owner = TypeDefinitionId.qualified("formula-test", name), index = 0)
        val t = TypeTemplate.ParameterWrapper(key)
        val list = StandardTypes.list.template(listOf(t))
        val receiver = FunctionParameterTemplate(name = "this", type = if (name == "rankAll") list else t)
        val context = if (name == "loudest") emptyList() else listOf(receiver)
        val parameters = if (name == "loudest") listOf(FunctionParameterTemplate(name = "of", type = list)) else emptyList()
        val result = if (name == "loudest") t else int.toTemplate()
        FormulaFunction(
            name = name,
            typeParameters = listOf(TypeParameter(key = key, name = "T", bounds = listOf(entityId.template()), derived = false)),
            signature = FunctionTypeTemplate(context = context, parameters = parameters, result = result),
            defaulted = emptySet(),
        ) { error("The checker test world does not run providers.") }
    }

private val testFunctions: Map<String, List<FormulaFunction>> =
    (
        CollectionFormulasGeneratedFormulaProvider().functions +
            NumberFormulasGeneratedFormulaProvider().functions +
            TextFormulasGeneratedFormulaProvider().functions +
            CoreFormulas.functions +
            listOf(
                provider("double", parameters = listOf("x" to int), result = int),
                provider("distanceTo", receiver = npc, result = int),
                provider("distanceTo", receiver = entityId.use(), result = int),
                provider("tie", receiver = namedId.use(), result = int),
                provider("tie", receiver = entityId.use(), result = int),
                provider("needsPlayer", receiver = player, result = int),
            ) +
            boundedProviders
    ).groupBy(FormulaFunction::name)

/** A resource in the test world: what naming it gives, and for a `Definition<Type>` the type it holds. */
data class WorldResource(
    val name: String,
    val naming: TypeUse,
    val typeValue: TypeUse? = null,
    val id: ResourceId = ResourceId(name),
)

private val typeOfTypes: TypeUse = ScalarKind.TYPE.use

/** The resources in scope for every checker case. */
val checkerResources: List<WorldResource> =
    listOf(
        WorldResource("bonus", function("level" to int, result = int)),
        WorldResource("items", listType(int)),
        WorldResource("stock", listType(item)),
        WorldResource("flag", boolean),
        WorldResource("maybe", nullable(int)),
        WorldResource("smith", refType(smithType)),
        WorldResource("npc", npc),
        WorldResource("twin", int, id = ResourceId("twin-1")),
        WorldResource("twin", int, id = ResourceId("twin-2")),
        WorldResource("a", string),
        WorldResource("door", door),
        WorldResource("payment", payment),
        WorldResource("pet", animalId.use()),
        WorldResource("level", int),
        WorldResource("ghost", goneId.use()),
        WorldResource("Energy", typeOfTypes, typeValue = energyId.use()),
        WorldResource("Shape", typeOfTypes),
    )

/** The checker's environment over [resources], with the targets in [deleted] gone. */
class CheckerWorld(
    private val resources: List<WorldResource> = checkerResources,
    private val deleted: Set<ResourceId> = emptySet(),
) : FormulaEnvironment {
    private val present get() = resources.filterNot { it.id in deleted }

    override fun resolve(use: TypeUse): Resolution<CheckedType> = testCatalog.resolve(use)

    override fun expand(use: TypeUse): TypeUse = testCatalog.expand(use)

    override fun inScope(name: String): List<ResourceId> = present.filter { it.name == name }.map(WorldResource::id)

    override fun functions(name: String): List<FormulaFunction> = testFunctions[name].orEmpty()

    override fun reference(target: ResourceId): TypeUse? = present.firstOrNull { it.id == target }?.naming

    override fun catalogTypeNamed(name: String): List<CatalogType> = catalogNames[name].orEmpty()

    override fun extensions(): Set<ExtensionName> = catalogNames.values.flatMapTo(linkedSetOf()) { types -> types.map { it.extension } }

    override fun typeValue(target: ResourceId): TypeUse? = present.firstOrNull { it.id == target }?.typeValue

    override fun isMissing(id: TypeDefinitionId): Boolean = id == goneId
}

/**
 * Checks [source] against [expected] as a saved formula: its names bound the way a commit binds them, each name
 * with exactly one resource candidate referencing it. A function typed [expected] is the function the source is the
 * body of; a null one asks the checker to infer the type.
 */
fun check(
    source: String,
    expected: TypeUse?,
    world: FormulaEnvironment = CheckerWorld(),
): CheckedFormula = checkBound(bind(source, expected, world), expected, world)

/** As [check], with every reference the commit bound emptied, as a delete of its target leaves it stored. */
fun checkWithEmptied(
    source: String,
    expected: TypeUse?,
): CheckedFormula {
    val bound = bind(source, expected, CheckerWorld())
    return checkBound(bound.copy(references = bound.references.map { it.copy(target = null) }), expected, CheckerWorld())
}

/** As [check], with every reference the commit bound still filled while its target gives no type. */
fun checkWithTargetsGone(
    source: String,
    expected: TypeUse?,
): CheckedFormula {
    val bound = bind(source, expected, CheckerWorld())
    val gone = bound.references.mapNotNull { it.target }.toSet()
    return checkBound(bound, expected, CheckerWorld(deleted = gone))
}

private fun bind(
    source: String,
    expected: TypeUse?,
    world: FormulaEnvironment,
): StoredFormula {
    val unbound = checkBound(StoredFormula(source), expected, world)
    val references =
        unbound.names
            .filter { it.meaning == NameMeaning.Unknown || it.meaning == NameMeaning.Provider || it.meaning == NameMeaning.CatalogType }
            .mapNotNull { answer -> answer.candidates.singleOrNull()?.let { StoredReference(answer.span, it) } }
    return StoredFormula(source, references)
}

private fun checkBound(
    formula: StoredFormula,
    expected: TypeUse?,
    world: FormulaEnvironment,
): CheckedFormula =
    with(world) {
        val body = expected?.let { (it as? TypeUse.FunctionWrapper)?.value }
        if (body != null) {
            checkFormula(formula, body.context, body.parameters, body.result)
        } else {
            checkFormula(formula, emptyList(), emptyList(), expected)
        }
    }

/** What a checker case expects: a type with no problems, or a problem with this code. */
sealed interface CheckAnswer {
    data class Typed(
        val type: TypeUse,
    ) : CheckAnswer {
        override fun toString(): String = "type ${type.shown}"
    }

    data class Problem(
        val code: String,
        val at: TextSpan?,
    ) : CheckAnswer {
        override fun toString(): String = listOfNotNull(code, at?.let { "at ${it.start}..${it.end}" }).joinToString(" ")
    }
}

fun type(type: TypeUse): CheckAnswer = CheckAnswer.Typed(type)

/** A problem with [code], at the span from `at.first` to `at.last`, end exclusive, when [at] is given. */
fun problem(
    code: String,
    at: IntRange? = null,
): CheckAnswer = CheckAnswer.Problem(code, at?.let { TextSpan(it.first, it.last) })

fun row(
    source: String,
    expected: TypeUse?,
    answer: CheckAnswer,
): Triple<String, TypeUse?, CheckAnswer> = Triple(source, expected, answer)

/** Asserts the checker gave [answer]: the type and no problems, or no type and a problem with that code and span. */
infix fun CheckedFormula.shouldAnswer(answer: CheckAnswer) {
    withClue("problems: $problems") {
        when (answer) {
            is CheckAnswer.Typed -> {
                problems.shouldBeEmpty()
                type shouldBe answer.type
            }

            is CheckAnswer.Problem -> {
                type shouldBe null
                problems.map { it.code } shouldContain answer.code
                answer.at?.let { span -> problems.filter { it.code == answer.code }.map { it.span } shouldContain span }
            }
        }
    }
}

/** A short name for a type, for test names. */
val TypeUse?.shown: String get() =
    this?.let {
        com.typewritermc.formula.check
            .shown(it)
    } ?: "nothing"
