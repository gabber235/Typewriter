package com.typewritermc.types

import com.typewritermc.authoring.CompilationUnit
import com.typewritermc.authoring.GraphLayout
import com.typewritermc.elements.Entry
import com.typewritermc.elements.Keyframe
import com.typewritermc.elements.Segment
import com.typewritermc.events.CancelableEvent
import com.typewritermc.events.Event

@TypewriterTypeImports(
    Color::class,
    CompilationUnit::class,
    Entry::class,
    Event::class,
    CancelableEvent::class,
    GraphLayout::class,
    Icon::class,
    Icon.Iconify::class,
    Icon.Svg::class,
    ResourceId::class,
    Keyframe::class,
    Segment::class,
)
internal object FrameworkTypeImports
