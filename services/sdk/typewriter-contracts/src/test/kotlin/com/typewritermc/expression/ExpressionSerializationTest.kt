package com.typewritermc.expression

import com.typewritermc.configuration.RuleDescriptor
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.json.Json
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue

@OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
val ExpressionSerializationTest by testSuite {
    test("domain rule serialization retains the generated expression in JSON and CBOR") {
        val rule =
            RuleDescriptor(
                ExpressionNode.createConditional(
                    test = ExpressionNode.LiteralWrapper(DataValue.BooleanWrapper(true)),
                    yes = ExpressionNode.LiteralWrapper(DataValue.StringValueWrapper("accepted")),
                    no = ExpressionNode.LiteralWrapper(DataValue.StringValueWrapper("rejected")),
                ),
            )
        val json = Json.encodeToString(RuleDescriptor.serializer(), rule)
        Json.decodeFromString(RuleDescriptor.serializer(), json) shouldBe rule
        val cbor = Cbor.encodeToByteArray(RuleDescriptor.serializer(), rule)
        Cbor.decodeFromByteArray(RuleDescriptor.serializer(), cbor) shouldBe rule
    }
}
