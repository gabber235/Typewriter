@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package com.typewritermc.types

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

private val requiredFieldsType = testType("required_fields")
private val nestedChildType = testType("nested_child")
private val nestedRootType = testType("nested_root")
private val defaultsType = testType("defaults")
private val unitType = testType("unit")
private val optionalType = testType("optional")
private val creatureType = testType("creature")
private val catType = testType("cat")
private val creatureRootType = testType("creature_root")
private val referenceTargetType = testType("reference_target")
private val boundedCollectionsType = testType("bounded_collections")
private val choiceType =
    TypeExpression.Enumeration(
        valueType = TypeExpression.StringType(),
        values = listOf(DataValue.StringValue("one"), DataValue.StringValue("two")),
    )

@Serializable
private enum class RequiredChoice {
    ONE,
    TWO,
}

@Serializable
private data class RequiredFields(
    val label: String,
    val enabled: Boolean,
    val reference: ResourceId,
    val choice: RequiredChoice,
    val values: List<String>,
    val lookup: Map<String, Int>,
)

@Serializable
private data class NestedChild(
    val title: String,
)

@Serializable
private data class NestedRoot(
    val children: List<NestedChild>,
    val lookup: Map<String, NestedChild>,
)

@Serializable
private data class Defaults(
    val enabled: Boolean,
    val title: String = "constructor default",
)

@Serializable
private data class UnitValue(
    val marker: Unit,
)

@Serializable
private data class OptionalValue(
    val value: String?,
)

@Serializable
private sealed interface Creature

@Serializable
@SerialName("cat")
private data class Cat(
    val name: String,
) : Creature

@Serializable
private data class CreatureRoot(
    val creature: Creature,
)

@Serializable
private data class BoundedCollections(
    val groups: List<List<String>>,
    val lookup: Map<String, List<String>>,
)

