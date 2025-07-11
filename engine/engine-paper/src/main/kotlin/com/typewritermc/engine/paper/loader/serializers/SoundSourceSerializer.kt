package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.*
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.utils.EmitterSoundSource
import com.typewritermc.engine.paper.utils.LocationSoundSource
import com.typewritermc.engine.paper.utils.SelfSoundSource
import com.typewritermc.engine.paper.utils.SoundSource
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.DataSerializer.Companion.toDataSerializer
import java.lang.reflect.Type

class SoundSourceSerializer : DataSerializer<SoundSource> by SoundSource.serializer().toDataSerializer()