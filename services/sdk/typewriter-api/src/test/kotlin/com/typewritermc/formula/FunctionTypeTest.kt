package com.typewritermc.formula

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.testkit.ready
import com.typewritermc.types.MAX_TYPE_DEPTH
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.integer
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.type_catalog.DataValue

val FunctionTypeTest by testSuite {
    val levelToInt = function("level" to int, result = int)

    test("a function type's stored form is a Formula record") {
        formulaCatalog
            .ready(levelToInt)
            .schema.fields
            .map { it.key } shouldBe listOf("source", "references")
    }

    test("a Formula value is admitted where a function type is expected") {
        formulaCatalog.ready(levelToInt).complete(formulaValue("level * 2")).shouldBeInstanceOf<CompletenessResult.Complete>()
    }

    test("a plain number is refused where a function type is expected") {
        val result = formulaCatalog.ready(levelToInt).complete(DataValue.integer(5))
        result.shouldBeInstanceOf<CompletenessResult.Invalid>().problems.map { it.code } shouldContain "expected_named"
    }

    test("function types with different parameter names are different types") {
        formulaCatalog.isReadableAs(levelToInt, function("rank" to int, result = int)) shouldBe false
        formulaCatalog.isReadableAs(levelToInt, function("level" to int, result = int)) shouldBe true
    }

    test("a function type resolves inside a generic argument") {
        formulaCatalog.resolve(listUse(levelToInt)).shouldBeInstanceOf<Resolution.Ready<*>>()
    }

    test("a function type deeper than the depth limit is refused") {
        val resolution = formulaCatalog.resolve(nestedFunctions(depth = MAX_TYPE_DEPTH + 1))
        resolution.shouldBeInstanceOf<Resolution.Invalid>().diagnostics.map { it.code } shouldContain "type_depth_limit"
    }
}
