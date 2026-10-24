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
            names<ClassName>()
                .filterNot { name -> runCatching { Class.forName(name.reflectionName()) }.isSuccess || name.isTypeAlias() }
        withClue("Missing api classes") { missing.shouldBeEmpty() }
    }

    test("every library expression scope has the factory generated code references beside it") {
        val missing =
            names<ClassName>()
                .filter { it.simpleName.endsWith("Expressions") }
                .map { it.peerClass(it.simpleName + "Factory") }
                .filterNot { name -> runCatching { Class.forName(name.reflectionName()) }.isSuccess }
        withClue("Missing expression factories") { missing.shouldBeEmpty() }
    }

    test("every referenced api function and enum entry exists") {
        val functions =
            names<MemberName>().filterNot { member ->
                when (val enclosing = member.enclosingClassName) {
                    null -> packageFunctions(member.packageName).contains(member.simpleName)
                    else -> Class.forName(enclosing.reflectionName()).fields.any { it.name == member.simpleName }
                }
            }
        withClue("Missing api functions") { functions.shouldBeEmpty() }
    }
}

private inline fun <reified T> names(): List<T> =
    TypewriterApi::class.java.declaredFields
        .filter { T::class.java.isAssignableFrom(it.type) }
        .map { field ->
            field.isAccessible = true
            field.get(TypewriterApi) as T
        }

/** `Configuration` is a typealias, so it has no class; it is checked through its expansion's use in generated code. */
private fun ClassName.isTypeAlias(): Boolean = canonicalName in TYPE_ALIASES

private val TYPE_ALIASES = setOf("com.typewritermc.configuration.Configuration")

/** Top level and extension function names of every file facade in [packageName] on the api classpath. */
private fun packageFunctions(packageName: String): Set<String> {
    val loader = requireNotNull(TypewriterApi::class.java.classLoader)
    val path = packageName.replace('.', '/')
    return loader
        .getResources(path)
        .toList()
        .flatMap { url ->
            when (url.protocol) {
                "jar" -> {
                    val jar = (url.openConnection() as java.net.JarURLConnection).jarFile
                    jar
                        .entries()
                        .toList()
                        .map { it.name }
                        .filter {
                            it.startsWith("$path/") &&
                                it.removePrefix("$path/").let { name -> '/' !in name && name.endsWith("Kt.class") }
                        }
                }

                "file" -> {
                    java.io
                        .File(url.toURI())
                        .listFiles()
                        .orEmpty()
                        .map { "$path/${it.name}" }
                        .filter { it.endsWith("Kt.class") }
                }

                else -> {
                    emptyList()
                }
            }
        }.flatMap { entry ->
            val facade = Class.forName(entry.removeSuffix(".class").replace('/', '.'), false, loader)
            facade.declaredMethods.map { it.name.substringBefore('-') }
        }.toSet()
}
