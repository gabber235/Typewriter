package com.typewritermc.codegen

import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.MemberName
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldBeEmpty

/** Every typewriter-api name generated code references must exist on the api classpath. */
val TypewriterApiTest by testSuite {
    test("every referenced api class exists") {
        val missing =
            names(ClassName::class.java)
                .filterNot { name -> runCatching { Class.forName(name.reflectionName()) }.isSuccess || name.isTypeAlias() }
        withClue("Missing api classes") { missing.shouldBeEmpty() }
    }

    test("every library expression scope has the factory generated code references beside it") {
        val missing =
            names(ClassName::class.java)
                .filter { it.simpleName.endsWith("Expressions") }
                .map { it.peerClass(it.simpleName + "Factory") }
                .filterNot { name -> runCatching { Class.forName(name.reflectionName()) }.isSuccess }
        withClue("Missing expression factories") { missing.shouldBeEmpty() }
    }

    test("every referenced api function and enum entry exists") {
        val functions =
            names(MemberName::class.java).filterNot { member ->
                when (val enclosing = member.enclosingClassName) {
                    null -> packageFunctions(member.packageName).contains(member.simpleName)
                    else -> Class.forName(enclosing.reflectionName()).fields.any { it.name == member.simpleName }
                }
            }
        withClue("Missing api functions") { functions.shouldBeEmpty() }
    }
}
