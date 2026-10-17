package com.typewritermc.authoring.skir

import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.ConnectIntent
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InputAnswer
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.LinkProjection
import com.typewritermc.authoring.PreparationDraft
import com.typewritermc.authoring.PreparationOperation
import com.typewritermc.authoring.PreparationStep
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.PreparedValue
import com.typewritermc.authoring.RequiredInput
import com.typewritermc.authoring.TraversalDirection
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.DataValue
import com.typewritermc.types.ListItem
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirConversionDiagnostic
import com.typewritermc.types.skir.SkirConversionResult
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import skirout.editor.v1.authoring.CommitResult as SkirCommitResult
import skirout.editor.v1.authoring.ConnectIntent as SkirConnectIntent
import skirout.editor.v1.authoring.CounterpartChoice as SkirCounterpartChoice
import skirout.editor.v1.authoring.EditIntent as SkirEditIntent
import skirout.editor.v1.authoring.NewCounterpartChoice as SkirNewCounterpartChoice
import skirout.editor.v1.authoring.PreparedEdit as SkirPreparedEdit
import skirout.editor.v1.authoring_facts.EditExpectation as SkirEditExpectation
import skirout.editor.v1.authoring_facts.ExpectationConflict as SkirExpectationConflict
import skirout.editor.v1.authoring_facts.LinkProjection as SkirLinkProjection
import skirout.editor.v1.authoring_facts.TraversalDirection as SkirTraversalDirection
import skirout.editor.v1.catalog.InputAnswer as SkirInputAnswer
import skirout.editor.v1.catalog.PreparationDraft as SkirPreparationDraft
import skirout.editor.v1.catalog.PreparationOperation as SkirPreparationOperation
import skirout.editor.v1.catalog.PreparationStep as SkirPreparationStep
import skirout.editor.v1.catalog.PreparationTarget as SkirPreparationTarget
import skirout.editor.v1.catalog.PreparedContent as SkirPreparedContent
import skirout.editor.v1.catalog.PreparedValue as SkirPreparedValue
import skirout.editor.v1.catalog.RequiredInput as SkirRequiredInput
import skirout.editor.v1.catalog.ValuePreparationRequest as SkirInitializationRequest
import skirout.editor.v1.diagnostic.ValueProblem as SkirValueProblem
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.DataValue as SkirDataValue
import skirout.editor.v1.type_catalog.ItemId as SkirItemId
import skirout.editor.v1.type_catalog.ListItem as SkirListItem
import skirout.editor.v1.type_catalog.NamedTypeUse as SkirNamedTypeUse
import skirout.editor.v1.type_catalog.RelationId as SkirRelationId
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId
import skirout.editor.v1.type_catalog.TypeUse as SkirTypeUse

/**
 * Carries initialization continuations, observed edit expectations, ordered intents, and commit outcomes over Skir.
 * Nested value conversion failures retain their traversal path inside the enclosing operation. Conversion preserves
 * proposals and preconditions; continuation validation and edit acceptance still belong to their runtime owners.
 */
object SkirAuthoringOperationCodec {
    fun encode(value: PreparationOperation): SkirConversionResult<SkirPreparationOperation> =
        captureOperationConversion { encodePreparationOperation(value) }

    fun decode(value: SkirPreparationOperation): SkirConversionResult<PreparationOperation> =
        captureOperationConversion {
            decodePreparationOperation(value)
        }

    fun encode(value: PreparationStep): SkirConversionResult<SkirPreparationStep> =
        captureOperationConversion { encodePreparationStep(value) }

    fun decode(value: SkirPreparationStep): SkirConversionResult<PreparationStep> =
        captureOperationConversion { decodePreparationStep(value) }

    fun encode(value: EditExpectation): SkirConversionResult<SkirEditExpectation> = captureOperationConversion { encodeExpectation(value) }

    fun decode(value: SkirEditExpectation): SkirConversionResult<EditExpectation> = captureOperationConversion { decodeExpectation(value) }