val ConcreteInitializationTest by testSuite {
    test("missing scalar reference enum and collection values remain unresolved") {
        val registry = registry(requiredFieldsPrototype())

        val result = registry.planInitialization(requiredFieldsType, null)

        val incomplete = result as TypeInitializationPlan.NeedsInput
        incomplete.supplied shouldBe DataValue.Record(emptyMap())
        incomplete.requirements.map(TypeInitializationRequirement::path).shouldContainExactlyInAnyOrder(
            DataPath.field("label"),
            DataPath.field("enabled"),
            DataPath.field("reference"),
            DataPath.field("choice"),
            DataPath.field("values"),
            DataPath.field("lookup"),
        )
        incomplete.requirements.map(TypeInitializationRequirement::reason).distinct() shouldBe
            listOf(TypeInitializationRequirementReason.MISSING_VALUE)
    }

    test("nested records retain list indexes and map keys in requirements") {
        val registry = registry(nestedChildPrototype(), nestedRootPrototype())
        val supplied =
            DataValue.Record(
                mapOf(
                    "children" to DataValue.ListValue(listOf(DataValue.Record(emptyMap()))),
                    "lookup" to
                        DataValue.MapValue(
                            listOf(
                                DataMapEntry(
                                    DataValue.StringValue("first"),
                                    DataValue.Record(emptyMap()),
                                ),
                            ),
                        ),
                ),
            )

        val result = registry.planInitialization(nestedRootType, supplied)

        val incomplete = result as TypeInitializationPlan.NeedsInput
        val requirements = incomplete.requirements
        requirements.map(TypeInitializationRequirement::path).shouldContainExactlyInAnyOrder(
            DataPath(
                listOf(
                    DataPathSegment.Field("children"),
                    DataPathSegment.Index(0),
                    DataPathSegment.Field("title"),
                ),
            ),
            DataPath(
                listOf(
                    DataPathSegment.Field("lookup"),
                    DataPathSegment.MapKey(DataValue.StringValue("first")),
                    DataPathSegment.Field("title"),
                ),
            ),
        )
        incomplete.supplied shouldBe supplied
    }

    test("editor initial values are materialized while constructor defaults stay absent") {
        val registry = registry(defaultsPrototype())

        val planned = registry.planInitialization(defaultsType, DataValue.Record(emptyMap()))

        planned shouldBe
            TypeInitializationPlan.Ready(
                DataValue.Record(
                    mapOf("enabled" to DataValue.Boolean(true)),
                ),
            )

        val initialized = registry.initializeConcrete(defaultsType, DataValue.Record(emptyMap()))
        registry.decodeAs<Defaults>(initialized) shouldBe Defaults(enabled = true)
        initialized.rootValue shouldBe
            DataValue.Record(
                mapOf(
                    "enabled" to DataValue.Boolean(true),
                    "title" to DataValue.StringValue("constructor default"),
                ),
            )
    }

    test("unit is the only missing value inferred automatically") {
        val registry = registry(unitPrototype())

        registry.planInitialization(unitType, null) shouldBe
            TypeInitializationPlan.Ready(
                DataValue.Record(mapOf("marker" to DataValue.Unit)),
            )
    }

    test("missing option requires an explicit Some or None choice") {
        val registry = registry(optionalPrototype())
        val missing = registry.planInitialization(optionalType, DataValue.Record(emptyMap()))

        missing shouldBe
            TypeInitializationPlan.NeedsInput(
                supplied = DataValue.Record(emptyMap()),
                requirements =
                    listOf(
                        TypeInitializationRequirement(
                            path = DataPath.field("value"),
                            expected = TypeExpression.Named(StandardTypes.optionOf(TypeExpression.StringType())),
                            reason = TypeInitializationRequirementReason.CONCRETE_TYPE_REQUIRED,
                        ),
                    ),
            )

        val none =
            DataValue.Record(
                mapOf(
                    "value" to
                        DataValue.Polymorphic(
                            concreteType = StandardTypes.noneOf(TypeExpression.StringType()),
                            value = DataValue.Unit,
                        ),
                ),
            )
        registry.planInitialization(optionalType, none) shouldBe TypeInitializationPlan.Ready(none)

        val some =
            DataValue.Record(
                mapOf(
                    "value" to
                        DataValue.Polymorphic(
                            concreteType = StandardTypes.someOf(TypeExpression.StringType()),
                            value = DataValue.Record(mapOf("value" to DataValue.StringValue("present"))),
                        ),
                ),
            )
        registry.planInitialization(optionalType, some) shouldBe TypeInitializationPlan.Ready(some)
    }

    test("abstract fields retain the selected concrete type") {
        val registry = registry(creaturePrototype(), catPrototype(), creatureRootPrototype())
        val missing = registry.planInitialization(creatureRootType, DataValue.Record(emptyMap()))

        val requirement = (missing as TypeInitializationPlan.NeedsInput).requirements.single()
        requirement.path shouldBe DataPath.field("creature")
        requirement.reason shouldBe TypeInitializationRequirementReason.CONCRETE_TYPE_REQUIRED

        val supplied =
            DataValue.Record(
                mapOf(
                    "creature" to
                        DataValue.Polymorphic(
                            concreteType = catType,
                            value = DataValue.Record(mapOf("name" to DataValue.StringValue("Milo"))),
                        ),
                ),
            )
        registry.planInitialization(creatureRootType, supplied) shouldBe TypeInitializationPlan.Ready(supplied)

        val initialized = registry.initializeConcrete(creatureRootType, supplied)
        registry.decodeAs<CreatureRoot>(initialized) shouldBe CreatureRoot(Cat("Milo"))
    }

    test("abstract type initial values select a concrete subtype for nested entries") {
        val initialCreature =
            DataValue.Polymorphic(
                concreteType = catType,
                value = DataValue.Record(mapOf("name" to DataValue.StringValue("Default cat"))),
            )
        val registry = registry(creaturePrototype(initialCreature), catPrototype(), creatureRootPrototype())

        val planned = registry.planInitialization(creatureRootType, DataValue.Record(emptyMap()))

        planned shouldBe
            TypeInitializationPlan.Ready(
                DataValue.Record(mapOf("creature" to initialCreature)),
            )
        val initialized = registry.initializeConcrete(creatureRootType, DataValue.Record(emptyMap()))
        registry.decodeAs<CreatureRoot>(initialized) shouldBe CreatureRoot(Cat("Default cat"))
    }

    test("concrete type initial values initialize the root representation") {
        val initialValue = DataValue.Record(mapOf("enabled" to DataValue.Boolean(false)))
        val prototype = defaultsPrototype(initialValue)
        val registry = registry(prototype)

        registry.planInitialization(defaultsType, null) shouldBe TypeInitializationPlan.Ready(initialValue)
        registry.decodeAs<Defaults>(registry.initializeConcrete(defaultsType, initialValue)) shouldBe Defaults(enabled = false)
    }

    test("abstract fields reject unrelated concrete types") {
        val registry = registry(creaturePrototype(), catPrototype(), creatureRootPrototype(), defaultsPrototype())
        val supplied =
            DataValue.Record(
                mapOf(
                    "creature" to
                        DataValue.Polymorphic(
                            concreteType = defaultsType,
                            value = DataValue.Record(mapOf("enabled" to DataValue.Boolean(true))),
                        ),
                ),
            )

        shouldThrow<IllegalArgumentException> {
            registry.planInitialization(creatureRootType, supplied)
        }
    }

    test("concrete subtype lookup requires the exact parent revision and arguments") {
        val registry = registry(creaturePrototype(), catPrototype())

        registry.concreteImplementationsOf(creatureType.copy(revision = 2)) shouldBe emptyList()
        registry.concreteImplementationsOf(
            creatureType.withArguments(listOf(TypeExpression.StringType())),
        ) shouldBe emptyList()
        registry.concreteImplementationsOf(creatureType).map(TypePrototype<*>::type) shouldBe listOf(catType)
    }

    test("minimum collection cardinality is reported at nested list and map paths") {
        val registry = registry(boundedCollectionsPrototype())
        val supplied =
            DataValue.Record(
                mapOf(
                    "groups" to DataValue.ListValue(listOf(DataValue.ListValue(emptyList()))),
                    "lookup" to
                        DataValue.MapValue(
                            listOf(
                                DataMapEntry(
                                    DataValue.StringValue("group"),
                                    DataValue.ListValue(emptyList()),
                                ),
                            ),
                        ),
                ),
            )

        val result = registry.planInitialization(boundedCollectionsType, supplied)

        val incomplete = result as TypeInitializationPlan.NeedsInput
        incomplete.supplied shouldBe supplied
        incomplete.requirements.map(TypeInitializationRequirement::path).shouldContainExactlyInAnyOrder(
            DataPath(
                listOf(
                    DataPathSegment.Field("groups"),
                    DataPathSegment.Index(0),
                ),
            ),
            DataPath(
                listOf(
                    DataPathSegment.Field("lookup"),
                    DataPathSegment.MapKey(DataValue.StringValue("group")),
                ),
            ),
        )
    }

    test("maximum collection cardinality rejects oversized nested collections") {
        val registry = registry(boundedCollectionsPrototype())
        val supplied =
            DataValue.Record(
                mapOf(
                    "groups" to
                        DataValue.ListValue(
                            listOf(
                                DataValue.ListValue(listOf(DataValue.StringValue("one"))),
                                DataValue.ListValue(listOf(DataValue.StringValue("two"))),
                            ),
                        ),
                    "lookup" to DataValue.MapValue(emptyList()),
                ),
            )

        shouldThrow<IllegalArgumentException> {
            registry.planInitialization(boundedCollectionsType, supplied)
        }
    }

    test("maximum map cardinality rejects oversized maps") {
        val registry = registry(boundedCollectionsPrototype())
        val supplied =
            DataValue.Record(
                mapOf(
                    "groups" to DataValue.ListValue(listOf(DataValue.ListValue(listOf(DataValue.StringValue("one"))))),
                    "lookup" to
                        DataValue.MapValue(
                            listOf(
                                DataMapEntry(
                                    DataValue.StringValue("first"),
                                    DataValue.ListValue(listOf(DataValue.StringValue("one"))),
                                ),
                                DataMapEntry(
                                    DataValue.StringValue("second"),
                                    DataValue.ListValue(listOf(DataValue.StringValue("two"))),
                                ),
                            ),
                        ),
                ),
            )

        shouldThrow<IllegalArgumentException> {
            registry.planInitialization(boundedCollectionsType, supplied)
        }
    }
}

