package com.typewritermc.basic.entries.audience

import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.spyk
import org.bukkit.entity.Player
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module

/**
 * The display with [players] in its audience, ready for its handlers to be called directly.
 *
 * [AudienceDisplay.addPlayer] initializes the display on its first player, and initializing
 * registers it with the running server through the `plugin` global, which no test has. The spy
 * keeps every real behavior, membership included, and skips only that registration.
 */
internal inline fun <reified D : AudienceDisplay> D.activeWith(vararg players: Player): D {
    val display = spyk(this)
    every { display.initialize() } just Runs
    every { display.dispose() } just Runs
    players.forEach { display.addPlayer(it) }
    return display
}

/**
 * A bare `Var.get` call resolves an interaction context through Koin even for a `ConstVar` whose
 * value never depends on it, so every spec that reads a `Var` needs this bootstrap.
 */
internal fun startAudienceKoin() {
    startKoin {
        modules(module { single { mockk<PlayerSessionManager>(relaxed = true) } })
    }
}

internal fun stopAudienceKoin() = stopKoin()
