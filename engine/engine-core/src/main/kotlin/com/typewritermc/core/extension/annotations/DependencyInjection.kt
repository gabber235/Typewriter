package com.typewritermc.core.extension.annotations

@Target(AnnotationTarget.CLASS, AnnotationTarget.FUNCTION)
annotation class Singleton

@Target(AnnotationTarget.CLASS, AnnotationTarget.FUNCTION)
annotation class Factory

@Target(AnnotationTarget.CLASS, AnnotationTarget.FUNCTION)
annotation class Named(val value: String)

@Target(AnnotationTarget.VALUE_PARAMETER)
@Retention(AnnotationRetention.RUNTIME)
annotation class Parameter

@Target(AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
annotation class Inject(val name: String)