    fun encode(value: LinkProjection): SkirConversionResult<SkirLinkProjection> = captureOperationConversion { encodeProjection(value) }

    fun decode(value: SkirLinkProjection): SkirConversionResult<LinkProjection> = captureOperationConversion { decodeProjection(value) }

    fun encode(value: PreparedEdit): SkirConversionResult<SkirPreparedEdit> = captureOperationConversion { encodePreparedEdit(value) }

    fun decode(value: SkirPreparedEdit): SkirConversionResult<PreparedEdit> = captureOperationConversion { decodePreparedEdit(value) }

    fun encode(value: CommitResult): SkirConversionResult<SkirCommitResult> = captureOperationConversion { encodeCommitResult(value) }

    fun encode(value: InitializationRequest): SkirConversionResult<SkirInitializationRequest> =
        captureOperationConversion { encodeInitializationRequest(value) }

    fun decode(value: SkirInitializationRequest): SkirConversionResult<InitializationRequest> =
        captureOperationConversion { decodeInitializationRequest(value) }

    fun encode(value: PreparedValue): SkirConversionResult<SkirPreparedValue> = captureOperationConversion { encodePreparedValue(value) }

    fun decode(value: SkirPreparedValue): SkirConversionResult<PreparedValue> = captureOperationConversion { decodePreparedValue(value) }
}

private fun OperationConversionScope.encodePreparationOperation(value: PreparationOperation): SkirPreparationOperation =
    when (value) {
        is PreparationOperation.Start -> {
            SkirPreparationOperation.StartWrapper(encodeInitializationRequest(value.request))
        }

        is PreparationOperation.Resume -> {
            SkirPreparationOperation.createResume(
                draft = encodePreparationDraft(value.draft),
                answers =
                    value.answers.map {
                        SkirInputAnswer(
                            path = convert(SkirAuthoringValueCodec.encode(it.path)),
                            value = convert(SkirDataValueCodec.encode(it.value)),
                        )
                    },
            )
        }
    }

private fun OperationConversionScope.decodePreparationOperation(value: SkirPreparationOperation): PreparationOperation =
    when (value) {
        is SkirPreparationOperation.StartWrapper -> {
            PreparationOperation.Start(decodeInitializationRequest(value.value))
        }

        is SkirPreparationOperation.ResumeWrapper -> {
            PreparationOperation.Resume(
                decodePreparationDraft(value.value.draft),
                value.value.answers.map {
                    InputAnswer(
                        convert(SkirAuthoringValueCodec.decode(it.path)),
                        convert(SkirDataValueCodec.decode(it.value)),
                    )
                },
            )
        }

        else -> {
            fail("Unknown preparation operation.")
        }
    }

private fun OperationConversionScope.encodePreparationStep(value: PreparationStep): SkirPreparationStep =
    when (value) {
        is PreparationStep.Ready -> SkirPreparationStep.ReadyWrapper(encodePreparedValue(value.value))
        is PreparationStep.NeedsInput -> SkirPreparationStep.NeedsInputWrapper(encodePreparationDraft(value.draft))
        is PreparationStep.Unavailable -> SkirPreparationStep.UnavailableWrapper(encodePreparationDraft(value.draft))
    }

private fun OperationConversionScope.decodePreparationStep(value: SkirPreparationStep): PreparationStep =
    when (value) {
        is SkirPreparationStep.ReadyWrapper -> PreparationStep.Ready(decodePreparedValue(value.value))
        is SkirPreparationStep.NeedsInputWrapper -> PreparationStep.NeedsInput(decodePreparationDraft(value.value))
        is SkirPreparationStep.UnavailableWrapper -> PreparationStep.Unavailable(decodePreparationDraft(value.value))
        else -> fail("Unknown preparation step.")
    }

