package com.typewritermc.presentation

import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.library.coreTagCollectionProjection
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.ListItem
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode

val DefaultPresentationRuntimeTest by testSuite {
    test("surface policies serialize through ordinary presentation nodes") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("surface policies"), StandardTypes.definitions)
        val checked = catalog.ready(TypeUse.Scalar(ScalarKind.Text))
        val accent = literalColor(com.typewritermc.types.Color(0x803366ccu))
        val fill =
            stateColor(accent.withAlpha(0.2)) {
                whenAll(PresentationInteractionState.Selected, color = accent)
                whenAll(PresentationInteractionState.Hovered, color = accent.withAlpha(0.5))
            }
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                build.container(
                    ContainerStyle(
                        background = fill,
                        foreground = ambientBackground().on(),
                        radius = PresentationRadius.Large,
                        transitionMilliseconds = 100,
                    ),
                ) {
                    align(PresentationAlignment.Center) { text(literal("Adventure")) }
                }
            }
        val container = (result.layout.singleFixed().element as PresentationElement.ContainerWrapper).value
        val states = (container.backgroundColor as skirout.editor.v1.presentation.PresentationColor.StatesWrapper).value
        states.rules.map { it.match.required } shouldBe
            listOf(
                listOf(skirout.editor.v1.presentation.PresentationInteractionState.SELECTED),
                listOf(skirout.editor.v1.presentation.PresentationInteractionState.HOVERED),
            )
        (states.fallback as skirout.editor.v1.presentation.PresentationColor.AlphaWrapper).value.alpha shouldBe 0.2
        val contrast = (container.foregroundColor as skirout.editor.v1.presentation.PresentationColor.ContrastWrapper).value
        contrast.source shouldBe
            skirout.editor.v1.presentation.PresentationColor.AmbientWrapper(
                skirout.editor.v1.presentation.PresentationAmbientColor.BACKGROUND,
            )
        container.transitionMilliseconds shouldBe 100
        val alignment = (container.child.singleFixed().element as PresentationElement.AlignWrapper).value
        alignment.alignment shouldBe skirout.editor.v1.presentation.PresentationAlignment.CENTER
    }

    test("resource headings compose ordinary nodes with identity and pane context") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("headings"), StandardTypes.definitions)
        val checked = catalog.ready(TypeUse.Scalar(ScalarKind.Text))
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                with(build) {
                    resourceHeading(literal("A title"), literal(com.typewritermc.types.Color(0xff123456u)), subject.identifier)
                }
            }
        val conditional = result.layout.singleFixed().element as PresentationElement.ConditionalWrapper
        val condition = conditional.value.condition as skirout.editor.v1.expression.ExpressionNode.CallWrapper
        condition.value.operation.value shouldBe "typewriter.value.eq"
        val count = condition.value.arguments.first() as skirout.editor.v1.expression.ExpressionNode.OrElseWrapper
        (count.value.input as skirout.editor.v1.expression.ExpressionNode.ReadWrapper).value.binding.value shouldBe
            "presentation.context.selection_count"
        val paragraphs =
            conditional.value.whenTrue
                .singleFixed()
                .fixedChildren()
        val title = (paragraphs.first().element as PresentationElement.TextWrapper).value
        val fit = title.sizing as skirout.editor.v1.presentation.TextSizing.FitWrapper
        com.typewritermc.types.skir.SkirDataValueCodec
            .decode(
                (fit.value.minimum as skirout.editor.v1.expression.ExpressionNode.LiteralWrapper).value,
            ).getOrThrow() shouldBe
            DataValue.Float(18.0)
        com.typewritermc.types.skir.SkirDataValueCodec
            .decode(
                (fit.value.maximum as skirout.editor.v1.expression.ExpressionNode.LiteralWrapper).value,
            ).getOrThrow() shouldBe
            DataValue.Float(40.0)
        title.paragraph.maxLines shouldBe 1
        title.paragraph.selectable shouldBe true
        title.paragraph.overflow shouldBe skirout.editor.v1.presentation.PresentationTextOverflow.ELLIPSIS
        val identity = paragraphs.last().element as PresentationElement.ConditionalWrapper
        val idText =
            (
                identity.value.whenTrue
                    .singleFixed()
                    .element as PresentationElement.TextWrapper
            ).value
        idText.paragraph.selectable shouldBe true
        idText.paragraph.softWrap shouldBe true
        val identifier = idText.value as skirout.editor.v1.expression.ExpressionNode.OrElseWrapper
        (identifier.value.input as skirout.editor.v1.expression.ExpressionNode.ReadWrapper).value.binding.value shouldBe
            "presentation.subject.identifier"
    }

    test("rich paragraphs serialize sizing and paragraph behavior") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("rich sizing"), StandardTypes.definitions)
        val checked = catalog.ready(TypeUse.Scalar(ScalarKind.Text))
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                build.richText {
                    sizing(TextSizing.Fit(literal(18.0), literal(40.0)))
                    paragraph(TextParagraph(maximumLines = 2, softWrap = true, selectable = true, tone = TextTone.Secondary))
                    style(TextStyleOverride(color = literal(com.typewritermc.types.Color(0xff123456u)).asPresentationColor(), weight = 500))
                    run(literal("First"))
                    run(literal("Second"), TextStyleOverride(weight = 700))
                }
            }
        val text = (result.layout.singleFixed().element as PresentationElement.RichTextWrapper).value
        (text.sizing is skirout.editor.v1.presentation.TextSizing.FitWrapper) shouldBe true
        text.paragraph.maxLines shouldBe 2
        text.paragraph.softWrap shouldBe true
        text.paragraph.selectable shouldBe true
        text.paragraph.tone shouldBe skirout.editor.v1.presentation.PresentationTextTone.SECONDARY
        text.runs.size shouldBe 2
        (text.style?.color != null) shouldBe true
        val restored =
            skirout.editor.v1.presentation.RichTextContent.serializer.fromBytes(
                skirout.editor.v1.presentation.RichTextContent.serializer
                    .toBytes(text),
            )
        restored shouldBe text
    }

    test("builds one symbolic generic material and applies it to concrete uses") {
        val id = TypeDefinitionId(TypeId.Qualified("test", "Weighted"), 1)
        val parameter = ParameterKey(id, 0)
        val definition =
            TypeDefinition(
                id = id,
                parameters = listOf(TypeParameter(parameter, "T")),
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(FieldOwner(id, "value"), TypeTemplate.Parameter(parameter)),
                            FieldDeclaration(
                                FieldOwner(id, "weight"),
                                TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                            ),
                        ),
                    ),
            )
        val target = PresentationTarget.Named(TypeTemplate.Named(id, listOf(TypeTemplate.Parameter(parameter))))
        val descriptor = descriptor("weighted", target, 0, PresentationRole.INSPECTOR)
        val origin = ProviderOrigin(descriptor.owner, ArtifactId("test:presentation"), "main")
        val runtime = DefaultPresentationRuntime()
        val provider =
            object : PresentationProvider {
                override fun build(binding: PresentationBuildBinding): PresentationBuildResult =
                    runtime.build(binding) { build ->
                        with(build) {
                            val value: PresentedField<Any?, Control> = field("value", Control::class)
                            typedField(value.input) { }
                            val weight: PresentedField<Int, NumberControl<Int>> =
                                field("weight", NumberControl::class as kotlin.reflect.KClass<NumberControl<Int>>)
                            weight { numericInput() }
                        }
                    }
            }
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, definition)),
                presentations = listOf(OwnedPresentation(origin, descriptor, provider)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration("symbolic presentation")))

        val material = assembly.snapshot.presentationMaterials.single()
        material.target shouldBe target
        val valueNode =
            material.layout
                .fixedChildren()
                .first()
                .element as PresentationElement.TypedFieldWrapper
        val expected = SkirTypeCodec.decode(valueNode.value.expectedType).getOrThrow()
        expected shouldBe TypeTemplate.Parameter(parameter)

        val text = mapOf(parameter to TypeUse.Scalar(ScalarKind.Text))
        val integer = mapOf(parameter to TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)))
        (target.type.apply(text) as Resolution.Ready).value shouldBe TypeUse.Named(id, listOf(TypeUse.Scalar(ScalarKind.Text)))
        (target.type.apply(integer) as Resolution.Ready).value shouldBe
            TypeUse.Named(id, listOf(TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32))))
        (expected.apply(text) as Resolution.Ready).value shouldBe TypeUse.Scalar(ScalarKind.Text)
        (expected.apply(integer) as Resolution.Ready).value shouldBe
            TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32))
    }

    test("isolates a named presentation with an invalid collection projection") {
        val subjectId = TypeDefinitionId(TypeId.Qualified("test", "InvalidCollectionSubject"), 1)
        val unrelatedId = TypeDefinitionId(TypeId.Qualified("test", "UnrelatedCollectionSubject"), 1)
        val subject =
            TypeDefinition(
                subjectId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(
                                FieldOwner(subjectId, "title"),
                                TypeTemplate.Scalar(ScalarKind.Text),
                            ),
                        ),
                    ),
            )
        val unrelated = TypeDefinition(unrelatedId, representation = RepresentationTemplate.Record(emptyList()))
        val target = PresentationTarget.Named(TypeTemplate.Named(subjectId))
        val descriptor = descriptor("invalid collection", target, 0, PresentationRole.INSPECTOR)
        val origin = ProviderOrigin(descriptor.owner, ArtifactId("test:invalid-collection"), "main")
        val projection =
            CollectionProjection<ProjectionFixtureResource, Int, ProjectionFixtureExpressions>(
                specification =
                    CollectionProjectionSpec(
                        sourceId = "invalid",
                        root = TypeTemplate.Named(subjectId),
                        rowType = TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                        fields =
                            listOf(
                                CollectionProjectionFieldSpec(
                                    target = ValuePath(),
                                    source =
                                        CollectionProjectionValueSpec.Content(
                                            ValuePath(listOf(PathSegment.Field("title"))),
                                        ),
                                ),
                            ),
                    ),
                expressions = ProjectionFixtureExpressionsFactory,
            )
        val runtime = DefaultPresentationRuntime()
        val provider =
            object : PresentationProvider {
                override fun build(binding: PresentationBuildBinding): PresentationBuildResult =
                    runtime.build(binding) { build ->
                        with(build) {
                            val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                            val invalid = projection.projectedCollectionSource(key = { literal("key") })
                            collectionLookup(invalid, title.input) {
                                found { text(literal("found")) }
                                missing { text(literal("missing")) }
                            }
                        }
                    }
            }

        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, subject), OwnedTypeDeclaration(origin, unrelated)),
                presentations = listOf(OwnedPresentation(origin, descriptor, provider)),
            ).assemble(
                CatalogAssemblyContext(
                    CatalogGeneration("invalid presentation collection"),
                    resources = listOf(AuthoringResourceDefinition(ResourceDefinitionId("test.invalid"), subjectId)),
                ),
            )

        val status =
            assembly.snapshot.types
                .single { it.definition.id == subjectId }
                .status as DeclarationStatus.Unavailable
        status.reasons.map { it.code } shouldBe listOf("invalid_presentation_collection_dependency")
        assembly.snapshot.types
            .single { it.definition.id == unrelatedId }
            .status shouldBe DeclarationStatus.Ready
        assembly.snapshot.presentationMaterials shouldBe emptyList()
    }

    test("admits readable projection mappings from declared resource roots") {
        val baseId = TypeDefinitionId(TypeId.Qualified("test", "ProjectionBase"), 1)
        val childId = TypeDefinitionId(TypeId.Qualified("test", "ProjectionChild"), 1)
        val resourceId = TypeDefinitionId(TypeId.Qualified("test", "ProjectionResource"), 1)
        val base =
            TypeDefinition(
                baseId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(FieldOwner(baseId, "title"), TypeTemplate.Scalar(ScalarKind.Text))),
                    ),
            )
        val child =
            TypeDefinition(
                childId,
                representation = RepresentationTemplate.Record(emptyList()),
                parents = listOf(TypeTemplate.Named(baseId)),
            )
        val resource =
            TypeDefinition(
                resourceId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(FieldOwner(resourceId, "child"), TypeTemplate.Named(childId)),
                            FieldDeclaration(FieldOwner(resourceId, "selected"), TypeTemplate.Scalar(ScalarKind.Text)),
                        ),
                    ),
            )
        val target = PresentationTarget.Named(TypeTemplate.Named(resourceId))
        val descriptor = descriptor("valid collection", target, 0, PresentationRole.INSPECTOR)
        val origin = ProviderOrigin(descriptor.owner, ArtifactId("test:valid-collection"), "main")
        val projection =
            CollectionProjection<ProjectionFixtureResource, Any, ProjectionFixtureExpressions>(
                specification =
                    CollectionProjectionSpec(
                        sourceId = "valid",
                        root = TypeTemplate.Named(resourceId),
                        rowType = TypeTemplate.Named(baseId),
                        fields =
                            listOf(
                                CollectionProjectionFieldSpec(
                                    target = ValuePath(),
                                    source =
                                        CollectionProjectionValueSpec.Content(
                                            ValuePath(listOf(PathSegment.Field("child"))),
                                        ),
                                ),
                            ),
                    ),
                expressions = ProjectionFixtureExpressionsFactory,
            )
        val runtime = DefaultPresentationRuntime()
        val provider =
            object : PresentationProvider {
                override fun build(binding: PresentationBuildBinding): PresentationBuildResult =
                    runtime.build(binding) { build ->
                        with(build) {
                            val selected: PresentedField<String, TextControl> = field("selected", TextControl::class)
                            val source = projection.projectedCollectionSource(key = { literal("key") })
                            collectionLookup(source, selected.input) {
                                found { text(literal("found")) }
                                missing { text(literal("missing")) }
                            }
                        }
                    }
            }

        val assembly =
            CatalogContributions(
                declarations =
                    listOf(base, child, resource).map { definition -> OwnedTypeDeclaration(origin, definition) },
                presentations = listOf(OwnedPresentation(origin, descriptor, provider)),
            ).assemble(
                CatalogAssemblyContext(
                    CatalogGeneration("valid presentation collection"),
                    resources = listOf(AuthoringResourceDefinition(ResourceDefinitionId("test.projection"), resourceId)),
                ),
            )

        assembly.snapshot.types
            .single { it.definition.id == resourceId }
            .status shouldBe DeclarationStatus.Ready
        assembly.snapshot.presentationMaterials
            .single()
            .dependencies.collections
            .single()
            .sourceId shouldBe "valid"
    }

    test("isolates collections with missing resources invalid bounds or invalid literals") {
        val missingId = TypeDefinitionId(TypeId.Qualified("test", "MissingResourceCollection"), 1)
        val literalId = TypeDefinitionId(TypeId.Qualified("test", "InvalidLiteralCollection"), 1)
        val boundedId = TypeDefinitionId(TypeId.Qualified("test", "InvalidBoundCollection"), 1)
        val unrelatedId = TypeDefinitionId(TypeId.Qualified("test", "ValidUnrelatedCollection"), 1)
        val baseId = TypeDefinitionId(TypeId.Qualified("test", "CollectionBound"), 1)
        val genericId = TypeDefinitionId(TypeId.Qualified("test", "BoundedCollectionRow"), 1)
        val parameter = ParameterKey(genericId, 0)
        val selected = TypeTemplate.Scalar(ScalarKind.Text)

        fun subject(id: TypeDefinitionId): TypeDefinition =
            TypeDefinition(
                id,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(FieldOwner(id, "title"), TypeTemplate.Scalar(ScalarKind.Text)),
                            FieldDeclaration(FieldOwner(id, "selected"), selected),
                        ),
                    ),
            )

        val base = TypeDefinition(baseId, representation = RepresentationTemplate.Record(emptyList()))
        val generic =
            TypeDefinition(
                genericId,
                parameters = listOf(TypeParameter(parameter, "T", bounds = listOf(TypeTemplate.Named(baseId)))),
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(FieldOwner(genericId, "value"), TypeTemplate.Parameter(parameter))),
                    ),
            )
        val projections =
            mapOf(
                missingId to
                    CollectionProjectionSpec(
                        sourceId = "missing-resource",
                        root = TypeTemplate.Named(missingId),
                        rowType = TypeTemplate.Scalar(ScalarKind.Text),
                        fields =
                            listOf(
                                CollectionProjectionFieldSpec(
                                    ValuePath(),
                                    CollectionProjectionValueSpec.Content(
                                        ValuePath(listOf(PathSegment.Field("title"))),
                                    ),
                                ),
                            ),
                    ),
                literalId to
                    CollectionProjectionSpec(
                        sourceId = "invalid-literal",
                        root = TypeTemplate.Named(literalId),
                        rowType = TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                        fields =
                            listOf(
                                CollectionProjectionFieldSpec(
                                    ValuePath(),
                                    CollectionProjectionValueSpec.Literal(DataValue.StringValue("wrong")),
                                ),
                            ),
                    ),
                boundedId to
                    CollectionProjectionSpec(
                        sourceId = "invalid-bound",
                        root = TypeTemplate.Named(boundedId),
                        rowType =
                            TypeTemplate.Named(
                                genericId,
                                listOf(TypeTemplate.Scalar(ScalarKind.Text)),
                            ),
                        fields =
                            listOf(
                                CollectionProjectionFieldSpec(
                                    ValuePath(listOf(PathSegment.Field("value"))),
                                    CollectionProjectionValueSpec.Literal(DataValue.StringValue("value")),
                                ),
                            ),
                    ),
            )
        val origin =
            ProviderOrigin(
                DeclarationOwner(
                    ContributionKey(
                        ContributionSourceId("test"),
                        "main",
                        ProducerId("test"),
                        ContributionName("invalid_collections"),
                    ),
                    "invalid-collections",
                ),
                ArtifactId("test:invalid-collections"),
                "main",
            )
        val runtime = DefaultPresentationRuntime()
        val ownedPresentations =
            projections.map { (id, specification) ->
                val target = PresentationTarget.Named(TypeTemplate.Named(id))
                val descriptor = descriptor(specification.sourceId, target, 0, PresentationRole.INSPECTOR)
                val projection =
                    CollectionProjection<ProjectionFixtureResource, Any, ProjectionFixtureExpressions>(
                        specification,
                        ProjectionFixtureExpressionsFactory,
                    )
                val provider =
                    object : PresentationProvider {
                        override fun build(binding: PresentationBuildBinding): PresentationBuildResult =
                            runtime.build(binding) { build ->
                                with(build) {
                                    val selectedField: PresentedField<String, TextControl> =
                                        field("selected", TextControl::class)
                                    val source = projection.projectedCollectionSource(key = { literal("key") })
                                    collectionLookup(source, selectedField.input) {
                                        found { text(literal("found")) }
                                        missing { text(literal("missing")) }
                                    }
                                }
                            }
                    }
                OwnedPresentation(origin, descriptor, provider)
            }
        val definitions = projections.keys.map(::subject) + listOf(base, generic, subject(unrelatedId))

        val assembly =
            CatalogContributions(
                declarations = definitions.map { definition -> OwnedTypeDeclaration(origin, definition) },
                presentations = ownedPresentations,
            ).assemble(
                CatalogAssemblyContext(
                    CatalogGeneration("invalid collection admission"),
                    resources =
                        listOf(
                            AuthoringResourceDefinition(ResourceDefinitionId("test.literal"), literalId),
                            AuthoringResourceDefinition(ResourceDefinitionId("test.bound"), boundedId),
                        ),
                ),
            )

        projections.keys.forEach { id ->
            val status =
                assembly.snapshot.types
                    .single { it.definition.id == id }
                    .status as DeclarationStatus.Unavailable
            status.reasons.map { it.code } shouldBe listOf("invalid_presentation_collection_dependency")
        }
        assembly.snapshot.types
            .single { it.definition.id == unrelatedId }
            .status shouldBe DeclarationStatus.Ready
        assembly.snapshot.presentationMaterials shouldBe emptyList()
    }

    test("resolves one presentation reference by its checked binding without mutating rejected registrations") {
        val reference = object : PresentationReference {}
        val catalog = DefaultCheckedCatalog(CatalogGeneration("reference targets"), StandardTypes.definitions)
        val text = descriptor("text reference", PresentationTarget.Representation(RepresentationKind.Text), 0)
        val boolean = descriptor("boolean reference", PresentationTarget.Representation(RepresentationKind.Boolean), 0)
        val first = DefaultPresentationRuntime()
        val second = DefaultPresentationRuntime()

        first.register(reference, text)
        first.register(reference, boolean)
        first.register(reference, text)

        runCatching {
            first.register(reference, text.copy(target = PresentationTarget.Representation(RepresentationKind.Integer)))
        }.isFailure shouldBe true

        fun selected(
            runtime: DefaultPresentationRuntime,
            kind: ScalarKind,
        ): String =
            runtime
                .build(PresentationBuildBinding(catalog.ready(TypeUse.Scalar(kind)).presentationTemplate(), PresentationRole.EDITOR)) {
                    it.invoke(reference) {}
                }.dependencies.presentations
                .single()
                .name

        selected(first, ScalarKind.Text) shouldBe text.id.name
        selected(first, ScalarKind.Boolean) shouldBe boolean.id.name
        runCatching { selected(second, ScalarKind.Text) }.isFailure shouldBe true
    }

    test("builds scalar field controls and remaining field exclusions") {
        val id = TypeDefinitionId(TypeId.Qualified("test", "PresentationSubject"), 1)
        val definition =
            TypeDefinition(
                id,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(
                                FieldOwner(id, "title"),
                                TypeTemplate.Scalar(ScalarKind.Text),
                            ),
                        ),
                        abstract = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("presentation runtime"), listOf(definition))
        val checked = (catalog.resolve(TypeUse.Named(id)) as Resolution.Ready).value
        val runtime = DefaultPresentationRuntime()
        val root =
            runtime.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.EDITOR)) { build ->
                with(build) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    title {
                        label("Title")
                        textInput()
                    }
                    remainingFields {
                        exclude(title)
                    }
                }
            }
        val column = (root.layout.element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
        val fieldNode = (column.value.children[0] as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value
        val remainingNode = (column.value.children[1] as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value
        val field = fieldNode.element as PresentationElement.TextInputWrapper
        val remaining = remainingNode.element as PresentationElement.RemainingFieldsWrapper
        field.value.control.binding.path.segments.size shouldBe 1
        (field.value.control.label != null) shouldBe true
        remaining.value.excluded.size shouldBe 1
    }

    test("dispatches value class mangled link controls") {
        val resourceId = TypeDefinitionId(TypeId.Qualified("test", "LinkTargetResource"), 1)
        val linkId = TypeDefinitionId(TypeId.Qualified("test", "LinkValue"), 1)
        val subjectId = TypeDefinitionId(TypeId.Qualified("test", "LinkControlSubject"), 1)
        val linkType = TypeTemplate.Named(linkId)
        val definitions =
            StandardTypes.definitions +
                TypeDefinition(resourceId, representation = RepresentationTemplate.Record(emptyList())) +
                TypeDefinition(
                    linkId,
                    representation =
                        RepresentationTemplate.Link(
                            com.typewritermc.types.EndpointId("test:link"),
                            TypeTemplate.Named(resourceId),
                        ),
                ) +
                TypeDefinition(
                    subjectId,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(
                                FieldDeclaration(FieldOwner(subjectId, "link"), linkType),
                                FieldDeclaration(
                                    FieldOwner(subjectId, "links"),
                                    TypeTemplate.Named(StandardTypes.set, listOf(linkType)),
                                ),
                            ),
                        ),
                )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("mangled link controls"), definitions)
        val checked = catalog.ready(TypeUse.Named(subjectId))
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                with(build) {
                    @Suppress("UNCHECKED_CAST")
                    val link: PresentedField<Any, LinkControl<ProjectionFixtureResource>> =
                        field(
                            "link",
                            LinkControl::class as kotlin.reflect.KClass<LinkControl<ProjectionFixtureResource>>,
                        )

                    @Suppress("UNCHECKED_CAST")
                    val links: PresentedField<Set<Any>, LinkCollectionControl<ProjectionFixtureResource>> =
                        field(
                            "links",
                            LinkCollectionControl::class as
                                kotlin.reflect.KClass<LinkCollectionControl<ProjectionFixtureResource>>,
                        )

                    link { linkInput(policy = LinkCandidatePolicyId("single")) }
                    links {
                        linkInput(
                            allowReorder = true,
                            policy = LinkCandidatePolicyId("many"),
                        )
                    }
                }
            }

        val elements = result.layout.fixedChildren().map(PresentationNode::element)
        val link = elements[0] as PresentationElement.LinkInputWrapper
        val links = elements[1] as PresentationElement.LinkInputWrapper
        link.value.candidatePolicy?.value shouldBe "single"
        link.value.allowReorder shouldBe false
        links.value.candidatePolicy?.value shouldBe "many"
        links.value.allowReorder shouldBe true
    }

    test("preserves layout kinds and control options") {
        val id = TypeDefinitionId(TypeId.Qualified("test", "PresentationInventory"), 1)
        val definition =
            TypeDefinition(
                id,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(FieldOwner(id, "title"), TypeTemplate.Scalar(ScalarKind.Text)),
                            FieldDeclaration(
                                FieldOwner(id, "amount"),
                                TypeTemplate.Scalar(
                                    com.typewritermc.types.ScalarKind
                                        .Integer(com.typewritermc.types.IntegerWidth.SIGNED_32),
                                ),
                            ),
                        ),
                    ),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("presentation inventory"), listOf(definition))
        val checked = (catalog.resolve(TypeUse.Named(id)) as Resolution.Ready).value
        val root =
            DefaultPresentationRuntime().build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.EDITOR)) { build ->
                with(build) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)

                    @Suppress("UNCHECKED_CAST")
                    val amount: PresentedField<Int, NumberControl<Int>> =
                        field("amount", NumberControl::class as kotlin.reflect.KClass<NumberControl<Int>>)
                    row(4.0, MainAxisAlignment.SpaceBetween, CrossAxisAlignment.Stretch) {
                        fixed {
                            title {
                                icon("book")
                                textInput(formatters = listOf(TextInputFormat.Trim, TextInputFormat.Pattern("[a-z]+")))
                            }
                        }
                        flexible(2, FlexFit.Tight) {
                            amount { sliderInput(0, 10, 5) }
                        }
                    }
                    wrap(2.0, 3.0) { divider() }
                    grid(2, 4.0, 5.0) { divider() }
                    stack { divider() }
                    section(PresentationBorder(1.0, literalColor(com.typewritermc.types.Color(0xff3366ccu)))) { divider() }
                    padding(PresentationInsets(1.0, 2.0, 3.0, 4.0)) { divider() }
                    container(
                        ContainerStyle(
                            background =
                                literal(
                                    com.typewritermc.types.Color
                                        .parseRgb("#3366CC"),
                                ).asPresentationColor(),
                        ),
                    ) { divider() }
                    tooltip(literal("help")) { divider() }
                    title {
                        selectInput(
                            listOf(SelectOption("one", literal("One"), literal("one"))),
                            allowCustomValue = true,
                        )
                    }
                }
            }

        val rootColumn = (root.layout.element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
        val elements = rootColumn.value.children.map { (it as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value.element }
        val row = (elements[0] as PresentationElement.ChildrenWrapper).value as ChildrenElement.RowWrapper
        row.value.layout.spacing shouldBe 4.0
        row.value.children[1].kind shouldBe skirout.editor.v1.presentation.AxisChild.Kind.FLEXIBLE_WRAPPER
        val first = (row.value.children[0] as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value
        val firstColumn = (first.element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
        val text =
            (
                (firstColumn.value.children.single() as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value.element
                    as PresentationElement.TextInputWrapper
            ).value
        text.inputFormatters.size shouldBe 2
        (text.control.prefix?.element is PresentationElement.IconWrapper) shouldBe true
        ((elements[1] as PresentationElement.ChildrenWrapper).value is ChildrenElement.WrapWrapper) shouldBe true
        ((elements[2] as PresentationElement.ChildrenWrapper).value is ChildrenElement.GridWrapper) shouldBe true
        ((elements[3] as PresentationElement.ChildrenWrapper).value is ChildrenElement.StackWrapper) shouldBe true
        (elements[4] is PresentationElement.SectionWrapper) shouldBe true
        (elements[5] is PresentationElement.PaddingWrapper) shouldBe true
        (elements[6] is PresentationElement.ContainerWrapper) shouldBe true
        (elements[7] is PresentationElement.TooltipWrapper) shouldBe true
        val select = elements[8] as PresentationElement.SelectInputWrapper
        select.value.options
            .single()
            .optionId shouldBe "one"
        select.value.allowCustomValue shouldBe true
    }

    test("binds composite callbacks to their nested schema and lexical values") {
        val wrapperId = TypeDefinitionId(TypeId.Qualified("test", "Code"), 1)
        val positionId = TypeDefinitionId(TypeId.Qualified("test", "Position"), 1)
        val subjectId = TypeDefinitionId(TypeId.Qualified("test", "CompositeSubject"), 1)
        val integer = ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_32)
        val position =
            TypeDefinition(
                positionId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(FieldOwner(positionId, "x"), TypeTemplate.Scalar(integer)),
                            FieldDeclaration(FieldOwner(positionId, "y"), TypeTemplate.Scalar(integer)),
                        ),
                    ),
            )
        val wrapper = TypeDefinition(wrapperId, representation = RepresentationTemplate.Scalar(ScalarKind.Text))
        val subject =
            TypeDefinition(
                subjectId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(
                                FieldOwner(subjectId, "list"),
                                TypeTemplate.Named(StandardTypes.list, listOf(TypeTemplate.Scalar(ScalarKind.Text))),
                            ),
                            FieldDeclaration(
                                FieldOwner(subjectId, "set"),
                                TypeTemplate.Named(StandardTypes.set, listOf(TypeTemplate.Scalar(ScalarKind.Text))),
                            ),
                            FieldDeclaration(
                                FieldOwner(subjectId, "map"),
                                TypeTemplate.Named(
                                    StandardTypes.map,
                                    listOf(
                                        TypeTemplate.Scalar(ScalarKind.Text),
                                        TypeTemplate.Nullable(TypeTemplate.Scalar(integer)),
                                    ),
                                ),
                            ),
                            FieldDeclaration(
                                FieldOwner(subjectId, "code"),
                                TypeTemplate.Named(wrapperId),
                            ),
                            FieldDeclaration(
                                FieldOwner(subjectId, "position"),
                                TypeTemplate.Named(positionId),
                            ),
                        ),
                    ),
            )
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration("nested presentation callbacks"),
                StandardTypes.definitions + wrapper + position + subject,
            )
        val checked = catalog.ready(TypeUse.Named(subjectId))
        val root =
            DefaultPresentationRuntime().build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.EDITOR)) { build ->
                with(build) {
                    @Suppress("UNCHECKED_CAST")
                    val list: PresentedField<List<String>, ListControl<TextControl>> =
                        field(
                            "list",
                            ListControl::class as kotlin.reflect.KClass<ListControl<TextControl>>,
                            mapOf(NestedPresentationSlot.Items to NestedPresentationScope(TextControl::class)),
                        )

                    @Suppress("UNCHECKED_CAST")
                    val set: PresentedField<Set<String>, SetControl<TextControl>> =
                        field(
                            "set",
                            SetControl::class as kotlin.reflect.KClass<SetControl<TextControl>>,
                            mapOf(NestedPresentationSlot.Items to NestedPresentationScope(TextControl::class)),
                        )

                    @Suppress("UNCHECKED_CAST")
                    val map: PresentedField<Map<String, Int?>, MapControl<TextControl, NullableControl<NumberControl<Int>>>> =
                        field(
                            "map",
                            MapControl::class as kotlin.reflect.KClass<MapControl<TextControl, NullableControl<NumberControl<Int>>>>,
                            mapOf(
                                NestedPresentationSlot.Keys to NestedPresentationScope(TextControl::class),
                                NestedPresentationSlot.Values to
                                    NestedPresentationScope(
                                        NullableControl::class,
                                        nested =
                                            mapOf(
                                                NestedPresentationSlot.Values to NestedPresentationScope(NumberControl::class),
                                            ),
                                    ),
                            ),
                        )

                    @Suppress("UNCHECKED_CAST")
                    val code: PresentedField<String, NamedControl<String, TextControl>> =
                        field(
                            "code",
                            NamedControl::class as kotlin.reflect.KClass<NamedControl<String, TextControl>>,
                            mapOf(NestedPresentationSlot.Payload to NestedPresentationScope(TextControl::class)),
                        )

                    @Suppress("UNCHECKED_CAST")
                    val positionField: PresentedField<Any, RecordControl<TestPositionScope>> =
                        field(
                            "position",
                            RecordControl::class as kotlin.reflect.KClass<RecordControl<TestPositionScope>>,
                            mapOf(
                                NestedPresentationSlot.Fields to
                                    NestedPresentationScope(
                                        TestPositionScope::class,
                                        create = { nested -> TestPositionScopeImpl(nested) },
                                    ),
                            ),
                        )

                    list { listInput { textInput() } }
                    set { collectionInput { textInput() } }
                    map {
                        mapInput(
                            keys = { textInput() },
                            values = { nullableInput { numericInput() } },
                        )
                    }
                    code { namedInput { textInput() } }
                    positionField { recordInput { x { numericInput() } } }
                }
            }

        val elements = root.layout.fixedChildren()
        val list = elements[0].element as PresentationElement.ListInputWrapper
        list.value.itemPresentation
            .singleFixed()
            .boundControl()
            .binding.bindingId.value shouldBe "list_item"
        val set = elements[1].element as PresentationElement.SetInputWrapper
        set.value.itemPresentation
            .singleFixed()
            .boundControl()
            .binding.bindingId.value shouldBe "set_item"
        val map = elements[2].element as PresentationElement.MapInputWrapper
        map.value.keyPresentation
            .singleFixed()
            .boundControl()
            .binding.bindingId.value shouldBe "map_key"
        val nullable =
            map.value.valuePresentation
                .singleFixed()
                .element as PresentationElement.NullableInputWrapper
        nullable.value.valuePresentation
            .singleFixed()
            .boundControl()
            .binding.bindingId.value shouldBe "map_value"
        val named = elements[3].element as PresentationElement.NamedInputWrapper
        named.value.payloadPresentation
            .singleFixed()
            .boundControl()
            .binding.path.segments.size shouldBe 1
        val record = elements[4].element as PresentationElement.RecordInputWrapper
        record.value.fieldPresentation
            .singleFixed()
            .boundControl()
            .binding.path.segments.size shouldBe 2
    }

    test("derives complete explicit presentation paths through records and collection items") {
        val positionId = TypeDefinitionId(TypeId.Qualified("test", "NestedChoicePosition"), 1)
        val subjectId = TypeDefinitionId(TypeId.Qualified("test", "NestedChoiceSubject"), 1)
        val integer = ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_32)
        val position =
            TypeDefinition(
                positionId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(FieldOwner(positionId, "x"), TypeTemplate.Scalar(integer))),
                    ),
            )
        val subject =
            TypeDefinition(
                subjectId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(FieldOwner(subjectId, "style"), TypeTemplate.Named(positionId)),
                            FieldDeclaration(
                                FieldOwner(subjectId, "buttons"),
                                TypeTemplate.Named(StandardTypes.list, listOf(TypeTemplate.Named(positionId))),
                            ),
                        ),
                    ),
            )
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration("nested explicit presentation paths"),
                StandardTypes.definitions + position + subject,
            )
        val checked = catalog.ready(TypeUse.Named(subjectId))
        val selected = com.typewritermc.types.PresentationId("test", "special numeric")
        val reference = object : PresentationReference {}
        val runtime =
            DefaultPresentationRuntime().also {
                it.register(reference, descriptor("special numeric", PresentationTarget.Representation(RepresentationKind.Integer), 0))
            }
        val layout =
            runtime.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR)) { build ->
                with(build) {
                    @Suppress("UNCHECKED_CAST")
                    val style: PresentedField<Any, RecordControl<TestPositionScope>> =
                        field(
                            "style",
                            RecordControl::class as kotlin.reflect.KClass<RecordControl<TestPositionScope>>,
                            mapOf(
                                NestedPresentationSlot.Fields to
                                    NestedPresentationScope(
                                        TestPositionScope::class,
                                        create = { nested -> TestPositionScopeImpl(nested) },
                                    ),
                            ),
                        )

                    @Suppress("UNCHECKED_CAST")
                    val buttons: PresentedField<List<Any>, ListControl<RecordControl<TestPositionScope>>> =
                        field(
                            "buttons",
                            ListControl::class as kotlin.reflect.KClass<ListControl<RecordControl<TestPositionScope>>>,
                            mapOf(
                                NestedPresentationSlot.Items to
                                    NestedPresentationScope(
                                        RecordControl::class,
                                        nested =
                                            mapOf(
                                                NestedPresentationSlot.Fields to
                                                    NestedPresentationScope(
                                                        TestPositionScope::class,
                                                        create = { nested -> TestPositionScopeImpl(nested) },
                                                    ),
                                            ),
                                    ),
                            ),
                        )

                    style { recordInput { x(using = reference) } }
                    buttons { listInput { recordInput { x(using = reference) } } }
                }
            }
        val material =
            PresentationMaterial(
                provider = com.typewritermc.types.PresentationId("test", "nested choices"),
                target = PresentationTarget.Named(TypeTemplate.Named(subjectId)),
                subject = TypeTemplate.Named(subjectId),
                role = PresentationRole.INSPECTOR,
                layout = layout.layout,
                dependencies = layout.dependencies,
            )

        material.explicitFieldSelections().map(OwnedFieldPresentation::field) shouldBe
            listOf(
                com.typewritermc.configuration.RelativeFieldPattern(
                    listOf(
                        com.typewritermc.configuration.FieldPatternSegment
                            .Field("style"),
                        com.typewritermc.configuration.FieldPatternSegment
                            .Field("x"),
                    ),
                ),
                com.typewritermc.configuration.RelativeFieldPattern(
                    listOf(
                        com.typewritermc.configuration.FieldPatternSegment
                            .Field("buttons"),
                        com.typewritermc.configuration.FieldPatternSegment.Items,
                        com.typewritermc.configuration.FieldPatternSegment
                            .Field("x"),
                    ),
                ),
            )
    }

    test("builds scoped collection match and invocation data nodes with lexical bindings") {
        val id = TypeDefinitionId(TypeId.Qualified("test", "PresentationDataSubject"), 1)
        val definition =
            TypeDefinition(
                id,
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(FieldOwner(id, "title"), TypeTemplate.Scalar(ScalarKind.Text))),
                    ),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("presentation data"), listOf(definition))
        val checked = catalog.ready(TypeUse.Named(id))
        val reference = object : PresentationReference {}
        val referenceId = com.typewritermc.types.PresentationId("test", "invoked")
        val parameter = presentationParameter<String>("title")
        val runtime =
            DefaultPresentationRuntime().also {
                it.register(reference, descriptor("invoked", PresentationTarget.Named(TypeTemplate.Named(id)), 0))
            }
        val repeatedSource =
            com.typewritermc.expression.Expr<List<String>, com.typewritermc.expression.Handled>(
                ExpressionNode.Literal(
                    DataValue.ListValue(
                        listOf(ListItem(ItemId("first"), DataValue.StringValue("value"))),
                    ),
                ),
            )
        val source =
            collectionSource<String, String>("rows", TypeTemplate.Scalar(ScalarKind.Text)) {
                key(row)
                relations("children", repeatedSource)
            }
        val root =
            runtime.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.EDITOR)) { build ->
                with(build) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    repeated<String, String>(repeatedSource) {
                        text(item.orElse(literal("missing")))
                        empty { text(literal("empty")) }
                        separator { divider() }
                    }
                    scoped(title.input) { textInput() }
                    typedField(title.input) { textInput() }
                    collectionLookup(source, title.input) {
                        found { text(row.orElse(literal("missing row"))) }
                        missing { text(literal("missing")) }
                        loading { text(literal("loading")) }
                    }
                    collectionGraph(source) {
                        root(title.input)
                        relation("children", CollectionDirection.Reverse, maximumDepth = 4)
                        node {
                            text(row.orElse(literal("missing node")))
                            descendants()
                        }
                    }
                    polymorphicMatch(title.input) {
                        case(AppliedPresentation<String>(TypeUse.Named(id), reference)) {
                            text(value.orElse(literal("missing value")))
                        }
                        fallback { text(literal("fallback")) }
                    }
                    invoke(reference) { bind(parameter, title.input) }
                }
            }

        root.dependencies.collections
            .single()
            .sourceId shouldBe "rows"
        root.dependencies.presentations
            .single()
            .name shouldBe "invoked"
        root.dependencies.types.single() shouldBe SkirTypeCodec.encode(TypeUse.Named(id)).getOrThrow()

        val elements = root.layout.fixedChildren().map(PresentationNode::element)
        val repeated = elements[0] as PresentationElement.RepeatedWrapper
        repeated.value.itemBindingId.value
            .startsWith("presentation.repeated.item") shouldBe true
        (repeated.value.presentation.empty != null) shouldBe true
        val scoped = elements[1] as PresentationElement.ScopedBindingWrapper
        scoped.value.child
            .singleFixed()
            .boundControl()
            .binding.bindingId shouldBe scoped.value.scopeBindingId
        val typed = elements[2] as PresentationElement.TypedFieldWrapper
        typed.value.presentation
            .singleFixed()
            .boundControl()
            .binding.path.segments.size shouldBe 1
        val lookup = elements[3] as PresentationElement.CollectionLookupWrapper
        lookup.value.sourceId shouldBe "rows"
        (lookup.value.loading != null) shouldBe true
        val graph = elements[4] as PresentationElement.CollectionGraphWrapper
        graph.value.sourceId shouldBe "rows"
        graph.value.maximumDepth shouldBe 4
        graph.value.direction shouldBe skirout.editor.v1.presentation.CollectionGraphDirection.REVERSE
        root.dependencies.collections
            .single()
            .relations
            .single()
            .targets shouldBe SkirTypeCodec.encode(repeatedSource.node).getOrThrow()
        val match = elements[5] as PresentationElement.PolymorphicMatchWrapper
        match.value.cases.size shouldBe 1
        (match.value.fallback != null) shouldBe true
        val invocation = elements[6] as PresentationElement.InvocationWrapper
        invocation.value.arguments
            .single()
            .input.value shouldBe "title"
        invocation.value.arguments
            .single()
            .binding.path.segments.size shouldBe 1

        val other =
            collectionSource<Boolean, String>("rows", TypeTemplate.Scalar(ScalarKind.Boolean)) {
                key(literal("same key type"))
            }
        val otherResult =
            runtime.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.EDITOR)) { build ->
                with(build) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    collectionLookup(other, title.input) {
                        found { text(literal("found")) }
                        missing { text(literal("missing")) }
                    }
                }
            }
        otherResult.dependencies.collections
            .single()
            .rowType shouldBe
            SkirTypeCodec.encode(TypeTemplate.Scalar(ScalarKind.Boolean)).getOrThrow()
        otherResult.dependencies.presentations shouldBe emptyList()

        runCatching {
            runtime.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.EDITOR)) { build ->
                with(build) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    collectionLookup(source, title.input) {
                        found { text(literal("found")) }
                        missing { text(literal("missing")) }
                    }
                    collectionLookup(other, title.input) {
                        found { text(literal("found")) }
                        missing { text(literal("missing")) }
                    }
                }
            }
        }.isFailure shouldBe true
    }

    test("projected collection sources use stable resource identities by default and allow handled custom keys") {
        val projection = coreTagCollectionProjection()
        val byResource = projection.projectedCollectionSource()
        val projectedRows = byResource.rows as CollectionRows.Projected

        byResource.id shouldBe projection.specification.sourceId
        byResource.rowType shouldBe projection.specification.rowType
        byResource.key.node shouldBe
            ExpressionNode.Read(projectedRows.resourceBinding, com.typewritermc.authoring.ValuePath())

        val byName: CollectionSource<com.typewritermc.library.TagCollectionRow, String> =
            projection.projectedCollectionSource(
                key = { expressions.name.orElse(literal("unnamed")) },
            )
        (byName.key.node is ExpressionNode.OrElse) shouldBe true
        byName.relations shouldBe emptyList()

        val resources: CollectionSource<com.typewritermc.library.Tag, ResourceId> =
            resourceCollectionSource(
                id = "tags",
                root = TypeTemplate.Named(com.typewritermc.library.TagDefinition.id),
                appearance = null,
            ) {}
        val resourceRows = resources.rows as CollectionRows.Resources
        resources.key.node shouldBe
            ExpressionNode.Read(resourceRows.resourceBinding, com.typewritermc.authoring.ValuePath())
    }

    test("selects specific presentations before priority and preserves fallback order") {
        val id = TypeDefinitionId(TypeId.Qualified("test", "RegistrySubject"), 1)
        val definition = TypeDefinition(id, representation = RepresentationTemplate.Record(emptyList()))
        val catalog = DefaultCheckedCatalog(CatalogGeneration("presentation registry"), listOf(definition))
        val checked = (catalog.resolve(TypeUse.Named(id)) as Resolution.Ready).value
        val representation =
            descriptor("generic", PresentationTarget.Representation(com.typewritermc.configuration.RepresentationKind.Record), 100)
        val named = descriptor("specific", PresentationTarget.Named(TypeTemplate.Named(id)), 10)
        val fallbackFirst =
            descriptor("fallback first", PresentationTarget.Named(TypeTemplate.Named(id)), 10, PresentationRole.REFERENCE_SUMMARY)
        val fallbackSecond =
            descriptor("fallback second", PresentationTarget.Named(TypeTemplate.Named(id)), 100, PresentationRole.CATALOG_OPTION)
        val registry =
            DefaultPresentationRegistry(
                catalog,
                listOf(representation, named, fallbackFirst, fallbackSecond),
                listOf(
                    RoleFallback(
                        PresentationRole.PAGE_TILE,
                        listOf(PresentationRole.REFERENCE_SUMMARY, PresentationRole.CATALOG_OPTION),
                    ),
                ),
            )

        (registry.select(PresentationRole.EDITOR, checked) as PresentationSelection.Selected).descriptor.id shouldBe named.id
        (registry.select(PresentationRole.PAGE_TILE, checked) as PresentationSelection.Selected).descriptor.id shouldBe fallbackFirst.id
    }

    test("inspector presentations do not satisfy editor selection") {
        val id = TypeDefinitionId(TypeId.Qualified("test", "RoleSubject"), 1)
        val definition = TypeDefinition(id, representation = RepresentationTemplate.Record(emptyList()))
        val catalog = DefaultCheckedCatalog(CatalogGeneration("role separation"), listOf(definition))
        val checked = (catalog.resolve(TypeUse.Named(id)) as Resolution.Ready).value
        val inspector = descriptor("inspector", PresentationTarget.Named(TypeTemplate.Named(id)), 10, PresentationRole.INSPECTOR)
        val registry = DefaultPresentationRegistry(catalog, listOf(inspector))

        (registry.select(PresentationRole.INSPECTOR, checked) as PresentationSelection.Selected).descriptor.id shouldBe inspector.id
        registry.select(PresentationRole.EDITOR, checked) shouldBe PresentationSelection.Missing(PresentationRole.EDITOR)
    }

    test("reports incomparable generic presentation targets as a conflict before priority") {
        val pairId = TypeDefinitionId(TypeId.Qualified("test", "Pair"), 1)
        val first = ParameterKey(pairId, 0)
        val second = ParameterKey(pairId, 1)
        val definition =
            TypeDefinition(
                pairId,
                listOf(TypeParameter(first, "A"), TypeParameter(second, "B")),
                RepresentationTemplate.Record(emptyList()),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("incomparable presentations"), StandardTypes.definitions + definition)
        val actual =
            catalog.ready(
                TypeUse.Named(
                    pairId,
                    listOf(
                        TypeUse.Scalar(ScalarKind.Text),
                        TypeUse.Named(StandardTypes.list, listOf(TypeUse.Scalar(ScalarKind.Text))),
                    ),
                ),
            )
        val left =
            descriptor(
                "left",
                PresentationTarget.Named(
                    TypeTemplate.Named(
                        pairId,
                        listOf(TypeTemplate.Scalar(ScalarKind.Text), TypeTemplate.Parameter(first)),
                    ),
                ),
                10,
            )
        val right =
            descriptor(
                "right",
                PresentationTarget.Named(
                    TypeTemplate.Named(
                        pairId,
                        listOf(
                            TypeTemplate.Parameter(first),
                            TypeTemplate.Named(
                                StandardTypes.list,
                                listOf(TypeTemplate.Scalar(ScalarKind.Text)),
                            ),
                        ),
                    ),
                ),
                100,
            )
        val selection = DefaultPresentationRegistry(catalog, listOf(left, right)).select(PresentationRole.EDITOR, actual)

        selection shouldBe PresentationSelection.Conflict(listOf(left.id, right.id))
    }

    test("selects repeated generic parameters before a broader target") {
        val pairId = TypeDefinitionId(TypeId.Qualified("test", "RepeatedPair"), 1)
        val first = ParameterKey(pairId, 0)
        val second = ParameterKey(pairId, 1)
        val definition =
            TypeDefinition(
                pairId,
                listOf(TypeParameter(first, "A"), TypeParameter(second, "B")),
                RepresentationTemplate.Record(emptyList()),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("repeated parameter presentation"), listOf(definition))
        val actual =
            catalog.ready(
                TypeUse.Named(
                    pairId,
                    listOf(TypeUse.Scalar(ScalarKind.Text), TypeUse.Scalar(ScalarKind.Text)),
                ),
            )
        val repeated =
            descriptor(
                "repeated",
                PresentationTarget.Named(
                    TypeTemplate.Named(
                        pairId,
                        listOf(TypeTemplate.Parameter(first), TypeTemplate.Parameter(first)),
                    ),
                ),
                10,
            )
        val broad =
            descriptor(
                "broad",
                PresentationTarget.Named(
                    TypeTemplate.Named(
                        pairId,
                        listOf(TypeTemplate.Parameter(first), TypeTemplate.Parameter(second)),
                    ),
                ),
                100,
            )

        val selection = DefaultPresentationRegistry(catalog, listOf(repeated, broad)).select(PresentationRole.EDITOR, actual)

        (selection as PresentationSelection.Selected).descriptor.id shouldBe repeated.id
    }

    test("matches presentation arguments through readable nominal subtypes") {
        val rewardId = TypeDefinitionId(TypeId.Qualified("test", "Reward"), 1)
        val coinId = TypeDefinitionId(TypeId.Qualified("test", "CoinReward"), 1)
        val variableId = TypeDefinitionId(TypeId.Qualified("test", "Variable"), 1)
        val variableParameter = ParameterKey(variableId, 0)
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration("readable presentation argument"),
                listOf(
                    TypeDefinition(rewardId, representation = RepresentationTemplate.Record(emptyList(), abstract = true)),
                    TypeDefinition(
                        coinId,
                        representation = RepresentationTemplate.Record(emptyList()),
                        parents = listOf(TypeTemplate.Named(rewardId)),
                    ),
                    TypeDefinition(
                        variableId,
                        parameters = listOf(TypeParameter(variableParameter, "T")),
                        representation = RepresentationTemplate.Record(emptyList()),
                    ),
                ),
            )
        val actual = catalog.ready(TypeUse.Named(variableId, listOf(TypeUse.Named(coinId))))
        val broad =
            descriptor(
                "reward variable",
                PresentationTarget.Named(
                    TypeTemplate.Named(variableId, listOf(TypeTemplate.Named(rewardId))),
                ),
                10,
            )

        val selection = DefaultPresentationRegistry(catalog, listOf(broad)).select(PresentationRole.EDITOR, actual)

        (selection as PresentationSelection.Selected).descriptor.id shouldBe broad.id
    }

    test("selects a concrete generic argument before its readable base argument") {
        val rewardId = TypeDefinitionId(TypeId.Qualified("test", "SpecificReward"), 1)
        val coinId = TypeDefinitionId(TypeId.Qualified("test", "SpecificCoinReward"), 1)
        val variableId = TypeDefinitionId(TypeId.Qualified("test", "SpecificVariable"), 1)
        val variableParameter = ParameterKey(variableId, 0)
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration("specific readable presentation argument"),
                listOf(
                    TypeDefinition(rewardId, representation = RepresentationTemplate.Record(emptyList(), abstract = true)),
                    TypeDefinition(
                        coinId,
                        representation = RepresentationTemplate.Record(emptyList()),
                        parents = listOf(TypeTemplate.Named(rewardId)),
                    ),
                    TypeDefinition(
                        variableId,
                        parameters = listOf(TypeParameter(variableParameter, "T")),
                        representation = RepresentationTemplate.Record(emptyList()),
                    ),
                ),
            )
        val actual = catalog.ready(TypeUse.Named(variableId, listOf(TypeUse.Named(coinId))))
        val concrete =
            descriptor(
                "coin variable",
                PresentationTarget.Named(
                    TypeTemplate.Named(variableId, listOf(TypeTemplate.Named(coinId))),
                ),
                10,
            )
        val broad =
            descriptor(
                "reward variable",
                PresentationTarget.Named(
                    TypeTemplate.Named(variableId, listOf(TypeTemplate.Named(rewardId))),
                ),
                100,
            )

        val selection = DefaultPresentationRegistry(catalog, listOf(concrete, broad)).select(PresentationRole.EDITOR, actual)

        (selection as PresentationSelection.Selected).descriptor.id shouldBe concrete.id
    }
}

