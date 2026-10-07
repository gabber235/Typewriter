package com.typewritermc.realm.checking

import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.InputIdentity
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT

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
        is EditExpectation.Value -> {
            setOf(InputIdentity.Value(at))
        }

        is EditExpectation.Configuration -> {
            setOf(InputIdentity.Form(at))
        }

        is EditExpectation.ResourceExists -> {
            setOf(InputIdentity.Existence(id))
        }

        is EditExpectation.Resource -> {
            setOf(
                InputIdentity.Existence(id),
                InputIdentity.Form(ValueLocation(id, ValuePath())),
                InputIdentity.Value(ValueLocation(id, ValuePath())),
            )
        }

        is EditExpectation.ResourceIds -> {
            setOf(RESOURCE_SELECTION_INPUT)
        }

        is EditExpectation.Links -> {
            setOf(InputIdentity.Incoming(resource, contract))
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
