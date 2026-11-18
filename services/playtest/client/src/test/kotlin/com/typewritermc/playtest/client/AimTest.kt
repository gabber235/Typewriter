package com.typewritermc.playtest.client

import com.typewritermc.playtest.client.Aim.Direction
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.shouldBe

val AimTest by testSuite {
    test("the default sensitivity turns the view 0.15 degrees per pixel") {
        Aim.degreesPerPixel(0.5) shouldBe (0.15 plusOrMinus 1e-9)
    }

    test("a target straight ahead to the south, east, north or west lies at yaw 0, -90, 180 or 90") {
        Aim.toward(0.0, 0.0, 0.0, 0.0, 0.0, 2.0).yaw shouldBe (0.0 plusOrMinus 1e-9)
        Aim.toward(0.0, 0.0, 0.0, 2.0, 0.0, 0.0).yaw shouldBe (-90.0 plusOrMinus 1e-9)
        Math.abs(Aim.toward(0.0, 0.0, 0.0, 0.0, 0.0, -2.0).yaw) shouldBe (180.0 plusOrMinus 1e-9)
        Aim.toward(0.0, 0.0, 0.0, -2.0, 0.0, 0.0).yaw shouldBe (90.0 plusOrMinus 1e-9)
    }

    test("a target below the eye has a positive pitch and one above a negative pitch") {
        Aim.toward(0.0, 1.62, 0.0, 0.0, 0.62, 1.0).pitch shouldBe (45.0 plusOrMinus 1e-9)
        Aim.toward(0.0, 1.62, 0.0, 0.0, 2.62, 1.0).pitch shouldBe (-45.0 plusOrMinus 1e-9)
    }

    test("the motion turns the short way round across south and north") {
        Aim.motion(Direction(170.0, 0.0), Direction(-170.0, 0.0), 0.15).x shouldBe (20.0 / 0.15 plusOrMinus 1e-6)
        Aim.motion(Direction(-170.0, 0.0), Direction(170.0, 0.0), 0.15).x shouldBe (-20.0 / 0.15 plusOrMinus 1e-6)
        Aim.motion(Direction(720.0, 0.0), Direction(10.0, 0.0), 0.15).x shouldBe (10.0 / 0.15 plusOrMinus 1e-6)
    }

    test("the motion turns pitch down for positive y and stops at the game's limit") {
        Aim.motion(Direction(0.0, 0.0), Direction(0.0, 30.0), 0.15).y shouldBe (30.0 / 0.15 plusOrMinus 1e-6)
        Aim.motion(Direction(0.0, 80.0), Direction(0.0, 120.0), 0.15).y shouldBe (10.0 / 0.15 plusOrMinus 1e-6)
        Aim.motion(Direction(0.0, -80.0), Direction(0.0, -120.0), 0.15).y shouldBe (-10.0 / 0.15 plusOrMinus 1e-6)
    }

    test("an angle wraps into minus 180 exclusive to 180") {
        Aim.wrap(180.0) shouldBe 180.0
        Aim.wrap(-180.0) shouldBe 180.0
        Aim.wrap(190.0) shouldBe (-170.0 plusOrMinus 1e-9)
        Aim.wrap(-540.0) shouldBe 180.0
        Aim.wrap(0.0) shouldBe 0.0
    }
}
