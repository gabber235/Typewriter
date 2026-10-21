package com.typewritermc.authoring.skir

import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.ConnectIntent
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.LinkProjection
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.TraversalDirection
import com.typewritermc.authoring.record
import com.typewritermc.types.ResourceId
import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import com.typewritermc.types.skir.SkirConversionDiagnostic
import com.typewritermc.types.skir.SkirConversionResult
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.authoring.CommitPreparedEditResponse as SkirCommitPreparedEditResponse
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
import skirout.editor.v1.catalog.PreparationTarget as SkirPreparationTarget
import skirout.editor.v1.catalog.PrepareValueResult as SkirPrepareValueResult
import skirout.editor.v1.catalog.PreparedContent as SkirPreparedContent
import skirout.editor.v1.catalog.PreparedValue as SkirPreparedValue
import skirout.editor.v1.catalog.RequiredInput as SkirRequiredInput
import skirout.editor.v1.catalog.ValuePreparationRequest as SkirInitializationRequest
import skirout.editor.v1.diagnostic.ValueProblem as SkirValueProblem
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId

/**
 * Carries initialization continuations, observed edit expectations, ordered intents, and commit outcomes over Skir.
 * Nested value conversion failures retain their traversal path inside the enclosing operation. Conversion preserves
 * proposals and preconditions; continuation validation and edit acceptance still belong to their runtime owners.
 */
object SkirAuthoringOperationCodec {
    fun encode(value: EditExpectation): SkirConversionResult<SkirEditExpectation> = captureOperationConversion { encodeExpectation(value) }

    fun decode(value: SkirEditExpectation): SkirConversionResult<EditExpectation> = captureOperationConversion { decodeExpectation(value) }

    fun encode(value: LinkProjection): SkirConversionResult<SkirLinkProjection> = captureOperationConversion { encodeProjection(value) }

    fun decode(value: SkirLinkProjection): SkirConversionResult<LinkProjection> = captureOperationConversion { decodeProjection(value) }

    fun encode(value: PreparedEdit): SkirConversionResult<SkirPreparedEdit> = captureOperationConversion { encodePreparedEdit(value) }

    fun decode(value: SkirPreparedEdit): SkirConversionResult<PreparedEdit> = captureOperationConversion { decodePreparedEdit(value) }

    fun encode(value: CommitResult): SkirConversionResult<SkirCommitPreparedEditResponse> =
        captureOperationConversion {
            encodeCommitResult(value)
        }
}

private fun OperationConversionScope.encodePreparedEdit(value: PreparedEdit): SkirPreparedEdit =
    SkirPreparedEdit(
        catalog = value.catalog,
        expectations = value.expectations.map { encodeExpectation(it) },
        intents = value.intents.mapIndexed { index, intent -> at("intent $index") { encodeIntent(intent) } },
    )

private fun OperationConversionScope.decodePreparedEdit(value: SkirPreparedEdit): PreparedEdit =
    PreparedEdit(
        catalog = CatalogGeneration(value = requireText(value.catalog.value, "Catalog generation")),
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
                at = value.at,
                expected =
                    value.expected?.let {
                        valid { it.requirePortable() }
                    },
            )
        }

        is EditExpectation.Resource -> {
            SkirEditExpectation.createResource(
                id = SkirResourceId(value = value.id.value),
                expected =
                    value.expected,
            )
        }

        is EditExpectation.ResourceExists -> {
            SkirEditExpectation.createResourceExists(id = SkirResourceId(value = value.id.value), expected = value.expected)
        }

        is EditExpectation.Configuration -> {
            SkirEditExpectation.createConfiguration(
                at = value.at,
                expected =
                    value.expected,
            )
        }

        is EditExpectation.ResourceIds -> {
            SkirEditExpectation.ResourceIdsWrapper(value.expected.sortedBy { it.value }.map { SkirResourceId(value = it.value) })
        }

        is EditExpectation.Links -> {
            SkirEditExpectation.createLinks(
                resource = SkirResourceId(value = value.resource.value),
                contract = value.contract,
                direction =
                    when (value.direction) {
                        TraversalDirection.Forward -> SkirTraversalDirection.FORWARD
                        TraversalDirection.Reverse -> SkirTraversalDirection.REVERSE
                        TraversalDirection.Both -> SkirTraversalDirection.BOTH
                    },
                expected = value.expected.map { encodeProjection(it) }.sortedBy(SkirLinkProjection.serializer::toJsonCode),
            )
        }
    }

