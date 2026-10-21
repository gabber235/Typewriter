package com.typewritermc.authoring

import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import skirout.editor.v1.authoring.ConnectIntent
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.type_catalog.ListItem

/*
 * Checks the prepared edits, edit intents and expectations editors and stored findings send where they enter the
 * runtime. Generated Skir constructors cannot enforce these rules, so admission and conflict checks rely on values
 * that passed one of these checks. Each check fails with an IllegalArgumentException naming the rule and returns the
 * canonical form: authored values and records in canonical notation, and the sets of resource ids and links without
 * duplicates in their canonical order.
 */

fun PreparedEdit.requireValid(): PreparedEdit {
    catalog.requireValid()
    return copy(expectations = expectations.map { it.requireValid() }, intents = intents.map { it.requireValid() })
}

fun EditExpectation.requireValid(): EditExpectation =
    when (this) {
        is EditExpectation.ValueWrapper -> {
            value.at.requireValid()
            EditExpectation.createValue(at = value.at, expected = value.expected?.requirePortable())
        }

        is EditExpectation.ResourceWrapper -> {
            value.id.requireValid()
            EditExpectation.createResource(id = value.id, expected = value.expected?.requireValid())
        }

        is EditExpectation.ResourceExistsWrapper -> {
            apply { value.id.requireValid() }
        }

        is EditExpectation.ConfigurationWrapper -> {
            apply {
                value.at.requireValid()
                value.expected?.requireValid()
            }
        }

        is EditExpectation.ResourceIdsWrapper -> {
            EditExpectation.resourceIds(value.onEach { it.requireValid() })
        }

        is EditExpectation.LinksWrapper -> {
            value.resource.requireValid()
            value.contract.requireValid()
            require(value.direction != TraversalDirection.UNKNOWN) { "Unknown traversal direction." }
            EditExpectation.links(value.resource, value.contract, value.direction, value.expected.map { it.requireValid() })
        }

        else -> {
            throw IllegalArgumentException("Unknown edit expectation.")
        }
    }

fun LinkProjection.requireValid(): LinkProjection =
    apply {
        contract.requireValid()
        first.requireValid()
        second.requireValid()
        firstLocation?.requireValid()
        secondLocation?.requireValid()
    }

fun EditIntent.requireValid(): EditIntent =
    when (this) {
        is EditIntent.CreateResourceWrapper -> {
            value.id.requireValid()
            EditIntent.createCreateResource(id = value.id, record = value.record.requireValid())
        }

        is EditIntent.DeleteResourceWrapper -> {
            apply { value.id.requireValid() }
        }

        is EditIntent.SetValueWrapper -> {
            value.at.requireValid()
            EditIntent.createSetValue(at = value.at, value = value.value.requirePortable())
        }

        is EditIntent.InsertWrapper -> {
            value.at.requireValid()
            value.after?.requireValid()
            value.item.id.requireValid()
            EditIntent.createInsert(
                at = value.at,
                after = value.after,
                item = ListItem(id = value.item.id, value = value.item.value.requirePortable()),
            )
        }

        is EditIntent.RemoveWrapper -> {
            apply {
                value.at.requireValid()
                value.item.requireValid()
            }
        }

        is EditIntent.MoveWrapper -> {
            apply {
                value.at.requireValid()
                value.item.requireValid()
                value.after?.requireValid()
            }
        }

        is EditIntent.ConnectRelationWrapper -> {
            EditIntent.ConnectRelationWrapper(value.requireValid())
        }

        is EditIntent.DisconnectRelationWrapper -> {
            apply { value.requireValid() }
        }

        is EditIntent.RetagWrapper -> {
            apply {
                value.at.requireValid()
                value.type.requireValid()
            }
        }

        is EditIntent.ConfigureResourceWrapper -> {
            apply {
                value.resource.requireValid()
                value.configuration.requireValid()
            }
        }

        else -> {
            throw IllegalArgumentException("Unknown edit intent.")
        }
    }

fun ConnectIntent.requireValid(): ConnectIntent {
    source.requireValid()
    target.requireValid()
    return copy(counterpart = counterpart?.requireValid())
}

fun CounterpartChoice.requireValid(): CounterpartChoice =
    when (this) {
        is CounterpartChoice.ExistingWrapper -> {
            apply { value.requireValid() }
        }

        is CounterpartChoice.NewWrapper -> {
            value.containing.requireValid()
            CounterpartChoice.createNew(containing = value.containing, prepared = value.prepared.requireValid())
        }

        else -> {
            throw IllegalArgumentException("Unknown counterpart choice.")
        }
    }
