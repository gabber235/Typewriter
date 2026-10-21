package com.typewritermc.expression

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.TypedSelection
import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.presentation.RuntimePresentationQueries
import com.typewritermc.presentation.resource
import com.typewritermc.types.Color
import com.typewritermc.types.ColorDefinition
import com.typewritermc.types.DataValue
import com.typewritermc.types.Icon
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.Ref
import com.typewritermc.types.RelationshipEndpoint
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.template
import com.typewritermc.types.toWire
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PublishedType
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.ExpressionQuery
import skirout.editor.v1.expression.ResourceQuerySource
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse

val CanonicalQueryTest by testSuite {
    test("read models preserve pending arguments and stay out of authored declarations") {
        val selection =
            SkirAuthoringValueCodec
                .encode(
                    TypeSelection.Pending(
                        queryTypeId,
                        listOf(ArgumentSelection.Unfilled, ArgumentSelection.Chosen(ScalarKind.TEXT.use)),
                    ),
                ).getOrThrow()
        CanonicalReadModels.typeSelection.decode(CanonicalReadModels.typeSelection.encode(selection)) shouldBe selection
        queryCatalog.declaration(CanonicalReadModels.typeSelection.use.definition).shouldBeInstanceOf<Resolution.Invalid>()
    }

    test("resource leaf reads select before rejecting an unfinished sibling") {
        val resource =
            RuntimePresentationQueries(mapOf(QueryResource::class to queryTypeId.namedTemplate()))
                .resource(literal(ResourceId("result")), QueryResource::class)
        val body = resource.value.field<String>("name").toNode()
        val program = queryProgram(body, ScalarKind.TEXT.use)
        val record =
            AuthoringRecord(
                TypeSelection.Complete(queryTypeId.namedUse()),
                mapOf("name" to DataValue.StringValue("Current name"), "extra" to DataValue.Unfilled),
            )
        val observation = QueryObservation(mapOf(ResourceId("result") to record))
        val evaluator =
            DefaultExpressionEvaluator(ExpressionValueReader { error("The query owns its resource read") }, queries = observation)
        with(QueryReads) {
            evaluator.evaluateChecked(program, ExpressionBindings(emptyMap()), EvaluationBudget(100, 100))
        } shouldBe Availability.Available(DataValue.StringValue("Current name"))
        observation.seenReadContext shouldBe QueryReads.readContext
    }

    test("declaration leaf projection follows the supplied observation") {
        val resource =
            RuntimePresentationQueries(mapOf(QueryResource::class to queryTypeId.namedTemplate()))
                .resource(literal(ResourceId("result")), QueryResource::class)
        val body =
            resource.type.display.color
                .toNode()
        val program = queryProgram(body, ColorDefinition.id.use())
        val record =
            AuthoringRecord(
                TypeSelection.Complete(queryTypeId.namedUse()),
                mapOf(
                    "name" to DataValue.StringValue("Name"),
                    "extra" to DataValue.Unfilled,
                ),
            )
        val first = QueryObservation(mapOf(ResourceId("result") to record), Color(0xFF123456u))
        val second = QueryObservation(mapOf(ResourceId("result") to record), Color(0xFF654321u))

        fun evaluate(observation: QueryObservation) =
            with(QueryReads) {
                DefaultExpressionEvaluator(ExpressionValueReader { error("Unexpected authored value read") }, queries = observation)
                    .evaluateChecked(program, ExpressionBindings(emptyMap()), EvaluationBudget(100, 100))
            }
        evaluate(first) shouldBe
            Availability.Available(DataValue.Named(ColorDefinition.use, DataValue.Integer(0xFF123456u.toString().toBigInteger())))
        evaluate(second) shouldBe
            Availability.Available(DataValue.Named(ColorDefinition.use, DataValue.Integer(0xFF654321u.toString().toBigInteger())))
    }

    test("query identity has the same representation as its caller literal") {
        val resource =
            RuntimePresentationQueries(mapOf(QueryResource::class to queryTypeId.namedTemplate()))
                .resource(literal(ResourceId("result")), QueryResource::class)
        val body = (resource.id eq literal(ResourceId("result"))).toNode()
        val program = queryProgram(body, ScalarKind.BOOLEAN.use)
        val record =
            AuthoringRecord(
                TypeSelection.Complete(queryTypeId.namedUse()),
                mapOf(
                    "name" to DataValue.Unfilled,
                    "extra" to DataValue.Unfilled,
                ),
            )
        with(QueryReads) {
            DefaultExpressionEvaluator(
                ExpressionValueReader { error("Unexpected authored value read") },
                queries =
                    QueryObservation(
                        mapOf(ResourceId("result") to record),
                    ),
            ).evaluateChecked(program, ExpressionBindings(emptyMap()), EvaluationBudget(100, 100))
        } shouldBe Availability.Available(DataValue.Boolean(true))
    }

    test("unchecked and unsupported queries fail instead of becoming missing") {
        val resource =
            RuntimePresentationQueries(mapOf(QueryResource::class to queryTypeId.namedTemplate()))
                .resource(literal(ResourceId("result")), QueryResource::class)
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("Unexpected authored value read") })
        with(QueryReads) {
            evaluator.evaluate(resource.id.toNode(), ExpressionBindings(emptyMap()), EvaluationBudget(100, 100))
        }.shouldBeInstanceOf<Availability.Failed>()
        with(QueryReads) {
            evaluator.evaluateChecked(
                queryProgram(resource.id.toNode(), ResourceIdDefinition.use.use),
                ExpressionBindings(emptyMap()),
                EvaluationBudget(100, 100),
            )
        }.shouldBeInstanceOf<Availability.Failed>()
    }

    test("typed reference reads root content rather than the reciprocal endpoint path") {
        val binding = ExpressionBindingId("reference")
        val reference =
            portableExpression<Ref<QueryEndpoint, QueryResource>>(
                testInput(binding),
            )
        val body =
            reference.resource.value
                .field<String>("name")
                .toNode()
        val program =
            (
                PortableExpressionChecker(queryCatalog::resolve).checkProgram(
                    body,
                    mapOf(binding to nominalExpressionType(queryLinkId.use(), false)),
                    nominalExpressionType(ScalarKind.TEXT.use, true),
                    queryTypeId,
                ) as Resolution.Ready
            ).value
        val record =
            AuthoringRecord(
                TypeSelection.Complete(queryTypeId.namedUse()),
                mapOf(
                    "name" to DataValue.StringValue("Root name"),
                    "extra" to DataValue.Unfilled,
                ),
            )
        val referenceValue =
            DataValue.Link(
                EndpointId(value = "query.endpoint"),
                LinkTarget(ResourceId("result"), ValuePath(listOf(PathSegment.Field("reverse")))),
            )
        with(QueryReads) {
            DefaultExpressionEvaluator(
                ExpressionValueReader { error("Unexpected authored value read") },
                queries =
                    QueryObservation(
                        mapOf(ResourceId("result") to record),
                    ),
            ).evaluateChecked(program, ExpressionBindings(emptyMap()), EvaluationBudget(100, 100), mapOf(binding to referenceValue))
        } shouldBe Availability.Available(DataValue.StringValue("Root name"))
    }

    test("a full resource projection respects the shared evaluation budget") {
        val resource =
            RuntimePresentationQueries(mapOf(QueryResource::class to queryTypeId.namedTemplate()))
                .resource(literal(ResourceId("result")), QueryResource::class)
        val record =
            AuthoringRecord(
                TypeSelection.Complete(queryTypeId.namedUse()),
                mapOf(
                    "name" to DataValue.StringValue("Name"),
                    "extra" to DataValue.Unfilled,
                ),
            )
        with(QueryReads) {
            DefaultExpressionEvaluator(
                ExpressionValueReader { error("Unexpected authored value read") },
                queries =
                    QueryObservation(
                        mapOf(ResourceId("result") to record),
                    ),
            ).evaluateChecked(
                queryProgram(resource.value.toNode(), queryTypeId.use()),
                ExpressionBindings(emptyMap()),
                EvaluationBudget(3, 100),
            )
        }.shouldBeInstanceOf<Availability.Failed>()
    }
    test("identical query syntax retains each collection binder target contract") {
        val first = ExpressionBindingId("first")
        val second = ExpressionBindingId("second")

        fun read(binding: ExpressionBindingId) = testInput(binding)
        val query =
            ExpressionNode.QueryWrapper(
                ExpressionQuery.ResourceIdentityWrapper(
                    ResourceQuerySource.ReferenceWrapper(
                        ExpressionNode.createLocal(
                            depth = 0,
                            slot = 0,
                            path =
                                skirout.editor.v1.type_catalog
                                    .ValuePath(segments = emptyList()),
                        ),
                    ),
                ),
            )
        val predicate = ExpressionNode.BooleanNotWrapper(ExpressionNode.IsNullWrapper(query))

        fun any(binding: ExpressionBindingId) = ExpressionNode.createAny(source = read(binding), body = predicate)
        val body = ExpressionNode.createAnd(left = any(first), right = any(second))
        val program =
            (
                PortableExpressionChecker(queryCatalog::resolve).checkProgram(
                    body,
                    mapOf(
                        first to nominalExpressionType(StandardTypes.list.use(listOf(queryLinkId.use())), false),
                        second to nominalExpressionType(StandardTypes.list.use(listOf(otherQueryLinkId.use())), false),
                    ),
                    nominalExpressionType(ScalarKind.BOOLEAN.use, true),
                    queryTypeId,
                ) as Resolution.Ready
            ).value
        program.queries.values
            .map { it.targetType }
            .toSet() shouldBe setOf(queryTypeId.use(), otherQueryTypeId.use())

        fun links(target: String) =
            DataValue.ListValue(
                listOf(
                    ListItem(
                        ItemId(target),
                        DataValue.Link(EndpointId(value = "query.endpoint"), LinkTarget(ResourceId(target), null)),
                    ),
                ),
            )
        val records =
            mapOf(
                ResourceId("first") to
                    AuthoringRecord(
                        TypeSelection.Complete(queryTypeId.namedUse()),
                        mapOf(
                            "name" to DataValue.Unfilled,
                            "extra" to DataValue.Unfilled,
                        ),
                    ),
                ResourceId("second") to AuthoringRecord(TypeSelection.Complete(otherQueryTypeId.namedUse()), emptyMap()),
            )
        with(QueryReads) {
            DefaultExpressionEvaluator(
                ExpressionValueReader { error("Unexpected authored value read") },
                queries = QueryObservation(records),
            ).evaluateChecked(
                program,
                ExpressionBindings(emptyMap()),
                EvaluationBudget(200, 100),
                mapOf(
                    first to links("first"),
                    second to links("second"),
                ),
            )
        } shouldBe Availability.Available(DataValue.Boolean(true))
    }
}