private fun OperationConversionScope.decodeExpectation(value: SkirEditExpectation): EditExpectation =
    when (value) {
        is SkirEditExpectation.ValueWrapper -> {
            EditExpectation.Value(
                valid { value.value.at.requireValid() },
                value.value.expected?.let {
                    valid { it.requirePortable() }
                },
            )
        }

        is SkirEditExpectation.ResourceWrapper -> {
            EditExpectation.Resource(
                ResourceId(requireText(value.value.id.value, "Resource identity")),
                value.value.expected?.let {
                    valid { it.requireValid() }
                },
            )
        }

        is SkirEditExpectation.ResourceExistsWrapper -> {
            EditExpectation.ResourceExists(ResourceId(requireText(value.value.id.value, "Resource identity")), value.value.expected)
        }

        is SkirEditExpectation.ConfigurationWrapper -> {
            EditExpectation.Configuration(
                valid { value.value.at.requireValid() },
                value.value.expected?.let {
                    valid { it.requireValid() }
                },
            )
        }

        is SkirEditExpectation.ResourceIdsWrapper -> {
            EditExpectation.ResourceIds(value.value.mapTo(linkedSetOf()) { ResourceId(requireText(it.value, "Resource identity")) })
        }

        is SkirEditExpectation.LinksWrapper -> {
            EditExpectation.Links(
                ResourceId(requireText(value.value.resource.value, "Resource identity")),
                RelationId(value = requireText(value.value.contract.value, "Relation identity")),
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
        contract = value.contract,
        first = SkirResourceId(value = value.first.value),
        second = SkirResourceId(value = value.second.value),
        firstLocation =
            value.firstLocation,
        secondLocation = value.secondLocation,
    )

private fun OperationConversionScope.decodeProjection(value: SkirLinkProjection): LinkProjection =
    LinkProjection(
        RelationId(value = requireText(value.contract.value, "Relation identity")),
        ResourceId(requireText(value.first.value, "Resource identity")),
        ResourceId(requireText(value.second.value, "Resource identity")),
        value.firstLocation?.let {
            valid { it.requireValid() }
        },
        value.secondLocation?.let { valid { it.requireValid() } },
    )

private fun OperationConversionScope.encodeIntent(value: EditIntent): SkirEditIntent =
    when (value) {
        is EditIntent.CreateResource -> {
            SkirEditIntent.createCreateResource(
                id = SkirResourceId(value = value.id.value),
                record = value.record,
            )
        }

        is EditIntent.DeleteResource -> {
            SkirEditIntent.createDeleteResource(id = SkirResourceId(value = value.id.value))
        }

        is EditIntent.SetValue -> {
            SkirEditIntent.createSetValue(
                at = value.at,
                value = valid { value.value.requirePortable() },
            )
        }

        is EditIntent.Insert -> {
            SkirEditIntent.createInsert(
                at = value.at,
                after = value.after,
                item = encodeListItem(value.item),
            )
        }

        is EditIntent.Remove -> {
            SkirEditIntent.createRemove(
                at = value.at,
                item = value.item,
            )
        }

        is EditIntent.Move -> {
            SkirEditIntent.createMove(
                at = value.at,
                item = value.item,
                after = value.after,
            )
        }

        is EditIntent.ConnectRelation -> {
            SkirEditIntent.ConnectRelationWrapper(encodeConnect(value.intent))
        }

        is EditIntent.DisconnectRelation -> {
            SkirEditIntent.DisconnectRelationWrapper(value.occurrence)
        }

        is EditIntent.Retag -> {
            SkirEditIntent.createRetag(
                at = value.at,
                type = value.type,
            )
        }

        is EditIntent.ConfigureResource -> {
            SkirEditIntent.createConfigureResource(
                resource = SkirResourceId(value = value.resource.value),
                configuration = value.configuration,
            )
        }
    }

private fun OperationConversionScope.decodeIntent(value: SkirEditIntent): EditIntent =
    when (value) {
        is SkirEditIntent.CreateResourceWrapper -> {
            EditIntent.CreateResource(
                id = ResourceId(requireText(value.value.id.value, "Resource identity")),
                record = valid { value.value.record.requireValid() },
            )
        }

        is SkirEditIntent.DeleteResourceWrapper -> {
            EditIntent.DeleteResource(ResourceId(requireText(value.value.id.value, "Resource identity")))
        }

        is SkirEditIntent.SetValueWrapper -> {
            EditIntent.SetValue(
                at = valid { value.value.at.requireValid() },
                value = valid { value.value.value.requirePortable() },
            )
        }

        is SkirEditIntent.InsertWrapper -> {
            EditIntent.Insert(
                at = valid { value.value.at.requireValid() },
                after = value.value.after?.let { ItemId(value = requireText(it.value, "Previous item identity")) },
                item = decodeListItem(value.value.item),
            )
        }

        is SkirEditIntent.RemoveWrapper -> {
            EditIntent.Remove(
                at = valid { value.value.at.requireValid() },
                item = ItemId(value = requireText(value.value.item.value, "Item identity")),
            )
        }

        is SkirEditIntent.MoveWrapper -> {
            EditIntent.Move(
                at = valid { value.value.at.requireValid() },
                item = ItemId(value = requireText(value.value.item.value, "Item identity")),
                after = value.value.after?.let { ItemId(value = requireText(it.value, "Previous item identity")) },
            )
        }

        is SkirEditIntent.ConnectRelationWrapper -> {
            EditIntent.ConnectRelation(decodeConnect(value.value))
        }

        is SkirEditIntent.DisconnectRelationWrapper -> {
            EditIntent.DisconnectRelation(valid { value.value.requireValid() })
        }

        is SkirEditIntent.RetagWrapper -> {
            EditIntent.Retag(
                at = valid { value.value.at.requireValid() },
                type = valid { value.value.type.requireValid() },
            )
        }

        is SkirEditIntent.ConfigureResourceWrapper -> {
            EditIntent.ConfigureResource(
                resource = ResourceId(requireText(value.value.resource.value, "Resource identity")),
                configuration = valid { value.value.configuration.requireValid() },
            )
        }

        else -> {
            fail("Unknown Skir edit intent variant.")
        }
    }

private fun OperationConversionScope.encodeConnect(value: ConnectIntent): SkirConnectIntent =
    SkirConnectIntent(
        source = value.source,
        target = SkirResourceId(value = value.target.value),
        counterpart =
            when (val counterpart = value.counterpart) {
                is CounterpartChoice.Existing -> {
                    SkirCounterpartChoice.ExistingWrapper(counterpart.occurrence)
                }

                is CounterpartChoice.New -> {
                    SkirCounterpartChoice.NewWrapper(
                        SkirNewCounterpartChoice(
                            containing = counterpart.containing,
                            prepared = counterpart.prepared,
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
        source = valid { value.source.requireValid() },
        target = ResourceId(requireText(value.target.value, "Target resource identity")),
        counterpart =
            when (val counterpart = value.counterpart) {
                is SkirCounterpartChoice.ExistingWrapper -> {
                    CounterpartChoice.Existing(valid { counterpart.value.requireValid() })
                }

                is SkirCounterpartChoice.NewWrapper -> {
                    CounterpartChoice.New(
                        containing = valid { counterpart.value.containing.requireValid() },
                        prepared = valid { counterpart.value.prepared.requireValid() },
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

private fun OperationConversionScope.encodeCommitResult(value: CommitResult): SkirCommitPreparedEditResponse =
    when (value) {
        CommitResult.Committed -> {
            SkirCommitPreparedEditResponse.COMMITTED
        }

        is CommitResult.Conflict -> {
            SkirCommitPreparedEditResponse.ConflictErrorWrapper(
                value.values.map { conflict ->
                    SkirExpectationConflict(expected = encodeExpectation(conflict.expected), actual = encodeExpectation(conflict.actual))
                },
            )
        }

        is CommitResult.Rejected -> {
            SkirCommitPreparedEditResponse.RejectedErrorWrapper(
                value.problems.map { problem ->
                    SkirValueProblem(
                        location = problem.location,
                        code = problem.code,
                    )
                },
            )
        }

        is CommitResult.CatalogChanged -> {
            SkirCommitPreparedEditResponse.CatalogChangedErrorWrapper(value.actual)
        }
    }

private fun OperationConversionScope.encodeListItem(value: ListItem) =
    ListItem(id = value.id, value = valid { value.value.requirePortable() })

private fun OperationConversionScope.decodeListItem(value: ListItem) =
    ListItem(
        id = ItemId(value = requireText(value.id.value, "Item identity")),
        value = valid { value.value.requirePortable() },
    )

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

    /** Reports a value that fails its boundary check as a conversion failure at the current path. */
    inline fun <Value> valid(check: () -> Value): Value =
        try {
            check()
        } catch (invalid: IllegalArgumentException) {
            fail(invalid.message ?: "Value is invalid.")
        }

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
