package com.typewritermc.engine.paper.loader.serializers

import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.DataSerializer.Companion.toDataSerializer
import com.typewritermc.core.utils.Generic

class GenericSerializer : DataSerializer<Generic> by Generic.serializer().toDataSerializer()