private fun testType(name: String): ResolvedTypeRef = ResolvedTypeRef(TypeId.Qualified("typewriter.test", name), revision = 1)

private fun registry(vararg prototypes: TypePrototype<*>): TypePrototypeRegistry =
    TypePrototypeRegistry(
        prototypes = prototypes.toList(),
        definitions = StandardTypes.definitions + prototypes.map(TypePrototype<*>::definition),
    )

private fun requiredFieldsPrototype() =
    SerializationConcreteTypePrototype(
        runtimeType = RequiredFields::class,
        type = requiredFieldsType,
        definition =
            TypeDefinition(
                id = requiredFieldsType,
                kind = NominalTypeKind.CONCRETE,
                representation =
                    TypeExpression.Record(
                        listOf(
                            TypeField("label", TypeExpression.StringType()),
                            TypeField("enabled", TypeExpression.Boolean),
                            TypeField("reference", TypeExpression.Reference(referenceTargetType)),
                            TypeField("choice", choiceType),
                            TypeField("values", TypeExpression.ListType(TypeExpression.StringType())),
                            TypeField(
                                "lookup",
                                TypeExpression.MapType(
                                    key = TypeExpression.StringType(),
                                    value = TypeExpression.Integer(IntegerWidth.SIGNED_32),
                                ),
                            ),
                        ),
                    ),
            ),
        serializer = RequiredFields.serializer(),
    )

private fun nestedChildPrototype() =
    SerializationConcreteTypePrototype(
        runtimeType = NestedChild::class,
        type = nestedChildType,
        definition =
            TypeDefinition(
                id = nestedChildType,
                kind = NominalTypeKind.CONCRETE,
                representation = TypeExpression.Record(listOf(TypeField("title", TypeExpression.StringType()))),
            ),
        serializer = NestedChild.serializer(),
    )