private fun OperationConversionScope.encodePreparationDraft(value: PreparationDraft): SkirPreparationDraft {
    val request = encodeInitializationRequest(InitializationRequest(value.catalog, value.target, null))
    val prepared = encodePreparedValue(PreparedValue(value.content, value.findings))
    return SkirPreparationDraft(
        catalog = request.catalog,
        target = request.target,
        content = prepared.content,
        pendingDefaults = value.pendingDefaults.map { convert(SkirAuthoringValueCodec.encode(it)) },
        requiredInputs =
            value.requiredInputs.map {
                SkirRequiredInput(
                    path = convert(SkirAuthoringValueCodec.encode(it.path)),
                    expected = convert(SkirTypeCodec.encode(it.expected)),
                )
            },
        findings = prepared.findings,
    )
}

private fun OperationConversionScope.decodePreparationDraft(value: SkirPreparationDraft): PreparationDraft {
    val request =
        decodeInitializationRequest(SkirInitializationRequest(catalog = value.catalog, target = value.target, suppliedValue = null))
    val prepared = decodePreparedValue(SkirPreparedValue(content = value.content, findings = value.findings))
    val pending = value.pendingDefaults.map { convert(SkirAuthoringValueCodec.decode(it)) }
    if (pending.toSet().size != pending.size) fail("A pending default path is duplicated.")
    return PreparationDraft(
        request.catalog,
        request.target,
        prepared.content,
        pending.toSet(),
        value.requiredInputs.map {
            RequiredInput(
                convert(SkirAuthoringValueCodec.decode(it.path)),
                convert(SkirTypeCodec.decode(it.expected)),
            )
        },
        prepared.findings,
    )
}

private fun OperationConversionScope.encodePreparedEdit(value: PreparedEdit): SkirPreparedEdit =
    SkirPreparedEdit(
        catalog = SkirCatalogGeneration(value = value.catalog.value),
        expectations = value.expectations.map { encodeExpectation(it) },
        intents = value.intents.mapIndexed { index, intent -> at("intent $index") { encodeIntent(intent) } },
    )

private fun OperationConversionScope.decodePreparedEdit(value: SkirPreparedEdit): PreparedEdit =
    PreparedEdit(
        catalog = CatalogGeneration(requireText(value.catalog.value, "Catalog generation")),
        expectations =
            value.expectations.map {
                decodeExpectation(it)
            },
        intents = value.intents.mapIndexed { index, intent -> at("intent $index") { decodeIntent(intent) } },
    )

private fun OperationConversionScope.encodeExpectation(value: EditExpectation): SkirEditExpectation =
    when (value) {
        is EditExpectation.Value -> {
            SkirEditExpectation.createValue(
                at = convert(SkirAuthoringValueCodec.encode(value.at)),
                expected =
                    value.expected?.let {
                        convert(SkirDataValueCodec.encode(it))
                    },
            )
        }

        is EditExpectation.Resource -> {
            SkirEditExpectation.createResource(
                id = SkirResourceId(value = value.id.value),
                expected =
                    value.expected?.let {
                        convert(SkirAuthoringValueCodec.encode(it))
                    },
            )
        }

        is EditExpectation.ResourceExists -> {
            SkirEditExpectation.createResourceExists(id = SkirResourceId(value = value.id.value), expected = value.expected)
        }

        is EditExpectation.Configuration -> {
            SkirEditExpectation.createConfiguration(
                at = convert(SkirAuthoringValueCodec.encode(value.at)),
                expected =
                    value.expected?.let {
                        convert(SkirAuthoringValueCodec.encode(it))
                    },
            )
        }

        is EditExpectation.ResourceIds -> {
            SkirEditExpectation.ResourceIdsWrapper(value.expected.sortedBy { it.value }.map { SkirResourceId(value = it.value) })
        }

        is EditExpectation.Links -> {
            SkirEditExpectation.createLinks(
                resource = SkirResourceId(value = value.resource.value),
                contract = SkirRelationId(value = value.contract.value),
                direction =
                    when (value.direction) {
                        TraversalDirection.Forward -> SkirTraversalDirection.FORWARD
                        TraversalDirection.Reverse -> SkirTraversalDirection.REVERSE
                        TraversalDirection.Both -> SkirTraversalDirection.BOTH
                    },
                expected = value.expected.sortedBy { it.toString() }.map { encodeProjection(it) },
            )
        }
    }

