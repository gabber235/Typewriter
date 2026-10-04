package com.typewritermc.elements

import com.typewritermc.authoring.Placement
import com.typewritermc.authoring.TimelineCuePlacement
import com.typewritermc.authoring.TimelineKeyframePlacement
import com.typewritermc.authoring.TimelineSegmentPlacement
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterRecordContract
import kotlin.reflect.KClass

/** Base contract for authored instances that can be referenced by other content. */
@TypewriterRecordContract
interface Element : Resource {
    val name: String
    val placement: Placement
}

/** An element that can occupy an entry role. */
interface Entry : Element

/** An authored timeline cue. */
@TypewriterRecordContract
interface Cue : Resource {
    val placement: TimelineCuePlacement
}

/** A cue spanning a frame interval. */
interface Segment : Cue {
    override val placement: TimelineSegmentPlacement
}

/** A cue placed at one frame. */
interface Keyframe : Cue {
    override val placement: TimelineKeyframePlacement
}

/** Attaches execution behavior to a declared Element type. */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterElementFacet(
    val element: KClass<out Element>,
)
