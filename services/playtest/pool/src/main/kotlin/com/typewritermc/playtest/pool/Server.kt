package com.typewritermc.playtest.pool

/**
 * A Paper the pool runs, in its [folder]: the shared one, or a restart attempt's own. Its [rules] say
 * what the pool does at each thing it hears about it. It keeps its process now, the boot it is in, the
 * cache that boot trains, and when its last boot and kill happened.
 */
internal class Server(
    val folder: PaperFolder,
    val rules: PaperRules,
) {
    val name: String get() = folder.name
    val port: Int get() = folder.port
    var peer: Peer? = null
    var part: Part? = null
    var boots = 0
    var training: AotCache.Boot.Train? = null
    var lost = false
    var killedAt = 0L
    var bootedAt = 0L
}
