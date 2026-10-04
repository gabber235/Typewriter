package com.typewritermc.realm.checking

import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputObservation
import com.typewritermc.checking.InputToken

interface ObservationRecorder {
    fun observe(
        identity: InputIdentity,
        token: InputToken,
    )

    fun captured(): List<InputObservation>
}

class DefaultObservationRecorder : ObservationRecorder {
    private val observations = linkedMapOf<InputIdentity, InputToken>()

    override fun observe(
        identity: InputIdentity,
        token: InputToken,
    ) {
        val previous = observations.putIfAbsent(identity, token)
        check(previous == null || previous == token) {
            "One check execution observed two versions of the same authored input."
        }
    }

    override fun captured(): List<InputObservation> = observations.map { (identity, token) -> InputObservation(identity, token) }
}

interface ReverseDependencyIndex {
    fun replace(
        instance: CheckInstanceId,
        observations: List<InputObservation>,
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
        observations: List<InputObservation>,
    ) = synchronized(lock) {
        retireLocked(instance)
        val inputs = observations.mapTo(linkedSetOf(), InputObservation::identity)
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
