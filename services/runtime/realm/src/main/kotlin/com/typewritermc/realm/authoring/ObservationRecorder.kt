package com.typewritermc.realm.authoring

import com.typewritermc.checking.InputIdentity
import com.typewritermc.types.catalog.DerivedOrigin

/** The one seam between a read and what it means: a reader reports each fact it read here. */
internal interface ObservationRecorder {
    fun observe(identity: InputIdentity)

    /** Where a graph read over [reads] reads a node: judged here from the reader's own view. */
    fun graphLinks(reads: CapturedAuthoringReads): GraphLinks =
        GraphLinks { resource, selection -> reads.linksAt(resource, reads.judge(resource, reads.view.linkSlice(resource)), selection) }

    /** What the binds of [reads]' catalog compute. */
    fun derivedTypes(reads: CapturedAuthoringReads): DerivedOrigin
}

/** Keeps every fact a reader read, in read order, for a reader outside a query: an edit's guard, a search, a plan. */
internal class DefaultObservationRecorder : ObservationRecorder {
    private val observed = linkedSetOf<InputIdentity>()

    /** Every fact read so far. */
    val inputs: Set<InputIdentity> get() = observed

    override fun observe(identity: InputIdentity) {
        observed += identity
    }

    /** What the view's binds compute: each runs once per view state, and what it read is evidence for this recorder too. */
    override fun derivedTypes(reads: CapturedAuthoringReads): DerivedOrigin =
        DerivedOrigin { owner, key ->
            reads.view.binds
                .answer(owner, key)
                .also { it.inputs.forEach(::observe) }
                .target
        }
}
