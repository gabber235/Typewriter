package com.typewritermc.entry

import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.AudienceManager
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.AudienceFilterEntry
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import org.bukkit.entity.Player
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

private class LeafEntry(override val id: String, private val display: AudienceDisplay) : AudienceEntry {
    override val name: String = id
    override suspend fun display(): AudienceDisplay = display
}

private class FilterEntry(
    override val id: String,
    override val children: List<Ref<out AudienceEntry>>,
) : AudienceFilterEntry {
    override val name: String = id
    val filter = SwitchedFilter(Ref(id, FilterEntry::class, this))
    override suspend fun display(): AudienceFilter = filter
}

private class SwitchedFilter(ref: Ref<FilterEntry>) : AudienceFilter(ref) {
    override fun initialize() {}
    override fun dispose() {}
    override fun filter(player: Player): Boolean = true

    fun switch(player: Player, on: Boolean) = player.updateFilter(on)
}

private open class LeafDisplay : AudienceDisplay() {
    override fun initialize() {}
    override fun dispose() {}
    override fun onPlayerAdd(player: Player) {}
    override fun onPlayerRemove(player: Player) {}
}

private class PausingDisplay : LeafDisplay() {
    val removing = CountDownLatch(1)
    val resume = CountDownLatch(1)

    override fun onPlayerRemove(player: Player) {
        removing.countDown()
        resume.await()
    }
}

class AudienceMembershipSpec : FunSpec({
    val manager = AudienceManager()

    beforeSpec { startKoin { modules(module { single { manager } }) } }
    afterSpec { stopKoin() }

    test("a filter switched back on while it is still removing its children keeps all of them") {
        val first = PausingDisplay()
        val second = LeafDisplay()
        val firstEntry = LeafEntry("first", first)
        val secondEntry = LeafEntry("second", second)
        val parent = FilterEntry(
            "parent",
            listOf(Ref("first", AudienceEntry::class, firstEntry), Ref("second", AudienceEntry::class, secondEntry)),
        )
        manager.index(sequenceOf(parent, firstEntry, secondEntry))

        val player = mockk<Player>()
        every { player.uniqueId } returns UUID.randomUUID()
        parent.filter.addPlayer(player)

        val switchOff = thread { parent.filter.switch(player, false) }
        first.removing.await(5, TimeUnit.SECONDS) shouldBe true
        val switchOn = thread { parent.filter.switch(player, true) }
        switchOn.join(200)
        first.resume.countDown()
        switchOff.join(5_000)
        switchOn.join(5_000)

        (player in parent.filter) shouldBe true
        (player in first) shouldBe true
        (player in second) shouldBe true
    }
})
