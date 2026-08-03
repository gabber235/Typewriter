package com.typewritermc.realm.repository.utils

import skirout.library.v1.page.PageType

internal fun PageType.databaseValue(): String =
    when (this) {
        PageType.SEQUENCE -> "sequence"
        PageType.STATIC -> "static"
        PageType.SCENE -> "scene"
        PageType.MANIFEST -> "manifest"
        is PageType.Unknown -> error("Unknown page type")
    }

internal fun String.toPageType(): PageType =
    when (this) {
        "sequence" -> PageType.SEQUENCE
        "static" -> PageType.STATIC
        "scene" -> PageType.SCENE
        "manifest" -> PageType.MANIFEST
        else -> error("Unknown stored page type: $this")
    }
