package com.typewritermc.engine.runtime

import com.typewritermc.engine.runtime.testing.GraphRejection
import com.typewritermc.engine.runtime.testing.OTHER
import com.typewritermc.engine.runtime.testing.PAGE
import com.typewritermc.engine.runtime.testing.assemble
import com.typewritermc.engine.runtime.testing.edge
import com.typewritermc.engine.runtime.testing.facts
import com.typewritermc.engine.runtime.testing.resource
import com.typewritermc.types.qualified
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldStartWith
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.TypeDefinitionId

val CompiledResourceGraphTest by testSuite {
    val unknownType = TypeDefinitionId.qualified("test", "unknown")

    test("a complete publication hydrates every resource through its native binding") {
        val graph = assemble(listOf(facts(resource(PAGE))))

        graph.resources shouldBe mapOf(PAGE to "hydrated value")
    }

    listOf(
        GraphRejection(
            "its root is missing from its shard",
            listOf(facts(resource(OTHER))),
            "Compiled Page root is absent from its shard.",
        ),
        GraphRejection(
            "a resource key appears in two shards",
            listOf(facts(resource(PAGE)), facts(resource(PAGE))),
            "Compiled resource $PAGE appears in more than one shard.",
        ),
        GraphRejection(
            "an edge names a relation the runtime catalog does not declare",
            listOf(facts(resource(PAGE), edges = listOf(edge(RelationId(value = "test.unknown"))))),
            "Compiled edge uses unknown relation test.unknown.",
        ),
        GraphRejection(
            "a resource type is unknown to the runtime catalog",
            listOf(facts(resource(PAGE, type = unknownType))),
            "Compiled resource $PAGE has an unresolved actual type",
        ),
        GraphRejection(
            "a resource is unfinished",
            listOf(facts(resource(PAGE, payload = DataValue.UNFILLED))),
            "Compiled resource $PAGE is unfinished",
        ),
        GraphRejection(
            "a resource value does not fit its type",
            listOf(facts(resource(PAGE, payload = DataValue.BooleanWrapper(true)))),
            "Compiled resource $PAGE is invalid",
        ),
        GraphRejection(
            "a resource was compiled by another binding provider",
            listOf(facts(resource(PAGE, provider = NativeBindingId(value = "replaced")))),
            "Compiled resource $PAGE uses a different native binding implementation.",
        ),
        GraphRejection(
            "a resource was compiled by another binding signature",
            listOf(facts(resource(PAGE, signature = "test:v2"))),
            "Compiled resource $PAGE uses a different native binding implementation.",
        ),
    ).forEach { (name, facts, reason) ->
        test("a publication is refused when $name") {
            shouldThrow<RuntimeException> { assemble(facts) }.message.orEmpty() shouldStartWith reason
        }
    }
}
