package com.typewritermc.codegen

import com.squareup.kotlinpoet.ClassName

fun <T> names(type: Class<T>): List<T> =
    TypewriterApi::class.java.declaredFields
        .filter { type.isAssignableFrom(it.type) }
        .map { field ->
            field.isAccessible = true
            type.cast(field.get(TypewriterApi))
        }

/** `Configuration` is a typealias, so it has no class; it is checked through its expansion's use in generated code. */
fun ClassName.isTypeAlias(): Boolean = canonicalName in TYPE_ALIASES

val TYPE_ALIASES = setOf("com.typewritermc.configuration.Configuration")

/** Top level and extension function names of every file facade in [packageName] on the api classpath. */
fun packageFunctions(packageName: String): Set<String> {
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
