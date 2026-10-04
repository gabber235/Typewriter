package com.typewritermc.authoring.skir

import com.typewritermc.authoring.BatchId
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.ConnectIntent
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InitializationRequestId
import com.typewritermc.authoring.InputConflict
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PreparedCreation
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.SnapshotId
import com.typewritermc.types.DataValue
import com.typewritermc.types.ListItem
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
import skirout.editor.v1.authoring.InputConflict as SkirInputConflict
import skirout.editor.v1.authoring.NewCounterpartChoice as SkirNewCounterpartChoice
import skirout.editor.v1.authoring.PreparedEdit as SkirPreparedEdit
import skirout.editor.v1.catalog.InitializationRequest as SkirInitializationRequest
import skirout.editor.v1.catalog.PreparedCreation as SkirPreparedCreation
import skirout.editor.v1.diagnostic.ValueProblem as SkirValueProblem
import skirout.editor.v1.type_catalog.BatchId as SkirBatchId
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.DataValue as SkirDataValue
import skirout.editor.v1.type_catalog.FieldValue as SkirFieldValue
import skirout.editor.v1.type_catalog.InitializationRequestId as SkirInitializationRequestId
import skirout.editor.v1.type_catalog.InputToken as SkirInputToken
import skirout.editor.v1.type_catalog.ItemId as SkirItemId
import skirout.editor.v1.type_catalog.ListItem as SkirListItem
import skirout.editor.v1.type_catalog.NamedTypeUse as SkirNamedTypeUse
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId
import skirout.editor.v1.type_catalog.SnapshotId as SkirSnapshotId
import skirout.editor.v1.type_catalog.TypeUse as SkirTypeUse

object SkirAuthoringOperationCodec {
    fun encode(value: PreparedEdit): SkirConversionResult<SkirPreparedEdit> = captureOperationConversion { encodePreparedEdit(value) }

    fun decode(value: SkirPreparedEdit): SkirConversionResult<PreparedEdit> = captureOperationConversion { decodePreparedEdit(value) }

    fun encode(value: CommitResult): SkirConversionResult<SkirCommitResult> = captureOperationConversion { encodeCommitResult(value) }

    fun encode(value: InitializationRequest): SkirConversionResult<SkirInitializationRequest> =
        captureOperationConversion { encodeInitializationRequest(value) }

    fun decode(value: SkirInitializationRequest): SkirConversionResult<InitializationRequest> =
        captureOperationConversion { decodeInitializationRequest(value) }

    fun encode(value: PreparedCreation): SkirConversionResult<SkirPreparedCreation> =
        captureOperationConversion { encodePreparedCreation(value) }

    fun decode(value: SkirPreparedCreation): SkirConversionResult<PreparedCreation> =
        captureOperationConversion { decodePreparedCreation(value) }
}

private fun OperationConversionScope.encodePreparedEdit(value: PreparedEdit): SkirPreparedEdit =
    SkirPreparedEdit(
        id = SkirBatchId(value = value.id.value),
        catalog = SkirCatalogGeneration(value = value.catalog.value),
        snapshot = SkirSnapshotId(value = value.snapshot.value),
        observations =
            value.observations.mapIndexed {
                index,
                observation,
                ->
                at("observation $index") { convert(SkirAuthoringValueCodec.encode(observation)) }
            },
        intents = value.intents.mapIndexed { index, intent -> at("intent $index") { encodeIntent(intent) } },
    )

private fun OperationConversionScope.decodePreparedEdit(value: SkirPreparedEdit): PreparedEdit =
    PreparedEdit(
        id = BatchId(requireText(value.id.value, "Batch identity")),
        catalog = CatalogGeneration(requireText(value.catalog.value, "Catalog generation")),
        snapshot = SnapshotId(requireText(value.snapshot.value, "Snapshot identity")),
        observations =
            value.observations.mapIndexed {
                index,
                observation,
                ->
                at("observation $index") { convert(SkirAuthoringValueCodec.decode(observation)) }
            },
        intents = value.intents.mapIndexed { index, intent -> at("intent $index") { decodeIntent(intent) } },
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
                            prepared = encodePreparedCreation(counterpart.prepared),
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
                        prepared = decodePreparedCreation(counterpart.value.prepared),
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
        is CommitResult.Committed -> {
            SkirCommitResult.createCommitted(
                snapshot = SkirSnapshotId(value = value.snapshot.value),
                changed = value.changed.map { convert(SkirAuthoringValueCodec.encode(it)) },
            )
        }

        is CommitResult.Conflict -> {
            SkirCommitResult.ConflictWrapper(
                value.inputs.map { conflict ->
                    SkirInputConflict(
                        input = convert(SkirAuthoringValueCodec.encode(conflict.input)),
                        expected = SkirInputToken(value = conflict.expected.value),
                        actual = conflict.actual?.let { SkirInputToken(value = it.value) },
                    )
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
        id = SkirInitializationRequestId(value = value.id.value),
        catalog = SkirCatalogGeneration(value = value.catalog.value),
        type = convert(SkirAuthoringValueCodec.encode(value.type)),
        supplied =
            value.supplied.toSortedMap().map { (name, supplied) ->
                SkirFieldValue(name = name, value = at(name) { convert(SkirDataValueCodec.encode(supplied)) })
            },
        intentHash = value.intentHash,
    )

private fun OperationConversionScope.decodeInitializationRequest(value: SkirInitializationRequest): InitializationRequest =
    InitializationRequest(
        id = InitializationRequestId(requireText(value.id.value, "Initialization request identity")),
        catalog = CatalogGeneration(requireText(value.catalog.value, "Catalog generation")),
        type = convert(SkirAuthoringValueCodec.decode(value.type)),
        supplied =
            value.supplied.associate { supplied ->
                supplied.name to
                    at(supplied.name) { convert(SkirDataValueCodec.decode(supplied.value)) }
            },
        intentHash = value.intentHash,
    )

private fun OperationConversionScope.encodePreparedCreation(value: PreparedCreation): SkirPreparedCreation =
    SkirPreparedCreation(
        record = convert(SkirAuthoringValueCodec.encode(value.record)),
        findings =
            value.findings.mapIndexed {
                index,
                finding,
                ->
                at("finding $index") { convert(SkirAuthoringValueCodec.encode(finding)) }
            },
    )

private fun OperationConversionScope.decodePreparedCreation(value: SkirPreparedCreation): PreparedCreation =
    PreparedCreation(
        record = convert(SkirAuthoringValueCodec.decode(value.record)),
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