private fun DefaultCheckedCatalog.ready(use: TypeUse): com.typewritermc.types.catalog.CheckedType = (resolve(use) as Resolution.Ready).value

private fun descriptor(
    name: String,
    target: PresentationTarget,
    priority: Int,
    role: PresentationRole = PresentationRole.EDITOR,
): PresentationDescriptor =
    PresentationDescriptor(
        com.typewritermc.types.PresentationId("test", name),
        DeclarationOwner(
            ContributionKey(
                ContributionSourceId("test"),
                "main",
                ProducerId("test"),
                ContributionName(name.replace(' ', '_')),
            ),
            name,
        ),
        target,
        setOf(role),
        priority,
    )

private interface TestPositionScope : Layout {
    val x: PresentedField<Int, NumberControl<Int>>
}

private class TestPositionScopeImpl(
    private val build: PresentationBuildScope,
) : TestPositionScope,
    Layout by build {
    @Suppress("UNCHECKED_CAST")
    override val x: PresentedField<Int, NumberControl<Int>>
        get() = build.field("x", NumberControl::class as kotlin.reflect.KClass<NumberControl<Int>>)
}

private class ProjectionFixtureResource : Resource

private object ProjectionFixtureExpressionsFactory : com.typewritermc.expression.ExpressionFactory<ProjectionFixtureExpressions> {
    override val scope = ProjectionFixtureExpressions::class

    override fun create(
        value: com.typewritermc.expression.Expr<*, out com.typewritermc.expression.MissingPolicy>,
    ): ProjectionFixtureExpressions = object : ProjectionFixtureExpressions {}
}

private interface ProjectionFixtureExpressions

private fun PresentationNode.fixedChildren(): List<PresentationNode> {
    val column = (element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
    return column.value.children.map { (it as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value }
}

private fun PresentationNode?.singleFixed(): PresentationNode = requireNotNull(this).fixedChildren().single()

private fun PresentationNode.boundControl(): skirout.editor.v1.presentation.BoundControl =
    when (val value = element) {
        is PresentationElement.TextInputWrapper -> value.value.control
        is PresentationElement.NumericInputWrapper -> value.value
        else -> error("Expected a scalar input, found $value.")
    }