private class QueryResource : Resource

private interface QueryEndpoint : RelationshipEndpoint<QueryResource, QueryResource>

private val queryTypeId = TypeDefinitionId.qualified("query.test", "Resource")
private val queryLinkId = TypeDefinitionId.qualified("query.test", "Reference")
private val otherQueryTypeId = TypeDefinitionId.qualified("query.test", "OtherResource")
private val otherQueryLinkId = TypeDefinitionId.qualified("query.test", "OtherReference")
private val queryDefinition =
    TypeDefinition.partial(
        id = queryTypeId,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf("name", "extra").map {
                        FieldDeclaration.partial(owner = FieldOwner(definition = queryTypeId, name = it), type = ScalarKind.TEXT.template)
                    },
                abstract_ = false,
            ),
    )
private val queryCatalog =
    DefaultCheckedCatalog(
        QueryReads.catalog,
        StandardTypes.definitions +
            listOf(
                TypeDefinition.partial(
                    id = otherQueryTypeId,
                    representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                ),
                TypeDefinition.partial(
                    id = otherQueryLinkId,
                    representation =
                        RepresentationTemplate.createLink(
                            endpoint = EndpointId(value = "query.endpoint"),
                            target = otherQueryTypeId.template(),
                        ),
                ),
                queryDefinition,
                ResourceIdDefinition.declaration,
                ColorDefinition.declaration,
                TypeDefinition.partial(
                    id = queryLinkId,
                    representation =
                        RepresentationTemplate.createLink(
                            endpoint = EndpointId(value = "query.endpoint"),
                            target = queryTypeId.template(),
                        ),
                ),
            ),
    )

