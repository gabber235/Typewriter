package com.typewritermc.presentation

import com.typewritermc.types.ColorDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integerScalar
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeTemplate

// The types of presentation slots, named after the Kotlin type their DSL methods accept.

/** Text slots: labels, messages, placeholders and identifiers. */
internal val TEXT_SLOT: TypeTemplate = ScalarKind.TEXT.template

/** Condition slots. */
internal val BOOLEAN_SLOT: TypeTemplate = ScalarKind.BOOLEAN.template

/** Logical pixel, ratio and other Double slots. */
internal val DOUBLE_SLOT: TypeTemplate = floatScalar(FloatWidth.SIXTY_FOUR).template

/** Count and Int slots. */
internal val INT_SLOT: TypeTemplate = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template

/** Duration slots. */
internal val DURATION_SLOT: TypeTemplate = ScalarKind.DURATION.template

/** Timestamp slots. */
internal val TIMESTAMP_SLOT: TypeTemplate = ScalarKind.TIMESTAMP.template

/** Color slots. */
internal val COLOR_SLOT: TypeTemplate = ColorDefinition.id.template()

/** A list of [item] values. */
internal fun listSlot(item: TypeTemplate): TypeTemplate = StandardTypes.list.template(listOf(item))
