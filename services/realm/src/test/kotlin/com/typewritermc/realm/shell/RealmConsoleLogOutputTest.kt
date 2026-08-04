package com.typewritermc.realm.shell

import de.infix.testBalloon.framework.core.testSuite
import io.mockk.mockk
import io.mockk.verify
import org.jline.reader.LineReader

val RealmConsoleLogOutputTest by testSuite {
    test("prints above an attached interactive prompt") {
        val reader = mockk<LineReader>(relaxed = true)
        val output = RealmConsoleLogOutput()

        output.attach(reader)
        output.write("Realm is ready")

        verify(exactly = 1) { reader.printAbove("Realm is ready") }
    }

    test("stops using the prompt after detachment") {
        val reader = mockk<LineReader>(relaxed = true)
        val output = RealmConsoleLogOutput()

        output.attach(reader)
        output.detach()
        output.write("Realm stopped")

        verify(exactly = 0) { reader.printAbove(any<String>()) }
    }
}
