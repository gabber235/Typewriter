package com.typewritermc.setup

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.library.Book
import com.typewritermc.library.Tag
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.library.tag
import com.typewritermc.library.taxonomy
import com.typewritermc.testkit.rejectionOf
import com.typewritermc.types.Ref
import com.typewritermc.types.Resource
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.arbitrary.element
import io.kotest.property.arbitrary.list
import io.kotest.property.arbitrary.map
import io.kotest.property.checkAll
import java.util.UUID

/** The ids that [value] holds after construction turned its handles into refs, read from a book's tag field. */
internal fun Any.toRefsOf(): List<String> {
    val part = setup("a") { library { books.book("x") { } } }.parts.single()
    val constructed = part.copy(type = Holder::class, ownerField = null, assigned = mapOf("value" to this)).construct() as Holder
    return when (val held = constructed.value) {
        is List<*> -> held.map { (it as Ref<*, *>).target.value }
        is Map<*, *> -> held.values.map { (it as Ref<*, *>).target.value }
        else -> error("Unexpected $held")
    }
}

/** A resource that holds any value, to observe what construction does to a handle nested in a collection. */
internal data class Holder(
    val value: Any,
) : Resource

internal fun tagPart(placement: GraphPlacement?): SetupPart =
    setup("a") { taxonomy { tags.tag("x") } }
        .parts
        .single()
        .copy(placement = placement)

internal fun constructionFailure(part: SetupPart): String? = shouldThrow<IllegalStateException> { part.construct() }.message