private fun OperationConversionScope.decodeExpectation(value: SkirEditExpectation): EditExpectation =
    when (value) {
        is SkirEditExpectation.ValueWrapper -> {
            EditExpectation.Value(
                convert(SkirAuthoringValueCodec.decode(value.value.at)),
                value.value.expected?.let {
                    convert(SkirDataValueCodec.decode(it))
                },
            )
        }

        is SkirEditExpectation.ResourceWrapper -> {
            EditExpectation.Resource(
                ResourceId(requireText(value.value.id.value, "Resource identity")),
                value.value.expected?.let {
                    convert(SkirAuthoringValueCodec.decode(it))
                },
            )
        }

        is SkirEditExpectation.ResourceExistsWrapper -> {
            EditExpectation.ResourceExists(ResourceId(requireText(value.value.id.value, "Resource identity")), value.value.expected)
        }

        is SkirEditExpectation.ConfigurationWrapper -> {
            EditExpectation.Configuration(
                convert(SkirAuthoringValueCodec.decode(value.value.at)),
                value.value.expected?.let {
                    convert(SkirAuthoringValueCodec.decode(it))
                },
            )
        }

        is SkirEditExpectation.ResourceIdsWrapper -> {
            EditExpectation.ResourceIds(value.value.mapTo(linkedSetOf()) { ResourceId(requireText(it.value, "Resource identity")) })
        }

        is SkirEditExpectation.LinksWrapper -> {
            EditExpectation.Links(
                ResourceId(requireText(value.value.resource.value, "Resource identity")),
                RelationId(requireText(value.value.contract.value, "Relation identity")),
                when (value.value.direction) {
                    SkirTraversalDirection.FORWARD -> TraversalDirection.Forward
                    SkirTraversalDirection.REVERSE -> TraversalDirection.Reverse
                    SkirTraversalDirection.BOTH -> TraversalDirection.Both
                    else -> fail("Unknown traversal direction")
                },
                value.value.expected.mapTo(linkedSetOf()) { decodeProjection(it) },
            )
        }

        else -> {
            fail("Unknown edit expectation")
        }
    }

private fun OperationConversionScope.encodeProjection(value: LinkProjection): SkirLinkProjection =
    SkirLinkProjection(
        contract = SkirRelationId(value = value.contract.value),
        first = SkirResourceId(value = value.first.value),
        second = SkirResourceId(value = value.second.value),
        firstLocation =
            value.firstLocation?.let {
                convert(SkirAuthoringValueCodec.encode(it))
            },
        secondLocation = value.secondLocation?.let { convert(SkirAuthoringValueCodec.encode(it)) },
    )

private fun OperationConversionScope.decodeProjection(value: SkirLinkProjection): LinkProjection =
    LinkProjection(
        RelationId(requireText(value.contract.value, "Relation identity")),
        ResourceId(requireText(value.first.value, "Resource identity")),
        ResourceId(requireText(value.second.value, "Resource identity")),
        value.firstLocation?.let {
            convert(SkirAuthoringValueCodec.decode(it))
        },
        value.secondLocation?.let { convert(SkirAuthoringValueCodec.decode(it)) },
    )

