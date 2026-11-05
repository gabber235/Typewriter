package com.typewritermc.realm.operation

import com.typewritermc.authoring.GraphPlacement

internal fun GraphPlacement.intersectsWithGap(other: GraphPlacement): Boolean =
    x.toLong() < other.x.toLong() + other.width + 1 && x.toLong() + width + 1 > other.x &&
        y.toLong() < other.y.toLong() + other.height + 1 && y.toLong() + height + 1 > other.y
