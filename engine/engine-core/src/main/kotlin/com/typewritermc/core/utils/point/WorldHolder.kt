package com.typewritermc.core.utils.point

interface WorldHolder<H : WorldHolder<H>> {
    val world: World

    fun withWorld(world: World): H
}