private fun OperationConversionScope.encodeIntent(value: EditIntent): SkirEditIntent =
    when (value) {
        is EditIntent.CreateResource -> {
            SkirEditIntent.createCreateResource(
                id = SkirResourceId(value = value.id.value),
                record = convert(SkirAuthoringValueCodec.encode(value.record)),
            )
        }

        is EditIntent.DeleteResource -> {
            SkirEditIntent.createDeleteResource(id = SkirResourceId(value = value.id.value))
        }

        is EditIntent.SetValue -> {
            SkirEditIntent.createSetValue(
                at = convert(SkirAuthoringValueCodec.encode(value.at)),
                value = convert(SkirDataValueCodec.encode(value.value)),
            )
        }

        is EditIntent.Insert -> {
            SkirEditIntent.createInsert(
                at = convert(SkirAuthoringValueCodec.encode(value.at)),
                after = value.after?.let { SkirItemId(value = it.value) },
                item = encodeListItem(value.item),
            )
        }

        is EditIntent.Remove -> {
            SkirEditIntent.createRemove(
                at = convert(SkirAuthoringValueCodec.encode(value.at)),
                item = SkirItemId(value = value.item.value),
            )
        }

        is EditIntent.Move -> {
            SkirEditIntent.createMove(
                at = convert(SkirAuthoringValueCodec.encode(value.at)),
                item = SkirItemId(value = value.item.value),
                after = value.after?.let { SkirItemId(value = it.value) },
            )
        }

        is EditIntent.ConnectRelation -> {
            SkirEditIntent.ConnectRelationWrapper(encodeConnect(value.intent))
        }

        is EditIntent.DisconnectRelation -> {
            SkirEditIntent.DisconnectRelationWrapper(convert(SkirAuthoringValueCodec.encode(value.occurrence)))
        }

        is EditIntent.Retag -> {
            SkirEditIntent.createRetag(
                at = convert(SkirAuthoringValueCodec.encode(value.at)),
                type = encodeNamedType(value.type),
            )
        }

        is EditIntent.ConfigureResource -> {
            SkirEditIntent.createConfigureResource(
                resource = SkirResourceId(value = value.resource.value),
                configuration = convert(SkirAuthoringValueCodec.encode(value.configuration)),
            )
        }
    }

private fun OperationConversionScope.decodeIntent(value: SkirEditIntent): EditIntent =
    when (value) {
        is SkirEditIntent.CreateResourceWrapper -> {
            EditIntent.CreateResource(
                id = ResourceId(requireText(value.value.id.value, "Resource identity")),
                record = convert(SkirAuthoringValueCodec.decode(value.value.record)),
            )
        }

        is SkirEditIntent.DeleteResourceWrapper -> {
            EditIntent.DeleteResource(ResourceId(requireText(value.value.id.value, "Resource identity")))
        }

        is SkirEditIntent.SetValueWrapper -> {
            EditIntent.SetValue(
                at = convert(SkirAuthoringValueCodec.decode(value.value.at)),
                value = convert(SkirDataValueCodec.decode(value.value.value)),
            )
        }

        is SkirEditIntent.InsertWrapper -> {
            EditIntent.Insert(
                at = convert(SkirAuthoringValueCodec.decode(value.value.at)),
                after = value.value.after?.let { ItemId(requireText(it.value, "Previous item identity")) },
                item = decodeListItem(value.value.item),
            )
        }

        is SkirEditIntent.RemoveWrapper -> {
            EditIntent.Remove(
                at = convert(SkirAuthoringValueCodec.decode(value.value.at)),
                item = ItemId(requireText(value.value.item.value, "Item identity")),
            )
        }

        is SkirEditIntent.MoveWrapper -> {
            EditIntent.Move(
                at = convert(SkirAuthoringValueCodec.decode(value.value.at)),
                item = ItemId(requireText(value.value.item.value, "Item identity")),
                after = value.value.after?.let { ItemId(requireText(it.value, "Previous item identity")) },
            )
        }

        is SkirEditIntent.ConnectRelationWrapper -> {
            EditIntent.ConnectRelation(decodeConnect(value.value))
        }

        is SkirEditIntent.DisconnectRelationWrapper -> {
            EditIntent.DisconnectRelation(convert(SkirAuthoringValueCodec.decode(value.value)))
        }

        is SkirEditIntent.RetagWrapper -> {
            EditIntent.Retag(
                at = convert(SkirAuthoringValueCodec.decode(value.value.at)),
                type = decodeNamedType(value.value.type),
            )
        }

        is SkirEditIntent.ConfigureResourceWrapper -> {
            EditIntent.ConfigureResource(
                resource = ResourceId(requireText(value.value.resource.value, "Resource identity")),
                configuration = convert(SkirAuthoringValueCodec.decode(value.value.configuration)),
            )
        }

        else -> {
            fail("Unknown Skir edit intent variant.")
        }
    }

