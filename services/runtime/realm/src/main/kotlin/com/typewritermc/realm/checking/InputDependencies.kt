package com.typewritermc.realm.checking

import com.typewritermc.authoring.of
import com.typewritermc.checking.InputIdentity
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.types.toSkir
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.type_catalog.ValueLocation

interface ObservationRecorder {
    fun observe(expectation: EditExpectation)

    fun captured(): List<EditExpectation>
}

class DefaultObservationRecorder : ObservationRecorder {
    private val expectations = linkedSetOf<EditExpectation>()

    override fun observe(expectation: EditExpectation) {
        expectations += expectation
    }

    override fun captured(): List<EditExpectation> = expectations.toList()
}

internal fun EditExpectation.dependencies(): Set<InputIdentity> =
    when (this) {
        is EditExpectation.ValueWrapper -> {
            setOf(InputIdentity.Value(value.at))
        }

        is EditExpectation.ConfigurationWrapper -> {
            setOf(InputIdentity.Form(value.at))
        }

        is EditExpectation.ResourceExistsWrapper -> {
            setOf(InputIdentity.Existence(value.id))
        }

        is EditExpectation.ResourceWrapper -> {
            setOf(
                InputIdentity.Existence(value.id),
                InputIdentity.Form(ValueLocation.of(value.id)),
                InputIdentity.Value(ValueLocation.of(value.id)),
            )
        }

        is EditExpectation.ResourceIdsWrapper -> {
            setOf(RESOURCE_SELECTION_INPUT)
        }

        is EditExpectation.LinksWrapper -> {
            setOf(InputIdentity.Incoming(value.resource, value.contract))
        }

        else -> {
            unknownVariant(this)
        }
    }

interface ReverseDependencyIndex {
    fun replace(
        instance: CheckInstanceId,
        observations: List<EditExpectation>,
    )

    fun affectedBy(changed: Set<InputIdentity>): Set<CheckInstanceId>

    fun retire(instance: CheckInstanceId)
}

class DefaultReverseDependencyIndex : ReverseDependencyIndex {
    private val lock = Any()
    private val byInstance = mutableMapOf<CheckInstanceId, Set<InputIdentity>>()
    private val byInput = mutableMapOf<InputIdentity, MutableSet<CheckInstanceId>>()

    override fun replace(
        instance: CheckInstanceId,
        observations: List<EditExpectation>,
    ) = synchronized(lock) {
        retireLocked(instance)
        val inputs = observations.flatMapTo(linkedSetOf()) { it.dependencies() }
        if (inputs.isEmpty()) return@synchronized
        byInstance[instance] = inputs
        inputs.forEach { input -> byInput.getOrPut(input, ::linkedSetOf).add(instance) }
    }

    override fun affectedBy(changed: Set<InputIdentity>): Set<CheckInstanceId> =
        synchronized(lock) {
            changed.flatMapTo(linkedSetOf()) { byInput[it].orEmpty() }
        }

    override fun retire(instance: CheckInstanceId) =
        synchronized(lock) {
            retireLocked(instance)
        }

    private fun retireLocked(instance: CheckInstanceId) {
        byInstance.remove(instance).orEmpty().forEach { input ->
            val dependents = byInput.getValue(input)
            dependents.remove(instance)
            if (dependents.isEmpty()) byInput.remove(input)
        }
    }
}
