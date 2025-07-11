package com.typewritermc.engine.paper.loader.serializers

import com.typewritermc.engine.paper.utils.CronExpression
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.DataSerializer.Companion.toDataSerializer
import com.typewritermc.core.serialization.xmap
import kotlinx.serialization.builtins.serializer

object CronExpressionSerializer : DataSerializer<CronExpression> by String.serializer().xmap(
    { expression },
    { CronExpression.createDynamic(this) }
).toDataSerializer()

// CronExpression.createDynamic