private fun OperationConversionScope.encodeConnect(value: ConnectIntent): SkirConnectIntent =
    SkirConnectIntent(
        source = convert(SkirAuthoringValueCodec.encode(value.source)),
        target = SkirResourceId(value = value.target.value),
        counterpart =
            when (val counterpart = value.counterpart) {
                is CounterpartChoice.Existing -> {
                    SkirCounterpartChoice.ExistingWrapper(convert(SkirAuthoringValueCodec.encode(counterpart.occurrence)))
                }

                is CounterpartChoice.New -> {
                    SkirCounterpartChoice.NewWrapper(
                        SkirNewCounterpartChoice(
                            containing = convert(SkirAuthoringValueCodec.encode(counterpart.containing)),
                            prepared = encodePreparedValue(counterpart.prepared),
                        ),
                    )
                }

                null -> {
                    null
                }
            },
    )

private fun OperationConversionScope.decodeConnect(value: SkirConnectIntent): ConnectIntent =
    ConnectIntent(
        source = convert(SkirAuthoringValueCodec.decode(value.source)),
        target = ResourceId(requireText(value.target.value, "Target resource identity")),
        counterpart =
            when (val counterpart = value.counterpart) {
                is SkirCounterpartChoice.ExistingWrapper -> {
                    CounterpartChoice.Existing(convert(SkirAuthoringValueCodec.decode(counterpart.value)))
                }

                is SkirCounterpartChoice.NewWrapper -> {
                    CounterpartChoice.New(
                        containing = convert(SkirAuthoringValueCodec.decode(counterpart.value.containing)),
                        prepared = decodePreparedValue(counterpart.value.prepared),
                    )
                }

                null -> {
                    null
                }

                else -> {
                    fail("Unknown Skir counterpart choice variant.")
                }
            },
    )

private fun OperationConversionScope.encodeCommitResult(value: CommitResult): SkirCommitResult =
    when (value) {
        CommitResult.Committed -> {
            SkirCommitResult.COMMITTED
        }

        is CommitResult.Conflict -> {
            SkirCommitResult.ConflictWrapper(
                value.values.map { conflict ->
                    SkirExpectationConflict(expected = encodeExpectation(conflict.expected), actual = encodeExpectation(conflict.actual))
                },
            )
        }

        is CommitResult.Rejected -> {
            SkirCommitResult.RejectedWrapper(
                value.problems.map { problem ->
                    SkirValueProblem(
                        location = convert(SkirAuthoringValueCodec.encode(problem.location)),
                        code = problem.code,
                    )
                },
            )
        }

        is CommitResult.CatalogChanged -> {
            SkirCommitResult.createCatalogChanged(value = value.actual.value)
        }
    }

private fun OperationConversionScope.encodeInitializationRequest(value: InitializationRequest): SkirInitializationRequest =
    SkirInitializationRequest(
        catalog = SkirCatalogGeneration(value = value.catalog.value),
        target =
            when (val target = value.target) {
                is PreparationTarget.Value -> {
                    SkirPreparationTarget.ValueWrapper(convert(SkirTypeCodec.encode(target.type)))
                }

                is PreparationTarget.Record -> {
                    SkirPreparationTarget.RecordWrapper(
                        convert(SkirAuthoringValueCodec.encode(target.selection)),
                    )
                }
            },
        suppliedValue = value.supplied?.let { convert(SkirDataValueCodec.encode(it)) },
    )

private fun OperationConversionScope.decodeInitializationRequest(value: SkirInitializationRequest): InitializationRequest =
    InitializationRequest(
        catalog = CatalogGeneration(requireText(value.catalog.value, "Catalog generation")),
        target =
            when (val target = value.target) {
                is SkirPreparationTarget.ValueWrapper -> {
                    PreparationTarget.Value(convert(SkirTypeCodec.decode(target.value)))
                }

                is SkirPreparationTarget.RecordWrapper -> {
                    PreparationTarget.Record(convert(SkirAuthoringValueCodec.decode(target.value)))
                }

                else -> {
                    fail("Preparation target is unknown.")
                }
            },
        supplied = value.suppliedValue?.let { convert(SkirDataValueCodec.decode(it)) },
    )

