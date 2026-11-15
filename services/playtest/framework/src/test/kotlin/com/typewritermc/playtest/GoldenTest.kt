package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.Renderer
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import java.nio.file.Files

val GoldenTest by testSuite {
    val runner = Renderer("Vulkan", "llvmpipe (LLVM 20.1.2, 256 bits)", "Mesa 26.2.5", "amd64")
    val mac = Renderer("OpenGL", "Apple M1 Max", "4.1 Metal - 89.4", "aarch64")
    val sidebar = Frame(3, 2, intArrayOf(0x7F7F7F, 0x7F7F7F, 0xFFAA00, 0x7F7F7F, 0xFFFFFF, 0xFFAA00))
    val approved by lazy { Golden(sidebar.sha256, 3, 2, runner) }

    test("a frame whose every pixel is its golden's matches it") {
        val again = Frame(3, 2, intArrayOf(0x7F7F7F, 0x7F7F7F, 0xFFAA00, 0x7F7F7F, 0xFFFFFF, 0xFFAA00))

        judge(approved, sidebar, again, runner) shouldBe GoldenVerdict.Matches
    }

    test("a frame one pixel off its golden fails, and its diff image marks that pixel alone") {
        val moved = Frame(3, 2, intArrayOf(0x7F7F7F, 0x7F7F7F, 0xFFAA00, 0x7F7F7F, 0xFFFFFE, 0xFFAA00))

        val differs = judge(approved, sidebar, moved, runner).shouldBeInstanceOf<GoldenVerdict.Differs>()

        differs.reason shouldBe "1 of 6 pixels differ"
        val diff = checkNotNull(differs.diff)
        val marked = (0 until 2).flatMap { y -> (0 until 3).map { x -> x to y } }.filter { (x, y) -> diff.rgbAt(x, y) == 0xFF0000 }
        marked shouldBe listOf(1 to 1)
    }

    test("a frame off its golden fails without a diff image when the golden's image is not at hand") {
        val moved = Frame(3, 2, intArrayOf(0x7F7F7F, 0x7F7F7F, 0xFFAA00, 0x7F7F7F, 0xFFFFFE, 0xFFAA00))

        val differs = judge(approved, null, moved, runner).shouldBeInstanceOf<GoldenVerdict.Differs>()

        differs.reason shouldContain "its pixels hash to ${moved.sha256}, the golden's to ${sidebar.sha256}"
        differs.diff shouldBe null
    }

    test("a frame of another size than its golden fails") {
        val larger = Frame(6, 4, IntArray(24) { 0x7F7F7F })

        judge(approved, sidebar, larger, runner).shouldBeInstanceOf<GoldenVerdict.Differs>().reason shouldBe
            "the frame is 6x4, the golden 3x2"
    }

    test("a golden drawn by another renderer is not checked, and the reason names both renderers") {
        val verdict = judge(approved, sidebar, Frame(3, 2, IntArray(6)), mac).shouldBeInstanceOf<GoldenVerdict.NotChecked>()

        verdict.reason shouldBe
            "the golden was drawn by Vulkan, llvmpipe (LLVM 20.1.2, 256 bits), Mesa 26.2.5, amd64; " +
            "this run draws with OpenGL, Apple M1 Max, 4.1 Metal - 89.4, aarch64"
    }

    test("a golden never approved is not checked") {
        judge(null, null, sidebar, runner) shouldBe GoldenVerdict.NotChecked("no golden is approved yet")
    }

    test("a frame read back from its PNG holds the same pixels") {
        val png = Files.createTempDirectory("golden").resolve("sidebar.png")

        sidebar.writePng(png)

        Frame.readPng(png).sha256 shouldBe sidebar.sha256
    }

    test("a captured frame's candidate names its golden file, its image, hash, size and renderer for an approve") {
        val candidate = Files.createTempDirectory("attempt").resolve("sidebar.golden")

        Golden.writeCandidate(candidate, "services/playtest/framework/src/gameTest/goldens/sidebar.golden", "sidebar.png", sidebar, runner)

        Files.readString(candidate) shouldBe
            """
            golden=services/playtest/framework/src/gameTest/goldens/sidebar.golden
            image=sidebar.png
            sha256=${sidebar.sha256}
            width=3
            height=2
            backend=Vulkan
            device=llvmpipe (LLVM 20.1.2, 256 bits)
            driver=Mesa 26.2.5
            arch=amd64

            """.trimIndent()
    }

    test("a golden file holds the hash, size and renderer an approve wrote, and no file holds no golden") {
        val folder = Files.createTempDirectory("goldens")
        Files.writeString(
            folder.resolve("sidebar.golden"),
            """
            sha256=${sidebar.sha256}
            width=3
            height=2
            backend=Vulkan
            device=llvmpipe (LLVM 20.1.2, 256 bits)
            driver=Mesa 26.2.5
            arch=amd64
            """.trimIndent(),
        )

        Golden.read(folder.resolve("sidebar.golden")) shouldBe approved
        Golden.read(folder.resolve("hotbar.golden")) shouldBe null
    }
}
