package com.typewritermc.realm.authoring

import skirout.editor.v1.authoring_facts.EditExpectation

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