private fun OperationConversionScope.encodePreparedValue(value: PreparedValue): SkirPreparedValue =
    SkirPreparedValue(
        content =
            when (val content = value.content) {
                is PreparedContent.Value -> {
                    SkirPreparedContent.ValueWrapper(convert(SkirDataValueCodec.encode(content.value)))
                }

                is PreparedContent.Record -> {
                    SkirPreparedContent.RecordWrapper(convert(SkirAuthoringValueCodec.encode(content.record)))
                }
            },
        findings =
            value.findings.mapIndexed {
                index,
                finding,
                ->
                at("finding $index") { convert(SkirAuthoringValueCodec.encode(finding)) }
            },
    )

private fun OperationConversionScope.decodePreparedValue(value: SkirPreparedValue): PreparedValue =
    PreparedValue(
        content =
            when (val content = value.content) {
                is SkirPreparedContent.ValueWrapper -> {
                    PreparedContent.Value(convert(SkirDataValueCodec.decode(content.value)))
                }

                is SkirPreparedContent.RecordWrapper -> {
                    PreparedContent.Record(convert(SkirAuthoringValueCodec.decode(content.value)))
                }

                else -> {
                    fail("Prepared content is unknown.")
                }
            },
        findings =
            value.findings.mapIndexed {
                index,
                finding,
                ->
                at("finding $index") { convert(SkirAuthoringValueCodec.decode(finding)) }
            },
    )

private fun OperationConversionScope.encodeListItem(value: ListItem) =
    SkirListItem(id = SkirItemId(value = value.id.value), value = convert(SkirDataValueCodec.encode(value.value)))

private fun OperationConversionScope.decodeListItem(value: SkirListItem) =
    ListItem(
        id = ItemId(requireText(value.id.value, "Item identity")),
        value = convert(SkirDataValueCodec.decode(value.value)),
    )

private fun OperationConversionScope.encodeNamedType(value: TypeUse.Named): SkirNamedTypeUse =
    when (val encoded = convert(SkirTypeCodec.encode(value))) {
        is SkirTypeUse.NamedWrapper -> encoded.value
        else -> fail("Named type encoded as another Skir variant.")
    }

private fun OperationConversionScope.decodeNamedType(value: SkirNamedTypeUse): TypeUse.Named =
    when (val decoded = convert(SkirTypeCodec.decode(SkirTypeUse.NamedWrapper(value)))) {
        is TypeUse.Named -> decoded
        else -> fail("Named Skir type decoded as another domain variant.")
    }

private inline fun <Value> captureOperationConversion(block: OperationConversionScope.() -> Value): SkirConversionResult<Value> =
    try {
        SkirConversionResult.Success(OperationConversionScope().block())
    } catch (failure: OperationConversionFailure) {
        SkirConversionResult.Failure(listOf(failure.diagnostic))
    }

private class OperationConversionScope {
    private val path = ArrayDeque<String>()

    inline fun <Value> at(
        segment: String,
        block: () -> Value,
    ): Value {
        path.addLast(segment)
        return try {
            block()
        } finally {
            path.removeLast()
        }
    }

    fun <Value> convert(result: SkirConversionResult<Value>): Value =
        when (result) {
            is SkirConversionResult.Success -> {
                result.value
            }

            is SkirConversionResult.Failure -> {
                val diagnostic = result.diagnostics.first()
                throw OperationConversionFailure(diagnostic.copy(path = path.toList() + diagnostic.path))
            }
        }

    fun fail(message: String): Nothing = throw OperationConversionFailure(SkirConversionDiagnostic(path.toList(), message))

    fun requireText(
        value: String,
        label: String,
    ): String {
        if (value.isBlank()) fail("$label must not be blank.")
        return value
    }
}

private class OperationConversionFailure(
    val diagnostic: SkirConversionDiagnostic,
) : RuntimeException(diagnostic.toString())
