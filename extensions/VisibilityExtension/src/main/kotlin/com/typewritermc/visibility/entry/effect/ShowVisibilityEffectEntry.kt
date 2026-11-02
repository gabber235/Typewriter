package com.typewritermc.visibility.entry.effect

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.rule.VisibilityRule

@Entry(
    "show_visibility_effect",
    "Renders the target normally, overriding lower priority effects",
    Colors.GREEN,
    "fa6-solid:eye"
)
/**
 * The `Show Visibility Effect` renders the target with the default vanilla appearance.
 *
 * Since only the highest priority rule is active for a viewer and target pair, giving a rule
 * with this effect a higher priority than a hide or disguise rule reveals the target again for
 * the selected viewers.
 *
 * ## How could this be used?
 * Vanished staff are hidden from everyone with a low priority rule, while a higher priority rule
 * with this effect lets other staff members still see them.
 */
class ShowVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
) : VisibilityEffectEntry {
    override fun createEffector(rule: VisibilityRule): VisibilityEffector = ShowVisibilityEffector()
}

private class ShowVisibilityEffector : VisibilityEffector {
    override suspend fun initialize() {}

    override suspend fun dispose() {}
}
