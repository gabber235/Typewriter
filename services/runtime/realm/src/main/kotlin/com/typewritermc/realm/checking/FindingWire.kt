package com.typewritermc.realm.checking

import com.typewritermc.checking.CheckOutcome
import com.typewritermc.checking.FindingStatus
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.checking.CheckInstanceId as SkirCheckInstanceId
import skirout.editor.v1.checking.CheckOutcome as SkirCheckOutcome
import skirout.editor.v1.checking.CheckTicket as SkirCheckTicket
import skirout.editor.v1.checking.FindingSet as SkirFindingSet
import skirout.editor.v1.checking.FindingStatus as SkirFindingStatus
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.CheckExecutionId as SkirCheckExecutionId
import skirout.editor.v1.type_catalog.SnapshotId as SkirSnapshotId

internal fun FindingSet.toWire(): SkirFindingSet =
    SkirFindingSet(
        ticket =
            SkirCheckTicket(
                instance =
                    SkirCheckInstanceId(
                        rule = SkirTypeCodec.encode(ticket.instance.rule).getOrThrow(),
                        location = SkirAuthoringValueCodec.encode(ticket.instance.location).getOrThrow(),
                    ),
                incarnation = ticket.incarnation,
                execution = SkirCheckExecutionId(value = ticket.execution.value),
                snapshot = SkirSnapshotId(value = ticket.snapshot.value),
                catalog = SkirCatalogGeneration(value = ticket.catalog.value),
            ),
        observations = observations.map { SkirAuthoringValueCodec.encode(it).getOrThrow() },
        outcome = outcome.toWire(),
        findings = findings.map { SkirTypeCodec.encode(it).getOrThrow() },
        status =
            when (status) {
                FindingStatus.Current -> SkirFindingStatus.CURRENT
                FindingStatus.Outdated -> SkirFindingStatus.OUTDATED
            },
    )

private fun CheckOutcome.toWire(): SkirCheckOutcome =
    when (this) {
        CheckOutcome.Finished -> {
            SkirCheckOutcome.FINISHED
        }

        is CheckOutcome.NeedsInput -> {
            SkirCheckOutcome.NeedsInputWrapper(locations.map { SkirAuthoringValueCodec.encode(it).getOrThrow() })
        }

        is CheckOutcome.Failed -> {
            SkirCheckOutcome.FailedWrapper(diagnostics.map { SkirTypeCodec.encode(it).getOrThrow() })
        }

        is CheckOutcome.Incomplete -> {
            SkirCheckOutcome.IncompleteWrapper(reason)
        }
    }
