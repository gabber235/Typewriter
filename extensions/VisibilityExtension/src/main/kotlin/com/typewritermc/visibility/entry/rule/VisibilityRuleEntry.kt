package com.typewritermc.visibility.entry.rule

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.priority
import com.typewritermc.core.entries.PriorityEntry
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.visibility.entry.effect.VisibilityEffectEntry
import com.typewritermc.visibility.rule.StandardVisibilityRuler
import com.typewritermc.visibility.rule.VisibilityRuler
import com.typewritermc.visibility.selector.AudienceViewerSelector
import com.typewritermc.visibility.selector.AudienceTargetSelector
import com.typewritermc.visibility.selector.TargetSelector
import com.typewritermc.visibility.selector.ViewerSelector
import java.util.Optional

@Entry(
    "visibility_rule",
    "Change how selected players are rendered to selected viewers",
    Colors.PURPLE,
    "mdi:eye-settings"
)
/**
 * The `Visibility Rule` changes how target players are rendered to viewer players.
 *
 * Viewers are the players whose view changes, targets are the players that look different.
 * Whenever a viewer and target combination matches this rule, the referenced effect is applied,
 * unless a rule with a higher priority already affects that combination. The rule's priority
 * comes from its page and can be overridden per entry.
 *
 * ## How could this be used?
 * Hide vanished staff from everyone, make quest givers glow for players on the quest, or show
 * party members through walls with a glow effect.
 */
class VisibilityRuleEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Selects the players that will see the effect (who is viewing).")
    val viewers: ViewerSelector = AudienceViewerSelector(),
    @Help("Selects the players the effect applies to (who is being seen).")
    val targets: TargetSelector = AudienceTargetSelector(),
    @Help("The effect applied to a target when this rule wins for a viewer and target pair.")
    val effect: Ref<VisibilityEffectEntry> = emptyRef(),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : VisibilityRuleProvider, PriorityEntry {
    override fun createRuler(): VisibilityRuler = StandardVisibilityRuler(
        viewers = viewers,
        targets = targets,
        priority = priority,
        entryId = id,
        effect = effect,
    )
}