private fun queryProgram(
    body: ExpressionNode,
    output: TypeUse,
): CheckedExpressionProgram =
    (
        PortableExpressionChecker(
            queryCatalog::resolve,
        ).checkProgram(body, emptyMap(), nominalExpressionType(output, true), queryTypeId) as Resolution.Ready
    ).value

private class QueryObservation(
    private val records: Map<ResourceId, AuthoringRecord>,
    private val color: Color = Color(0xFF123456u),
) : CanonicalQueryReader {
    override val catalog: CheckedCatalog = queryCatalog
    var seenReadContext: ReadContext? = null

    context(reads: AuthoredReads)
    override fun resource(id: ResourceId): Availability<AuthoringRecord> {
        seenReadContext = reads.readContext
        return records[id]?.let { Availability.Available(it) } ?: Availability.Unavailable(listOf(ValueLocation(id, ValuePath())))
    }

    context(reads: AuthoredReads)
    override fun declaration(id: TypeDefinitionId): Availability<PublishedType> =
        Availability.Available(
            PublishedType.partial(
                definition = queryDefinition,
                status = DeclarationStatus.READY,
                display = TypeDisplay("Resource", "Description", Icon.Iconify("lucide:box"), color).toWire(),
            ),
        )
}

private object QueryReads : AuthoredReads {
    override val catalog = CatalogGeneration("canonical.query.test")
    override val readContext = ReadContext(catalog)

    override fun <T> read(path: BoundPath<T>): Availability<T> = error("Unexpected typed read")

    override fun <T> readRepresentation(
        path: BoundPath<*>,
        representation: TypeUse,
    ): Availability<T> = error("Unexpected representation read")

    override fun presence(path: BoundPath<*>): Availability<Boolean> = error("Unexpected presence read")

    override fun binding(path: BoundPath<*>): Availability<DraftBinding> = error("Unexpected draft read")

    override fun canonicalValueKey(path: BoundPath<*>): Availability<String> = error("Unexpected canonical key read")

    override fun members(path: BoundCollectionPath): List<ItemId> = emptyList()

    override fun <D> select(query: TypedSelection<D>): PartialSelection<D> = error("Unexpected selection read")
}
