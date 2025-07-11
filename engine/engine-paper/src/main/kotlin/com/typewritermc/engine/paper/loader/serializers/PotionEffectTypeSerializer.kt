package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.DataSerializer.Companion.toDataSerializer
import com.typewritermc.core.serialization.xmap
import kotlinx.serialization.builtins.serializer
import net.kyori.adventure.key.Key
import org.bukkit.Registry
import org.bukkit.potion.PotionEffectType
import java.lang.reflect.Type

class PotionEffectTypeSerializer : DataSerializer<PotionEffectType>
    by String.serializer().xmap<String, PotionEffectType>({ key.asString() }, { Registry.EFFECT.get(Key.key(this)) }).toDataSerializer()