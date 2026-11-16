package com.typewritermc.playtest.pool

import org.jacoco.core.data.ExecutionDataWriter
import org.jacoco.core.instr.Instrumenter
import org.jacoco.core.runtime.LoggerRuntime
import org.jacoco.core.runtime.RuntimeData
import java.io.ByteArrayOutputStream
import java.nio.file.Files
import java.nio.file.Path
import java.util.function.IntUnaryOperator

/**
 * [Subject] as the JaCoCo agent inside Paper counts it: instrumented as the agent instruments a plugin
 * class, with its counts read and reset in the agent's execution data format, and its class dumped
 * into [classes] the way the agent's `classdumpdir` does.
 */
class Counted(
    val classes: Path,
) {
    private val runtime = LoggerRuntime()
    private val data = RuntimeData().also(runtime::startup)
    private val name = Subject::class.java.name.replace('.', '/')
    private val original = checkNotNull(Subject::class.java.getResourceAsStream("/$name.class")).use { it.readAllBytes() }
    private val counted: IntUnaryOperator

    init {
        val instrumented = Instrumenter(runtime).instrument(original, name)
        val loader =
            object : ClassLoader(Counted::class.java.classLoader) {
                override fun loadClass(
                    className: String,
                    resolve: Boolean,
                ): Class<*> =
                    if (className == Subject::class.java.name) {
                        findLoadedClass(className) ?: defineClass(className, instrumented, 0, instrumented.size)
                    } else {
                        super.loadClass(className, resolve)
                    }
            }
        counted = loader.loadClass(Subject::class.java.name).getConstructor().newInstance() as IntUnaryOperator
    }

    /** Runs the subject's code [which] on the counted class; returns the source line that code sits on. */
    fun run(which: Int): Int = counted.applyAsInt(which)

    /** What ran since the last read, as the agent hands it over; from now on nothing counts as run. */
    fun readAndReset(): ByteArray {
        val out = ByteArrayOutputStream()
        val writer = ExecutionDataWriter(out)
        // The runtime hands over its live counts and zeroes them right after, so each is written as it comes.
        data.collect(
            { counted ->
                writer.visitClassExecution(counted)
                val dumped = classes.resolve("%s.%016x.class".format(counted.name, counted.id))
                Files.createDirectories(dumped.parent)
                Files.write(dumped, original)
            },
            writer,
            true,
        )
        return out.toByteArray()
    }

    /** A plugin class with code that runs apart: each answers the line it sits on. */
    class Subject : IntUnaryOperator {
        override fun applyAsInt(which: Int): Int = if (which == 1) first() else second()

        private fun first(): Int = Throwable().stackTrace[0].lineNumber

        private fun second(): Int = Throwable().stackTrace[0].lineNumber
    }

    companion object {
        /** The line the subject's code [which] sits on, from the class as compiled. */
        fun lineOf(which: Int): Int = Subject().applyAsInt(which)
    }
}
