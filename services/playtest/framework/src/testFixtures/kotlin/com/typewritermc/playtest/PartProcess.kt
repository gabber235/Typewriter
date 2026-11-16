package com.typewritermc.playtest

import com.typewritermc.playtest.wire.PartFile
import kotlin.jvm.optionals.getOrNull

/**
 * The process of the game part whose folder in the pool folder is [folder] (`paper`, an own Paper's
 * name, `client-<player>`), from the part file the pool writes there at every boot; null while no
 * process of that boot runs.
 */
internal fun partProcess(folder: String): ProcessHandle? =
    PartFile
        .read(
            PlaytestSettings
                .fromSystemProperties()
                .poolDir
                .resolve(folder)
                .resolve(PartFile.NAME),
        ).flatMap(PartFile::running)
        .getOrNull()
