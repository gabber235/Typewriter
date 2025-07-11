package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.*
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.DataSerializer.Companion.toDataSerializer
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import java.lang.reflect.Type

class PositionSerializer : DataSerializer<Position> by