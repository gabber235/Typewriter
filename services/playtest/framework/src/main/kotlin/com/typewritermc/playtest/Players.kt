package com.typewritermc.playtest

import skirout.harness.v1.wire.PlayerClaim

/** How many of the pool's players a requirement claims: a count, or every player the pool holds. */
object Players {
    /** [count] players, at least 1. */
    fun count(count: Int): PlayerClaim = PlayerClaim.CountWrapper(count)

    /** Every player the pool holds, however many it runs. */
    val wholePool: PlayerClaim = PlayerClaim.WHOLE_POOL
}
