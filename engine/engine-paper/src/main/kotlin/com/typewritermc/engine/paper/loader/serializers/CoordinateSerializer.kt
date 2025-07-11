package com.typewritermc.engine.paper.loader.serializers

import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.serializer
import com.typewritermc.core.utils.point.Coordinate
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.builtins.serializer

object CoordinateSerializer : DataSerializer<Coordinate> by serializer(
    "x", { x }, Double.serializer().nullable,
    "y", { y }, Double.serializer().nullable,
    "z", { z }, Double.serializer().nullable,
    "yaw", { yaw }, Float.serializer().nullable,
    "pitch", { pitch }, Float.serializer().nullable,
    { x, y, z, yaw, pitch -> Coordinate(x ?: 0.0, y ?: 0.0, z ?: 0.0, yaw ?: 0f, pitch ?: 0f) }
)