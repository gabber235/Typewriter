package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.utils.Generic
import com.typewritermc.engine.paper.entry.entries.*
import java.lang.reflect.ParameterizedType
import java.lang.reflect.Type

class VarSerializer : DataSerializer<Var<*>> {
    override val type: Class<*> = Var::class.java

    override fun serialize(src: Var<*>, typeOfSrc: Type, context: JsonSerializationContext): JsonElement {
        when (src) {
            is ConstVar<*> -> return context.serialize(src.value)
            is BackedVar<*> -> {
                val obj = JsonObject()
                obj.addProperty("_kind", "backed")
                obj.add("ref", context.serialize(src.ref))
                obj.add("data", context.serialize(src.data))
                return obj
            }

            is MappedVar<*> -> {
                throw IllegalStateException("Could not serialize mapped var")
            }

            is ComputeVar<*> -> {
                throw IllegalStateException("Could not serialize compute var")
            }
        }
    }

    override fun deserialize(json: JsonElement, typeOfT: Type, context: JsonDeserializationContext): Var<*>? {
        val actualType = (typeOfT as? ParameterizedType)?.actualTypeArguments?.get(0)
            ?: throw IllegalArgumentException("Could not find actual type for Var")

        if (actualType !is Class<*>) {
            throw IllegalArgumentException("Actual type for Var must be a class but was ${actualType::class.qualifiedName}")
        }


        if (!json.isJsonObject) {
            val value: Any = context.deserialize(json, actualType) ?: return null
            return ConstVar(value)
        }
        val obj = json.asJsonObject
        if (!obj.has("_kind") || obj.get("_kind").asString != "backed") {
            val value: Any = context.deserialize(json, actualType) ?: return null
            return ConstVar(value)
        }

        val refId = obj.getAsJsonPrimitive("ref").asString
        val data = obj.get("data")
        val ref = Ref(refId, VariableEntry::class)
        return BackedVar(ref, Generic(data), actualType.kotlin)
    }
}