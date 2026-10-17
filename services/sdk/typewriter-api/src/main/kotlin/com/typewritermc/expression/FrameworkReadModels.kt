package com.typewritermc.expression

import com.typewritermc.authoring.TypeSelection
import com.typewritermc.types.TypeUse
import com.typewritermc.types.TypewriterReadModels
import com.typewritermc.types.catalog.PublishedType

@TypewriterReadModels(TypeUse::class, TypeSelection::class, PublishedType::class)
internal object FrameworkReadModels
