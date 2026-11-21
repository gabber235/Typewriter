package com.typewritermc.visibility.entry.rule

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.priority
import com.typewritermc.core.entries.PriorityEntry
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.AudienceFilterEntry
import com.typewritermc.engine.paper.entry.entries.PassThroughFilter
import com.typewritermc.visibility.entry.effect.VisibilityEffectEntry
import com.typewritermc.visibility.rule.StandardVisibilityRuler
import com.typewritermc.visibility.rule.VisibilityRuler
import com.typewritermc.visibility.selector.AudienceTargetSelector
import com.typewritermc.visibility.selector.AudienceViewerSelector
import com.typewritermc.visibility.selector.TargetSelector
import java.util.Optional

@Entry(
    "audience_visibility_rule",
    "Visibility rule where the audience members are the viewers",
    Colors.PURPLE,
    "mdi:eye-check"
)
/**
 * The `Audience Visibility Rule` is a visibility rule that takes its viewers from the audience
 * it is part of.
 *
 * Players in this audience see the selected targets with the referenced effect. Children of this
 * entry behave like a normal audience and are shown to all audience members.
 *
 * ## How could this be used?
 * Give players that unlocked spirit sight a glow effect on hidden spirit players, by putting
 * this entry under the audience that grants spirit sight.
 */
class AudienceVisibilityRuleEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    @Help("Selects the players the effect applies to (who is being seen).")
    val targets: TargetSelector = AudienceTargetSelector(),
    @Help("The effect applied to a target when this rule wins for a viewer and target pair.")
    val effect: Ref<VisibilityEffectEntry> = emptyRef(),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : AudienceFilterEntry, VisibilityRuleProvider, PriorityEntry {
    override suspend fun display(): AudienceFilter = PassThroughFilter(ref())

    override fun createRuler(): VisibilityRuler = StandardVisibilityRuler(
        viewers = AudienceViewerSelector(ref()),
        targets = targets,
        priority = priority,
        entryId = id,
        effect = effect,
    )
}