private fun nestedRootPrototype() =
    SerializationConcreteTypePrototype(
        runtimeType = NestedRoot::class,
        type = nestedRootType,
        definition =
            TypeDefinition(
                id = nestedRootType,
                kind = NominalTypeKind.CONCRETE,
                representation =
                    TypeExpression.Record(
                        listOf(
                            TypeField(
                                "children",
                                TypeExpression.ListType(TypeExpression.Named(nestedChildType)),
                            ),
                            TypeField(
                                "lookup",
                                TypeExpression.MapType(
                                    key = TypeExpression.StringType(),
                                    value = TypeExpression.Named(nestedChildType),
                                ),
                            ),
                        ),
                    ),
            ),
        serializer = NestedRoot.serializer(),
    )

private fun defaultsPrototype(initialValue: DataValue? = null) =
    SerializationConcreteTypePrototype(
        runtimeType = Defaults::class,
        type = defaultsType,
        definition =
            TypeDefinition(
                id = defaultsType,
                kind = NominalTypeKind.CONCRETE,
                representation =
                    TypeExpression.Record(
                        listOf(
                            TypeField("enabled", TypeExpression.Boolean, initialValue = DataValue.Boolean(true)),
                            TypeField("title", TypeExpression.StringType(), defaulted = true),
                        ),
                    ),
                initialValue = initialValue,
            ),
        serializer = Defaults.serializer(),
    )

private fun unitPrototype() =
    SerializationConcreteTypePrototype(
        runtimeType = UnitValue::class,
        type = unitType,
        definition =
            TypeDefinition(
                id = unitType,
                kind = NominalTypeKind.CONCRETE,
                representation = TypeExpression.Record(listOf(TypeField("marker", TypeExpression.Unit))),
            ),
        serializer = UnitValue.serializer(),
    )

private fun optionalPrototype() =
    SerializationConcreteTypePrototype(
        runtimeType = OptionalValue::class,
        type = optionalType,
        definition =
            TypeDefinition(
                id = optionalType,
                kind = NominalTypeKind.CONCRETE,
                representation =
                    TypeExpression.Record(
                        listOf(
                            TypeField("value", TypeExpression.Named(StandardTypes.optionOf(TypeExpression.StringType()))),
                        ),
                    ),
            ),
        serializer = OptionalValue.serializer(),
    )

private fun creaturePrototype(initialValue: DataValue? = null) =
    CatalogAbstractTypePrototype(
        runtimeType = Creature::class,
        type = creatureType,
        definition =
            TypeDefinition(
                id = creatureType,
                kind = NominalTypeKind.OPEN_ABSTRACT,
                initialValue = initialValue,
            ),
    )

private fun catPrototype() =
    SerializationConcreteTypePrototype(
        runtimeType = Cat::class,
        type = catType,
        definition =
            TypeDefinition(
                id = catType,
                kind = NominalTypeKind.CONCRETE,
                parents = listOf(creatureType),
                representation = TypeExpression.Record(listOf(TypeField("name", TypeExpression.StringType()))),
            ),
        serializer = Cat.serializer(),
    )

private fun creatureRootPrototype() =
    SerializationConcreteTypePrototype(
        runtimeType = CreatureRoot::class,
        type = creatureRootType,
        definition =
            TypeDefinition(
                id = creatureRootType,
                kind = NominalTypeKind.CONCRETE,
                representation =
                    TypeExpression.Record(
                        listOf(TypeField("creature", TypeExpression.Named(creatureType))),
                    ),
            ),
        serializer = CreatureRoot.serializer(),
    )

private fun boundedCollectionsPrototype() =
    SerializationConcreteTypePrototype(
        runtimeType = BoundedCollections::class,
        type = boundedCollectionsType,
        definition =
            TypeDefinition(
                id = boundedCollectionsType,
                kind = NominalTypeKind.CONCRETE,
                representation =
                    TypeExpression.Record(
                        listOf(
                            TypeField(
                                "groups",
                                TypeExpression.ListType(
                                    element =
                                        TypeExpression.ListType(
                                            element = TypeExpression.StringType(),
                                            minimumLength = 1,
                                            maximumLength = 1,
                                        ),
                                    maximumLength = 1,
                                ),
                            ),
                            TypeField(
                                "lookup",
                                TypeExpression.MapType(
                                    key = TypeExpression.StringType(),
                                    value =
                                        TypeExpression.ListType(
                                            element = TypeExpression.StringType(),
                                            minimumLength = 1,
                                        ),
                                    maximumLength = 1,
                                ),
                            ),
                        ),
                    ),
            ),
        serializer = BoundedCollections.serializer(),
    )
